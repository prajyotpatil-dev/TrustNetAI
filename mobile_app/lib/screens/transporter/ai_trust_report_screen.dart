import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../providers/ai_provider.dart';
import '../../widgets/app_layout.dart';

class AITrustReportScreen extends StatefulWidget {
  const AITrustReportScreen({super.key});

  @override
  State<AITrustReportScreen> createState() => _AITrustReportScreenState();
}

class _AITrustReportScreenState extends State<AITrustReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _generateReport(String type) {
    final uid = context.read<UserProvider>().user?.uid;
    if (uid == null) return;

    final ai = context.read<AIProvider>();
    switch (type) {
      case 'trust_report':
        ai.fetchGeminiReport(transporterId: uid);
        break;
      case 'fraud_analysis':
        ai.fetchFraudAnalysis(transporterId: uid);
        break;
      case 'delivery_prediction':
        ai.fetchDeliveryPrediction(transporterId: uid);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      role: 'transporter',
      child: Consumer2<UserProvider, AIProvider>(
        builder: (context, userProvider, ai, child) {
          final user = userProvider.user;
          final trustScore = user?.trustScore ?? 0.0;

          // Determine theme based on trust score
          Color themeColor;
          IconData headerIcon;
          String statusText;

          if (trustScore >= 80) {
            themeColor = const Color(0xFF16A34A);
            headerIcon = Icons.verified;
            statusText = 'Excellent Reliability';
          } else if (trustScore >= 50) {
            themeColor = const Color(0xFFD97706);
            headerIcon = Icons.warning_amber_rounded;
            statusText = 'Needs Improvement';
          } else {
            themeColor = const Color(0xFFDC2626);
            headerIcon = Icons.gpp_bad;
            statusText = 'High Risk';
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header ──────────────────────────────────────
                      const Text(
                        'AI Trust Report',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 14, color: Colors.purple),
                          const SizedBox(width: 4),
                          const Text(
                            'Powered by Gemini AI',
                            style: TextStyle(fontSize: 14, color: Colors.purple, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          if (user?.aiUpdatedAt != null)
                            Text(
                              'Updated ${_timeAgo(user!.aiUpdatedAt!)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Overall Status Card ─────────────────────────
                      _buildStatusCard(themeColor, headerIcon, statusText, trustScore),
                      const SizedBox(height: 20),

                      // ── Tab Bar ──────────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: const Color(0xFF0F172A),
                          unselectedLabelColor: Colors.black45,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          tabs: const [
                            Tab(text: '📊 Trust'),
                            Tab(text: '🚨 Fraud'),
                            Tab(text: '📈 Predict'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Tab Content ──────────────────────────────────
                      SizedBox(
                        height: 520,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildTrustTab(ai, user?.aiReport),
                            _buildFraudTab(ai, user?.aiFraudAnalysis),
                            _buildPredictionTab(ai, user?.aiDeliveryPrediction),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Status Card
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStatusCard(Color color, IconData icon, String status, double score) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text('Trust Score: ${score.toStringAsFixed(0)} / 100', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                ],
              ),
            ),
            // Score badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                score.toStringAsFixed(0),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Trust Report Tab
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTrustTab(AIProvider ai, String? reportText) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGenerateButton(
            label: 'Generate Trust Report',
            icon: Icons.analytics,
            color: const Color(0xFF2563EB),
            isLoading: ai.isLoadingReport,
            onPressed: () => _generateReport('trust_report'),
          ),
          const SizedBox(height: 16),
          if (ai.isLoadingReport)
            _buildLoadingState('Gemini is analyzing trust metrics...')
          else if (ai.geminiReport != null)
            _buildReportContent(ai.geminiReport!)
          else if (reportText != null && reportText.isNotEmpty)
            _buildReportContent(reportText)
          else
            _buildEmptyState('Tap the button above to generate an AI-powered trust analysis based on your real performance data.'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Fraud Analysis Tab
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFraudTab(AIProvider ai, String? fraudText) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGenerateButton(
            label: 'Run Fraud Analysis',
            icon: Icons.security,
            color: const Color(0xFFDC2626),
            isLoading: ai.isLoadingFraudAnalysis,
            onPressed: () => _generateReport('fraud_analysis'),
          ),
          const SizedBox(height: 16),
          if (ai.isLoadingFraudAnalysis)
            _buildLoadingState('Scanning for anomalies and fraud patterns...')
          else if (ai.fraudAnalysisReport != null)
            _buildReportContent(ai.fraudAnalysisReport!)
          else if (fraudText != null && fraudText.isNotEmpty)
            _buildReportContent(fraudText)
          else
            _buildEmptyState('Tap to run a comprehensive AI fraud analysis that checks for suspicious patterns, duplicate proofs, and anomalies.'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Delivery Prediction Tab
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPredictionTab(AIProvider ai, String? predictionText) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGenerateButton(
            label: 'Generate Prediction',
            icon: Icons.trending_up,
            color: const Color(0xFF7C3AED),
            isLoading: ai.isLoadingPrediction,
            onPressed: () => _generateReport('delivery_prediction'),
          ),
          const SizedBox(height: 16),
          if (ai.isLoadingPrediction)
            _buildLoadingState('Predicting delivery behavior based on history...')
          else if (ai.deliveryPrediction != null)
            _buildReportContent(ai.deliveryPrediction!)
          else if (predictionText != null && predictionText.isNotEmpty)
            _buildReportContent(predictionText)
          else
            _buildEmptyState('Tap to get AI-powered predictions about delay probability, failure risk, and expected delivery behavior.'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Shared Widgets
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGenerateButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withValues(alpha: 0.8)),
              )
            : Icon(icon, color: Colors.white, size: 20),
        label: Text(
          isLoading ? 'Generating...' : label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildLoadingState(String message) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF5F3FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const CircularProgressIndicator(color: Colors.purple),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.purple.shade300, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.auto_awesome, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent(String reportText) {
    // Parse sections from the AI output
    final sections = _parseSections(reportText);

    if (sections.isEmpty) {
      // Unparseable — show as a single block
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(reportText, style: const TextStyle(height: 1.6, fontSize: 14)),
        ),
      );
    }

    return Column(
      children: sections.map((section) {
        final config = _getSectionConfig(section['title']!);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: config.color.withValues(alpha: 0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(config.icon, color: config.color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        section['title']!,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: config.color),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    section['content']!,
                    style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, String>> _parseSections(String text) {
    final sections = <Map<String, String>>[];
    final lines = text.split('\n');
    String? currentTitle;
    final buffer = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Detect section headers like "1. OVERALL ASSESSMENT" or "STRENGTHS" or "FRAUD RISK LEVEL:"
      if (_isSectionHeader(trimmed)) {
        if (currentTitle != null && buffer.isNotEmpty) {
          sections.add({'title': currentTitle, 'content': buffer.toString().trim()});
          buffer.clear();
        }
        currentTitle = _cleanHeader(trimmed);
      } else if (currentTitle != null) {
        buffer.writeln(trimmed);
      } else {
        // Content before any header
        buffer.writeln(trimmed);
      }
    }

    if (currentTitle != null && buffer.isNotEmpty) {
      sections.add({'title': currentTitle, 'content': buffer.toString().trim()});
    } else if (currentTitle == null && buffer.isNotEmpty) {
      // No sections could be parsed
      return [];
    }

    return sections;
  }

  bool _isSectionHeader(String line) {
    final upper = line.toUpperCase();
    return RegExp(r'^(\d+\.\s*)?[A-Z\s]{4,}').hasMatch(upper) &&
        (upper.contains('ASSESSMENT') ||
            upper.contains('STRENGTHS') ||
            upper.contains('RISK') ||
            upper.contains('RECOMMENDATION') ||
            upper.contains('SUGGESTED') ||
            upper.contains('FRAUD') ||
            upper.contains('SUSPICIOUS') ||
            upper.contains('MONITORING') ||
            upper.contains('DELAY') ||
            upper.contains('FAILURE') ||
            upper.contains('EXPECTED') ||
            upper.contains('OPTIMAL') ||
            upper.contains('IMPROVEMENT') ||
            upper.contains('PREDICTION') ||
            upper.contains('ACTIONS'));
  }

  String _cleanHeader(String header) {
    // Remove leading numbers/punctuation like "1. ", "**", etc.
    return header
        .replaceAll(RegExp(r'^\d+\.\s*'), '')
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r':$'), '')
        .trim();
  }

  _SectionConfig _getSectionConfig(String title) {
    final upper = title.toUpperCase();
    if (upper.contains('ASSESSMENT') || upper.contains('OVERALL') || upper.contains('SUMMARY')) {
      return _SectionConfig(Icons.analytics, const Color(0xFF2563EB));
    }
    if (upper.contains('STRENGTH')) {
      return _SectionConfig(Icons.thumb_up, const Color(0xFF16A34A));
    }
    if (upper.contains('RISK') || upper.contains('FRAUD') || upper.contains('SUSPICIOUS')) {
      return _SectionConfig(Icons.warning_amber, const Color(0xFFD97706));
    }
    if (upper.contains('RECOMMENDATION') || upper.contains('ACTIONS') || upper.contains('MONITORING')) {
      return _SectionConfig(Icons.lightbulb_outline, const Color(0xFF7C3AED));
    }
    if (upper.contains('DELAY') || upper.contains('FAILURE') || upper.contains('PREDICTION')) {
      return _SectionConfig(Icons.trending_up, const Color(0xFF0891B2));
    }
    if (upper.contains('EXPECTED') || upper.contains('OPTIMAL') || upper.contains('IMPROVEMENT')) {
      return _SectionConfig(Icons.insights, const Color(0xFF059669));
    }
    return _SectionConfig(Icons.info_outline, const Color(0xFF475569));
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('dd MMM').format(dt);
  }
}

class _SectionConfig {
  final IconData icon;
  final Color color;
  _SectionConfig(this.icon, this.color);
}
