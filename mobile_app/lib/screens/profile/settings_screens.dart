import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _push = true;
  bool _email = true;
  bool _sms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Alerts on your device screen'),
            value: _push,
            onChanged: (v) => setState(() => _push = v),
          ),
          SwitchListTile(
            title: const Text('Email Notifications'),
            subtitle: const Text('Updates sent to your inbox'),
            value: _email,
            onChanged: (v) => setState(() => _email = v),
          ),
          SwitchListTile(
            title: const Text('SMS Notifications'),
            subtitle: const Text('Critical alerts via text message'),
            value: _sms,
            onChanged: (v) => setState(() => _sms = v),
          ),
        ],
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('How can we help you?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _supportCard(Icons.chat_bubble_outline, 'Chat with us', 'Available 24/7'),
          _supportCard(Icons.email_outlined, 'Email Support', 'support@trustnet.ai'),
          _supportCard(Icons.phone_outlined, 'Call Helpline', '1800-TRUST-NET'),
          const SizedBox(height: 20),
          const Text('FAQs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const ExpansionTile(title: Text('How is the Trust Score calculated?'), children: [Padding(padding: EdgeInsets.all(16), child: Text('Trust score is calculated using AI models analyzing on-time delivery rates, ePOD compliance, and dispute history.'))]),
          const ExpansionTile(title: Text('How do I update my GSTIN?'), children: [Padding(padding: EdgeInsets.all(16), child: Text('Go to Edit Profile. If your account is already verified, you may need to contact support to change your GSTIN.'))]),
        ],
      ),
    );
  }

  Widget _supportCard(IconData icon, String title, String subtitle) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2563EB)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Privacy Policy', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Last updated: March 2026', style: TextStyle(color: Colors.black54)),
            SizedBox(height: 24),
            Text('1. Data Collection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('We collect personal data and shipment location data to provide our core trust-scoring and tracking services. This includes GPS locations during active shipment transit.'),
            SizedBox(height: 16),
            Text('2. Data Usage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Your data is strictly used to evaluate network trust, provide AI risk reports, and ensure transparent logistics operations.'),
            SizedBox(height: 16),
            Text('3. Data Protection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('All data is encrypted in transit and at rest using industry-standard protocols.'),
          ],
        ),
      ),
    );
  }
}
