import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/anilist_service.dart';
import '../services/lastfm_service.dart';
import '../services/open_library_service.dart';
import '../services/tmdb_service.dart';
import '../widgets/album_result_tile.dart';
import '../widgets/book_result_tile.dart';
import '../widgets/comic_result_tile.dart';
import '../widgets/rating_modal.dart';

class AddMediaScreen extends StatefulWidget {
  final int initialTab;

  const AddMediaScreen({super.key, this.initialTab = 0});

  @override
  State<AddMediaScreen> createState() => _AddMediaScreenState();
}

class _AddMediaScreenState extends State<AddMediaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<dynamic> _results = [];
  bool _isSearching = false;
  bool _isLoadingDetails = false;
  String? _error;
  Timer? _debounceTimer;
  int _currentPage = 1;
  bool _hasMore = false;
  String _lastQuery = '';
  final _openLibraryService = OpenLibraryService();
  final _anilistService = AniListService();

  LastFmService? get _lastFmService {
    try {
      return context.read<LastFmService>();
    } catch (_) {
      return null;
    }
  }

  TmdbService? get _tmdbService {
    try {
      return context.read<TmdbService>();
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 5, vsync: this, initialIndex: widget.initialTab);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      _results = [];
      _error = null;
      _currentPage = 1;
      _hasMore = false;
      _lastQuery = '';
    });
    _search(_searchController.text);
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _hasMore = false;
        _currentPage = 1;
        _lastQuery = '';
      });
      return;
    }

    final tmdbService = _tmdbService;
    if (_tabController.index < 2 &&
        (tmdbService == null || !tmdbService.isConfigured)) {
      setState(() {
        _error = 'TMDB API key not configured. Go to Settings to add it.';
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
      if (query != _lastQuery) {
        _results = [];
        _currentPage = 1;
      }
    });

    try {
      final page = _currentPage;
      if (_tabController.index == 0) {
        final results = await tmdbService!.searchMovies(query, page: page);
        setState(() {
          _results = page == 1 ? results : [..._results, ...results];
          _isSearching = false;
          _hasMore = results.isNotEmpty;
          _lastQuery = query;
        });
      } else if (_tabController.index == 1) {
        final results = await tmdbService!.searchTvShows(query, page: page);
        setState(() {
          _results = page == 1 ? results : [..._results, ...results];
          _isSearching = false;
          _hasMore = results.isNotEmpty;
          _lastQuery = query;
        });
      } else if (_tabController.index == 2) {
        final results =
            await _openLibraryService.searchBooks(query, page: page);
        setState(() {
          _results = page == 1 ? results : [..._results, ...results];
          _isSearching = false;
          _hasMore = results.isNotEmpty;
          _lastQuery = query;
        });
      } else if (_tabController.index == 3) {
        final results = await _anilistService.searchComics(query, page: page);
        setState(() {
          _results = page == 1 ? results : [..._results, ...results];
          _isSearching = false;
          _hasMore = results.isNotEmpty;
          _lastQuery = query;
        });
      } else {
        await _searchLastFm(query, page: page);
      }
    } catch (e) {
      setState(() {
        _error = 'Search failed: ${e.toString()}';
        _results = [];
        _isSearching = false;
        _hasMore = false;
      });
    }
  }

  Future<void> _searchLastFm(String query, {required int page}) async {
    final lastFm = _lastFmService;
    if (lastFm == null || !lastFm.isConfigured) {
      setState(() {
        _error = 'Last.fm API key not configured. Go to Settings to add it.';
        _results = [];
        _isSearching = false;
      });
      return;
    }

    final results = await lastFm.searchAlbums(query, page: page);
    setState(() {
      _results = page == 1 ? results : [..._results, ...results];
      _isSearching = false;
      _hasMore = results.isNotEmpty;
      _lastQuery = query;
    });
  }

  Future<void> _loadMore() async {
    if (_isSearching || !_hasMore) return;
    setState(() {
      _currentPage += 1;
    });
    await _search(_lastQuery);
  }

  Future<void> _selectMovie(TmdbSearchResult result) async {
    setState(() {
      _isLoadingDetails = true;
    });

    try {
      final tmdbService = _tmdbService;
      if (tmdbService == null) return;
      final details = await tmdbService.getMovieDetails(result.id);
      final posterUrl = details.getFullPosterUrl(tmdbService);

      final movie = MovieBlock(
        id: const Uuid().v4(),
        title: details.title,
        runtimeMinutes: details.runtime,
        posterUrl: posterUrl,
        synopsis: details.overview,
        tmdbId: details.id,
      );

      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });

        final modalResult = await RatingModal.show(
          context: context,
          media: movie,
          posterUrl: posterUrl,
          synopsis: details.overview,
          runtimeMinutes: details.runtime,
        );

        if (modalResult != null && mounted) {
          Navigator.pop(context, modalResult.media);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load movie details: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    }
  }

  Future<void> _selectTvShow(TmdbTvSearchResult result) async {
    setState(() {
      _isLoadingDetails = true;
    });

    try {
      final tmdbService = _tmdbService;
      if (tmdbService == null) return;
      final details = await tmdbService.getTvShowDetails(result.id);
      final posterUrl = details.getFullPosterUrl(tmdbService);

      final seasons = details.seasons.map((s) {
        return SeasonBlock(
          id: const Uuid().v4(),
          title: s.name,
          seasonNumber: s.seasonNumber,
          posterUrl: s.getFullPosterUrl(tmdbService),
        );
      }).toList();

      final tvShow = TvShowBlock(
        id: const Uuid().v4(),
        title: details.name,
        posterUrl: posterUrl,
        synopsis: details.overview,
        tmdbId: details.id,
        network: details.primaryNetwork,
        status: details.status,
        seasons: seasons,
      );

      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
        Navigator.pop(context, tvShow);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load TV show details: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    }
  }

  Future<void> _selectBook(OpenLibrarySearchResult result) async {
    final book = BookBlock(
      id: const Uuid().v4(),
      title: result.title,
      author: result.authorName,
      pageCount: result.pageCount ?? 0,
      isbn: result.isbn,
      coverUrl: result.coverUrl,
      openLibraryId: result.key,
    );
    Navigator.pop(context, book);
  }

  Future<void> _selectComic(AniListSearchResult result) async {
    final comic = ComicBookBlock(
      id: const Uuid().v4(),
      title: result.title,
      author: result.author,
      chapterCount: result.chapterCount ?? 0,
      coverUrl: result.coverImage,
      synopsis: result.description,
      anilistId: result.id,
    );
    Navigator.pop(context, comic);
  }

  Future<void> _selectAlbum(LastFmSearchResult result) async {
    final album = AlbumBlock(
      id: const Uuid().v4(),
      title: result.title,
      artist: result.artist,
      trackCount: result.trackCount ?? 0,
      coverUrl: result.imageUrl,
      lastFmMbid: result.mbid,
    );
    Navigator.pop(context, album);
  }

  @override
  Widget build(BuildContext context) {
    final tmdbService = _tmdbService;
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Add Media'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.movie), text: 'Movies'),
                Tab(icon: Icon(Icons.tv), text: 'TV Shows'),
                Tab(icon: Icon(Icons.menu_book), text: 'Books'),
                Tab(icon: Icon(Icons.style), text: 'Comics'),
                Tab(icon: Icon(Icons.album), text: 'Listen'),
              ],
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: switch (_tabController.index) {
                      0 => 'Search for a movie...',
                      1 => 'Search for a TV show...',
                      2 => 'Search for a book...',
                      3 => 'Search for a comic...',
                      _ => 'Search for an album...',
                    },
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _search,
                ),
              ),
              if (_tabController.index < 2 &&
                  !(tmdbService?.isConfigured ?? false))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'TMDB API key not configured.\nGo to Settings to add it.',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _results.isEmpty && _searchController.text.isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  switch (_tabController.index) {
                                    0 => Icons.movie_filter_outlined,
                                    1 => Icons.tv,
                                    2 => Icons.menu_book,
                                    3 => Icons.style,
                                    _ => Icons.album,
                                  },
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  switch (_tabController.index) {
                                    0 => 'No movies found',
                                    1 => 'No TV shows found',
                                    2 => 'No books found',
                                    3 => 'No comics found',
                                    _ => 'No albums found',
                                  },
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _results.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      switch (_tabController.index) {
                                        0 => 'Search for a movie to add',
                                        1 => 'Search for a TV show to add',
                                        2 => 'Search for a book to add',
                                        3 => 'Search for a comic to add',
                                        _ => 'Search for an album to add',
                                      },
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  Expanded(
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      itemCount: _results.length,
                                      itemBuilder: (context, index) {
                                        final result = _results[index];
                                        if (result is TmdbSearchResult) {
                                          return _MovieResultTile(
                                            result: result,
                                            tmdbService: tmdbService!,
                                            onTap: () => _selectMovie(result),
                                          );
                                        } else if (result
                                            is TmdbTvSearchResult) {
                                          return _TvResultTile(
                                            result: result,
                                            tmdbService: tmdbService!,
                                            onTap: () => _selectTvShow(result),
                                          );
                                        } else if (result
                                            is OpenLibrarySearchResult) {
                                          return BookResultTile(
                                            result: result,
                                            onTap: () => _selectBook(result),
                                          );
                                        } else if (result
                                            is AniListSearchResult) {
                                          return ComicResultTile(
                                            result: result,
                                            onTap: () => _selectComic(result),
                                          );
                                        } else if (result
                                            is LastFmSearchResult) {
                                          return AlbumResultTile(
                                            result: result,
                                            onTap: () => _selectAlbum(result),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                                  if (_hasMore)
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: TextButton(
                                        onPressed: _loadMore,
                                        child: const Text('Load More'),
                                      ),
                                    ),
                                ],
                              ),
              ),
            ],
          ),
        ),
        if (_isLoadingDetails)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _MovieResultTile extends StatelessWidget {
  final TmdbSearchResult result;
  final TmdbService tmdbService;
  final VoidCallback onTap;

  const _MovieResultTile({
    required this.result,
    required this.tmdbService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final posterUrl = result.getFullPosterUrl(tmdbService);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: posterUrl != null
                    ? CachedNetworkImage(
                        imageUrl: posterUrl,
                        width: 60,
                        height: 90,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 60,
                          height: 90,
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 60,
                          height: 90,
                          color: Colors.grey[300],
                          child: const Icon(Icons.movie, size: 30),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 90,
                        color: Colors.grey[300],
                        child: const Icon(Icons.movie, size: 30),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (result.year.isNotEmpty) ...[
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            result.year,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (result.voteAverage != null) ...[
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            result.voteAverage!.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (result.overview != null &&
                        result.overview!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        result.overview!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TvResultTile extends StatelessWidget {
  final TmdbTvSearchResult result;
  final TmdbService tmdbService;
  final VoidCallback onTap;

  const _TvResultTile({
    required this.result,
    required this.tmdbService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final posterUrl = result.getFullPosterUrl(tmdbService);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: posterUrl != null
                    ? CachedNetworkImage(
                        imageUrl: posterUrl,
                        width: 60,
                        height: 90,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 60,
                          height: 90,
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 60,
                          height: 90,
                          color: Colors.grey[300],
                          child: const Icon(Icons.tv, size: 30),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 90,
                        color: Colors.grey[300],
                        child: const Icon(Icons.tv, size: 30),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (result.year.isNotEmpty) ...[
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            result.year,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (result.voteAverage != null) ...[
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            result.voteAverage!.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (result.overview != null &&
                        result.overview!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        result.overview!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
