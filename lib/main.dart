import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Screens
import 'screens/add_contacts_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/safety_counter_screen.dart';
import 'screens/location_sharing_screen.dart';
import 'screens/route_safety.dart';
import 'screens/home_screen.dart';
import 'screens/soslivestreamscreen.dart';
import 'screens/permission_flow.dart';
import 'screens/video_call_screen.dart';
import 'screens/sentinel_companion.dart';
import 'screens/registration_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/otp_input_screen.dart';
import 'screens/login_screen.dart';
//added by saravanan
//added by bhavanesh
// 🔔 Firebase Background Handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔔 BG Message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print(
        '📬 Foreground message received: ${message.notification?.title} - ${message.notification?.body}');
  });

  final prefs = await SharedPreferences.getInstance();
  final bool permissionsGiven = prefs.getBool('permissions_given') ?? false;
  final bool userRegistered = prefs.getBool('user_registered') ?? false;
  final bool phoneVerified = prefs.getBool('phone_verified') ?? false;
  final bool userLoggedIn = prefs.getBool('user_logged_in') ?? false;

  String initialRoute;
  if (!userLoggedIn) {
    initialRoute = '/login';
  } else if (!userRegistered) {
    initialRoute = '/register';
  } else if (!phoneVerified) {
    initialRoute = '/otp-verification';
  } else if (!permissionsGiven) {
    initialRoute = '/permissions';
  } else {
    initialRoute = '/home';
  }

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Safety App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'SF Pro Display',
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegistrationScreen(),
        '/otp-input': (context) => OTPInputScreen(verificationId: '',),
        '/permissions': (context) => const PermissionFlow(),
        '/home': (context) => const HomeMapScreen(),
        '/sos': (context) => const SosLiveStreamScreen(),
        '/location-sharing': (context) => const TrustedLocationSharingScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/safety-counter': (context) => const SafetyCounterScreen(),
        '/video-call': (context) => const VideoCallScreen(),
        '/sentinel': (context) => const SentinelCompanionScreen(),
        '/add-contacts': (context) => const AddContactsScreen(),
        '/route-safety': (context) => const RouteSafetyScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/otp-verification') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              return OTPVerificationScreen(verificationId: args['verificationId']);
            },
          );
        }
        return null;
      },
    );
  }
}
