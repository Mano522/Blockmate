import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/content_service.dart';

class EditCategoryScreen extends StatefulWidget {
  const EditCategoryScreen({
    super.key,
    this.categoryId,
    required this.subjectId,
    required this.moduleId,
    required this.subjectTitle,
  });

  final String? categoryId;
  final String subjectId;
  final String moduleId;
  final String subjectTitle;

  bool get isEdit => categoryId != null && categoryId!.isNotEmpty;

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _loading = false;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Update Question' : 'Add Question'),
      ),
      body: _fetching
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Question'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Question is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: 'Answer'),
                      minLines: 4,
                      maxLines: 8,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: Text(_loading
                            ? (widget.isEdit ? 'Updating...' : 'Adding...')
                            : (widget.isEdit ? 'Update' : 'Add')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _fetch() async {
    setState(() => _fetching = true);
    try {
      final item = await context.read<ContentService>().fetchCategory(widget.categoryId!);
      if (mounted) {
        _titleController.text = item.title;
        _descController.text = item.desc;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final service = context.read<ContentService>();
      if (widget.isEdit) {
        await service.updateCategory(
          id: widget.categoryId!,
          title: _titleController.text.trim(),
          desc: _descController.text.trim(),
        );
      } else {
        await service.addCategory(
          title: _titleController.text.trim(),
          desc: _descController.text.trim(),
          subjectId: widget.subjectId,
          moduleId: widget.moduleId,
        );
      }
      if (mounted) {
        Navigator.of(context).pop(true);
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
}
