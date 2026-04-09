import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category_item.dart';
import '../models/module_item.dart';
import '../services/content_service.dart';
import '../state/session_controller.dart';
import '../widgets/app_shell.dart';
import '../widgets/file_section_widget.dart';
import 'edit_category_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({
    super.key,
    required this.subjectId,
    required this.moduleId,
    required this.subjectTitle,
  });

  final String subjectId;
  final String moduleId;
  final String subjectTitle;

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _loading = true;
  List<CategoryItem> _categories = const [];
  ModuleItem? _moduleData;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<SessionController>().user?.isAdmin == true;

    return AppShell(
      title: widget.subjectTitle,
      actions: [
        if (isAdmin)
          IconButton(
            onPressed: _addQuestion,
            icon: const Icon(Icons.add),
            tooltip: 'Add question',
          ),
      ],
      body: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search questions...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      if (_moduleData != null)
                        FileSectionWidget(
                          type: 'module',
                          ownerId: widget.moduleId,
                          files: _moduleData!.files,
                          isAdmin: isAdmin,
                          onChanged: _load,
                        ),
                      const SizedBox(height: 10),
                      if (_categories.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No questions added yet.'),
                          ),
                        ),
                      ..._categories.map(
                        (category) => Card(
                          child: ExpansionTile(
                            title: Text(category.title),
                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(category.desc.isEmpty ? 'No answer provided yet.' : category.desc),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (isAdmin) ...[
                                    TextButton(
                                      onPressed: () => _editQuestion(category.id),
                                      child: const Text('Edit'),
                                    ),
                                    TextButton(
                                      onPressed: () => _deleteQuestion(category.id),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSearchChanged(String _) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final service = context.read<ContentService>();
      final categories = await service.fetchCategories(
        search: _searchController.text.trim(),
        subjectId: widget.subjectId,
        moduleId: widget.moduleId,
      );
      final moduleData = await service.fetchModule(widget.moduleId);
      if (mounted) {
        setState(() {
          _categories = categories;
          _moduleData = moduleData;
        });
      }
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

  Future<void> _addQuestion() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditCategoryScreen(
          subjectId: widget.subjectId,
          moduleId: widget.moduleId,
          subjectTitle: widget.subjectTitle,
        ),
      ),
    );

    if (changed == true) {
      _load();
    }
  }

  Future<void> _editQuestion(String categoryId) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditCategoryScreen(
          categoryId: categoryId,
          subjectId: widget.subjectId,
          moduleId: widget.moduleId,
          subjectTitle: widget.subjectTitle,
        ),
      ),
    );

    if (changed == true) {
      _load();
    }
  }

  Future<void> _deleteQuestion(String id) async {
    final service = context.read<ContentService>();

    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete question'),
            content: const Text('Are you sure you want to delete this question?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
    if (!ok) return;

    try {
      await service.deleteCategory(id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question deleted')));
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
