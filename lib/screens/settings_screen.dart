import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/lastfm_service.dart';
import '../services/tmdb_service.dart';
import '../services/volume_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _lastFmKeyController = TextEditingController();
  bool _isTestingKey = false;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  void _loadApiKey() {
    final tmdbService = context.read<TmdbService>();
    _apiKeyController.text = tmdbService.apiKey ?? '';

    final lastFmService = context.read<LastFmService>();
    _lastFmKeyController.text = lastFmService.apiKey ?? '';
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _lastFmKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveApiKey() async {
    final tmdbService = context.read<TmdbService>();
    final prefs = await SharedPreferences.getInstance();
    final key = _apiKeyController.text.trim();

    if (key.isEmpty) {
      tmdbService.setApiKey(null);
      await prefs.remove('tmdb_api_key');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('TMDB API key removed')),
        );
      }
      return;
    }

    setState(() {
      _isTestingKey = true;
    });

    final isValid = await tmdbService.testApiKey(key);

    setState(() {
      _isTestingKey = false;
    });

    if (isValid) {
      tmdbService.setApiKey(key);
      await prefs.setString('tmdb_api_key', key);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('TMDB API key saved')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid API key. Please check and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveLastFmApiKey() async {
    final lastFmService = context.read<LastFmService>();
    final prefs = await SharedPreferences.getInstance();
    final key = _lastFmKeyController.text.trim();

    lastFmService.setApiKey(key.isEmpty ? null : key);
    if (key.isEmpty) {
      await prefs.remove('lastfm_api_key');
    } else {
      await prefs.setString('lastfm_api_key', key);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            key.isEmpty ? 'Last.fm API key removed' : 'Last.fm API key saved',
          ),
        ),
      );
    }
  }

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
                  'TMDB API Configuration',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.movie_filter_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'The Movie Database API Key',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Required for movie search and poster images. Get a free key at themoviedb.org',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _apiKeyController,
                          obscureText: _obscureKey,
                          decoration: InputDecoration(
                            labelText: 'API Key',
                            border: const OutlineInputBorder(),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _obscureKey
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureKey = !_obscureKey;
                                    });
                                  },
                                ),
                                if (_apiKeyController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _apiKeyController.clear();
                                      setState(() {});
                                    },
                                  ),
                              ],
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isTestingKey ? null : _saveApiKey,
                            icon: _isTestingKey
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                                _isTestingKey ? 'Validating...' : 'Save Key'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Last.fm API Configuration',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.album),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Last.fm API Key',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Required for album search in the Listen tab.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _lastFmKeyController,
                          decoration: const InputDecoration(
                            labelText: 'API Key',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saveLastFmApiKey,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Key'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
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
                final isActive =
                    manager.activeVolume?.providerId == volume.providerId;
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: manager.clearError,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
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
      child: InkWell(
        onTap: isLoading ? null : onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _getIcon(volume),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                    const SizedBox(height: 4),
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
              ),
              Icon(
                isActive ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ],
          ),
        ),
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
