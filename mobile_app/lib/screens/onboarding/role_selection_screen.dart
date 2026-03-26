import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _handleRoleSelect(BuildContext context, String role) {
    context.push('/login', extra: role);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // slate-50 to blue-50 approx
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Welcome to TrustNet AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A), // slate-900
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your role to continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF475569), // slate-600
                ),
              ),
              const SizedBox(height: 48),
              
              _buildRoleCard(
                title: 'Business Owner',
                description: 'MSME looking to track shipments and monitor partner trust scores',
                icon: Icons.business,
                iconColor: const Color(0xFF2563EB), // blue-600
                iconBgColor: const Color(0xFFDBEAFE), // blue-100
                features: [
                  'Track shipments in real-time',
                  'Monitor trust scores',
                  'AI-powered risk reports',
                  'Network trust visualization'
                ],
                onTap: () => _handleRoleSelect(context, 'business'),
              ),
              
              const SizedBox(height: 24),
              
              _buildRoleCard(
                title: 'Transporter',
                description: 'Logistics provider managing shipments and building trust',
                icon: Icons.local_shipping,
                iconColor: const Color(0xFF16A34A), // green-600
                iconBgColor: const Color(0xFFDCFCE7), // green-100
                features: [
                  'Create digital LR/bilty',
                  'Update shipment status',
                  'Upload geo-tagged ePOD',
                  'Build your trust score'
                ],
                onTap: () => _handleRoleSelect(context, 'transporter'),
              ),
              
              const SizedBox(height: 48),
              const Text(
                'Your role determines the features and dashboards available to you',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B), // slate-500
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 24),
            Column(
              children: features.map((feature) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.check, color: iconColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: title == 'Transporter' ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Continue as ${title.split(' ')[0]}'),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
