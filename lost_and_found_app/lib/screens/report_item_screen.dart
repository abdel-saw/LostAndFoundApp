// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, use_key_in_widget_constructors, library_private_types_in_public_api, use_build_context_synchronously, sort_child_properties_last

import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lost_and_found_app/services/supabase_service.dart';
import 'package:lost_and_found_app/utils/extensions.dart';

class ReportItemScreen extends StatefulWidget {
  @override
  _ReportItemScreenState createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends State<ReportItemScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String _type = 'lost';
  String _category = 'Personal';
  Uint8List? _imageBytes;

  Future<void> _pickImage() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;
    final files = input.files;
    if (files != null && files.isNotEmpty) {
      final file = files.first;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;
      final bytes = reader.result as Uint8List;
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _reportItem() async {
    final isAuthenticated = await SupabaseService.isUserAuthenticated();
    if (!isAuthenticated || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please sign in and enter item name')));
      return;
    }

    String? photoUrl;
    if (_imageBytes != null) {
      try {
        photoUrl = await SupabaseService.uploadImage(_imageBytes!);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
        return;
      }
    }

    final data = {
      'type': _type,
      'name': _nameController.text,
      'description': _descriptionController.text,
      'category': _category,
      'location': _locationController.text,
      'timestamp': DateTime.now().toIso8601String(),
      'user_id': await SupabaseService.getCurrentUserId(),
      'photo_url': photoUrl ?? '',
    };

    try {
      await SupabaseService.reportItem(data);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item Reported')));
      _nameController.clear();
      _descriptionController.clear();
      _locationController.clear();
      setState(() => _imageBytes = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _signOut() async {
    try {
      await SupabaseService.signOut();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signed out successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.report, color: Color(0xFF6C63FF)),
            SizedBox(width: 8),
            Text(
              'Report Item',
              style: TextStyle(
          color: Color(0xFF6C63FF),
          fontWeight: FontWeight.bold,
          fontSize: 22,
          letterSpacing: 1.5,
          shadows: [
            Shadow(
              color: Colors.black12,
              offset: Offset(1, 2),
              blurRadius: 4,
            ),
          ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFE6E6FA),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Text('LostAndFound', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              decoration: BoxDecoration(color: Color(0xFFE6E6FA)),
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text('Reported Items'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('Report Item'),
              onTap: () {
                Navigator.pop(context); 
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Report Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
              value: _type,
              items: ['lost', 'found'].map((value) => DropdownMenuItem(value: value, child: Text(value.capitalize()))).toList(),
              onChanged: (value) => setState(() => _type = value!),
              ),
              TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Item Name', border: OutlineInputBorder())),
              SizedBox(height: 10),
              TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 2,
              ),
              SizedBox(height: 10),
              TextField(
              controller: _locationController,
              decoration: InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
              ),
              SizedBox(height: 10),
              DropdownButton<String>(
              value: _category,
              items: ['Personal', 'Electronics', 'Other'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
              onChanged: (value) => setState(() => _category = value!),
              ),
              ElevatedButton(onPressed: _pickImage, child: Text('Pick Image')),
              if (_imageBytes != null) Image.memory(_imageBytes!, height: 100, fit: BoxFit.cover),
              SizedBox(height: 20),
              Center(
              child: SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                onPressed: _reportItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 4,
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                child: Text('Report Item', style: TextStyle(letterSpacing: 1)),
                ),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}