import 'package:flutter/material.dart';

import '../release/release_info.dart';
import 'legal_information_screen.dart';

class AboutMorseboundScreen extends StatelessWidget {
  const AboutMorseboundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ABOUT MORSEBOUND')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.graphic_eq_rounded,
                          size: 58,
                          color: Color(0xFF8FFFEA),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'MORSEBOUND',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Learn Morse code by sound.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFA9BBC1),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Version ${ReleaseInfo.displayVersion}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          ReleaseInfo.packageId,
                          style: TextStyle(
                            color: Color(0xFF82969D),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const _InfoCard(
                  icon: Icons.school_outlined,
                  title: 'PURPOSE',
                  body:
                      'Morsebound is a sound-first Morse code learning game '
                      'designed to build direct auditory recognition instead '
                      'of dependence on visual dot-and-dash decoding.',
                ),
                const SizedBox(height: 12),
                const _InfoCard(
                  icon: Icons.hearing_rounded,
                  title: 'TRAINING APPROACH',
                  body:
                      'Training combines gradual character progression, '
                      'Farnsworth-style spacing, adaptive review, active '
                      'recall, retention checks, typed Real Copy, sending '
                      'practice, and radio-style variation.',
                ),
                const SizedBox(height: 12),
                const _InfoCard(
                  icon: Icons.cloud_done_outlined,
                  title: 'ACCOUNTS & SYNC',
                  body:
                      'Signing in is recommended so mastery, retention, '
                      'career progress, streaks, and settings can synchronize '
                      'between supported devices. Local/offline training '
                      'remains available by explicit choice.',
                ),
                const SizedBox(height: 12),
                const _InfoCard(
                  icon: Icons.shield_outlined,
                  title: 'PRIVACY',
                  body:
                      'Morsebound does not use advertising or a dedicated '
                      'analytics service in this release. Firebase '
                      'Authentication and Cloud Firestore provide optional '
                      'account sign-in and synchronized progress storage.',
                ),
                const SizedBox(height: 18),
                const Text(
                  'LEGAL & DATA',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      _LegalTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        section: LegalSection.privacy,
                      ),
                      const Divider(height: 1),
                      _LegalTile(
                        icon: Icons.description_outlined,
                        title: 'Terms of Use',
                        section: LegalSection.terms,
                      ),
                      const Divider(height: 1),
                      _LegalTile(
                        icon: Icons.delete_outline_rounded,
                        title: 'Account & Data Deletion',
                        section: LegalSection.deletion,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          ReleaseInfo.brand,
                          style: TextStyle(
                            color: Color(0xFF8FFFEA),
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          ReleaseInfo.creatorCredit,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Morsebound is an independent educational project.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF82969D),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF8FFFEA)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: .7,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    body,
                    style: const TextStyle(
                      color: Color(0xFFA9BBC1),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalTile extends StatelessWidget {
  const _LegalTile({
    required this.icon,
    required this.title,
    required this.section,
  });

  final IconData icon;
  final String title;
  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LegalInformationScreen(initialSection: section),
        ),
      ),
    );
  }
}
