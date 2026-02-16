
// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors_in_immutables, library_private_types_in_public_api, unused_field

import 'package:flutter/material.dart';
import 'package:lost_and_found_app/utils/extensions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onComment;
  final TextEditingController commentController;

  ItemCard({required this.item, required this.onComment, required this.commentController});

  @override
  _ItemCardState createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final type = widget.item['type']?.toString() ?? 'Unknown';
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text('${widget.item['name'] ?? 'Unnamed'} (${type.capitalize()})'),
        subtitle: Text('${widget.item['description'] ?? ''} - ${widget.item['location'] ?? ''}'),
        trailing: widget.item['photo_url'] != ''
            ? Image.network(widget.item['photo_url'], width: 50, fit: BoxFit.cover)
            : null,
        onExpansionChanged: (expanded) {
          setState(() => _isExpanded = expanded);
        },
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: Supabase.instance.client
                      .from('comments')
                      .stream(primaryKey: ['id'])
                      .eq('item_id', widget.item['id'])
                      .order('timestamp', ascending: false),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('Error loading comments: ${snapshot.error}');
                    }
                    final comments = snapshot.data ?? [];
                    if (comments.isEmpty) {
                      return Text('No comments yet.');
                    }
                    return Column(
                      children: comments
                          .map((comment) => ListTile(
                                title: Text(comment['text'] as String? ?? ''),
                                subtitle: Text(comment['timestamp'] as String? ?? ''),
                              ))
                          .toList(),
                    );
                  },
                ),
                TextField(
                  controller: widget.commentController,
                  decoration: InputDecoration(labelText: 'Add Comment', border: OutlineInputBorder()),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      widget.onComment();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}