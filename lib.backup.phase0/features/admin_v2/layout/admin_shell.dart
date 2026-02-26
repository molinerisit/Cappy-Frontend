import 'package:flutter/material.dart';
import '../modules/node_tree/node_tree_editor_screen.dart';
import '../modules/node_library/node_library_screen.dart';

class AdminShell extends StatefulWidget {
  final String? initialPathId;
  final String? initialNodeId;

  const AdminShell({super.key, this.initialPathId, this.initialNodeId});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  List<Widget> _buildScreens() {
    return [
      NodeTreeEditorScreen(
        initialPathId: widget.initialPathId,
        initialNodeId: widget.initialNodeId,
      ),
      const Placeholder(),
      const Placeholder(),
      const NodeLibraryScreen(),
      const Placeholder(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Workspace'),
        actions: [
          SizedBox(
            width: 260,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search content',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: const [
              Icon(Icons.cloud_done_outlined, size: 20),
              SizedBox(width: 8),
              Text('Auto-save enabled'),
            ],
          ),
          const SizedBox(width: 24),
          CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            child: const Icon(Icons.person_outline, color: Colors.black54),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.account_tree_outlined),
                label: Text('Paths'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.public_outlined),
                label: Text('Culture'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.restaurant_outlined),
                label: Text('Recipes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.library_books_outlined),
                label: Text('Node Library'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _buildScreens()[_selectedIndex]),
        ],
      ),
    );
  }
}
