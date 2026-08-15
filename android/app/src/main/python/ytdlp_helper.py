import json
import concurrent.futures
import yt_dlp

def _extract_stream(video_id_or_url):
    target = video_id_or_url if str(video_id_or_url).startswith("http") else f"https://www.youtube.com/watch?v={video_id_or_url}"
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
                'player_client': ['android', 'ios', 'mweb'],
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
    """Extracts direct audio stream URL and matching HTTP headers using yt-dlp."""
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
            thumb_url = thumbnails[-1].get('url') if thumbnails and isinstance(thumbnails[-1], dict) else ''

            results.append({
                'id': item_id,
                'title': title,
                'artist': artist,
                'album': e.get('album'),
                'duration': duration,
                'thumbnailUrl': thumb_url,
                'coverArt': item_id,
            })
        return results

import urllib.request

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
                    except:
                        pass
                elif len(dur_split) == 3:
                    try:
                        duration_secs = int(dur_split[0]) * 3600 + int(dur_split[1]) * 60 + int(dur_split[2])
                    except:
                        pass

                thumbs = r.get("thumbnail", {}).get("musicThumbnailRenderer", {}).get("thumbnail", {}).get("thumbnails", [])
                thumb = thumbs[-1].get("url", "") if thumbs else ""

                results.append({
                    "id": video_id,
                    "title": title,
                    "artist": artist,
                    "album": album_name,
                    "duration": duration_secs,
                    "thumbnailUrl": thumb,
                    "coverArt": video_id
                })
                if len(results) >= limit:
                    break
            if len(results) >= limit:
                break
        return results
    except Exception:
        return []

def search_dual(query, limit=20):
    """Executes official YouTube Music and YouTube Classic searches concurrently."""
    classic_target = f"ytsearch{limit}:{query}"

    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
        f_music = executor.submit(_search_ytmusic_innertube, query, limit)
        f_classic = executor.submit(_search_query, classic_target, limit)

        music_results = f_music.result()
        # Fallback to yt-dlp search if Innertube search is empty
        if not music_results:
            music_results = _search_query(f"ytsearch{limit}:{query} audio", limit)

        classic_results = f_classic.result()

    return json.dumps({
        'music': music_results,
        'youtube': classic_results,
    })

def search(query, limit=25):
    """Searches YouTube for tracks matching query using yt-dlp."""
    return json.dumps(_search_query(f"ytsearch{limit}:{query}", limit))

def get_video_info(video_id_or_url):
    """Extracts metadata for a single video using yt-dlp."""
    target = video_id_or_url if str(video_id_or_url).startswith("http") else f"https://www.youtube.com/watch?v={video_id_or_url}"
    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
        'nocheckcertificate': True,
        'skip_download': True,
        'lazy_extractors': True,
    }
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(target, download=False)
        item_id = info.get('id') or str(video_id_or_url)
        thumbnails = info.get('thumbnails') or []
        thumb_url = thumbnails[-1].get('url') if thumbnails and isinstance(thumbnails[-1], dict) else ''

        return json.dumps({
            'id': item_id,
            'title': info.get('title') or 'Unknown Title',
            'artist': info.get('uploader') or info.get('channel') or info.get('artist') or 'Unknown Artist',
            'album': info.get('album'),
            'duration': int(info.get('duration') or 0),
            'thumbnailUrl': thumb_url,
            'coverArt': item_id,
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
                    except:
                        pass
                elif len(dur_split) == 3:
                    try:
                        dur_secs = int(dur_split[0]) * 3600 + int(dur_split[1]) * 60 + int(dur_split[2])
                    except:
                        pass

                thumbs = r.get("thumbnail", {}).get("thumbnails", [])
                thumb = thumbs[-1].get("url", "") if thumbs else ""

                results.append({
                    "id": vid,
                    "title": title,
                    "artist": artist,
                    "album": album,
                    "duration": dur_secs,
                    "thumbnailUrl": thumb,
                    "coverArt": vid
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

    # If it is a radio request (RDAMVM... or RD...), use official YouTube Music Radio endpoint
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
            thumb_url = thumbnails[-1].get('url') if thumbnails and isinstance(thumbnails[-1], dict) else ''

            results.append({
                'id': item_id,
                'title': title,
                'artist': artist,
                'album': e.get('album'),
                'duration': duration,
                'thumbnailUrl': thumb_url,
                'coverArt': item_id,
            })
        return json.dumps(results)
