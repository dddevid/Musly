import json
import concurrent.futures
import urllib.request
import re
import yt_dlp

def _upgrade_thumb_url(url, size=800):
    if not url:
        return ""
    url_str = str(url).strip()
    if "googleusercontent.com" in url_str or "ggpht.com" in url_str:
        base = url_str.split("=")[0]
        return f"{base}=w{size}-h{size}-l90-rj"
    elif "i.ytimg.com" in url_str or "img.youtube.com" in url_str:
        match = re.search(r"/vi/([a-zA-Z0-9_-]{11})", url_str)
        if match:
            vid = match.group(1)
            return f"https://i.ytimg.com/vi/{vid}/hqdefault.jpg"
    return url_str

def _resolve_stream_fast_innertube(video_id):
    """Directly queries YouTube/YT Music Innertube player endpoint for instant (<200ms) audio stream resolution."""
    url = "https://www.youtube.com/youtubei/v1/player?prettyPrint=false"
    headers = {
        "User-Agent": "com.google.android.apps.youtube.music/6.33.52 (Linux; U; Android 13; en_US) gzip",
        "Content-Type": "application/json",
        "Origin": "https://music.youtube.com",
        "X-YouTube-Client-Name": "21",
        "X-YouTube-Client-Version": "6.33.52",
    }
    data = {
        "context": {
            "client": {
                "clientName": "ANDROID_MUSIC",
                "clientVersion": "6.33.52",
                "hl": "en",
                "gl": "US",
                "androidSdkVersion": 33
            }
        },
        "videoId": video_id,
        "playbackContext": {
            "contentPlaybackContext": {
                "html5Preference": "HTML5_PREF_WANTS"
            }
        }
    }
    try:
        req = urllib.request.Request(url, data=json.dumps(data).encode("utf-8"), headers=headers)
        resp = urllib.request.urlopen(req, timeout=3.5)
        res = json.loads(resp.read().decode("utf-8"))
        streaming_data = res.get("streamingData", {})
        formats = streaming_data.get("adaptiveFormats", [])
        
        audio_formats = [f for f in formats if f.get("mimeType", "").startswith("audio/") and f.get("url")]
        
        if not audio_formats:
            # Try with ANDROID main client
            data["context"]["client"] = {
                "clientName": "ANDROID",
                "clientVersion": "19.09.37",
                "hl": "en",
                "gl": "US",
                "androidSdkVersion": 33
            }
            req2 = urllib.request.Request(url, data=json.dumps(data).encode("utf-8"), headers=headers)
            resp2 = urllib.request.urlopen(req2, timeout=3.5)
            res2 = json.loads(resp2.read().decode("utf-8"))
            streaming_data2 = res2.get("streamingData", {})
            formats2 = streaming_data2.get("adaptiveFormats", [])
            audio_formats = [f for f in formats2 if f.get("mimeType", "").startswith("audio/") and f.get("url")]

        if audio_formats:
            audio_formats.sort(key=lambda x: int(x.get("bitrate") or 0), reverse=True)
            chosen = audio_formats[0]
            stream_url = chosen.get("url", "")
            mime = chosen.get("mimeType", "")
            ext = "webm" if "webm" in mime or "opus" in mime else "mp4"
            
            return {
                "url": stream_url,
                "headers": {
                    "User-Agent": "com.google.android.apps.youtube.music/6.33.52 (Linux; U; Android 13; en_US)",
                    "Accept": "*/*",
                },
                "ext": ext
            }
    except Exception:
        pass
    return None

