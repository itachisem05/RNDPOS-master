import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:usa/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:usa/API/api_service.dart';

Future<void> initializeFirebase() async {
  // Check if Firebase has already been initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeFirebase();

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  setupForegroundMessageListener();
  runApp(MyApp());

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // Get the device token
  String? token = await messaging.getToken();
  print('Device token: $token');
  print('User granted permission: ${settings.authorizationStatus}');
}

void setupForegroundMessageListener() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  String _data = '';
  late final ApiService _apiService;

  // New state variables to store device info
  String? deviceModelD;
  String? deviceOSD;
  List<String> languagesD = [];
  String timezoneD = '';
  String? token;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _apiService = ApiService();
    _loadData(); // Load saved data on startup
    getDeviceInfo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _data = prefs.getString('data') ?? '';
    });
  }

  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('data', _data);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveData(); // Save state when paused
    } else if (state == AppLifecycleState.resumed) {
      _loadData(); // Restore state when resumed
    }
  }

  Future<void> getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    languagesD = getDeviceLanguages();
    timezoneD = getDeviceTimezone();

    // Get device information
    if (Theme.of(context).platform == TargetPlatform.android) {
      var androidInfo = await deviceInfo.androidInfo;
      deviceModelD = androidInfo.model;
      deviceOSD = 'Android ${androidInfo.version.release}';
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      var iosInfo = await deviceInfo.iosInfo;
      deviceModelD = iosInfo.model;
      deviceOSD = 'iOS ${iosInfo.systemVersion}';
    }

    print('Device Model: $deviceModelD');
    print('Device OS: $deviceOSD');
    print('Languages: $languagesD');
    print('Timezone: $timezoneD');

    // Get the device token and post device info
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    token = await messaging.getToken();
    print('Device token: $token');

    if (token != null && deviceModelD != null && deviceOSD != null) {
      await _postDeviceInfo(
        identifier: token!,
        deviceModel: deviceModelD!,
        deviceOS: deviceOSD!,
      );
    }
  }

  List<String> getDeviceLanguages() {
    return List<String>.from(Intl.systemLocale.split('_'));
  }

  String getDeviceTimezone() {
    return DateTime.now().timeZoneName; // Gets the current timezone name
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'R&DPOS',
      debugShowCheckedModeBanner: false,
      routes: AppRoutes.routes,
      initialRoute: AppRoutes.splashScreen,
    );
  }

  Future<void> _postDeviceInfo({
    required String identifier,
    // required String fireBaseToken,
    // required String language,
    // required int timezone,
    required String deviceModel,
    required String deviceOS,
  }) async {
    try {
      var response = await _apiService.sendDeviceInfo(
        identifier: token ?? "",
        // fireBaseToken: fireBaseToken,
        // languages: languagesD ?? ,
        // timezone: timezoneD ?? "",
        deviceModel: deviceModelD ?? "",
        deviceOS: deviceOSD?? "",
      );

      print('Device info sent successfully: $response');
    } catch (e) {
      print('Data save failed: $e');
    }
  }
}
