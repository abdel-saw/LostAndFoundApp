import 'package:flutter/material.dart';
import 'package:lost_and_found_app/services/photo_picker.dart';
import 'package:lost_and_found_app/services/supabase_service.dart';
import 'package:lost_and_found_app/utils/extensions.dart';

class ReportItemScreen extends StatefulWidget {
  const ReportItemScreen({super.key});
  @override
  State<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends State<ReportItemScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  String _type = 'lost';
  String _category = 'Personal';
  SelectedPhoto? _photo;
  bool _busy = false;
  bool _picking = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_busy || _picking) return;
    setState(() => _picking = true);
    try {
      final photo = await pickPhoto();
      if (mounted && photo != null) setState(() => _photo = photo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _report() async {
    if (_busy || _picking) return;
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an item name')));
      return;
    }
    final data = <String, dynamic>{
      'type': _type, 'name': _name.text.trim(), 'description': _description.text,
      'category': _category, 'location': _location.text, 'photo_url': '',
    };
    final photo = _photo;
    setState(() => _busy = true);
    try {
      if (photo != null) {
        data['photo_url'] = await SupabaseService.uploadImage(photo.bytes, contentType: photo.contentType);
      }
      await SupabaseService.reportItem(data);
      if (!mounted) return;
      _name.clear();
      _description.clear();
      _location.clear();
      setState(() => _photo = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item Reported')));
      if (Navigator.canPop(context)) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    final navigator = Navigator.of(context);
    try {
      await SupabaseService.signOut();
      if (navigator.mounted) navigator.popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Report Item'), actions: [
      IconButton(key: const Key('sign-out'), tooltip: 'Sign out',
        onPressed: _busy ? null : _signOut, icon: const Icon(Icons.logout)),
    ]),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        DropdownButton<String>(value: _type,
          items: ['lost', 'found'].map((value) =>
            DropdownMenuItem(value: value, child: Text(value.capitalize()))).toList(),
          onChanged: _busy ? null : (value) => setState(() => _type = value!)),
        TextField(key: const Key('report-name'), controller: _name, maxLength: 120,
          decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder())),
        TextField(key: const Key('report-description'), controller: _description,
          maxLines: 2, maxLength: 2000,
          decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
        TextField(key: const Key('report-location'), controller: _location, maxLength: 200,
          decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder())),
        DropdownButton<String>(value: _category,
          items: ['Personal', 'Electronics', 'Other'].map((value) =>
            DropdownMenuItem(value: value, child: Text(value))).toList(),
          onChanged: _busy ? null : (value) => setState(() => _category = value!)),
        ElevatedButton(key: const Key('pick-photo'),
          onPressed: _busy || _picking ? null : _pickPhoto,
          child: Text(_picking ? 'Choosing photo…' : 'Pick Image')),
        const Text('JPEG, PNG or WebP · up to 5 MiB · photos use public URLs'),
        if (_photo != null)
          Image.memory(_photo!.bytes, key: const Key('photo-preview'),
            height: 100, fit: BoxFit.cover),
        const SizedBox(height: 20),
        ElevatedButton(key: const Key('submit-report'),
          onPressed: _busy || _picking ? null : _report,
          child: Text(_busy ? 'Submitting…' : 'Report Item')),
      ]),
    ),
  );
}
