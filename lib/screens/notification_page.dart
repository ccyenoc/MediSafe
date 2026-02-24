import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../colors/color.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.royalBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: user == null
          ? _emptyState()
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('schedules')
                  .where('isActive', isEqualTo: true)
                  .where('time',
                      isGreaterThanOrEqualTo:
                          Timestamp.fromDate(DateTime.now()))
                  .orderBy('time')
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) return _emptyState();

                final now = DateTime.now();
                final todayStart =
                    DateTime(now.year, now.month, now.day);
                final tomorrowStart = todayStart.add(const Duration(days: 1));
                final dayAfterStart =
                    tomorrowStart.add(const Duration(days: 1));

                final today = <QueryDocumentSnapshot>[];
                final tomorrow = <QueryDocumentSnapshot>[];
                final upcoming = <QueryDocumentSnapshot>[];

                for (final doc in docs) {
                  final t =
                      (doc['time'] as Timestamp).toDate();
                  if (t.isBefore(tomorrowStart)) {
                    today.add(doc);
                  } else if (t.isBefore(dayAfterStart)) {
                    tomorrow.add(doc);
                  } else {
                    upcoming.add(doc);
                  }
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    if (today.isNotEmpty) ...[
                      _sectionHeader('Today'),
                      ...today.map((d) => _notifTile(d)),
                    ],
                    if (tomorrow.isNotEmpty) ...[
                      _sectionHeader('Tomorrow'),
                      ...tomorrow.map((d) => _notifTile(d)),
                    ],
                    if (upcoming.isNotEmpty) ...[
                      _sectionHeader('Upcoming'),
                      ...upcoming.map((d) => _notifTile(d)),
                    ],
                  ],
                );
              },
            ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.royalBlue,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _notifTile(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final medicine = data['medicineName'] ?? 'Medicine';
    final notes = (data['notes'] as String? ?? '').trim();
    final time = (data['time'] as Timestamp).toDate();

    final timeStr = _formatTime(time);
    final dateStr = _formatDate(time);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE4F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.medication_rounded,
              color: AppColors.royalBlue, size: 24),
        ),
        title: Text(
          medicine,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '$dateStr • $timeStr',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.royalBlue),
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                notes,
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            timeStr,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.royalBlue,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: const Color(0xFFD1E3F8),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.royalBlue, width: 2),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 72, color: AppColors.royalBlue),
          ),
          const SizedBox(height: 24),
          const Text('All Caught Up!',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 8),
          const Text(
            'No upcoming medication reminders.\nAdd a schedule to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    if (date == today) return 'Today';
    if (date == today.add(const Duration(days: 1))) return 'Tomorrow';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