def _extract_stream(video_id_or_url):
    clean_id = str(video_id_or_url).replace("ytmusic://", "")
    if clean_id.startswith("http"):
        if "v=" in clean_id:
            clean_id = clean_id.split("v=")[-1].split("&")[0]
        elif "/" in clean_id:
            clean_id = clean_id.split("/")[-1]

    # 1. Fast Innertube path (~150-300ms)
    fast = _resolve_stream_fast_innertube(clean_id)
    if fast and fast.get("url"):
        return fast

    # 2. yt-dlp fallback
    target = video_id_or_url if str(video_id_or_url).startswith("http") else f"https://www.youtube.com/watch?v={clean_id}"
    ydl_opts = {
        'format': 'ba/b[acodec!=none]/bestaudio/best',
        'quiet': True,
        'no_warnings': True,
        'nocheckcertificate': True,
        'noplaylist': True,
        'skip_download': True,
        'lazy_extractors': True,
        'no_color': True,
        'youtube_include_dash_manifest': False,
        'youtube_include_hls_manifest': False,
        'extractor_args': {
            'youtube': {
                'player_client': ['android_music', 'android', 'ios', 'mweb'],
                'skip': ['translated_subs', 'comments', 'webpage', 'dash', 'hls']
            }
        }
    }
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(target, download=False)
        url = info.get('url')
        headers = info.get('http_headers') or {}
        ext = info.get('ext') or 'mp4'
        if not url and 'entries' in info:
            entries = info.get('entries') or []
            if entries and entries[0]:
                url = entries[0].get('url')
                headers = entries[0].get('http_headers') or headers
                ext = entries[0].get('ext') or ext

        return {
            'url': url or '',
            'headers': headers,
            'ext': ext,
        }

def get_stream_url(video_id_or_url):
    """Extracts direct audio stream URL and matching HTTP headers using Innertube / yt-dlp."""
    return json.dumps(_extract_stream(video_id_or_url))

def _search_query(target, limit):
    ydl_opts = {
        'extract_flat': True,
        'quiet': True,
        'no_warnings': True,
        'nocheckcertificate': True,
        'skip_download': True,
        'lazy_extractors': True,
    }
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(target, download=False)
        entries = info.get('entries', []) or []
        results = []
        for e in entries[:limit]:
            if not e:
                continue
            item_id = e.get('id') or e.get('url') or ''
            title = e.get('title') or 'Unknown Title'
            artist = e.get('uploader') or e.get('channel') or e.get('artist') or 'Unknown Artist'
            duration = int(e.get('duration') or 0)
            thumbnails = e.get('thumbnails') or []
            raw_thumb = thumbnails[-1].get('url') if thumbnails and isinstance(thumbnails[-1], dict) else ''
            thumb_url = _upgrade_thumb_url(raw_thumb, 800) if raw_thumb else f"https://i.ytimg.com/vi/{item_id}/hqdefault.jpg"

            results.append({
                'id': item_id,
                'title': title,
                'artist': artist,
                'album': e.get('album'),
                'duration': duration,
                'thumbnailUrl': thumb_url,
                'coverArt': thumb_url if thumb_url else item_id,
            })
        return results

