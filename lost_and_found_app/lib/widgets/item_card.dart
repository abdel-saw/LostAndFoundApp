import 'package:flutter/material.dart';
import 'package:lost_and_found_app/utils/extensions.dart';
import 'package:lost_and_found_app/services/supabase_service.dart';

class ItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  const ItemCard({super.key, required this.item});

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  final _commentController = TextEditingController();
  late Stream<List<Map<String, dynamic>>> _comments;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  void _loadComments() {
    _comments = SupabaseService.getCommentsStream(widget.item['id'] as int);
  }

  @override
  void didUpdateWidget(covariant ItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item['id'] != widget.item['id']) _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (_posting || text.isEmpty) return;
    setState(() => _posting = true);
    try {
      await SupabaseService.addComment(widget.item['id'] as int, text);
      if (!mounted) return;
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.item['type']?.toString() ?? 'Unknown';
    final photo = widget.item['photo_url']?.toString() ?? '';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text('${widget.item['name'] ?? 'Unnamed'} (${type.capitalize()})'),
        subtitle: Text('${widget.item['description'] ?? ''} - ${widget.item['location'] ?? ''}'),
        trailing: photo.isEmpty ? null : Image.network(photo,
          key: ValueKey('photo-${widget.item['id']}'), width: 50, height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => const Icon(Icons.broken_image_outlined)),
        children: [
          Padding(padding: const EdgeInsets.all(12), child: Column(children: [
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _comments,
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text('Error loading comments: ${snapshot.error}');
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final comments = snapshot.data!;
                if (comments.isEmpty) return const Text('No comments yet.');
                return Column(children: comments.map((comment) =>
                  ListTile(title: Text(comment['text']?.toString() ?? ''))).toList());
              },
            ),
            TextField(
              key: ValueKey('comment-${widget.item['id']}'),
              controller: _commentController, maxLength: 2000,
              decoration: const InputDecoration(labelText: 'Add Comment', border: OutlineInputBorder()),
              onSubmitted: (_) => _addComment(),
            ),
            TextButton(
              key: ValueKey('post-comment-${widget.item['id']}'),
              onPressed: _posting ? null : _addComment,
              child: Text(_posting ? 'Posting…' : 'Post comment'),
            ),
          ])),
        ],
      ),
    );
  }
}
