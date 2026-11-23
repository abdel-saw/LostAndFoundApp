import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lost_and_found_app/services/supabase_service.dart';
import 'package:lost_and_found_app/widgets/item_card.dart';
import 'package:lost_and_found_app/utils/extensions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  late final Stream<List<Map<String, dynamic>>> _items;
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _items = SupabaseService.getItemsStream('all', '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    try {
      await SupabaseService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('LostAndFound'),
      backgroundColor: const Color(0xFFE6E6FA),
      actions: [
        IconButton(key: const Key('sign-out'), tooltip: 'Sign out',
          icon: const Icon(Icons.logout), onPressed: _signOut),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      key: const Key('new-report'),
      onPressed: () => Navigator.pushNamed(context, '/report'),
      icon: const Icon(Icons.add), label: const Text('Report Item'),
    ),
    body: StreamBuilder<List<Map<String, dynamic>>>(
      stream: _items,
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final term = _searchController.text.toLowerCase();
        final visible = items.where((item) =>
          (_filterType == 'all' || item['type'] == _filterType) &&
          (item['name']?.toString() ?? '').toLowerCase().contains(term)).toList();
        final categories = <String, double>{};
        for (final item in items) {
          final category = item['category']?.toString() ?? 'Other';
          categories[category] = (categories[category] ?? 0) + 1;
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Search and Filter Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(key: const Key('item-search'), controller: _searchController,
              decoration: const InputDecoration(labelText: 'Search by Name', border: OutlineInputBorder()),
              onChanged: (_) => setState(() {})),
            DropdownButton<String>(
              value: _filterType,
              items: ['all', 'lost', 'found'].map((value) =>
                DropdownMenuItem(value: value, child: Text(value.capitalize()))).toList(),
              onChanged: (value) => setState(() => _filterType = value!)),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              Text('Error: ${snapshot.error}')
            else if (visible.isEmpty)
              const Text('No items found')
            else
              ...visible.map((item) => ItemCard(key: ValueKey(item['id']), item: item)),
            const SizedBox(height: 24),
            const Text('Item Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (categories.isNotEmpty)
              SizedBox(height: 220, child: PieChart(PieChartData(
                sections: categories.entries.map((e) => PieChartSectionData(
                  title: e.key, value: e.value,
                  color: e.key == 'Personal' ? Colors.blue :
                    e.key == 'Electronics' ? Colors.red : Colors.green,
                  radius: 60,
                )).toList(),
              ))),
          ]),
        );
      },
    ),
  );
}
