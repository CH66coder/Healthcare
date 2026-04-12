import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/firebase_service.dart';
import '../utils/language_provider.dart';
import '../widgets/language_toggle.dart';
import 'chat_history_screen.dart';
import 'doctors_screen.dart';
import 'pharmacy_screen.dart';
import 'health_records_screen.dart';
import 'appointments_screen.dart';
import 'lab_test_screen.dart';
import 'doctor_requests_screen.dart';
import 'ambulance_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const Color _primary = Color(0xFF00C896);
  static const Color _bg     = Color(0xFF0D1117);
  static const Color _card   = Color(0xFF161B27);
  static const Color _border = Color(0xFF1E2A42);
  static const Color _red    = Color(0xFFFF3B30);

  // SOS hold state
  bool   _sosPressing  = false;
  double _sosProgress  = 0.0;
  int    _sosCountdown = 3;
  Timer? _sosTimer;

  final List<Widget> _screens = const [
    _HomeTab(),
    DoctorsScreen(),
    PharmacyScreen(),
    HealthRecordsScreen(),
  ];

  void _onSosPressStart() {
    setState(() {
      _sosPressing  = true;
      _sosProgress  = 0.0;
      _sosCountdown = 3;
    });
    HapticFeedback.heavyImpact();

    int ticks = 0;
    _sosTimer = Timer.periodic(
        const Duration(milliseconds: 50), (timer) {
      ticks++;
      setState(() {
        _sosProgress  = ticks / 60;
        _sosCountdown = 3 - (ticks / 20).floor();
        if (_sosCountdown < 1) _sosCountdown = 1;
      });
      if (ticks % 20 == 0) HapticFeedback.mediumImpact();
      if (ticks >= 60) {
        timer.cancel();
        setState(() {
          _sosPressing  = false;
          _sosProgress  = 0.0;
          _sosCountdown = 3;
        });
        HapticFeedback.heavyImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AmbulanceMapScreen()),
        );
      }
    });
  }

  void _onSosPressEnd() {
    _sosTimer?.cancel();
    setState(() {
      _sosPressing  = false;
      _sosProgress  = 0.0;
      _sosCountdown = 3;
    });
  }

  @override
  void dispose() {
    _sosTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Main screen content ──────────────────
          _screens[_currentIndex],

          // ── SOS countdown overlay ────────────────
          if (_sosPressing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.82),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width:  160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          Container(
                            width:  160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _red.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                          ),
                          // Progress ring
                          SizedBox(
                            width:  140,
                            height: 140,
                            child: CircularProgressIndicator(
                              value:      _sosProgress,
                              strokeWidth: 7,
                              backgroundColor:
                                  _red.withOpacity(0.15),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                      _red),
                            ),
                          ),
                          // Countdown number
                          Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_sosCountdown',
                                style: GoogleFonts.poppins(
                                  color:      _red,
                                  fontSize:   64,
                                  fontWeight: FontWeight.w900,
                                  height:     1,
                                ),
                              ),
                              Text(
                                'sec',
                                style: GoogleFonts.poppins(
                                  color:    _red.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      lang.isTamil ? '🚨 SOS அனுப்புகிறோம்...' : '🚨 Sending SOS...',
                      style: GoogleFonts.poppins(
                        color:      _red,
                        fontSize:   22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      lang.isTamil ? 'விட்டுவிட ரத்து செய்யும்' : 'Release to cancel',
                      style: GoogleFonts.poppins(
                        color:    Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Cancel button
                    GestureDetector(
                      onTap: _onSosPressEnd,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.white24),
                          borderRadius:
                              BorderRadius.circular(30),
                        ),
                        child: Text(
                          lang.t('cancel'),
                          style: GoogleFonts.poppins(
                            color:    Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: _card,
          border:
              Border(top: BorderSide(color: _border, width: 1)),
        ),
        child: Row(
          children: [
            // ── Left 2 tabs ──────────────────────────
            Expanded(
              child: BottomNavigationBar(
                currentIndex:
                    _currentIndex < 2 ? _currentIndex : 0,
                onTap: (i) =>
                    setState(() => _currentIndex = i),
                backgroundColor: Colors.transparent,
                selectedItemColor: _primary,
                unselectedItemColor: const Color(0xFF4A5568),
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                selectedLabelStyle: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
                unselectedLabelStyle:
                    GoogleFonts.poppins(fontSize: 11),
                items: [
                  BottomNavigationBarItem(
                      icon: const Icon(Icons.home_outlined),
                      activeIcon: const Icon(Icons.home_rounded),
                      label: lang.isTamil ? 'முகப்பு' : 'Home'),
                  BottomNavigationBarItem(
                      icon: const Icon(Icons.medical_services_outlined),
                      activeIcon: const Icon(Icons.medical_services_rounded),
                      label: lang.isTamil ? 'மருத்துவர்' : 'Doctors'),
                ],
              ),
            ),

            // ── SOS Button ───────────────────────────
            GestureDetector(
              onTapDown: (_) => _onSosPressStart(),
              onTapUp:   (_) => _onSosPressEnd(),
              onTapCancel:   _onSosPressEnd,
              child: Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                width:  64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _red,
                  boxShadow: [
                    BoxShadow(
                      color:      _red.withOpacity(0.5),
                      blurRadius: 18,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                        Icons.local_hospital_rounded,
                        color: Colors.white,
                        size: 24),
                    Text(
                      'SOS',
                      style: GoogleFonts.poppins(
                        color:      Colors.white,
                        fontSize:   10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Right 2 tabs ─────────────────────────
            Expanded(
              child: BottomNavigationBar(
                currentIndex: _currentIndex >= 2
                    ? _currentIndex - 2
                    : 0,
                onTap: (i) =>
                    setState(() => _currentIndex = i + 2),
                backgroundColor: Colors.transparent,
                selectedItemColor: _primary,
                unselectedItemColor: const Color(0xFF4A5568),
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                selectedLabelStyle: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
                unselectedLabelStyle:
                    GoogleFonts.poppins(fontSize: 11),
                items: [
                  BottomNavigationBarItem(
                      icon: const Icon(Icons.local_pharmacy_outlined),
                      activeIcon: const Icon(Icons.local_pharmacy_rounded),
                      label: lang.isTamil ? 'மருந்தகம்' : 'Pharmacy'),
                  BottomNavigationBarItem(
                      icon: const Icon(Icons.folder_outlined),
                      activeIcon: const Icon(Icons.folder_rounded),
                      label: lang.isTamil ? 'பதிவுகள்' : 'Records'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HOME TAB ──────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  const _HomeTab();
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _svc = FirebaseService();
  late final Stream<QuerySnapshot> _apptStream;
  late final Stream<QuerySnapshot> _labStream;
  late final Stream<QuerySnapshot> _requestsStream;

  final List<Map<String, dynamic>> _healthFactsEn = [
    {
      'icon':  '💧',
      'fact':  'Drink 8 glasses of water daily to stay hydrated and boost energy.',
      'color': Color(0xFF2196F3),
    },
    {
      'icon':  '🏃',
      'fact':  '30 minutes of walking daily reduces heart disease risk by 35%.',
      'color': Color(0xFF00C896),
    },
    {
      'icon':  '😴',
      'fact':  '7–9 hours of sleep strengthens your immune system significantly.',
      'color': Color(0xFF6C63FF),
    },
    {
      'icon':  '🥦',
      'fact':  'Eating colorful vegetables daily provides essential antioxidants.',
      'color': Color(0xFF4CAF50),
    },
    {
      'icon':  '🧘',
      'fact':  '10 minutes of meditation daily reduces stress and anxiety by 40%.',
      'color': Color(0xFFFFB347),
    },
    {
      'icon':  '❤️',
      'fact':  'Laughing 15 minutes a day improves blood flow and heart health.',
      'color': Color(0xFFFF6B6B),
    },
    {
      'icon':  '🌞',
      'fact':  '15 minutes of morning sunlight boosts vitamin D and mood.',
      'color': Color(0xFFFFD700),
    },
  ];

  final List<Map<String, dynamic>> _healthFactsTa = [
    {
      'icon':  '💧',
      'fact':  'தினமும் 8 கிளாஸ் தண்ணீர் குடிப்பது உடலை சுறுசுறுப்பாக வைக்கும்.',
      'color': Color(0xFF2196F3),
    },
    {
      'icon':  '🏃',
      'fact':  'தினமும் 30 நிமிட நடைப்பயிற்சி இதய நோய் அபாயத்தை 35% குறைக்கும்.',
      'color': Color(0xFF00C896),
    },
    {
      'icon':  '😴',
      'fact':  '7-9 மணி நேர தூக்கம் உங்கள் நோய் எதிர்ப்பு சக்தியை வலுப்படுத்தும்.',
      'color': Color(0xFF6C63FF),
    },
    {
      'icon':  '🥦',
      'fact':  'வண்ணமயமான காய்கறிகள் சாப்பிடுவது அத்தியாவசிய ஆன்டிஆக்ஸிடன்ட்களை வழங்கும்.',
      'color': Color(0xFF4CAF50),
    },
    {
      'icon':  '🧘',
      'fact':  'தினமும் 10 நிமிட தியானம் மன அழுத்தத்தை 40% குறைக்கும்.',
      'color': Color(0xFFFFB347),
    },
    {
      'icon':  '❤️',
      'fact':  'தினமும் 15 நிமிடம் சிரிப்பது இரத்த ஓட்டத்தை மேம்படுத்தும்.',
      'color': Color(0xFFFF6B6B),
    },
    {
      'icon':  '🌞',
      'fact':  'காலை 15 நிமிட வெயில் விட்டமின் D மற்றும் மனநிலையை மேம்படுத்தும்.',
      'color': Color(0xFFFFD700),
    },
  ];

  int    _factIndex   = 0;
  double _factOpacity = 1.0;
  Timer? _factTimer;

  static const Color _primary = Color(0xFF00C896);
  static const Color _bg      = Color(0xFF0D1117);
  static const Color _card    = Color(0xFF161B27);
  static const Color _border  = Color(0xFF1E2A42);
  static const Color _text2   = Color(0xFF8B9EC7);

  @override
  void initState() {
    super.initState();
    _apptStream     = _svc.listenToMyAppointments();
    _labStream      = _svc.listenToMyLabTests();
    _requestsStream = _svc.listenToDoctorRequests();
    _startFactRotation();
  }

  void _startFactRotation() {
    _factTimer =
        Timer.periodic(const Duration(seconds: 5), (_) async {
      setState(() => _factOpacity = 0.0);
      await Future.delayed(const Duration(milliseconds: 400));
      setState(
          () => _factIndex = (_factIndex + 1) % _healthFactsEn.length);
      setState(() => _factOpacity = 1.0);
    });
  }

  @override
  void dispose() {
    _factTimer?.cancel();
    super.dispose();
  }

  void _showProfilePopup(BuildContext context) {
    final lang  = context.read<LanguageProvider>();
    final user  = FirebaseAuth.instance.currentUser;
    final name  = user?.displayName ?? 'Patient';
    final email = user?.email ?? '';

    showModalBottomSheet(
      context:          context,
      backgroundColor:  Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF161B27),
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
              top: BorderSide(
                  color: Color(0xFF1E2A42), width: 1)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width:  40,
              height: 4,
              decoration: BoxDecoration(
                color:        const Color(0xFF1E2A42),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width:  80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primary.withOpacity(0.8),
                    const Color(0xFF6C63FF).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:       _primary.withOpacity(0.3),
                    blurRadius:  20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'P',
                  style: GoogleFonts.poppins(
                      color:      Colors.white,
                      fontSize:   32,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(name,
                style: GoogleFonts.poppins(
                    color:      Colors.white,
                    fontSize:   20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(email,
                style: GoogleFonts.poppins(
                    color: _text2, fontSize: 13)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color:  _primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_rounded,
                      color: _primary, size: 14),
                  const SizedBox(width: 6),
                  Text(lang.isTamil ? 'நோயாளி' : 'Patient',
                      style: GoogleFonts.poppins(
                          color:      _primary,
                          fontSize:   12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Language toggle inside profile ──
            const LanguageToggle(),
            const SizedBox(height: 12),
            _ProfileInfoRow(
                icon:  Icons.person_outline_rounded,
                label: lang.isTamil ? 'முழு பெயர்' : 'Full Name',
                value: name),
            const SizedBox(height: 12),
            _ProfileInfoRow(
                icon:  Icons.email_outlined,
                label: lang.isTamil ? 'மின்னஞ்சல்' : 'Email',
                value: email),
            const SizedBox(height: 12),
            _ProfileInfoRow(
                icon:  Icons.shield_outlined,
                label: lang.isTamil ? 'கணக்கு வகை' : 'Account Type',
                value: lang.isTamil ? 'நோயாளி கணக்கு' : 'Patient Account'),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFFF4757).withOpacity(0.15),
                  foregroundColor: const Color(0xFFFF4757),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                        color: const Color(0xFFFF4757)
                            .withOpacity(0.3)),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await _svc.signOut();
                },
                icon: const Icon(Icons.logout_rounded,
                    size: 18),
                label: Text(
                  lang.isTamil ? 'வெளியேறு' : 'Log Out',
                  style: GoogleFonts.poppins(
                      fontSize:   15,
                      fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang  = context.watch<LanguageProvider>();
    final user  = FirebaseAuth.instance.currentUser;
    final name  = user?.displayName ?? 'Patient';
    final currentFact = lang.isTamil
        ? _healthFactsTa[_factIndex]
        : _healthFactsEn[_factIndex];

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Decorative background ──────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _HealthBgPainter(),
            ),
          ),
          // ── Main content ───────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${lang.t('hello')}, $name 👋',
                            style: GoogleFonts.poppins(
                                color:      Colors.white,
                                fontSize:   22,
                                fontWeight: FontWeight.w700)),
                          Text(
                            lang.t('how_feeling'),
                            style: GoogleFonts.poppins(
                                color:    _text2,
                                fontSize: 14)),
                        ],
                      ),
                      const Spacer(),
                      // ── Language toggle in header ──
                      const LanguageToggle(),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () =>
                            _showProfilePopup(context),
                        child: Container(
                          width:  44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _primary.withOpacity(0.7),
                                const Color(0xFF6C63FF)
                                    .withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end:   Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:      _primary
                                    .withOpacity(0.25),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : 'P',
                              style: GoogleFonts.poppins(
                                  color:      Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize:   18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Health Fact Card ─────────────
                  AnimatedOpacity(
                    opacity:  _factOpacity,
                    duration: const Duration(
                        milliseconds: 400),
                    child: Container(
                      width:   double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (currentFact['color'] as Color)
                                .withOpacity(0.15),
                            (currentFact['color'] as Color)
                                .withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end:   Alignment.bottomRight,
                        ),
                        borderRadius:
                            BorderRadius.circular(18),
                        border: Border.all(
                          color:
                              (currentFact['color'] as Color)
                                  .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width:  52,
                            height: 52,
                            decoration: BoxDecoration(
                              color:
                                  (currentFact['color']
                                          as Color)
                                      .withOpacity(0.15),
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                currentFact['icon']
                                    as String,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontFamilyFallback: [
                                    'Apple Color Emoji',
                                    'Noto Color Emoji',
                                    'Segoe UI Emoji',
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.isTamil ? 'உடல்நல குறிப்பு 💡' : 'Health Tip 💡',
                                  style: GoogleFonts.poppins(
                                      color: currentFact['color'] as Color,
                                      fontSize:    11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5)),
                                const SizedBox(height: 4),
                                Text(
                                  currentFact['fact'] as String,
                                  style: GoogleFonts.poppins(
                                      color:      Colors.white,
                                      fontSize:   13,
                                      fontWeight: FontWeight.w500,
                                      height:     1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Doctor Requests Banner ───────
                  StreamBuilder<QuerySnapshot>(
                    stream: _requestsStream,
                    builder: (context, snapshot) {
                      final count =
                          snapshot.data?.docs.length ?? 0;
                      if (count == 0)
                        return const SizedBox.shrink();
                      return GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const
                                    DoctorRequestsScreen())),
                        child: Container(
                          margin: const EdgeInsets.only(
                              bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF)
                                .withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFF6C63FF)
                                    .withOpacity(0.4)),
                          ),
                          child: Row(children: [
                            Container(
                              padding:
                                  const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF6C63FF)
                                        .withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: const Text('📋',
                                  style: TextStyle(
                                      fontSize: 22)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.isTamil
                                        ? '$count மருத்துவர் கோரிக்கை நிலுவையில்'
                                        : '$count Doctor Request${count > 1 ? 's' : ''} Pending',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize:   14,
                                        fontWeight:
                                            FontWeight.w700),
                                  ),
                                  Text(
                                    lang.isTamil ? 'காண தட்டவும்' : 'Tap to view & confirm',
                                    style: GoogleFonts.poppins(
                                        color:    _text2,
                                        fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF6C63FF)),
                          ]),
                        ),
                      );
                    },
                  ),

                  // ── Quick Actions ────────────────
                  Text(lang.t('quick_actions'),
                      style: GoogleFonts.poppins(
                          color:      Colors.white,
                          fontSize:   16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 14),
                  Column(
                    children: [
                      Row(children: [
                        Expanded(
                          child: _QuickAction(
                            icon:     Icons.smart_toy_outlined,
                            label:    lang.t('medibot'),
                            subtitle: lang.t('medibot_sub'),
                            color:    const Color(0xFF6C63FF),
                            emoji:    '🤖',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const
                                        ChatHistoryScreen())),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.medical_services_outlined,
                            label:    lang.t('find_doctor'),
                            subtitle: lang.t('find_doctor_sub'),
                            color:    const Color(0xFF00C896),
                            emoji:    '👨‍⚕️',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const DoctorsScreen())),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: _QuickAction(
                            icon:
                                Icons.local_pharmacy_outlined,
                            label:    lang.t('pharmacy'),
                            subtitle: lang.t('pharmacy_sub'),
                            color:    const Color(0xFFFF6B6B),
                            emoji:    '💊',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const PharmacyScreen())),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickAction(
                            icon:     Icons.science_outlined,
                            label:    lang.t('lab_tests'),
                            subtitle: lang.t('lab_tests_sub'),
                            color:    const Color(0xFFFFB347),
                            emoji:    '🧪',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const LabTestScreen())),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: _QuickAction(
                            icon:
                                Icons.calendar_today_outlined,
                            label:    lang.t('appointments'),
                            subtitle: lang.t('appointments_sub'),
                            color:    const Color(0xFF2196F3),
                            emoji:    '📅',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const
                                        AppointmentsScreen())),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickAction(
                            icon:     Icons.folder_outlined,
                            label:    lang.t('records'),
                            subtitle: lang.t('records_sub'),
                            color:    const Color(0xFF00BCD4),
                            emoji:    '📋',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const
                                        HealthRecordsScreen())),
                          ),
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── My Appointments ──────────────
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(lang.t('my_appointments'),
                          style: GoogleFonts.poppins(
                              color:      Colors.white,
                              fontSize:   16,
                              fontWeight: FontWeight.w600)),
                      TextButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const
                                    AppointmentsScreen())),
                        child: Text(lang.t('view_all'),
                            style: GoogleFonts.poppins(
                                color:    _primary,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: _apptStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return _EmptyCard(
                            icon:    '📅',
                            message: lang.t('no_appointments'));
                      }
                      final docs =
                          snapshot.data!.docs.toList()
                            ..sort((a, b) {
                              final at = (a.data()
                                  as Map)['createdAt'];
                              final bt = (b.data()
                                  as Map)['createdAt'];
                              if (at == null) return 1;
                              if (bt == null) return -1;
                              return (bt as Timestamp)
                                  .compareTo(at as Timestamp);
                            });
                      return Column(
                        children: docs.take(2).map((doc) {
                          final d = doc.data()
                              as Map<String, dynamic>;
                          return _AppointmentCard(
                              data: d, docId: doc.id);
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── My Lab Tests ─────────────────
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang.isTamil ? 'என் ஆய்வக சோதனைகள்' : 'My Lab Tests',
                        style: GoogleFonts.poppins(
                            color:      Colors.white,
                            fontSize:   16,
                            fontWeight: FontWeight.w600)),
                      TextButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const LabTestScreen())),
                        child: Text(
                          lang.isTamil ? 'புதிதாக பதிவு செய்' : 'Book New',
                          style: GoogleFonts.poppins(
                              color:    _primary,
                              fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: _labStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return _EmptyCard(
                            icon:    '🧪',
                            message: lang.isTamil
                                ? 'இன்னும் ஆய்வக சோதனைகள் இல்லை'
                                : 'No lab tests booked yet');
                      }
                      final docs =
                          snapshot.data!.docs.toList()
                            ..sort((a, b) {
                              final at = (a.data()
                                  as Map)['createdAt'];
                              final bt = (b.data()
                                  as Map)['createdAt'];
                              if (at == null) return 1;
                              if (bt == null) return -1;
                              return (bt as Timestamp)
                                  .compareTo(at as Timestamp);
                            });
                      return Column(
                        children: docs.take(2).map((doc) {
                          final d = doc.data()
                              as Map<String, dynamic>;
                          final tests =
                              (d['tests'] as List?)
                                      ?.join(', ') ??
                                  'Tests';
                          final status =
                              d['status'] ?? 'pending';
                          final sc = status == 'completed'
                              ? const Color(0xFF8B9EC7)
                              : const Color(0xFFFFB347);
                          return Container(
                            margin: const EdgeInsets.only(
                                bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _card,
                              borderRadius:
                                  BorderRadius.circular(14),
                              border: Border.all(
                                  color: _border),
                            ),
                            child: Row(children: [
                              Container(
                                padding:
                                    const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                          0xFFFFB347)
                                      .withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(
                                          12),
                                ),
                                child: const Text('🧪',
                                    style: TextStyle(
                                        fontSize: 20)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(tests,
                                        style: GoogleFonts
                                            .poppins(
                                                color: Colors
                                                    .white,
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight
                                                        .w600),
                                        maxLines: 1,
                                        overflow: TextOverflow
                                            .ellipsis),
                                    Text(d['lab'] ?? '',
                                        style: GoogleFonts
                                            .poppins(
                                                color: _text2,
                                                fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets
                                    .symmetric(
                                    horizontal: 10,
                                    vertical:   4),
                                decoration: BoxDecoration(
                                  color:
                                      sc.withOpacity(0.15),
                                  borderRadius:
                                      BorderRadius.circular(
                                          20),
                                ),
                                child: Text(status,
                                    style: GoogleFonts.poppins(
                                        color:      sc,
                                        fontSize:   11,
                                        fontWeight:
                                            FontWeight.w600)),
                              ),
                            ]),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Health Background Painter ─────────────────────────────
class _HealthBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final g1 = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFF00C896).withOpacity(0.13),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.85, size.height * 0.08),
        radius: size.width * 0.5,
      ));
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.08),
        size.width * 0.5, g1);

    final g2 = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFF6C63FF).withOpacity(0.11),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.1, size.height * 0.75),
        radius: size.width * 0.5,
      ));
    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.75),
        size.width * 0.5, g2);

    final g3 = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFF2196F3).withOpacity(0.07),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.45),
        radius: size.width * 0.6,
      ));
    canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.45),
        size.width * 0.6, g3);

    final ecgPaint = Paint()
      ..color       = const Color(0xFF00C896).withOpacity(0.07)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;

    final hbPath = Path();
    final hbY    = size.height * 0.18;
    final sx     = size.width * 0.03;
    hbPath.moveTo(sx, hbY);
    hbPath.lineTo(sx + size.width * 0.10, hbY);
    hbPath.lineTo(sx + size.width * 0.13, hbY - 20);
    hbPath.lineTo(sx + size.width * 0.16, hbY + 28);
    hbPath.lineTo(sx + size.width * 0.19, hbY - 14);
    hbPath.lineTo(sx + size.width * 0.22, hbY);
    hbPath.lineTo(sx + size.width * 0.40, hbY);
    canvas.drawPath(hbPath, ecgPaint);

    final hbPath2 = Path();
    final hbY2    = size.height * 0.55;
    final sx2     = size.width * 0.6;
    hbPath2.moveTo(sx2, hbY2);
    hbPath2.lineTo(sx2 + size.width * 0.08, hbY2);
    hbPath2.lineTo(sx2 + size.width * 0.11, hbY2 - 16);
    hbPath2.lineTo(sx2 + size.width * 0.14, hbY2 + 22);
    hbPath2.lineTo(sx2 + size.width * 0.17, hbY2 - 10);
    hbPath2.lineTo(sx2 + size.width * 0.20, hbY2);
    hbPath2.lineTo(sx2 + size.width * 0.32, hbY2);
    canvas.drawPath(
        hbPath2,
        ecgPaint
          ..color =
              const Color(0xFF6C63FF).withOpacity(0.06));

    final crossPaint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap   = StrokeCap.round;

    void drawCross(double x, double y, double r, Color c) {
      crossPaint.color = c.withOpacity(0.07);
      canvas.drawLine(
          Offset(x - r, y), Offset(x + r, y), crossPaint);
      canvas.drawLine(
          Offset(x, y - r), Offset(x, y + r), crossPaint);
    }

    drawCross(size.width * 0.93, size.height * 0.28, 11,
        const Color(0xFF2196F3));
    drawCross(size.width * 0.07, size.height * 0.48, 8,
        const Color(0xFF00C896));
    drawCross(size.width * 0.80, size.height * 0.63, 13,
        const Color(0xFFFF6B6B));
    drawCross(size.width * 0.12, size.height * 0.85, 9,
        const Color(0xFFFFB347));

    final circlePaint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1;
    circlePaint.color =
        const Color(0xFF6C63FF).withOpacity(0.06);
    canvas.drawCircle(
        Offset(size.width * 0.92, size.height * 0.52),
        42, circlePaint);
    circlePaint.color =
        const Color(0xFF00C896).withOpacity(0.05);
    canvas.drawCircle(
        Offset(size.width * 0.05, size.height * 0.22),
        30, circlePaint);
    circlePaint.color =
        const Color(0xFF2196F3).withOpacity(0.04);
    canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.92),
        55, circlePaint);

    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 14; i++) {
      final t    = i / 13;
      final side = i % 2 == 0 ? 1 : -1;
      final x    = size.width * 0.96 + 10.0 * side;
      final y    = size.height * 0.32 + t * size.height * 0.35;
      dotPaint.color =
          const Color(0xFF00C896).withOpacity(0.09 - t * 0.05);
      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
      if (i < 13) {
        canvas.drawLine(
          Offset(x, y),
          Offset(
              size.width * 0.96 + 10.0 * -side,
              size.height * 0.32 +
                  (i + 1) / 13 * size.height * 0.35),
          Paint()
            ..color       =
                const Color(0xFF00C896).withOpacity(0.04)
            ..strokeWidth = 0.8,
        );
      }
    }

    final heartPaint = Paint()
      ..color       = const Color(0xFFFF6B6B).withOpacity(0.06)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final hx       = size.width * 0.87;
    final hy       = size.height * 0.83;
    const hs       = 24.0;
    final heartPath = Path();
    heartPath.moveTo(hx, hy + hs * 0.35);
    heartPath.cubicTo(
        hx, hy, hx - hs, hy, hx - hs, hy - hs * 0.3);
    heartPath.cubicTo(
        hx - hs, hy - hs * 0.85, hx, hy - hs * 0.8,
        hx, hy - hs * 0.3);
    heartPath.cubicTo(
        hx, hy - hs * 0.8, hx + hs, hy - hs * 0.85,
        hx + hs, hy - hs * 0.3);
    heartPath.cubicTo(hx + hs, hy, hx, hy, hx, hy + hs * 0.35);
    canvas.drawPath(heartPath, heartPaint);

    final pillPaint = Paint()
      ..color       = const Color(0xFFFFB347).withOpacity(0.06)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(
              size.width * 0.08, size.height * 0.35),
          width:  14,
          height: 30),
      const Radius.circular(7),
    );
    canvas.drawRRect(pillRect, pillPaint);
    canvas.drawLine(
      Offset(size.width * 0.08 - 7, size.height * 0.35),
      Offset(size.width * 0.08 + 7, size.height * 0.35),
      pillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      false;
}

