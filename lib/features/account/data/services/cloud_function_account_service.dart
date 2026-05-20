import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

/// Ejecuta el borrado completo de cuenta en el servidor (Auth + Firestore).
class CloudFunctionAccountService {
  CloudFunctionAccountService({FirebaseFunctions? functions})
    : _functions =
          functions ??
          FirebaseFunctions.instanceFor(
            app: Firebase.app(),
            region: 'us-central1',
          );

  final FirebaseFunctions _functions;

  Future<void> deleteUserAccount() async {
    final callable = _functions.httpsCallable('deleteUserAccount');
    await callable.call();
  }
}
