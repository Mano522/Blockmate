import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/category_item.dart';
import '../services/content_service.dart';
import '../state/session_controller.dart';
import '../widgets/app_shell.dart';
import 'subjects_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  List<CategoryItem> _globalResults = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredSemesters = AppConstants.semesters
        .where((s) => s['title']!.toLowerCase().contains(query))
        .toList();

    return AppShell(
      title: 'BlockMate',
      body: ListView(
        children: [
          const Text(
            'Visvesvaraya Technological University',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search for Semesters, Subjects or Questions...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 20),
          if (_loading) const LinearProgressIndicator(),
          if (_searchController.text.trim().isNotEmpty && _globalResults.isNotEmpty) ...[
            const Text('Global Question Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ..._globalResults.map(
              (q) => Card(
                child: ListTile(
                  title: Text(q.title),
                  subtitle: Text('${q.subjectTitle ?? 'Unknown'} - ${q.moduleTitle ?? 'Unknown'}\n${q.desc}'),
                  isThreeLine: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            _searchController.text.trim().isEmpty ? 'Semesters' : 'Matching Semesters',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (filteredSemesters.isEmpty)
            Text('No semesters found matching "${_searchController.text.trim()}"')
          else
            ...filteredSemesters.map(
              (sem) => Card(
                child: ListTile(
                  title: Text(sem['title']!),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SubjectsScreen(semesterName: sem['title']!),
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 10),
          Consumer<SessionController>(
            builder: (context, session, _) => Text(
              session.user == null
                  ? ''
                  : 'Logged in as ${session.user!.name.isEmpty ? session.user!.email : session.user!.name} (${session.user!.role})',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSearchChanged(String value) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final search = value.trim();
      if (search.isEmpty) {
        if (!mounted) return;
        setState(() {
          _globalResults = const [];
          _loading = false;
        });
        return;
      }

      setState(() => _loading = true);
      try {
        final data = await context.read<ContentService>().searchCategories(search);
        if (mounted) setState(() => _globalResults = data);
      } catch (_) {
        if (mounted) setState(() => _globalResults = const []);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }
}
