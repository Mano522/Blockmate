import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../models/study_file.dart';
import '../services/content_service.dart';

class FileSectionWidget extends StatefulWidget {
  const FileSectionWidget({
    super.key,
    required this.type,
    required this.ownerId,
    required this.files,
    required this.isAdmin,
    required this.onChanged,
  });

  final String type;
  final String ownerId;
  final List<StudyFile> files;
  final bool isAdmin;
  final Future<void> Function() onChanged;

  @override
  State<FileSectionWidget> createState() => _FileSectionWidgetState();
}

class _FileSectionWidgetState extends State<FileSectionWidget> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_copy_outlined),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Study Materials & Links',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (widget.isAdmin)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.add_circle_outline),
                    onSelected: (value) {
                      if (value == 'upload') {
                        _pickAndUpload();
                      } else {
                        _addLink();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'upload', child: Text('Upload file')),
                      PopupMenuItem(value: 'link', child: Text('Add link')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_busy) const LinearProgressIndicator(),
            if (widget.files.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No study materials or links added yet.'),
              ),
            ...widget.files.map(
              (file) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(file.isExternal ? Icons.link : Icons.file_present_outlined),
                title: Text(file.name),
                subtitle: Text(file.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () => _openFile(file),
                    ),
                    if (widget.isAdmin)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteFile(file),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    final service = context.read<ContentService>();

    final result = await FilePicker.platform.pickFiles(withData: false);
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;

    final selected = result.files.first;
    if (selected.path == null) return;

    final nameController = TextEditingController(text: selected.name);
    final displayName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Display name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Upload'),
          ),
        ],
      ),
    );
    if (displayName == null || displayName.isEmpty) return;

    setState(() => _busy = true);
    try {
      await service.uploadFile(
        type: widget.type,
        id: widget.ownerId,
        filePath: File(selected.path!).path,
        displayName: displayName,
      );
      await widget.onChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File uploaded successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addLink() async {
    final service = context.read<ContentService>();

    final nameController = TextEditingController();
    final urlController = TextEditingController();

    final payload = await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Link name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              (nameController.text.trim(), urlController.text.trim()),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (payload == null) return;
    var (name, url) = payload;
    if (name.isEmpty || url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    setState(() => _busy = true);
    try {
      await service.addLink(
        type: widget.type,
        id: widget.ownerId,
        name: name,
        url: url,
      );
      await widget.onChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link added successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteFile(StudyFile file) async {
    final service = context.read<ContentService>();

    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete file'),
            content: const Text('Are you sure you want to delete this item?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    setState(() => _busy = true);
    try {
      await service.deleteFile(
        type: widget.type,
        ownerId: widget.ownerId,
        fileId: file.id,
      );
      await widget.onChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openFile(StudyFile file) async {
    final url = file.isExternal
        ? file.url
        : '${AppConstants.apiBaseUrl.replaceFirst('/api/v1', '')}${file.url}';

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch the URL.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: $e')),
        );
      }
    }
  }
}
