import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/volume_manager.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<VolumeManager>(
        builder: (context, manager, child) {
          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Storage Location',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
              ...manager.availableVolumes.map((volume) {
                final isActive = manager.activeVolume?.providerId == volume.providerId;
                final isLoading = manager.isLoading && isActive;

                return _VolumeTile(
                  volume: volume,
                  isActive: isActive,
                  isLoading: isLoading,
                  onSelect: () async {
                    if (!isActive) {
                      await manager.setVolume(volume);
                    }
                  },
                  onAuthenticate: volume.requiresAuth && !volume.isAuthenticated
                      ? () => manager.authenticateVolume(volume)
                      : null,
                );
              }),
              if (manager.error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              manager.error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: manager.clearError,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'About',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('MediaCentre'),
                subtitle: Text('Version 1.0.0'),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Your library is stored in a hidden app folder on Google Drive. '
                  'Only this app can access it. Switch between devices and your '
                  'data syncs automatically.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VolumeTile extends StatelessWidget {
  final dynamic volume;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onSelect;
  final VoidCallback? onAuthenticate;

  const _VolumeTile({
    required this.volume,
    required this.isActive,
    required this.isLoading,
    required this.onSelect,
    this.onAuthenticate,
  });

  @override
  Widget build(BuildContext context) {
    final requiresAuth = volume.requiresAuth;
    final isAuthenticated = volume.isAuthenticated;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: RadioListTile<String>(
        value: volume.providerId,
        groupValue: isActive ? volume.providerId : null,
        onChanged: isLoading ? null : (_) => onSelect(),
        title: Row(
          children: [
            Text(volume.providerName),
            if (isLoading) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getSubtitle(volume)),
            if (requiresAuth && !isAuthenticated && !isActive) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onAuthenticate,
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Sign In'),
              ),
            ],
            if (requiresAuth && isAuthenticated)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Connected',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        secondary: _getIcon(volume),
      ),
    );
  }

  String _getSubtitle(dynamic volume) {
    if (volume.providerId == 'local') {
      return 'Saved on this device only';
    } else if (volume.providerId == 'drive') {
      return 'Sync across all devices';
    }
    return '';
  }

  Icon _getIcon(dynamic volume) {
    if (volume.providerId == 'local') {
      return const Icon(Icons.storage);
    } else if (volume.providerId == 'drive') {
      return const Icon(Icons.cloud);
    }
    return const Icon(Icons.folder);
  }
}
