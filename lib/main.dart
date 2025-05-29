import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

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
import 'screens/test-backend.dart';
import 'screens/onesignal_test_page.dart';

/// Background handler for Firebase Messaging
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔔 BG Message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    print("❌ Firebase initialization failed: $e");
  }

  // Setup Firebase Cloud Messaging background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Foreground message listener
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📬 Foreground FCM: ${message.notification?.title} - ${message.notification?.body}');
    print('📬 Data: ${message.data}');
  });

  // OneSignal Initialization
  print('🔔 Initializing OneSignal...');
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("f7eb2ffc-7c5a-4c4f-9bdb-2345f7ac9ec7");
  OneSignal.Notifications.requestPermission(true);

  OneSignal.User.pushSubscription.addObserver((state) {
    print('🔔 OneSignal ID: ${state.current.id}');
  });

  OneSignal.Notifications.addClickListener((event) {
    print('🔔 Notification clicked: ${event.notification.title}');
    // You can handle navigation here based on event.notification.additionalData
  });

  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    print('🔔 Foreground notification: ${event.notification.title}');
    event.notification.display(); // Show it manually
  });

  Future.delayed(Duration(seconds: 3), () {
    final subId = OneSignal.User.pushSubscription.id;
    print('🔑 Final OneSignal ID: $subId');
  });

  // Shared Preferences
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
        '/test-onesignal': (context) => OneSignalTestPage(),
        '/test-backend': (context) => BackendTestPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/otp-verification') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(
              verificationId: args['verificationId'],
            ),
          );
        }
        return null;
      },
    );
  }
}
