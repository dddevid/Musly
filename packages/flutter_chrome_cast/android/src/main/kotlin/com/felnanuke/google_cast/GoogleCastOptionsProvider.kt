package com.felnanuke.google_cast
import android.content.Context
import com.google.android.gms.cast.framework.CastOptions
import com.google.android.gms.cast.framework.OptionsProvider
import com.google.android.gms.cast.framework.SessionProvider



  class GoogleCastOptionsProvider : OptionsProvider {
     companion object{
         var options: CastOptions? = null
     }
    override fun getCastOptions(context: Context): CastOptions {
        if (options == null) {
            val launcherOptions = com.google.android.gms.cast.LaunchOptions.Builder()
                .setAndroidReceiverCompatible(true)
                .build()
            options = CastOptions.Builder()
                .setReceiverApplicationId("CC1AD845") // Default Media Receiver
                .setLaunchOptions(launcherOptions)
                .setResumeSavedSession(true)
                .setEnableReconnectionService(true)
                .build()
        }
        return options!!
    }

    override fun getAdditionalSessionProviders(p0: Context): MutableList<SessionProvider>? {
        return null
    }
}