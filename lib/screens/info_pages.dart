import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../main.dart';
import '../strings.dart';
import '../theme.dart';

class EyePage extends StatelessWidget {
  const EyePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Image.asset('assets/images/eye_poster.jpg', height: 280, fit: BoxFit.cover),
        const SizedBox(height: 12),
        _heading(s('abteye')),
        _body(s('abteye2')),
        _heading(s('abteye3')),
        _body(s('abteye4')),
        _heading(s('abteye5')),
        _body(s('abteye6')),
        _heading(s('abteye7')),
        _body(s('abteye8')),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.callGreen),
          onPressed: () => launchUrl(Uri.parse('tel:${AppConst.servicePhone}')),
          child: Text(s('call')),
        ),
      ],
    );
  }
}

class NdfPage extends StatelessWidget {
  const NdfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _heading(s('ndf1')),
        _body(s('ndf2')),
        _heading(s('ndf3')),
        _body(s('ndf4')),
        _heading(s('ndf5')),
        _body(s('ndf6')),
        _heading(s('ndf7')),
        _body(s('ndf8')),
        _heading(s('ndf9')),
        _body(s('ndf10')),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: () => _confirmPay(context), child: Text(s('donate_online'))),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => launchUrl(
            Uri.parse(AppConst.ndfHistory),
            mode: LaunchMode.externalApplication,
          ),
          child: Text(s('payment_history')),
        ),
      ],
    );
  }

  Future<void> _confirmPay(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redirecting to Web page'),
        content: Text(s('redirect')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ok')),
        ],
      ),
    );
    if (ok == true) {
      await launchUrl(Uri.parse(AppConst.ndfHome), mode: LaunchMode.externalApplication);
    }
  }
}

class MorguePage extends StatefulWidget {
  const MorguePage({super.key});

  @override
  State<MorguePage> createState() => _MorguePageState();
}

class _MorguePageState extends State<MorguePage> {
  String _city = AppConst.cities.first;

  Future<void> _call() async {
    if (_city != 'Amreli') {
      toast('Sorry,Currently Our service is Unavailable for selected city');
      return;
    }
    await launchUrl(Uri.parse('tel:${AppConst.servicePhone}'));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [_body(s('mourge'))],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonFormField<String>(
            initialValue: _city,
            decoration: InputDecoration(labelText: s('select_city')),
            items: [
              for (final city in AppConst.cities)
                DropdownMenuItem(value: city, child: Text(city)),
            ],
            onChanged: (value) => setState(() => _city = value ?? _city),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.callGreen),
            onPressed: _call,
            child: Text(s('call')),
          ),
        ),
      ],
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Future<void> _contact() async {
  //   final uri = Uri.parse(
  //     'mailto:${AppConst.developerEmail}?subject=${Uri.encodeComponent(AppConst.developerName)}',
  //   );
  //   final opened = await launchUrl(uri);
  //   if (!opened) {
  //     await launchUrl(Uri.parse('tel:${AppConst.developerPhone}'));
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(s('about_us'))),
      body: Center(
        child:  Image.asset('assets/images/djbs_logos.png', height: 180),
        
      )
      // Column(
      //   mainAxisAlignment: MainAxisAlignment.center,
      //   children: [
      //     const Spacer(),
      //     Image.asset('assets/images/djbs_logos.png', height: 180),
          // const Spacer(),
          // Padding(
          //   padding: const EdgeInsets.only(bottom: 16),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       Text('${s('design')} : ', style: const TextStyle(color: AppColors.termGray)),
          //       GestureDetector(
          //         onTap: _contact,
          //         child: Text(
          //           s('jatinsoft'),
          //           style: const TextStyle(
          //             color: AppColors.googleBlue,
          //             fontWeight: FontWeight.bold,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
      //   ],
      // ),
    );
  }
}

Widget _heading(String text) {
  return Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Text(
      text,
      style: const TextStyle(color: AppColors.fbBlue, fontSize: 22, fontWeight: FontWeight.w600),
    ),
  );
}

Widget _body(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 16, height: 1.35)),
  );
}
