import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<UserProvider>().user?.role;
    if (role == 'business') {
      return const BusinessMenu();
    } else {
      return const TransporterMenu();
    }
  }
}

class BusinessMenu extends StatelessWidget {
  const BusinessMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const _AppDrawerHeader(isBusiness: true),
          AppDrawerTile(icon: Icons.home, title: 'Dashboard', route: '/business/dashboard', currentRoute: GoRouterState.of(context).uri.toString()),
          AppDrawerTile(icon: Icons.inventory_2, title: 'Track', route: '/business/track', currentRoute: GoRouterState.of(context).uri.toString()),
          AppDrawerTile(icon: Icons.shield, title: 'Trust Score', route: '/business/trust-score', currentRoute: GoRouterState.of(context).uri.toString()),
          AppDrawerTile(icon: Icons.warning_amber_rounded, title: 'AI Report', route: '/business/risk-report', currentRoute: GoRouterState.of(context).uri.toString()),
          AppDrawerTile(icon: Icons.hub, title: 'Network', route: '/business/network-trust', currentRoute: GoRouterState.of(context).uri.toString()),
          const Divider(),
          AppDrawerTile(icon: Icons.history, title: 'History', route: '/shipment-history', currentRoute: GoRouterState.of(context).uri.toString(), isPush: true),
          const Spacer(),
          AppDrawerTile(icon: Icons.logout, title: 'Sign Out', route: '/login', currentRoute: GoRouterState.of(context).uri.toString(), isLogout: true),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class TransporterMenu extends StatelessWidget {
  const TransporterMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const _AppDrawerHeader(isBusiness: false),
          AppDrawerTile(icon: Icons.home, title: 'Dashboard', route: '/transporter/dashboard', currentRoute: GoRouterState.of(context).uri.toString()),
          AppDrawerTile(icon: Icons.local_shipping_outlined, title: 'Available Loads', route: '/transporter/marketplace', currentRoute: GoRouterState.of(context).uri.toString()),
          AppDrawerTile(icon: Icons.local_shipping, title: 'Update', route: '/transporter/dashboard', currentRoute: GoRouterState.of(context).uri.toString()),
          AppDrawerTile(icon: Icons.cloud_upload, title: 'ePOD', route: '/transporter/dashboard', currentRoute: GoRouterState.of(context).uri.toString()),
          const Divider(),
          AppDrawerTile(icon: Icons.history, title: 'History', route: '/shipment-history', currentRoute: GoRouterState.of(context).uri.toString(), isPush: true),
          const Spacer(),
          AppDrawerTile(icon: Icons.logout, title: 'Sign Out', route: '/login', currentRoute: GoRouterState.of(context).uri.toString(), isLogout: true),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AppDrawerHeader extends StatelessWidget {
  final bool isBusiness;

  const _AppDrawerHeader({required this.isBusiness});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
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
    );
  }
}

class AppDrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final String currentRoute;
  final bool isLogout;
  final bool isPush;

  const AppDrawerTile({
    super.key,
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
