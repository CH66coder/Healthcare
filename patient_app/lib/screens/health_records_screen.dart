import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class HealthRecordsScreen extends StatelessWidget {
  const HealthRecordsScreen({super.key});

  static const Color _primary = Color(0xFF00C896);
  static const Color _bg = Color(0xFF0D1117);
  static const Color _card = Color(0xFF161B27);
  static const Color _border = Color(0xFF1E2A42);
  static const Color _text2 = Color(0xFF8B9EC7);

  @override
  Widget build(BuildContext context) {
    final svc = FirebaseService();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          title: const Text('Health Records'),
          bottom: TabBar(
            labelColor: _primary,
            unselectedLabelColor: _text2,
            indicatorColor: _primary,
            labelStyle:
                GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Prescriptions'),
              Tab(text: 'Lab Tests'),
              Tab(text: 'Orders'),
            ],
          ),
        ),
        body: TabBarView(children: [
          // Prescriptions
          StreamBuilder<QuerySnapshot>(
            stream: svc.listenToPrescriptions(
                svc.currentUser?.uid ?? ''),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return _empty('No prescriptions yet');
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: snap.data!.docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return _RecordCard(
                    icon: '💊',
                    title: 'Prescription',
                    subtitle: d['diagnosis'] ?? '',
                    detail: 'Dr. ${d['doctorName'] ?? ''} • ${d['medicines']?.length ?? 0} medicines',
                    color: const Color(0xFF6C63FF),
                    onTap: () => _showPrescriptionDetail(context, d),
                  );
                }).toList(),
              );
            },
          ),
          // Lab Tests
          StreamBuilder<QuerySnapshot>(
            stream: svc.listenToMyLabTests(),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return _empty('No lab tests booked');
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: snap.data!.docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final tests = (d['tests'] as List?)?.length ?? 0;
                  return _RecordCard(
                    icon: '🧪',
                    title: 'Lab Test',
                    subtitle: d['lab'] ?? '',
                    detail: '$tests tests • ₹${d['totalAmount'] ?? 0}',
                    color: const Color(0xFFFFB347),
                    status: d['status'] ?? 'booked',
                  );
                }).toList(),
              );
            },
          ),
          // Orders
          StreamBuilder<QuerySnapshot>(
            stream: svc.listenToMyOrders(),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return _empty('No orders yet');
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: snap.data!.docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return _RecordCard(
                    icon: '📦',
                    title: 'Medicine Order',
                    subtitle: d['pharmacy'] ?? '',
                    detail: '₹${d['total'] ?? 0}',
                    color: const Color(0xFFFF6B6B),
                    status: d['status'] ?? 'pending',
                  );
                }).toList(),
              );
            },
          ),
        ]),
      ),
    );
  }

  Widget _empty(String msg) => Center(
        child: Text(msg,
            style: GoogleFonts.poppins(color: _text2, fontSize: 14)),
      );

  void _showPrescriptionDetail(
      BuildContext context, Map<String, dynamic> d) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Prescription',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              Text('Dr. ${d['doctorName'] ?? ''}',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF8B9EC7), fontSize: 13)),
              const SizedBox(height: 16),
              _row('Diagnosis', d['diagnosis'] ?? ''),
              const SizedBox(height: 12),
              if (d['specialistReferral'] != null &&
                  (d['specialistReferral'] as String).isNotEmpty)
                _row('Refer to', d['specialistReferral']),
              const SizedBox(height: 16),
              Text('Medicines',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const SizedBox(height: 8),
              ...(d['medicines'] as List? ?? []).map((m) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2535),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m['name'] ?? '',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        Text(
                            '${m['frequency']} • ${m['duration']} • ${m['instructions']}',
                            style: GoogleFonts.poppins(
                                color: const Color(0xFF8B9EC7),
                                fontSize: 12)),
                      ],
                    ),
                  )),
              if ((d['notes'] as String?)?.isNotEmpty ?? false) ...[
                const SizedBox(height: 12),
                _row('Notes', d['notes'] ?? ''),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  color: const Color(0xFF8B9EC7), fontSize: 12)),
          Text(value,
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 14)),
        ],
      );
}

class _RecordCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String detail;
  final Color color;
  final String? status;
  final VoidCallback? onTap;

  const _RecordCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.color,
    this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF161B27),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E2A42)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          color: color, fontSize: 12)),
                Text(detail,
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF8B9EC7), fontSize: 12)),
              ],
            ),
          ),
          if (status != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00C896).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(status!,
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF00C896), fontSize: 10)),
            ),
          if (onTap != null)
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF4A5568)),
        ]),
      ),
    );
  }
}
