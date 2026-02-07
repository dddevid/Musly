import 'package:flutter_chrome_cast/entities/cast_device.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// <p>A class that manages the device discovery process. </p>
/// <p><a class="el notranslate" href="/cast/docs/reference/ios/interface_g_c_k_discovery_manager" data-title="A class that manages the device discovery process. ">GCKDiscoveryManager</a> manages a collection of <a class="el notranslate" href="/cast/docs/reference/ios/interface_g_c_k_device_provider" data-title="An abstract base class for performing device discovery and session construction. ">GCKDeviceProvider</a> subclass instances, each of which is responsible for discovering devices of a specific type. It also maintains a lexicographically ordered list of the currently discovered devices.</p>
/// <p>The framework automatically starts the discovery process when the application moves to the foreground and suspends it when the application moves to the background. It is generally not necessary for the application to call <a class="el notranslate" href="/cast/docs/reference/ios/interface_g_c_k_discovery_manager#a91dde311473c86fc4865d423498b8a2d" data-title="Starts the discovery process. ">startDiscovery (GCKDiscoveryManager)</a> and <a class="el notranslate" href="/cast/docs/reference/ios/interface_g_c_k_discovery_manager#a7ab4287d3ba99588f32689cefe053a15" data-title="Stops the discovery process. ">stopDiscovery (GCKDiscoveryManager)</a>, except as an optimization measure to reduce network traffic and CPU utilization in areas of the application that do not use Cast functionality.</p>
/// <p>If the application is using the framework's Cast dialog, either by way of <a class="el notranslate" href="/cast/docs/reference/ios/interface_g_c_k_u_i_cast_button" data-title="A subclass of UIButton that implements a &quot;Cast&quot; button. ">GCKUICastButton</a> or by presenting it directly, then that dialog will use <a class="el notranslate" href="/cast/docs/reference/ios/interface_g_c_k_discovery_manager" data-title="A class that manages the device discovery process. ">GCKDiscoveryManager</a> to populate its list of available devices. If however the application is providing its own device selection/control dialog UI, then it should use the <a class="el notranslate" href="/cast/docs/reference/ios/interface_g_c_k_discovery_manager" data-title="A class that manages the device discovery process. ">GCKDiscoveryManager</a> and its associated listener protocol, <a class="el notranslate" href="/cast/docs/reference/ios/protocol_g_c_k_discovery_manager_listener-p" data-title="The GCKDiscoveryManager listener protocol. ">GCKDiscoveryManagerListener</a>, to populate and update its list of available devices.</p>
/// <dl class="section since"><dt>Since</dt><dd>3.0 </dd></dl>

abstract class GoogleCastDiscoveryManagerPlatformInterface
    implements PlatformInterface {
  /// Returns the list of currently discovered devices.
  List<GoogleCastDevice> get devices;

  /// Returns a stream of the currently discovered devices.
  Stream<List<GoogleCastDevice>> get devicesStream;

  /// Starts the discovery process.
  /// strongly recommended to call this method when the application is show cast devices dialog
  /// because the battery consumption is high when the discovery process is running.
  Future<void> startDiscovery();

  ///Stops the discovery process.
  /// strongly recommended to call this method when the application close the show cast devices dialog
  /// for reduce battery consumption.
  Future<void> stopDiscovery();

  ///Tests whether discovery is currently active for the given device category.
  Future<bool> isDiscoveryActiveForDeviceCategory(String deviceCategory);
}