def _search_ytmusic_innertube(query, limit=25):
    """Directly queries the official YouTube Music Innertube API with the official Songs filter."""
    url = "https://music.youtube.com/youtubei/v1/search?prettyPrint=false"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Content-Type": "application/json",
        "Origin": "https://music.youtube.com",
        "Referer": "https://music.youtube.com/"
    }
    data = {
        "context": {
            "client": {
                "clientName": "WEB_REMIX",
                "clientVersion": "1.20240101.01.00",
                "hl": "en",
                "gl": "US"
            }
        },
        "query": query,
        "params": "EgWKAQIIAWoKEAUQAxAEEAkQBQ=="
    }
    try:
        req = urllib.request.Request(url, data=json.dumps(data).encode("utf-8"), headers=headers)
        resp = urllib.request.urlopen(req, timeout=7)
        res = json.loads(resp.read().decode("utf-8"))
        sections = res.get("contents", {}).get("tabbedSearchResultsRenderer", {}).get("tabs", [{}])[0].get("tabRenderer", {}).get("content", {}).get("sectionListRenderer", {}).get("contents", [])
        results = []
        for sec in sections:
            music_shelf = sec.get("musicShelfRenderer", {})
            contents = music_shelf.get("contents", [])
            for item in contents:
                r = item.get("musicResponsiveListItemRenderer", {})
                flex = r.get("flexColumns", [])
                if not flex:
                    continue
                title_runs = flex[0].get("musicResponsiveListItemFlexColumnRenderer", {}).get("text", {}).get("runs", [])
                title = title_runs[0].get("text", "") if title_runs else ""
                nav = title_runs[0].get("navigationEndpoint", {}).get("watchEndpoint", {}) if title_runs else {}
                video_id = nav.get("videoId", "")
                if not video_id:
                    overlay = r.get("overlay", {}).get("musicItemThumbnailOverlayRenderer", {}).get("content", {}).get("musicPlayButtonRenderer", {}).get("playNavigationEndpoint", {}).get("watchEndpoint", {})
                    video_id = overlay.get("videoId", "")
                if not video_id:
                    continue

                info_runs = flex[1].get("musicResponsiveListItemFlexColumnRenderer", {}).get("text", {}).get("runs", []) if len(flex) > 1 else []
                parts = []
                curr = []
                for x in info_runs:
                    t = x.get("text", "")
                    if t == " • ":
                        if curr:
                            parts.append("".join(curr))
                            curr = []
                    else:
                        curr.append(t)
                if curr:
                    parts.append("".join(curr))

                artist = "Unknown Artist"
                album_name = None
                duration_secs = 0
                if len(parts) >= 3:
                    artist = parts[0]
                    album_name = parts[1]
                    duration_str = parts[2]
                elif len(parts) == 2:
                    artist = parts[0]
                    duration_str = parts[1]
                elif len(parts) == 1:
                    artist = parts[0]
                    duration_str = "0:00"
                else:
                    duration_str = "0:00"

                dur_split = duration_str.split(":")
                if len(dur_split) == 2:
                    try:
                        duration_secs = int(dur_split[0]) * 60 + int(dur_split[1])
                    except Exception:
                        pass
                elif len(dur_split) == 3:
                    try:
                        duration_secs = int(dur_split[0]) * 3600 + int(dur_split[1]) * 60 + int(dur_split[2])
                    except Exception:
                        pass

                thumbs = r.get("thumbnail", {}).get("musicThumbnailRenderer", {}).get("thumbnail", {}).get("thumbnails", [])
                raw_thumb = thumbs[-1].get("url", "") if thumbs else ""
                thumb = _upgrade_thumb_url(raw_thumb, 800) if raw_thumb else f"https://i.ytimg.com/vi/{video_id}/hqdefault.jpg"

                results.append({
                    "id": video_id,
                    "title": title,
                    "artist": artist,
                    "album": album_name,
                    "duration": duration_secs,
                    "thumbnailUrl": thumb,
                    "coverArt": thumb if thumb else video_id
                })
                if len(results) >= limit:
                    break
            if len(results) >= limit:
                break
        return results
    except Exception:
        return []

def _search_youtube_innertube(query, limit=25):
    """Directly queries official YouTube Innertube API (<500ms) without yt-dlp."""
    url = "https://www.youtube.com/youtubei/v1/search?prettyPrint=false"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Content-Type": "application/json",
        "Origin": "https://www.youtube.com",
        "Referer": "https://www.youtube.com/"
    }
    data = {
        "context": {
            "client": {
                "clientName": "WEB",
                "clientVersion": "2.20240101.00.00",
                "hl": "en",
                "gl": "US"
            }
        },
        "query": query
    }
    try:
        req = urllib.request.Request(url, data=json.dumps(data).encode("utf-8"), headers=headers)
        resp = urllib.request.urlopen(req, timeout=5)
        res = json.loads(resp.read().decode("utf-8"))
        contents = res.get("contents", {}).get("twoColumnSearchResultsRenderer", {}).get("primaryContents", {}).get("sectionListRenderer", {}).get("contents", [])
        results = []
        for c in contents:
            item_sec = c.get("itemSectionRenderer", {}).get("contents", [])
            for item in item_sec:
                vr = item.get("videoRenderer", {})
                if not vr:
                    continue
                vid = vr.get("videoId")
                if not vid:
                    continue
                title_runs = vr.get("title", {}).get("runs", [])
                title = title_runs[0].get("text", "") if title_runs else "Unknown Title"
                owner_runs = vr.get("ownerText", {}).get("runs", [])
                artist = owner_runs[0].get("text", "") if owner_runs else "Unknown Artist"

                dur_text = vr.get("lengthText", {}).get("simpleText", "")
                dur_secs = 0
                if dur_text:
                    parts = dur_text.split(":")
                    if len(parts) == 2:
                        try: dur_secs = int(parts[0]) * 60 + int(parts[1])
                        except Exception: pass
                    elif len(parts) == 3:
                        try: dur_secs = int(parts[0]) * 3600 + int(parts[1]) * 60 + int(parts[2])
                        except Exception: pass

                thumb = f"https://i.ytimg.com/vi/{vid}/hqdefault.jpg"
                results.append({
                    "id": vid,
                    "title": title,
                    "artist": artist,
                    "album": None,
                    "duration": dur_secs,
                    "thumbnailUrl": thumb,
                    "coverArt": thumb
                })
                if len(results) >= limit:
                    break
            if len(results) >= limit:
                break
        return results
    except Exception:
        return []

