import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/tmdb_service.dart';
import 'services/volume_manager.dart';
import 'screens/library_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final tmdbService = TmdbService();
  tmdbService.setApiKey(prefs.getString('tmdb_api_key'));

  runApp(MediaCentreApp(
    tmdbService: tmdbService,
  ));
}

class MediaCentreApp extends StatelessWidget {
  final TmdbService tmdbService;

  const MediaCentreApp({
    super.key,
    required this.tmdbService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VolumeManager()..initialize()),
        Provider.value(value: tmdbService),
      ],
      child: MaterialApp(
        title: 'MediaCentre',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const LibraryScreen(),
      ),
    );
  }
}
