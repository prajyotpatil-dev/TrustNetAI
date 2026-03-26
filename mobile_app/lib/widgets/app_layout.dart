import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class AppLayout extends StatelessWidget {
  final Widget child;
  final String role; // 'business' or 'transporter'

  const AppLayout({super.key, required this.child, required this.role});

  @override
  Widget build(BuildContext context) {
    // For simplicity on mobile, we use a BottomNavigationBar or a Drawer.
    // Let's use a standard Scaffold with a Drawer for navigation.
    final isBusiness = role == 'business';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('TrustNet AI', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final user = userProvider.user;
                final displayName = user?.name ?? (isBusiness ? 'Business Owner' : 'Transporter');
                final displayEmail = user?.email.isNotEmpty == true 
                    ? user!.email 
                    : (user?.phone.isNotEmpty == true ? user!.phone : 'Loading...');

                return UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    color: isBusiness ? const Color(0xFFDBEAFE) : const Color(0xFFDCFCE7),
                  ),
                  accountName: Text(
                    displayName,
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                  ),
                  accountEmail: Text(displayEmail, style: const TextStyle(color: Colors.black54)),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: isBusiness ? const Color(0xFF2563EB) : const Color(0xFF16A34A),
                    child: Text(
                      displayName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
            if (isBusiness) ...[
              _DrawerTile(icon: Icons.home, title: 'Dashboard', route: '/business/dashboard', currentRoute: GoRouterState.of(context).uri.toString()),
              _DrawerTile(icon: Icons.inventory_2, title: 'Track', route: '/business/track/SH001', currentRoute: GoRouterState.of(context).uri.toString(), isPush: true),
              _DrawerTile(icon: Icons.shield, title: 'Trust Score', route: '/business/trust-score', currentRoute: GoRouterState.of(context).uri.toString()),
              _DrawerTile(icon: Icons.warning_amber_rounded, title: 'AI Report', route: '/business/risk-report', currentRoute: GoRouterState.of(context).uri.toString()),
              _DrawerTile(icon: Icons.hub, title: 'Network', route: '/business/network-trust', currentRoute: GoRouterState.of(context).uri.toString()),
            ] else ...[
              _DrawerTile(icon: Icons.home, title: 'Dashboard', route: '/transporter/dashboard', currentRoute: GoRouterState.of(context).uri.toString()),
              _DrawerTile(icon: Icons.add_circle_outline, title: 'Create', route: '/transporter/create-shipment', currentRoute: GoRouterState.of(context).uri.toString(), isPush: true),
              _DrawerTile(icon: Icons.local_shipping, title: 'Update', route: '/transporter/update-status/SH001', currentRoute: GoRouterState.of(context).uri.toString(), isPush: true),
              _DrawerTile(icon: Icons.cloud_upload, title: 'ePOD', route: '/transporter/upload-epod/SH001', currentRoute: GoRouterState.of(context).uri.toString(), isPush: true),
            ],
            const Divider(),
            _DrawerTile(icon: Icons.history, title: 'History', route: '/shipment-history', currentRoute: GoRouterState.of(context).uri.toString(), isPush: true),
            const Spacer(),
            _DrawerTile(icon: Icons.logout, title: 'Sign Out', route: '/login', currentRoute: GoRouterState.of(context).uri.toString(), isLogout: true),
            const SizedBox(height: 24),
          ],
        ),
      ),
      body: child,
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final String currentRoute;
  final bool isLogout;
  final bool isPush;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.route,
    required this.currentRoute,
    this.isLogout = false,
    this.isPush = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentRoute == route;
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : (isSelected ? const Color(0xFF2563EB) : Colors.grey.shade600)),
      title: Text(
        title, 
        style: TextStyle(
          color: isLogout ? Colors.red : (isSelected ? const Color(0xFF2563EB) : Colors.black87),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        )
      ),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (isLogout) {
          context.go('/role-selection');
        } else if (isPush) {
          context.push(route);
        } else {
          context.go(route);
        }
      },
    );
  }
}
