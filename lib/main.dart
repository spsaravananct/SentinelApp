import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

// Screens
import 'screens/add_contacts_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/otp_input_screen.dart';
import 'screens/safety_counter_screen.dart';
import 'screens/location_sharing_screen.dart';
import 'screens/route_safety.dart';
import 'screens/home_screen.dart';
import 'screens/soslivestreamscreen.dart';
import 'screens/permission_flow.dart';
import 'screens/video_call_screen.dart';
import 'screens/sentinel_companion.dart';
import 'screens/registration_screen.dart';
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

  // Initialize Firebase
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("❌ Firebase initialization failed: $e");
  }

  // Setup Firebase Cloud Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Handle Firebase foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📬 Foreground FCM: ${message.notification?.title} - ${message.notification?.body}');
    print('📬 Data: ${message.data}');
  });

  // Initialize OneSignal
  try {
    print('🔔 Initializing OneSignal...');
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize("f7eb2ffc-7c5a-4c4f-9bdb-2345f7ac9ec7");
    OneSignal.Notifications.requestPermission(true);

    // OneSignal event listeners
    OneSignal.User.pushSubscription.addObserver((state) {
      print('🔔 OneSignal ID: ${state.current.id}');
    });

    OneSignal.Notifications.addClickListener((event) {
      print('🔔 Notification clicked: ${event.notification.title}');
      // Handle navigation based on notification data
    });

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print('🔔 Foreground notification: ${event.notification.title}');
      event.notification.display();
    });

    // Get OneSignal ID after delay
    Future.delayed(const Duration(seconds: 3), () {
      final subId = OneSignal.User.pushSubscription.id;
      print('🔑 Final OneSignal ID: $subId');
    });

    print("✅ OneSignal initialized successfully");
  } catch (e) {
    print("❌ OneSignal initialization failed: $e");
  }

  // Get user state from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final bool permissionsGiven = prefs.getBool('permissions_given') ?? false;
  final bool userRegistered = prefs.getBool('user_registered') ?? false;
  final bool phoneVerified = prefs.getBool('phone_verified') ?? false;
  final bool userLoggedIn = prefs.getBool('user_logged_in') ?? false;

  // Determine initial route based on user state
  String initialRoute;
  if (!userRegistered) {
    // User hasn't registered yet, start with registration
    initialRoute = '/register';
  } else if (!phoneVerified) {
    // User registered but phone not verified, go to OTP verification
    initialRoute = '/otp-verification';
  } else if (!userLoggedIn) {
    // User registered and phone verified but not logged in, go to login
    initialRoute = '/login';
  } else if (!permissionsGiven) {
    // User logged in but permissions not given, go to permissions
    initialRoute = '/permissions';
  } else {
    // All steps completed, go to home
    initialRoute = '/home';
  }

  print("🚀 Starting app with initial route: $initialRoute");
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
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/otp-verification': (context) => const OTPVerificationScreen(verificationId: null,),
        '/otp-input': (context) => const OTPInputScreen(),
        '/login': (context) => const LoginScreen(),
        '/permissions': (context) => const PermissionFlow(),
        '/home': (context) => const HomeMapScreen(),
        '/sos': (context) => const SosLiveStreamScreen(),
        '/location-sharing': (context) => const TrustedLocationSharingScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/safety-counter': (context) => const SafetyCounterScreen(),
        '/video-call': (context) => const VideoCallScreen(),
        '/sentinel': (context) => const SentinelCompanionScreen(),
        '/add-contacts': (context) => ContactScreen(),
        '/route-safety': (context) => const RouteSafetyScreen(),
        '/test-onesignal': (context) => OneSignalTestPage(),
        '/test-backend': (context) => BackendTestPage(),
      },
      onGenerateRoute: (settings) {
        // Handle dynamic routes that need arguments
        switch (settings.name) {
          case '/otp-input':
            final args = settings.arguments as Map<String, String>?;
            return MaterialPageRoute(
              builder: (_) => const OTPInputScreen(),
              settings: RouteSettings(
                name: '/otp-input',
                arguments: args,
              ),
            );
          case '/otp-verification':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => OTPVerificationScreen(
                verificationId: args?['verificationId'] ?? '',
              ),
            );
          default:
            return null;
        }
      },
    );
  }
}