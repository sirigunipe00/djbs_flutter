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
  String? _city;

  Future<void> _call() async {
    if (_city == null || _city == 'NONE') {
      toast(s('please_select_district'));
      return;
    }
    if (_city != 'Amreli') {
      toast(s('facility_unavailable_msg'));
      return;
    }
    await launchUrl(Uri.parse('tel:${AppConst.servicePhone}'));
  }

  @override
  Widget build(BuildContext context) {
    final districts = AppConst.cities.where((c) => c != 'NONE').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card with Chamber Icon & Title
          Card(
            elevation: 0,
            color: const Color(0xFFF4F7FC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3EDFB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          'assets/images/ic_card_chamber.png',
                          height: 32,
                          width: 32,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.inventory_2_outlined,
                            color: Color(0xFF1E5BB8),
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s('morgue'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Intro text
                  Text(
                    s('morgue_intro'),
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.5,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Instruction text
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF1E5BB8)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s('morgue_instruction'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                            color: Color(0xFF1E5BB8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Please Note / Disclaimer Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFD97706),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s('morgue_note'),
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // District Label
          Text(
            s('district_label'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),

          // District Dropdown
          DropdownButtonFormField<String>(
            value: _city,
            hint: Text(
              s('select_your_district'),
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.location_city_outlined, color: Color(0xFF1E5BB8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E5BB8), width: 1.8),
              ),
            ),
            items: [
              for (final city in districts)
                DropdownMenuItem(
                  value: city,
                  child: Text(city, style: const TextStyle(fontSize: 15)),
                ),
            ],
            onChanged: (value) => setState(() => _city = value),
          ),

          const SizedBox(height: 16),

          // If district selected, show status card
          if (_city != null) ...[
            if (_city == 'Amreli')
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '$_city - ${s('morgue')}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s('facility_available_amreli'),
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF64748B), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s('facility_unavailable_msg'),
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
          ],

          // Contact Facility Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.callGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
            ),
            icon: const Icon(Icons.phone_in_talk, size: 20),
            label: Text(
              s('contact_facility'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: _call,
          ),
          const SizedBox(height: 20),
        ],
      ),
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
