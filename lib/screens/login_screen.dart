import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../main.dart';
import '../models/donor.dart';
import '../services/app_services.dart';
import '../strings.dart';
import '../utils/verhoeff.dart';
import '../utils/word_capitalization.dart';
import 'forgot_screen.dart';
import 'home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _signIn = true;
  bool _busy = false;
  bool _hideLoginPass = true;
  bool _hideSignupPass = true;

  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _aadhar = TextEditingController();
  final _mobile = TextEditingController();
  String _city = AppConst.cities.first;
  String _group = AppConst.groups.first;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeShell()),
        );
      });
    }
  }

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPass.dispose();
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _aadhar.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _openFacebook() async {
    final app = Uri.parse(AppConst.facebookApp);
    final web = Uri.parse(AppConst.facebookWeb);
    if (await canLaunchUrl(app)) {
      await launchUrl(app);
    } else {
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }
  }

  Future<bool> _connected() async {
    if (await Net.online()) return true;
    toast('Internet connection may not available');
    return false;
  }

  Future<void> _login() async {
    if (!await _connected()) return;
    final email = _loginEmail.text.trim();
    final pass = _loginPass.text;
    if (email.isEmpty) {
      toast('Enter Email Address !');
      return;
    }
    if (!AppConst.emailPattern.hasMatch(email)) {
      toast('Enter Valid Email Address!');
      _loginEmail.clear();
      return;
    }
    if (pass.isEmpty) {
      toast('Enter Password !');
      return;
    }
    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );
      toast('Login Success');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } catch (_) {
      toast('Authentication failed.');
      toast('Make sure you have entered correct Username and Password.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _register() async {
    if (!await _connected()) return;
    final email = _email.text.trim();
    final pass = _pass.text;
    final name = _name.text.replaceAll('.', '');
    final aadhar = _aadhar.text.trim();
    final mobile = _mobile.text.trim();

    if (!Verhoeff.validate(aadhar)) {
      toast('Enter Valid Aadhar Number!');
      _aadhar.clear();
      return;
    }
    if (!AppConst.emailPattern.hasMatch(email)) {
      toast('Enter Valid Email Address!');
      _email.clear();
      return;
    }
    if (email.isEmpty) {
      toast('Enter Email Address !');
      return;
    }
    if (pass.isEmpty) {
      toast('Enter Password !');
      return;
    }
    if (name.isEmpty) {
      toast('Enter Name !');
      return;
    }
    if (name.length < 8) {
      toast('Enter Full Name!');
      return;
    }
    if (mobile.isEmpty) {
      toast('Enter Mobile Number !');
      return;
    }
    if (mobile.length < 10) {
      toast('Enter Valid Mobile Number!');
      return;
    }
    if (_city.toLowerCase() == 'none') {
      toast('Select City !');
      return;
    }
    if (_group.toLowerCase() == 'none') {
      toast('Select Blood Group !');
      return;
    }

    setState(() => _busy = true);
    try {
      await AppLocation.refresh();
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );
      await cred.user?.updateDisplayName(name);
      final donor = Donor(
        name: name,
        mobileNumber: mobile,
        bloodGroup: _group,
        city: _city,
        lat: AppLocation.lat.toString(),
        lan: AppLocation.lng.toString(),
        adhar: aadhar,
      );
      await FirebaseDatabase.instance
          .ref('donors')
          .child(_city)
          .child(_group)
          .push()
          .set(donor.toMap());
      toast('Registration Success');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        toast('Email Already Exist! Please Login to continue.');
      } else {
        toast('Error : ${e.message}');
      }
    } catch (e) {
      toast('Error : $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final signInWidth = _signIn ? width * 0.85 : width * 0.15;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _CyclingGradient(),
          const _Snowfall(),
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeInOut,
                width: signInWidth,
                color: const Color(0x48F5AB35),
                child: _signIn ? _signInPanel() : _verticalTab(s('login'), upward: false, openSignIn: true),
              ),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeInOut,
                  color: const Color(0x48446CB3),
                  child: _signIn ? _verticalTab(s('signup'), upward: true, openSignIn: false) : _signUpPanel(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verticalTab(String label, {required bool upward, required bool openSignIn}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _busy ? null : () => setState(() => _signIn = openSignIn),
      child: Center(
        child: RotatedBox(
          quarterTurns: upward ? 3 : 1,
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  Widget _signInPanel() {
    return ColoredBox(
      color: const Color(0x48BFBFBF),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _busy
                        ? const _LoadingDots()
                        : SvgPicture.asset('assets/images/ic_login.svg', height: 56),
                    const SizedBox(height: 20),
                    _whiteField(controller: _loginEmail, hint: s('Email'), keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 24),
                    _whiteField(
                      controller: _loginPass,
                      hint: s('Password'),
                      obscure: _hideLoginPass,
                      onToggle: () => setState(() => _hideLoginPass = !_hideLoginPass),
                    ),
                    const SizedBox(height: 25),
                    _textAction(s('login'), _busy ? null : _login),
                    const SizedBox(height: 25),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ForgotScreen()),
                        );
                      },
                      child: Text(
                        s('forgetpass').replaceAll(RegExp(r'<[^>]+>'), ''),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                    IconButton(
                      onPressed: _openFacebook,
                      icon: SvgPicture.asset('assets/images/ic_facebook.svg', height: 36),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _signUpPanel() {
    return ColoredBox(
      color: const Color(0x48BFBFBF),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(36, 24, 36, 24),
          children: [
            Center(
              child: _busy
                  ? const _LoadingDots()
                  : SvgPicture.asset('assets/images/ic_user.svg', height: 56),
            ),
            const SizedBox(height: 12),
            _whiteField(
              controller: _name,
              hint: s('fullName'),
              textCapitalization: TextCapitalization.words,
              inputFormatters: const [WordCapitalizationFormatter()],
            ),
            _whiteField(controller: _email, hint: s('Email'), keyboard: TextInputType.emailAddress),
            _whiteField(controller: _mobile, hint: s('mobile_num'), keyboard: TextInputType.phone),
            _whiteField(controller: _aadhar, hint: s('aadhar'), keyboard: TextInputType.number),
            _whiteField(
              controller: _pass,
              hint: s('Password'),
              obscure: _hideSignupPass,
              onToggle: () => setState(() => _hideSignupPass = !_hideSignupPass),
            ),
            const SizedBox(height: 8),
            Text(s('select_city').toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 6),
            _spinner(
              value: _city,
              items: AppConst.cities,
              onChanged: (value) => setState(() => _city = value),
            ),
            const SizedBox(height: 8),
            Text(s('b_group').toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 6),
            _spinner(
              value: _group,
              items: AppConst.groups,
              onChanged: (value) => setState(() => _group = value),
            ),
            const SizedBox(height: 20),
            _textAction(s('signup'), _busy ? null : _register),
          ],
        ),
      ),
    );
  }

  Widget _textAction(String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label.toUpperCase(),
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 30),
      ),
    );
  }

  Widget _whiteField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType? keyboard,
    VoidCallback? onToggle,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        suffixIcon: onToggle == null
            ? null
            : IconButton(
                onPressed: onToggle,
                icon: Icon(
                  obscure ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                ),
              ),
      ),
    );
  }

  Widget _spinner({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 160,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0x48BFBFBF),
          borderRadius: BorderRadius.circular(5),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: const Color(0xFF3A539B),
            iconEnabledColor: Colors.white,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            items: [
              for (final item in items)
                DropdownMenuItem(
                  value: item,
                  child: Text(item, style: const TextStyle(color: Colors.white)),
                ),
            ],
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 4; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 12,
                  height: 12,
                  transform: Matrix4.translationValues(
                    0,
                    -8 * math.sin((_controller.value * math.pi * 2) + i),
                    0,
                  ),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CyclingGradient extends StatefulWidget {
  const _CyclingGradient();

  @override
  State<_CyclingGradient> createState() => _CyclingGradientState();
}

class _CyclingGradientState extends State<_CyclingGradient> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  static const _stops = <(Alignment, Alignment, Color, Color)>[
    (Alignment.topRight, Alignment.bottomLeft, Color(0xFFFFD6D3), Color(0xFF044FAB)),
    (Alignment.bottomLeft, Alignment.topRight, Color(0xFF32FF3F), Color(0xFF43B4EF)),
    (Alignment.bottomRight, Alignment.topLeft, Color(0xFF517F95), Color(0xFF933C94)),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final scaled = _controller.value * _stops.length;
        final index = scaled.floor() % _stops.length;
        final next = (index + 1) % _stops.length;
        final t = scaled - scaled.floor();
        final a = _stops[index];
        final b = _stops[next];
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.lerp(a.$1, b.$1, t)!,
              end: Alignment.lerp(a.$2, b.$2, t)!,
              colors: [
                Color.lerp(a.$3, b.$3, t)!,
                Color.lerp(a.$4, b.$4, t)!,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Snowfall extends StatefulWidget {
  const _Snowfall();

  @override
  State<_Snowfall> createState() => _SnowfallState();
}

class _SnowfallState extends State<_Snowfall> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();
  late final List<_Flake> _flakes = List.generate(40, (i) {
    final random = math.Random(i);
    return _Flake(
      x: random.nextDouble(),
      speed: 0.35 + random.nextDouble() * 0.65,
      size: 1.5 + random.nextDouble() * 2.5,
      phase: random.nextDouble(),
      drift: random.nextDouble() * 16 - 8,
    );
  });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _SnowPainter(_flakes, _controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Flake {
  const _Flake({
    required this.x,
    required this.speed,
    required this.size,
    required this.phase,
    required this.drift,
  });

  final double x;
  final double speed;
  final double size;
  final double phase;
  final double drift;
}

class _SnowPainter extends CustomPainter {
  _SnowPainter(this.flakes, this.t);

  final List<_Flake> flakes;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xCCFFFFFF);
    for (final flake in flakes) {
      final progress = (t * flake.speed + flake.phase) % 1;
      final dx = flake.x * size.width + math.sin(progress * math.pi * 2) * flake.drift;
      final dy = progress * size.height;
      canvas.drawCircle(Offset(dx, dy), flake.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter oldDelegate) => oldDelegate.t != t;
}
