import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'app_drawer.dart';

class AppLayout extends StatelessWidget {
  final Widget child;
  final String role; // 'business' or 'transporter'

  const AppLayout({super.key, required this.child, required this.role});

  @override
  Widget build(BuildContext context) {
    // For simplicity on mobile, we use a BottomNavigationBar or a Drawer.
    // Let's use a standard Scaffold with a Drawer for navigation.
    return PopScope(
      canPop: !context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && context.canPop()) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: context.canPop() 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  context.pop();
                },
              )
            : null,
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
        drawer: context.canPop() ? null : const AppDrawer(), // Hide drawer when pushing inner screens
        body: child,
      ),
    );
  }
}
