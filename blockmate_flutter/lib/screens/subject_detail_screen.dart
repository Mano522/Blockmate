import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/module_item.dart';
import '../models/subject.dart';
import '../services/content_service.dart';
import '../state/session_controller.dart';
import '../widgets/app_shell.dart';
import '../widgets/file_section_widget.dart';
import 'category_list_screen.dart';

class SubjectDetailScreen extends StatefulWidget {
  const SubjectDetailScreen({
    super.key,
    required this.subjectId,
    required this.subjectTitle,
    this.initialSubject,
  });

  final String subjectId;
  final String subjectTitle;
  final Subject? initialSubject;

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  final _searchController = TextEditingController();
  bool _loading = true;
  Subject? _subject;
  List<ModuleItem> _modules = const [];

  @override
  void initState() {
    super.initState();
    _subject = widget.initialSubject;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<SessionController>().user?.isAdmin == true;
    final filtered = _modules
        .where((m) => m.title.toLowerCase().contains(_searchController.text.trim().toLowerCase()))
        .toList();

    return AppShell(
      title: widget.subjectTitle,
      actions: [
        if (isAdmin)
          IconButton(
            onPressed: _addModule,
            icon: const Icon(Icons.add),
            tooltip: 'Add module',
          ),
      ],
      body: _loading && _subject == null
          ? const Center(child: CircularProgressIndicator())
          : _subject == null
              ? const Center(child: Text('Subject not found'))
              : Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search modules...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    if (_loading && _subject != null) const LinearProgressIndicator(),
                    Expanded(
                      child: ListView(
                        children: [
                          if (filtered.isEmpty && !_loading)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text(_searchController.text.isEmpty
                                    ? 'No modules added yet.'
                                    : 'No modules found matching "${_searchController.text.trim()}"'),
                              ),
                            ),
                          ...filtered.map(
                            (module) => Card(
                              child: ListTile(
                                title: Text(module.title),
                                trailing: isAdmin
                                    ? IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () => _deleteModule(module),
                                      )
                                    : const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CategoryListScreen(
                                        subjectId: _subject!.id,
                                        moduleId: module.id,
                                        subjectTitle: '${widget.subjectTitle} - ${module.title}',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FileSectionWidget(
                            type: 'subject',
                            ownerId: _subject!.id,
                            files: _subject!.files,
                            isAdmin: isAdmin,
                            onChanged: _load,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Future<void> _load() async {
    final service = context.read<ContentService>();

    setState(() => _loading = true);
    try {
      // If we don't have the subject (or want to refresh it), fetch it by ID if possible
      // Assuming fetchSubjects or a fetchSubjectById exists. ContentService has fetchSubjects(title: ...)
      // Let's use fetchSubjects(title: ...) but filter by ID if we have to, 
      // or better, if the API supports fetching all subjects and we find ours.
      
      final subjects = await service.fetchSubjects(title: widget.subjectTitle);
      final subject = subjects.firstWhere(
        (s) => s.id == widget.subjectId,
        orElse: () => subjects.isNotEmpty ? subjects.first : _subject!,
      );
      
      final modules = await service.fetchModules(subjectId: subject.id);
      if (mounted) {
        setState(() {
          _subject = subject;
          _modules = modules;
        });
      }
    } catch (e) {
      if (mounted && _subject == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addModule() async {
    if (_subject == null) return;
    final service = context.read<ContentService>();

    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add module'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Module title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    if (title == null || title.isEmpty) return;

    try {
      await service.addModule(
        title: title,
        subjectId: _subject!.id,
        order: _modules.length + 1,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Module added successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _deleteModule(ModuleItem module) async {
    final service = context.read<ContentService>();

    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete module'),
            content: const Text('This will delete all questions in this module. Continue?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
    if (!ok) return;

    try {
      await service.deleteModule(module.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Module deleted')));
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
