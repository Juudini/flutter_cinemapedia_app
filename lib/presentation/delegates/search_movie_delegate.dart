import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:cinemapedia/config/helpers/human_formats.dart';
import 'package:cinemapedia/domain/entities/movie.dart';
import 'package:flutter/material.dart';

typedef SearchMoviesCallback = Future<List<Movie>> Function(String query);

class SearchMovieDelegate extends SearchDelegate<Movie?> {
  final SearchMoviesCallback searchMovies;
  final List<Movie> initialMovies;

  StreamController<List<Movie>> debouncedMovies = StreamController.broadcast();
  Timer? _debounceTimer;

  SearchMovieDelegate({
    required this.searchMovies,
    required this.initialMovies,
  });

  void clearStreams() {
    debouncedMovies.close();
  }

  void _onQueryChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(
      const Duration(milliseconds: 800),
      () async {
        if (query.isEmpty) {
          debouncedMovies.add([]);
          return;
        }
        final movies = await searchMovies(query);
        debouncedMovies.add(movies);
      },
    );
  }

  @override
  String get searchFieldLabel => 'Buscar películas';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      FadeIn(
        animate: query.isNotEmpty,
        child: IconButton(
          onPressed: () => query = '',
          icon: const Icon(Icons.clear),
        ),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        clearStreams();
        close(context, null);
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return const Text('build results');
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    _onQueryChanged(query);
    return StreamBuilder<Object>(
        stream: debouncedMovies.stream,
        builder: (context, snapshot) {
          return FutureBuilder(
            future: searchMovies(query),
            initialData: initialMovies,
            builder: (context, snapshot) {
              final movies = snapshot.data ?? [];

              return ListView.builder(
                itemCount: movies.length,
                itemBuilder: (context, index) => _MovieSearchItem(
                  movie: movies[index],
                  onMovieSelected: (context, movie) {
                    clearStreams();
                    close(context, movie);
                  },
                ),
              );
            },
          );
        });
  }
}

class _MovieSearchItem extends StatelessWidget {
  final Movie movie;
  final Function onMovieSelected;
  const _MovieSearchItem({required this.movie, required this.onMovieSelected});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textStyles = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () {
        onMovieSelected(context, movie);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: FadeIn(
                child: Image.network(
                  movie.posterPath,
                  height: 100,
                  width: 70,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: size.width * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: textStyles.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    movie.overview,
                    style: textStyles.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star_half,
                          color: Colors.amber, size: 20),
                      Text(
                        HumanFormats.number(movie.voteAverage, 1),
                        style: textStyles.bodySmall,
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
