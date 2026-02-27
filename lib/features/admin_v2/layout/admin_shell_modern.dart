import 'package:flutter/material.dart';
import '../screens/admin_dashboard_modern.dart';
import '../modules/node_library/node_library_screen.dart';
import '../modules/countries/countries_management_screen.dart';

enum _AdminModernView { dashboard, library, countries }

class AdminShellModern extends StatefulWidget {
  final String? initialPathId;
  final String? initialNodeId;

  const AdminShellModern({super.key, this.initialPathId, this.initialNodeId});

  @override
  State<AdminShellModern> createState() => _AdminShellModernState();
}

class _AdminShellModernState extends State<AdminShellModern> {
  _AdminModernView _currentView = _AdminModernView.dashboard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: switch (_currentView) {
        _AdminModernView.library => Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() => _currentView = _AdminModernView.dashboard);
                  },
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Volver a Caminos'),
                ),
              ),
            ),
            const Expanded(child: NodeLibraryScreen()),
          ],
        ),
        _AdminModernView.countries => CountriesManagementScreen(
          onBack: () {
            setState(() => _currentView = _AdminModernView.dashboard);
          },
        ),
        _AdminModernView.dashboard => AdminDashboardScreenModern(
          onLibraryTap: () {
            setState(() => _currentView = _AdminModernView.library);
          },
          onCountriesTap: () {
            setState(() => _currentView = _AdminModernView.countries);
          },
        ),
      },
    );
  }
}
