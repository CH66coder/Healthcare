import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/doctor_firebase_service.dart';
import 'doctor_home_screen.dart';

class DoctorAuthScreen extends StatefulWidget {
  const DoctorAuthScreen({super.key});
  @override
  State<DoctorAuthScreen> createState() => _DoctorAuthScreenState();
}

class _DoctorAuthScreenState extends State<DoctorAuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _svc = DoctorFirebaseService();

  // Login
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();

  // Register
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPass = TextEditingController();
  final _regSpecialty = TextEditingController();
  final _regLocation = TextEditingController();
  final _regExperience = TextEditingController();
  final _regFee = TextEditingController();

  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  static const Color _primary = Color(0xFF2196F3);
  static const Color _bg = Color(0xFF0A0F1E);
  static const Color _card = Color(0xFF131929);
  static const Color _border = Color(0xFF1E3050);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {})); // rebuild on tab change
  }

  @override
  void dispose() {
    _tab.dispose();
    _loginEmail.dispose(); _loginPass.dispose();
    _regName.dispose(); _regEmail.dispose(); _regPass.dispose();
    _regSpecialty.dispose(); _regLocation.dispose();
    _regExperience.dispose(); _regFee.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loginEmail.text.trim().isEmpty || _loginPass.text.isEmpty) {
      _snack('Fill all fields'); return;
    }
    setState(() => _loading = true);
    final user = await _svc.signIn(_loginEmail.text.trim(), _loginPass.text);
    setState(() => _loading = false);
    if (user != null && mounted) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const DoctorHomeScreen()));
    } else {
      _snack('Login failed. Check credentials.');
    }
  }

  Future<void> _register() async {
    if (_regName.text.isEmpty || _regEmail.text.isEmpty ||
        _regPass.text.isEmpty || _regSpecialty.text.isEmpty) {
      _snack('Name, email, specialty and password are required'); return;
    }
    setState(() => _loading = true);
    final user = await _svc.signUp(
      _regEmail.text.trim(),
      _regPass.text,
      _regName.text.trim(),
      _regSpecialty.text.trim().toLowerCase().replaceAll(' ', '-'),
      location: _regLocation.text.trim(),
      experienceYears: int.tryParse(_regExperience.text.trim()) ?? 1,
      consultationFee: double.tryParse(_regFee.text.trim()) ?? 500,
      rating: 4.5,
    );
    setState(() => _loading = false);
    if (user != null && mounted) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const DoctorHomeScreen()));
    } else {
      _snack('Registration failed. Try again.');
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: _card));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _primary.withOpacity(0.4), width: 2),
                ),
                child: const Icon(Icons.medical_services, color: _primary, size: 40),
              ),
              const SizedBox(height: 16),
              Text('Doctor Portal',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
              Text('HealthCare Pro',
                  style: GoogleFonts.poppins(color: const Color(0xFF8B9EC7), fontSize: 14)),
              const SizedBox(height: 40),

              // Tab bar
              Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                      color: _primary, borderRadius: BorderRadius.circular(10)),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF8B9EC7),
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  dividerColor: Colors.transparent,
                  tabs: const [Tab(text: 'Login'), Tab(text: 'Register')],
                ),
              ),
              const SizedBox(height: 24),

              // ── Show login or register form directly (no fixed height SizedBox) ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _tab.index == 0
                    ? _loginForm()
                    : _registerForm(),
              ),

              const SizedBox(height: 16),
              if (_loading)
                const CircularProgressIndicator(color: _primary),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loginForm() => Column(
        key: const ValueKey('login'),
        mainAxisSize: MainAxisSize.min,
        children: [
          _field(_loginEmail, 'Email', Icons.email_outlined,
              type: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _field(_loginPass, 'Password', Icons.lock_outline,
              obscure: _obscure1,
              suffix: IconButton(
                icon: Icon(
                    _obscure1 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color(0xFF8B9EC7), size: 20),
                onPressed: () => setState(() => _obscure1 = !_obscure1),
              )),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              child: const Text('Login'),
            ),
          ),
        ],
      );

  Widget _registerForm() => Column(
        key: const ValueKey('register'),
        mainAxisSize: MainAxisSize.min,
        children: [
          _field(_regName, 'Full Name', Icons.person_outline),
          const SizedBox(height: 10),
          _field(_regEmail, 'Email', Icons.email_outlined,
              type: TextInputType.emailAddress),
          const SizedBox(height: 10),
          _field(_regSpecialty, 'Specialty (e.g. dermatologist)',
              Icons.medical_services_outlined),
          const SizedBox(height: 10),
          _field(_regLocation, 'Location / City (e.g. Koramangala)',
              Icons.location_on_outlined),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _field(_regExperience, 'Experience (yrs)',
                  Icons.work_outline, type: TextInputType.number),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _field(_regFee, 'Consult Fee (₹)',
                  Icons.currency_rupee, type: TextInputType.number),
            ),
          ]),
          const SizedBox(height: 10),
          _field(_regPass, 'Password', Icons.lock_outline,
              obscure: _obscure2,
              suffix: IconButton(
                icon: Icon(
                    _obscure2 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color(0xFF8B9EC7), size: 20),
                onPressed: () => setState(() => _obscure2 = !_obscure2),
              )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _register,
              child: const Text('Register as Doctor'),
            ),
          ),
        ],
      );

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {bool obscure = false, Widget? suffix, TextInputType? type}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: type,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: const Color(0xFF4A5568), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF8B9EC7), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF1A2340),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E3050))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E3050))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}