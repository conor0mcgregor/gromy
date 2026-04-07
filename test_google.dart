import 'package:google_sign_in/google_sign_in.dart';

Future<void> main() async {
  await GoogleSignIn.instance.initialize(clientId: 'test');
  print(GoogleSignIn.instance);
}