def search_dual(query, limit=20):
    """Executes official YouTube Music and YouTube Classic searches concurrently via Innertube in <600ms."""
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
        f_music = executor.submit(_search_ytmusic_innertube, query, limit)
        f_classic = executor.submit(_search_youtube_innertube, query, limit)

        music_results = f_music.result()
        if not music_results:
            music_results = _search_youtube_innertube(f"{query} audio", limit)

        classic_results = f_classic.result()

    return json.dumps({
        'music': music_results,
        'youtube': classic_results,
    })

def search(query, limit=25):
    """Searches YouTube for tracks matching query using fast Innertube search (<500ms)."""
    results = _search_ytmusic_innertube(query, limit)
    if not results:
        results = _search_youtube_innertube(query, limit)
    return json.dumps(results)

def get_video_info(video_id_or_url):
    """Extracts metadata for a single video using yt-dlp."""
    clean_id = str(video_id_or_url).replace("ytmusic://", "")
    target = clean_id if clean_id.startswith("http") else f"https://www.youtube.com/watch?v={clean_id}"
    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
        'nocheckcertificate': True,
        'skip_download': True,
        'lazy_extractors': True,
    }
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(target, download=False)
        item_id = info.get('id') or clean_id
        thumbnails = info.get('thumbnails') or []
        raw_thumb = thumbnails[-1].get('url') if thumbnails and isinstance(thumbnails[-1], dict) else ''
        thumb_url = _upgrade_thumb_url(raw_thumb, 800) if raw_thumb else f"https://i.ytimg.com/vi/{item_id}/hqdefault.jpg"

        return json.dumps({
            'id': item_id,
            'title': info.get('title') or 'Unknown Title',
            'artist': info.get('uploader') or info.get('channel') or info.get('artist') or 'Unknown Artist',
            'album': info.get('album'),
            'duration': int(info.get('duration') or 0),
            'thumbnailUrl': thumb_url,
            'coverArt': thumb_url if thumb_url else item_id,
        })

