import 'package:flutter/material.dart';
import 'package:flutter_chrome_cast/lib.dart';
import 'package:provider/provider.dart';
import '../services/cast_service.dart';

class CastButton extends StatelessWidget {
  const CastButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.cast),
      color: Colors.white,
      onPressed: () => _showCastDialog(context),
    );
  }

  Future<void> _showCastDialog(BuildContext context) async {
    final discoveryManager = GoogleCastDiscoveryManager.instance;
    await discoveryManager.startDiscovery();

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Cast Device'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<List<GoogleCastDevice>>(
              stream: discoveryManager.devicesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final devices = snapshot.data ?? [];

                if (devices.isEmpty) {
                  return const SizedBox(
                    height: 100,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Searching for devices...'),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      leading: const Icon(Icons.tv),
                      title: Text(device.friendlyName),
                      subtitle: Text(device.modelName ?? ''),
                      onTap: () {
                        context.read<CastService>().startSession(device);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    // Stop discovery when dialog closes to save battery
    await discoveryManager.stopDiscovery();
  }
}
