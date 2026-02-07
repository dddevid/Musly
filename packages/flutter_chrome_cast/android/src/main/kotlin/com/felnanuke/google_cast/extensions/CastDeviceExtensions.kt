package com.felnanuke.google_cast.extensions

import com.google.android.gms.cast.CastDevice

fun CastDevice.toMap(): Map<*, *> {
    return mapOf(
        "id" to this.deviceId,
        "name" to this.friendlyName,
        "model_name" to this.modelName,
        "device_version" to this.deviceVersion,
        "is_on_local_network" to this.isOnLocalNetwork,
    )

}