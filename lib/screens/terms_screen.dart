import 'package:flutter/material.dart';

import '../services/app_services.dart';
import '../strings.dart';
import '../theme.dart';
import 'login_screen.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  @override
  Widget build(BuildContext context) {
    final paragraphs = [
      for (var i = 2; i <= 14; i++) s('term$i'),
    ];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      s('term1'),
                      style: const TextStyle(
                        color: AppColors.googleBlue,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final text in paragraphs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          text,
                          style: const TextStyle(
                            color: AppColors.termGray,
                            fontSize: 16,
                            height: 1.35,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.googleBlue,
                  ),
                  onPressed: () async {
                    await Prefs.setAgreed();
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text(s('i_agree') == 'i_agree' ? 'I Agree' : s('i_agree')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
