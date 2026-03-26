import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {'title': 'Shipment Delivered', 'body': 'LR-00123 has been delivered to Delhi Hub.', 'time': '2 mins ago', 'read': false, 'icon': Icons.check_circle, 'color': Colors.green},
      {'title': 'Trust Score Alert', 'body': 'Fast Freight Co score dropped below 60.', 'time': '1 hr ago', 'read': false, 'icon': Icons.warning, 'color': Colors.red},
      {'title': 'OTP Verified', 'body': 'Login from a new device was successful.', 'time': '3 hrs ago', 'read': true, 'icon': Icons.lock, 'color': Colors.blue},
      {'title': 'New Shipment', 'body': 'Shipment LR-00555 created and ready for pickup.', 'time': 'Yesterday', 'read': true, 'icon': Icons.inventory_2, 'color': Colors.orange},
      {'title': 'ePOD Uploaded', 'body': 'Proof of delivery uploaded for LR-00499.', 'time': '2 days ago', 'read': true, 'icon': Icons.cloud_done, 'color': Colors.purple},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [TextButton(onPressed: () {}, child: const Text('Mark all read'))],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final n = notifications[i];
          final isRead = n['read'] as bool;
          final color = n['color'] as Color;
          return Container(
            color: isRead ? Colors.white : const Color(0xFFF0F9FF),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(n['icon'] as IconData, color: color, size: 22),
              ),
              title: Row(children: [
                Expanded(child: Text(n['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold))),
                if (!isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
              ]),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 4),
                Text(n['body'] as String, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 4),
                Text(n['time'] as String, style: const TextStyle(fontSize: 11, color: Colors.black38)),
              ]),
            ),
          );
        },
      ),
    );
  }
}


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final data = await context.read<FirebaseService>().get('users', user.uid);
        if (mounted) {
          setState(() {
            _userData = data;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const Divider(height: 1),
                  _profileTile(Icons.edit, 'Edit Profile', () => context.push('/profile/edit')),
                  _profileTile(
                    Icons.shield,
                    'Trust Score',
                    () {
                      final role = _userData?['role'] as String?;
                      if (role == 'business') {
                        context.push('/business/trust-score');
                      } else {
                        // Transporters see their score on the dashboard
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trust score is displayed on your tracking dashboard.')));
                      }
                    },
                  ),
                  _profileTile(Icons.notifications, 'Notification Settings', () => context.push('/profile/notifications')),
                  _profileTile(Icons.lock, 'Change Password', () => context.push('/profile/change-password')),
                  _profileTile(Icons.help_outline, 'Help & Support', () => context.push('/profile/help')),
                  _profileTile(Icons.privacy_tip_outlined, 'Privacy Policy', () => context.push('/profile/privacy')),
                  const Divider(height: 1),
                  _profileTile(
                    Icons.logout,
                    'Sign Out',
                    () async {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) context.go('/role-selection');
                    },
                    color: Colors.red,
                  ),
                  const SizedBox(height: 24),
                  const Center(child: Text('TrustNet AI v1.0.0', style: TextStyle(color: Colors.black38, fontSize: 12))),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final authUser = FirebaseAuth.instance.currentUser;
    final email = authUser?.email ?? _userData?['email'] ?? authUser?.phoneNumber ?? 'No Email';
    final name = _userData?['name'] ?? authUser?.displayName ?? 'User';
    final role = _userData?['role'] == 'business' ? 'Business Owner' : 'Transporter';

    return Container(
      padding: const EdgeInsets.all(32),
      color: const Color(0xFFF8FAFC),
      child: Column(children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
          child: Text(
            name[0].toUpperCase(),
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
          ),
        ),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(email, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(20)),
          child: Text(role, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _profileTile(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black54),
      title: Text(title, style: TextStyle(color: color ?? Colors.black87)),
      trailing: color == null ? const Icon(Icons.chevron_right, color: Colors.black38) : null,
      onTap: onTap,
    );
  }
}


class ShipmentHistoryScreen extends StatelessWidget {
  const ShipmentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shipments = [
      {'lr': 'LR-00456', 'from': 'Mumbai', 'to': 'Delhi', 'date': '24 Mar 2026', 'status': 'Delivered', 'score': 92},
      {'lr': 'LR-00399', 'from': 'Pune', 'to': 'Chennai', 'date': '18 Mar 2026', 'status': 'Delivered', 'score': 78},
      {'lr': 'LR-00312', 'from': 'Delhi', 'to': 'Kolkata', 'date': '10 Mar 2026', 'status': 'Delivered', 'score': 85},
      {'lr': 'LR-00278', 'from': 'Bangalore', 'to': 'Hyderabad', 'date': '5 Mar 2026', 'status': 'Delayed', 'score': 55},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipment History', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: shipments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final s = shipments[i];
          final score = s['score'] as int;
          final scoreColor = score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red;
          final isDelivered = s['status'] == 'Delivered';
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(s['lr'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Chip(
                    label: Text(s['status'] as String, style: const TextStyle(color: Colors.white, fontSize: 11)),
                    backgroundColor: isDelivered ? Colors.green : Colors.red,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.black38),
                  Text(' ${s['from']} → ${s['to']}', style: const TextStyle(color: Colors.black54)),
                ]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    const Icon(Icons.calendar_today, size: 13, color: Colors.black38),
                    Text(' ${s['date']}', style: const TextStyle(color: Colors.black45, fontSize: 12)),
                  ]),
                  Row(children: [
                    const Text('Trust: ', style: TextStyle(color: Colors.black45, fontSize: 12)),
                    Text('$score', style: TextStyle(fontWeight: FontWeight.bold, color: scoreColor)),
                  ]),
                ]),
              ]),
            ),
          );
        },
      ),
    );
  }
}
