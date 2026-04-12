import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/ambulance_map_screen.dart';
import 'utils/language_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// MethodChannel to talk to MainActivity
const _sosChannel = MethodChannel('com.example.patient_app/sos_widget');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const PatientApp(),
    ),
  );
}

class PatientApp extends StatefulWidget {
  const PatientApp({super.key});
  @override
  State<PatientApp> createState() => _PatientAppState();
}

class _PatientAppState extends State<PatientApp> {
  @override
  void initState() {
    super.initState();
    _checkSOSLaunch();
    // Listen for widget tap while app is running
    _sosChannel.setMethodCallHandler((call) async {
      if (call.method == 'launchSOS') {
        _showSOSConfirmation();
      }
    });
  }

  // Check if app was launched FROM the widget
  Future<void> _checkSOSLaunch() async {
    try {
      final bool launched =
          await _sosChannel.invokeMethod('checkSOSLaunch') ?? false;
      if (launched) {
        // Wait for navigator to be ready
        await Future.delayed(const Duration(milliseconds: 500));
        _showSOSConfirmation();
      }
    } catch (e) {
      print('SOS check error: $e');
    }
  }

  void _showSOSConfirmation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      showDialog(
        context: ctx,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF161B27),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_rounded,
                    color: Color(0xFFFF3B30), size: 38),
              ),
              const SizedBox(height: 16),
              const Text('🚨 Emergency SOS',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              const Text(
                'An ambulance will be dispatched to your location.\n\nTap CANCEL if this was a mistake.',
                style: TextStyle(
                    color: Color(0xFF8B9EC7),
                    fontSize: 13,
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
              _SOSCountdownConfirm(
                onConfirmed: () {
                  Navigator.of(ctx).pop();
                  _launchSOS();
                },
                onCancelled: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('✅ SOS cancelled'),
                      backgroundColor: Color(0xFF00C896),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  void _launchSOS() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const AmbulanceMapScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthCare Pro',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C896),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF0D1117),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF161B27),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF1E2A42), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E2535),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E2A42)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E2A42)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF00C896), width: 1.5),
          ),
          hintStyle: GoogleFonts.poppins(
              color: const Color(0xFF4A5568), fontSize: 14),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C896),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF0D1117),
              body: Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF00C896)),
              ),
            );
          }
          if (snapshot.hasData) return const HomeScreen();
          return const AuthScreen();
        },
      ),
    );
  }
}

// ── Countdown — auto-SENDS SOS in 5 sec unless cancelled ───
class _SOSCountdownConfirm extends StatefulWidget {
  final VoidCallback onConfirmed;
  final VoidCallback onCancelled;

  const _SOSCountdownConfirm({
    required this.onConfirmed,
    required this.onCancelled,
  });

  @override
  State<_SOSCountdownConfirm> createState() =>
      _SOSCountdownConfirmState();
}

class _SOSCountdownConfirmState extends State<_SOSCountdownConfirm> {
  int _seconds = 5;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _seconds--);
      if (_seconds <= 0) {
        t.cancel();
        widget.onConfirmed(); // auto-send SOS
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          '$_seconds',
          style: TextStyle(
            color: _seconds <= 2
                ? const Color(0xFFFF3B30)
                : const Color(0xFFFFB347),
            fontSize: 48,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          'Sending SOS in $_seconds seconds...',
          style: const TextStyle(
              color: Color(0xFF8B9EC7), fontSize: 12),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: _seconds / 5,
          backgroundColor: const Color(0xFFFF3B30).withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            _seconds <= 2
                ? const Color(0xFFFF3B30)
                : const Color(0xFFFFB347),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _timer.cancel();
                  widget.onConfirmed();
                },
                icon: const Icon(Icons.local_hospital_rounded,
                    color: Colors.white, size: 16),
                label: const Text('Send Now',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B30),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _timer.cancel();
                  widget.onCancelled();
                },
                icon: const Icon(Icons.close_rounded,
                    color: Color(0xFF8B9EC7), size: 16),
                label: const Text('Cancel',
                    style: TextStyle(
                        color: Color(0xFF8B9EC7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1E2A42)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}