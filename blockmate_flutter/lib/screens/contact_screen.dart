import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/app_shell.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Contact',
      body: ListView(
        children: [
          const Text(
            'Have questions or need assistance? We\'re here to help!',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          _tile(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: 'manojkumark3377@gmail.com',
            onTap: () => _launch('mailto:manojkumark3377@gmail.com'),
          ),
          _tile(
            icon: Icons.chat_outlined,
            title: 'WhatsApp',
            subtitle: '+91 9704341511',
            onTap: () => _launch('https://wa.me/919704341511'),
          ),
          _tile(
            icon: Icons.camera_alt_outlined,
            title: 'Instagram',
            subtitle: '@venzenith_official',
            onTap: () => _launch('https://www.instagram.com/venzenith_official?igsh=MWtxZ2doeXFtbmg1Zg=='),
          ),
          _tile(
            icon: Icons.work_outline,
            title: 'LinkedIn',
            subtitle: 'Manoj Kumar K',
            onTap: () => _launch('https://www.linkedin.com/in/manoj-kumar-k-201155341/'),
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.open_in_new),
        onTap: onTap,
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
