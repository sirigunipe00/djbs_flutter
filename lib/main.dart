import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/app_services.dart';
import 'strings.dart';
import 'theme.dart';

final messengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      // apiKey: 'AIzaSyAo6V6JCmsTEV1IaHRYGHhWwxei356a1-g',
      // appId: '1:943441457939:android:c69522079f7dc063',
      // messagingSenderId: '943441457939',
      // projectId: 'djbs-app',
      // databaseURL: 'https://djbs-app.firebaseio.com',
      // storageBucket: 'djbs-app.appspot.com',
      apiKey: 'AIzaSyDcX2zvjrBeXXQ5XDics45H-Me7RTqNFys',
      appId: '1:476147133104:android:d2a4b34415bf790e6a2975',
      messagingSenderId: '476147133104',
      projectId: 'djbs-foundation',
      databaseURL: 'https://djbs-foundation-default-rtdb.asia-southeast1.firebasedatabase.app',
      storageBucket: 'djbs-foundation.firebasestorage.app',
    ),
  );
  await Strings.instance.load();
  final agreed = await Prefs.hasAgreed();
  runApp(DjbsApp(startAtLogin: agreed));
}

class DjbsApp extends StatelessWidget {
  const DjbsApp({super.key, required this.startAtLogin});

  final bool startAtLogin;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Strings.instance,
      builder: (context, _) {
        return MaterialApp(
          title: s('app_name'),
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          scaffoldMessengerKey: messengerKey,
          home: SplashScreen(startAtLogin: startAtLogin),
        );
      },
    );
  }
}

void toast(String message) {
  messengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
