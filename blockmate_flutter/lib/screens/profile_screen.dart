import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../state/session_controller.dart';
import '../widgets/app_shell.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _fetching = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Profile',
      body: _fetching
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Name required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loading ? null : _update,
                    child: Text(_loading ? 'Updating...' : 'Update Profile'),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _fetch() async {
    final authService = context.read<AuthService>();
    final session = context.read<SessionController>();

    setState(() => _fetching = true);
    try {
      final profile = await authService.fetchProfile();
      if (mounted) {
        _nameController.text = profile.name;
        _emailController.text = profile.email;
      }
    } catch (_) {
      final user = session.user;
      if (user != null) {
        _nameController.text = user.name;
        _emailController.text = user.email;
      }
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    final current = context.read<SessionController>();

    setState(() => _loading = true);
    try {
      final payload = await authService.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );

      final merged = <String, dynamic>{
        'token': payload['token'] ?? current.token,
        ...payload,
        'user': payload,
      };
      await current.saveSession(merged);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
