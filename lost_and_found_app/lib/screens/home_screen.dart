// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, use_build_context_synchronously, sort_child_properties_last

// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';

import 'package:lost_and_found_app/services/supabase_service.dart';
import 'package:lost_and_found_app/widgets/item_card.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:lost_and_found_app/utils/extensions.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String _filterType = 'all';
  

  Future<void> _addComment(int itemId) async {
    if (await SupabaseService.isUserAuthenticated() == false || _commentController.text.isEmpty) return;

    try {
      await SupabaseService.addComment(itemId, _commentController.text);
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Comment Added')));
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
        title: Text('LostAndFound ', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFFAEC6CF), fontFamily: 'Roboto')),
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
                Navigator.pushReplacementNamed(context, '/report');
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Search and Filter UI ---
                Text('Search and Filter Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(labelText: 'Search by Name', border: OutlineInputBorder()),
                  onChanged: (value) => setState(() {}),
                ),
                SizedBox(height: 10),
                DropdownButton<String>(
                  value: _filterType,
                  items: ['all', 'lost', 'found'].map((value) => DropdownMenuItem(value: value, child: Text(value.capitalize()))).toList(),
                  onChanged: (value) => setState(() => _filterType = value!),
                ),
                // --- Items List ---
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: SupabaseService.getItemsStream(_filterType, _searchController.text),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No items found'));
                    }
                    final items = snapshot.data!;
                    SupabaseService.cacheItems(items);
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final type = item['type']?.toString() ?? 'Unknown';
                        final name = item['name']?.toString() ?? 'Unnamed';
                        return ItemCard(
                          item: {
                            'id': item['id'],
                            'type': type,
                            'name': name,
                            'description': item['description']?.toString() ?? '',
                            'location': item['location']?.toString() ?? '',
                            'photo_url': item['photo_url']?.toString() ?? ''
                          },
                          onComment: () => _addComment(item['id'] as int),
                          commentController: _commentController,
                        );
                      },
                    );
                  },
                ),
                SizedBox(height: 20),
                // --- Categories Pie Chart ---
                Text('Item Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  height: 200,
                  padding: EdgeInsets.all(8),
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: SupabaseService.getItemsStream('all', ''),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return CircularProgressIndicator();
                      final items = snapshot.data!;
                      final categories = {'Personal': 0.0, 'Electronics': 0.0, 'Other': 0.0};
                      for (var item in items) {
                        final category = item['category']?.toString() ?? 'Other';
                        categories[category] = (categories[category] ?? 0.0) + 1;
                      }
                      return PieChart(
                        PieChartData(
                          sections: categories.entries
                              .map((e) => PieChartSectionData(
                                    title: e.key,
                                    value: e.value,
                                    color: e.key == 'Personal' ? Colors.blue : e.key == 'Electronics' ? Colors.red : Colors.green,
                                    radius: 50,
                                  ))
                              .toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
     
    );
  }
}