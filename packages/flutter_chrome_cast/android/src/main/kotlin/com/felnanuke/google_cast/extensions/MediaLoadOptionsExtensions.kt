package com.felnanuke.google_cast.extensions

import com.google.android.gms.cast.MediaLoadOptions

class GoogleCastMediaLoadOptions {
    companion object {
        fun fromMap(map: Map<String, Any?>): MediaLoadOptions {
            val autoPlay = map["autoPlay"] as Boolean
            val playPosition = map["playPosition"] as Int
            val activeTrackIds = map["activeTrackIds"] as ArrayList<Long>?
            val credentials = map["credentials"] as String?
            val credentialsType = map["credentialsType"] as String?
            val playbackRate = map["playbackRate"] as Double
            val builder = MediaLoadOptions.Builder()
            builder.setAutoplay(autoPlay)
            builder.setPlayPosition((playPosition * 1000).toLong())
            if (activeTrackIds != null)
                builder.setActiveTrackIds(activeTrackIds.toLongArray())
            builder.setCredentials(credentials)
            builder.setCredentialsType(credentialsType)
            builder.setPlaybackRate(playbackRate)
            return builder.build()

        }
    }
}