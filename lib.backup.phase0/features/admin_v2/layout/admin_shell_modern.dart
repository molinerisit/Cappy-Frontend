import 'package:flutter/material.dart';
import '../screens/admin_dashboard_modern.dart';
import '../modules/node_library/node_library_screen.dart';

class AdminShellModern extends StatefulWidget {
  final String? initialPathId;
  final String? initialNodeId;

  const AdminShellModern({super.key, this.initialPathId, this.initialNodeId});

  @override
  State<AdminShellModern> createState() => _AdminShellModernState();
}

class _AdminShellModernState extends State<AdminShellModern> {
  bool _isLibraryOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLibraryOpen
          ? const NodeLibraryScreen()
          : AdminDashboardScreenModern(
              onLibraryTap: () {
                setState(() => _isLibraryOpen = true);
              },
            ),
    );
  }
}
