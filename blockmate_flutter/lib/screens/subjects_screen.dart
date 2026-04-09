import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subject.dart';
import '../services/content_service.dart';
import '../state/session_controller.dart';
import '../widgets/app_shell.dart';
import 'subject_detail_screen.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key, required this.semesterName});

  final String semesterName;

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final _searchController = TextEditingController();
  bool _loading = true;
  List<Subject> _subjects = const [];

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<SessionController>().user?.isAdmin == true;
    final filtered = _subjects
        .where((s) => s.title.toLowerCase().contains(_searchController.text.trim().toLowerCase()))
        .toList();

    return AppShell(
      title: widget.semesterName,
      actions: [
        if (isAdmin)
          IconButton(
            onPressed: _addSubject,
            icon: const Icon(Icons.add),
            tooltip: 'Add subject',
          ),
      ],
      body: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search subjects...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(_subjects.isEmpty
                            ? 'No subjects added for this semester.'
                            : 'No subjects found matching "${_searchController.text.trim()}"'),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final subject = filtered[index];
                          return Card(
                            child: ListTile(
                              title: Text(subject.title),
                              trailing: isAdmin
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _deleteSubject(subject),
                                    )
                                  : const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SubjectDetailScreen(
                                      subjectId: subject.id,
                                      subjectTitle: subject.title,
                                      initialSubject: subject,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchSubjects() async {
    setState(() => _loading = true);
    try {
      final items = await context.read<ContentService>().fetchSubjects(semester: widget.semesterName);
      if (mounted) setState(() => _subjects = items);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addSubject() async {
    final service = context.read<ContentService>();

    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add subject'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Subject title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    if (title == null || title.isEmpty) return;

    try {
      await service.addSubject(
        title: title,
        semester: widget.semesterName,
        order: _subjects.length + 1,
      );
      await _fetchSubjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subject added successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _deleteSubject(Subject subject) async {
    final service = context.read<ContentService>();

    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete subject'),
            content: Text('This will delete "${subject.title}" and all modules/questions. Continue?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    try {
      await service.deleteSubject(subject.id);
      await _fetchSubjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subject deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }
}
