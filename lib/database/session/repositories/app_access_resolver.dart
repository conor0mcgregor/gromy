import '../models/app_access_state.dart';

abstract interface class AppAccessResolver {
  Stream<AppAccessState> watch();

  Future<AppAccessState> resolve();
}
