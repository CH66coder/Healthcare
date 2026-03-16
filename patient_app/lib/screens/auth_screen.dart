import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firebaseService = FirebaseService();

  // Login
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();

  // Register
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();

  bool _loading = false;
  bool _obscureLogin = true;
  bool _obscureReg = true;

  static const Color _primary = Color(0xFF00C896);
  static const Color _bg = Color(0xFF0D1117);
  static const Color _card = Color(0xFF161B27);
  static const Color _border = Color(0xFF1E2A42);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loginEmailCtrl.text.trim().isEmpty ||
        _loginPassCtrl.text.isEmpty) {
      _showSnack('Please fill all fields');
      return;
    }
    setState(() => _loading = true);
    final user = await _firebaseService.signIn(
        _loginEmailCtrl.text.trim(), _loginPassCtrl.text);
    setState(() => _loading = false);
    if (user != null && mounted) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      _showSnack('Login failed. Check credentials.');
    }
  }

  Future<void> _register() async {
    if (_regNameCtrl.text.trim().isEmpty ||
        _regEmailCtrl.text.trim().isEmpty ||
        _regPassCtrl.text.isEmpty) {
      _showSnack('Please fill all fields');
      return;
    }
    if (_regPassCtrl.text.length < 6) {
      _showSnack('Password must be at least 6 characters');
      return;
    }
    setState(() => _loading = true);
    final user = await _firebaseService.signUp(
        _regEmailCtrl.text.trim(),
        _regPassCtrl.text,
        _regNameCtrl.text.trim());
    setState(() => _loading = false);
    if (user != null && mounted) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      _showSnack('Registration failed. Try again.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: const Color(0xFF1E2535)));
  }

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
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _primary.withOpacity(0.4), width: 2),
                ),
                child: const Icon(Icons.medical_services_rounded,
                    color: _primary, size: 40),
              ),
              const SizedBox(height: 16),
              Text('HealthCare Pro',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700)),
              Text('Your health, our priority',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF8B9EC7), fontSize: 14)),
              const SizedBox(height: 40),
              // Tab bar
              Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF8B9EC7),
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  dividerColor: Colors.transparent,
                  tabs: const [Tab(text: 'Login'), Tab(text: 'Register')],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 340,
                child: TabBarView(
                  controller: _tabController,
                  children: [_loginForm(), _registerForm()],
                ),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const CircularProgressIndicator(color: _primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loginForm() {
    return Column(
      children: [
        _field(
          controller: _loginEmailCtrl,
          hint: 'Email address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _field(
          controller: _loginPassCtrl,
          hint: 'Password',
          icon: Icons.lock_outline,
          obscure: _obscureLogin,
          suffixIcon: IconButton(
            icon: Icon(
                _obscureLogin ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: const Color(0xFF8B9EC7),
                size: 20),
            onPressed: () => setState(() => _obscureLogin = !_obscureLogin),
          ),
        ),
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
  }

  Widget _registerForm() {
    return Column(
      children: [
        _field(
            controller: _regNameCtrl,
            hint: 'Full name',
            icon: Icons.person_outline),
        const SizedBox(height: 12),
        _field(
            controller: _regEmailCtrl,
            hint: 'Email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _field(
          controller: _regPassCtrl,
          hint: 'Password (min 6 chars)',
          icon: Icons.lock_outline,
          obscure: _obscureReg,
          suffixIcon: IconButton(
            icon: Icon(
                _obscureReg ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: const Color(0xFF8B9EC7),
                size: 20),
            onPressed: () => setState(() => _obscureReg = !_obscureReg),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _register,
            child: const Text('Create Account'),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF8B9EC7), size: 20),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