def _get_ytmusic_radio(video_id, limit=50):
    """Fetches official YouTube Music Radio tracks directly via the YouTube Music Next endpoint."""
    url = "https://music.youtube.com/youtubei/v1/next?prettyPrint=false"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Content-Type": "application/json",
        "Origin": "https://music.youtube.com",
        "Referer": "https://music.youtube.com/"
    }
    data = {
        "context": {
            "client": {
                "clientName": "WEB_REMIX",
                "clientVersion": "1.20240101.01.00",
                "hl": "en",
                "gl": "US"
            }
        },
        "videoId": video_id,
        "playlistId": "RDAMVM" + video_id,
        "isAudioOnly": True
    }
    try:
        req = urllib.request.Request(url, data=json.dumps(data).encode("utf-8"), headers=headers)
        resp = urllib.request.urlopen(req, timeout=7)
        res = json.loads(resp.read().decode("utf-8"))
        tabs = res.get("contents", {}).get("singleColumnMusicWatchNextResultsRenderer", {}).get("tabbedRenderer", {}).get("watchNextTabbedResultsRenderer", {}).get("tabs", [])
        results = []
        for t in tabs:
            panel = t.get("tabRenderer", {}).get("content", {}).get("musicQueueRenderer", {}).get("content", {}).get("playlistPanelRenderer", {})
            contents = panel.get("contents", [])
            for item in contents:
                r = item.get("playlistPanelVideoRenderer", {})
                if not r:
                    continue
                vid = r.get("videoId", "")
                if not vid or vid == video_id:
                    continue
                title_runs = r.get("title", {}).get("runs", [])
                title = title_runs[0].get("text", "") if title_runs else ""
                byline_runs = r.get("longBylineText", {}).get("runs", [])
                parts = []
                curr = []
                for x in byline_runs:
                    t_str = x.get("text", "")
                    if t_str == " • ":
                        if curr:
                            parts.append("".join(curr))
                            curr = []
                    else:
                        curr.append(t_str)
                if curr:
                    parts.append("".join(curr))

                artist = parts[0] if parts else "Unknown Artist"
                album = parts[1] if len(parts) > 1 and "view" not in parts[1].lower() and "like" not in parts[1].lower() else None

                dur_str = r.get("lengthText", {}).get("runs", [{}])[0].get("text", "0:00")
                dur_split = dur_str.split(":")
                dur_secs = 0
                if len(dur_split) == 2:
                    try:
                        dur_secs = int(dur_split[0]) * 60 + int(dur_split[1])
                    except Exception:
                        pass
                elif len(dur_split) == 3:
                    try:
                        dur_secs = int(dur_split[0]) * 3600 + int(dur_split[1]) * 60 + int(dur_split[2])
                    except Exception:
                        pass

                thumbs = r.get("thumbnail", {}).get("thumbnails", [])
                raw_thumb = thumbs[-1].get("url", "") if thumbs else ""
                thumb = _upgrade_thumb_url(raw_thumb, 800) if raw_thumb else f"https://i.ytimg.com/vi/{vid}/hqdefault.jpg"

                results.append({
                    "id": vid,
                    "title": title,
                    "artist": artist,
                    "album": album,
                    "duration": dur_secs,
                    "thumbnailUrl": thumb,
                    "coverArt": thumb if thumb else vid
                })
                if len(results) >= limit:
                    break
            if len(results) >= limit:
                break
        return results
    except Exception:
        return []

def get_playlist(playlist_id_or_url, limit=50):
    """Extracts playlist/radio videos using official YouTube Music API with yt-dlp fallback."""
    raw = str(playlist_id_or_url).strip()

    if raw.startswith("RDAMVM") or raw.startswith("RD") or "RDAMVM" in raw or "list=RD" in raw:
        video_id = raw.replace("RDAMVM", "").replace("RD", "")
        if "list=" in video_id:
            video_id = video_id.split("list=")[-1].replace("RDAMVM", "").replace("RD", "")
        if "v=" in raw:
            video_id = raw.split("v=")[-1].split("&")[0]

        radio_tracks = _get_ytmusic_radio(video_id, limit)
        if radio_tracks:
            return json.dumps(radio_tracks)

    if raw.startswith("http"):
        target = raw
    elif raw.startswith("RDAMVM"):
        video_id = raw.replace("RDAMVM", "")
        target = f"https://www.youtube.com/watch?v={video_id}&list=RD{video_id}"
    elif raw.startswith("RD"):
        video_id = raw.replace("RD", "")
        target = f"https://www.youtube.com/watch?v={video_id}&list=RD{video_id}"
    else:
        target = f"https://www.youtube.com/playlist?list={raw}"

    ydl_opts = {
        'extract_flat': True,
        'quiet': True,
        'no_warnings': True,
        'nocheckcertificate': True,
        'skip_download': True,
        'lazy_extractors': True,
    }
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(target, download=False)
        entries = (info.get('entries', []) or [])[:limit]
        results = []
        for e in entries:
            if not e:
                continue
            item_id = e.get('id') or e.get('url') or ''
            if not item_id:
                continue
            title = e.get('title') or 'Unknown Title'
            artist = e.get('uploader') or e.get('channel') or e.get('artist') or 'Unknown Artist'
            duration = int(e.get('duration') or 0)
            thumbnails = e.get('thumbnails') or []
            raw_thumb = thumbnails[-1].get('url') if thumbnails and isinstance(thumbnails[-1], dict) else ''
            thumb_url = _upgrade_thumb_url(raw_thumb, 800) if raw_thumb else f"https://i.ytimg.com/vi/{item_id}/hqdefault.jpg"

            results.append({
                'id': item_id,
                'title': title,
                'artist': artist,
                'album': e.get('album'),
                'duration': duration,
                'thumbnailUrl': thumb_url,
                'coverArt': thumb_url if thumb_url else item_id,
            })
        return json.dumps(results)