// ─── Profile Info Row ──────────────────────────────────────
class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        const Color(0xFF1E2535),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF1E2A42)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00C896).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              color: const Color(0xFF00C896), size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    color:    const Color(0xFF8B9EC7),
                    fontSize: 11)),
            Text(value,
                style: GoogleFonts.poppins(
                    color:      Colors.white,
                    fontSize:   13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ]),
    );
  }
}

// ─── Quick Action Card ─────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData   icon;
  final String     label;
  final String     subtitle;
  final String     emoji;
  final Color      color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25)),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.12),
              color.withOpacity(0.04),
              const Color(0xFF161B27),
            ],
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
            stops:  const [0.0, 0.4, 1.0],
          ),
        ),
        child: Row(
          children: [
            Text(
              emoji,
              style: const TextStyle(
                fontSize: 28,
                fontFamilyFallback: [
                  'Apple Color Emoji',
                  'Noto Color Emoji',
                  'Segoe UI Emoji',
                  'Twemoji Mozilla',
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.poppins(
                          color:      Colors.white,
                          fontSize:   13,
                          fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          color:    const Color(0xFF8B9EC7),
                          fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color:        color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  color: color, size: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State Card ──────────────────────────────────────
class _EmptyCard extends StatelessWidget {
  final String icon;
  final String message;
  const _EmptyCard(
      {required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        const Color(0xFF161B27),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2A42)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon,
              style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Text(message,
              style: GoogleFonts.poppins(
                  color:    const Color(0xFF8B9EC7),
                  fontSize: 14)),
        ],
      ),
    );
  }
}

// ─── Appointment Card ──────────────────────────────────────
class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String               docId;
  const _AppointmentCard(
      {required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'pending';
    Color statusColor = const Color(0xFFFFB347);
    if (status == 'confirmed')
      statusColor = const Color(0xFF00C896);
    if (status == 'completed')
      statusColor = const Color(0xFF8B9EC7);

    return Container(
      margin:  const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        const Color(0xFF161B27),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2A42)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00C896).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
                Icons.medical_services_outlined,
                color: Color(0xFF00C896),
                size:  22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['doctorName'] ?? 'Doctor',
                    style: GoogleFonts.poppins(
                        color:      Colors.white,
                        fontSize:   14,
                        fontWeight: FontWeight.w600)),
                Text(data['specialty'] ?? '',
                    style: GoogleFonts.poppins(
                        color:    const Color(0xFF8B9EC7),
                        fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:        statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status,
                style: GoogleFonts.poppins(
                    color:      statusColor,
                    fontSize:   11,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}