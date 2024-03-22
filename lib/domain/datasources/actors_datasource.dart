import 'package:cinemapedia/domain/entities/actor.dart';

abstract class ActorsDatatasource {
  Future<List<Actor>> getActorsByMovie(String movieId);
}
