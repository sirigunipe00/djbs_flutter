import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
// import 'package:share_plus/share_plus.dart';

import '../constants.dart';
import '../main.dart';
import '../services/app_services.dart';
import '../strings.dart';
import '../theme.dart';
import 'ambulance_screen.dart';
import 'bank_screen.dart';
import 'donor_form_screen.dart';
import 'info_pages.dart';
import 'login_screen.dart';
import 'need_blood_screen.dart';
import 'settings_screen.dart';

enum _HomePage { home, eye, ndf, morgue }

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  _HomePage _page = _HomePage.home;
  String? _photoUrl;
  bool _uploading = false;
  DateTime? _lastBack;
  final Map<String, String> _banners = {};

  User? get _user => FirebaseAuth.instance.currentUser;
  bool get _isAdmin => _user?.uid == AppConst.adminUid;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final user = _user;
    if (user == null) {
      _goLogin();
      return;
    }
    await user.reload();
    final fresh = FirebaseAuth.instance.currentUser;
    if (fresh != null && !fresh.emailVerified) {
      await fresh.sendEmailVerification();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Please Verify Your Account'),
          content: const Text(
            "we've sent you a verification email, if you didn't get it please retry login to get verification mail",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ok'),
            ),
          ],
        ),
      );
      await FirebaseAuth.instance.signOut();
      _goLogin();
      return;
    }
    final warning = await AppLocation.refresh();
    if (warning != null) toast(warning);
    if (!await Net.online()) {
      toast('Internet connection may not available');
    }
    await _loadPhoto();
    _listenBanners();
    if (mounted) setState(() {});
  }

  void _listenBanners() {
    final ref = FirebaseDatabase.instance.ref('DJBS');
    for (final key in ['img_1', 'img_2', 'img_3', 'img_4', 'img_5']) {
      ref.child(key).onValue.listen((event) {
        final url = event.snapshot.value?.toString() ?? '';
        if (!mounted) return;
        setState(() => _banners[key] = url);
      });
    }
  }

  Future<void> _loadPhoto() async {
    try {
      final url = await ProfileStore.imageUrl(_user?.displayName);
      if (mounted) setState(() => _photoUrl = url);
    } catch (_) {
      toast('Please set profile Picture');
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    final user = _user;
    if (picked == null || user == null) return;
    setState(() => _uploading = true);
    try {
      final url = await ProfileStore.upload(user, File(picked.path));
      if (mounted) setState(() => _photoUrl = url);
      toast('Upload successful');
    } catch (e) {
      toast(e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _goLogin() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _setLang(String code, String label) {
    Strings.instance.setLang(code);
    toast('App Language is set to $label');
  }

  String get _title {
    switch (_page) {
      case _HomePage.home:
        return s('home');
      case _HomePage.eye:
        return s('eye_donor');
      case _HomePage.ndf:
        return s('n.d.f');
      case _HomePage.morgue:
        return s('morgue');
    }
  }

  Future<void> _onBack() async {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
      return;
    }
    if (_page != _HomePage.home) {
      setState(() => _page = _HomePage.home);
      return;
    }
    final now = DateTime.now();
    if (_lastBack == null || now.difference(_lastBack!) > const Duration(seconds: 2)) {
      _lastBack = now;
      toast('Press again to exit.');
      return;
    }
    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_onBack());
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(
            _title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF1E5BB8),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.language, color: Colors.white),
              onSelected: (code) {
                if (code == 'en') _setLang('en', 'English');
                if (code == 'hi') _setLang('hi', 'Hindi');
                if (code == 'gu') _setLang('gu', 'Gujarati');
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'en', child: Text('English')),
                PopupMenuItem(value: 'hi', child: Text('Hindi')),
                PopupMenuItem(value: 'gu', child: Text('Gujarati')),
              ],
            ),
          ],
        ),
        drawer: _drawer(),
        body: switch (_page) {
          _HomePage.home => _homeBody(),
          _HomePage.eye => const EyePage(),
          _HomePage.ndf => const NdfPage(),
          _HomePage.morgue => const MorguePage(),
        },
      ),
    );
  }

  Widget _drawer() {
    final user = _user;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 200,
            padding: const EdgeInsets.fromLTRB(20, 36, 16, 16),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/header_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white,
                        backgroundImage: _photoUrl == null
                            ? const AssetImage('assets/images/user_ic.png')
                                as ImageProvider
                            : CachedNetworkImageProvider(_photoUrl!),
                      ),
                      if (_uploading)
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  user?.displayName ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          _item(Icons.home, s('home'), () => _openPage(_HomePage.home)),
          _item(Icons.bloodtype, s('need_blood'), () => _push(const NeedBloodScreen())),
          _item(Icons.local_hospital, s('find_blood_bank'), () => _push(const BankScreen())),
          _item(Icons.visibility, s('eye_donor'), () => _openPage(_HomePage.eye)),
          _item(Icons.military_tech, s('n.d.f'), () => _openPage(_HomePage.ndf)),
          _item(Icons.inventory_2, s('morgue'), () => _openPage(_HomePage.morgue)),
          _item(Icons.airport_shuttle, s('ambulance'), () => _push(const AmbulanceScreen())),
          _item(Icons.info_outline, s('about_us'), () => _push(const AboutScreen())),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(s('user'), style: const TextStyle(color: AppColors.termGray)),
          ),
          _item(Icons.share, s('share'), _share),
          if (_isAdmin)
            _item(Icons.person_add, s('add_user'), () => _push(const DonorFormScreen())),
          _item(Icons.settings, s('settings'), () => _push(const SettingsScreen())),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _openPage(_HomePage page) => setState(() => _page = page);

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
        text: 'DJBS Foundation App \n ${AppConst.playStore}',
        subject: 'DJBS Foundation App',
      ),
    );
  }

  Widget _homeBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 14),

                  // 1. Header logo row with flanking icons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left icons
                        Image.asset(
                          'assets/images/ic_blood_128.png',
                          height: 38,
                          width: 38,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 15),
                        Image.asset(
                          'assets/images/bank_ic_128.png',
                          height: 38,
                          width: 38,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 15),

                        // // Center logo box
                        // Image.asset(
                        //   'assets/images/djbs_logos.png',
                        //   height: 64,
                        //   fit: BoxFit.contain,
                        // ),
                        // const SizedBox(width: 10),

                        // Right icons
                        Image.asset(
                          'assets/images/eye_ic_128.png',
                          height: 32,
                          width: 32,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 15),
                        Image.asset(
                          'assets/images/soldier_ic_128.png',
                          height: 32,
                          width: 32,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 15),
                        Image.asset(
                          'assets/images/ambulance_128.png',
                          height: 32,
                          width: 32,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tagline: Service • Support • Save Lives
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:  [
                      Text(
                        'Service',
                        style: TextStyle(
                          color: Color(0xFF1E5BB8),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '•',
                          style: TextStyle(
                            color: Color(0xFFE91E63),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        'Support',
                        style: TextStyle(
                          color: Color(0xFF1E5BB8),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '•',
                          style: TextStyle(
                            color: Color(0xFFE91E63),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        'Save Lives',
                        style: TextStyle(
                          color: Color(0xFF1E5BB8),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 2. Feature Cards (2 columns x 3 rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Row 1: Need Blood & Find Blood Bank
                        Row(
                          children: [
                            Expanded(
                              child: _featureCard(
                                title: s('need_blood'),
                                subtitle: s('need_blood_desc'),
                                iconAsset: 'assets/images/ic_card_need_blood.png',
                                bgColor: const Color(0xFFFCECF3),
                                onTap: () => _push(const NeedBloodScreen()),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _featureCard(
                                title: s('find_blood_bank'),
                                subtitle: s('find_blood_bank_desc'),
                                iconAsset: 'assets/images/ic_card_blood_bank.png',
                                bgColor: const Color(0xFFE9F3FE),
                                onTap: () => _push(const BankScreen()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Row 2: Eye Donor & N.D.F.
                        Row(
                          children: [
                            Expanded(
                              child: _featureCard(
                                title: s('eye_donor'),
                                subtitle: s('eye_donor_desc'),
                                iconAsset: 'assets/images/eye_ic_128.png',
                                bgColor: const Color(0xFFFDF5E7),
                                onTap: () => _openPage(_HomePage.eye),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _featureCard(
                                title: s('n.d.f'),
                                subtitle: s('ndf_desc'),
                                iconAsset: 'assets/images/ic_card_ndf.png',
                                bgColor: const Color(0xFFEDF7ED),
                                onTap: () => _openPage(_HomePage.ndf),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Row 3: Dead Body Chamber & Ambulance
                        Row(
                          children: [
                            Expanded(
                              child: _featureCard(
                                title: s('morgue'),
                                subtitle: s('morgue_desc'),
                                iconAsset: 'assets/images/ic_card_chamber.png',
                                bgColor: const Color(0xFFF6F7FC),
                                onTap: () => _openPage(_HomePage.morgue),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _featureCard(
                                title: s('ambulance'),
                                subtitle: s('ambulance_desc'),
                                iconAsset: 'assets/images/ambulance_128.png',
                                bgColor: const Color(0xFFF6F7FB),
                                onTap: () => _push(const AmbulanceScreen()),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // DJBS logo on left, Sheetal pink logo on right (enlarged)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/djbs_logos.png',
                          height: 92,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 18),
                        Image.asset(
                          'assets/images/sheetal.png',
                          height: 72,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Spacer(),

                  // 3. Bottom illustration artwork
                  Image.asset(
                    'assets/images/home_bottom_illustration.png',
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _featureCard({
    required String title,
    required String subtitle,
    required String iconAsset,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 146,
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 42,
                width: 42,
                child: Image.asset(iconAsset, fit: BoxFit.contain),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF112952),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Color(0xFF687690),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6A7B95),
                  fontSize: 11.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _banner(String? url) {
  //   if (url == null || url.isEmpty || !url.startsWith('http')) {
  //     return Image.asset('assets/images/loading.jpg', height: 180, fit: BoxFit.cover);
  //   }
  //   return CachedNetworkImage(
  //     imageUrl: url,
  //     height: 180,
  //     width: double.infinity,
  //     fit: BoxFit.cover,
  //     placeholder: (_, _) => Image.asset('assets/images/loading.jpg', height: 180, fit: BoxFit.cover),
  //     errorWidget: (_, _, _) => Image.asset('assets/images/loading.jpg', height: 180, fit: BoxFit.cover),
  //   );
  // }
}
