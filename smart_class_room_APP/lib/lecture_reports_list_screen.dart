import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'report_details_screen.dart';

class LectureReportsListScreen extends StatelessWidget {
  final String roomId;

  const LectureReportsListScreen({super.key, required this.roomId});

  static const Color bgColor = Color(0xFF0E1325);
  static const Color cardColor = Color(0xFF1A2142);
  static const Color primaryBlue = Color(0xFF4DA3FF);
  static const Color accentGreen = Color(0xFF00E676);

  // دالة لجلب اسم الكورس بناءً على الـ ID من قاعدة البيانات
  Future<String> _getCourseName(String courseId) async {
    final ref = FirebaseDatabase.instance.ref().child('courses/$courseId/name');
    final snapshot = await ref.get();
    return snapshot.value?.toString() ?? courseId;
  }

  @override
  Widget build(BuildContext context) {
    final reportsRef = FirebaseDatabase.instance.ref().child('lectureReports/$roomId');

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Reports - $roomId", style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: reportsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryBlue));
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return _buildEmptyState();
          }

          final reportsData = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          List<Map<String, dynamic>> allReports = [];

          reportsData.forEach((lectureId, dates) {
            final dateMap = Map<String, dynamic>.from(dates as Map);
            dateMap.forEach((date, details) {
              allReports.add({
                'lectureId': lectureId,
                'date': date,
                'data': details,
              });
            });
          });

          allReports.sort((a, b) => b['date'].compareTo(a['date']));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: allReports.length,
            itemBuilder: (context, index) {
              final report = allReports[index];
              final data = report['data'];
              final courseId = data['lectureInfo']['courseId'] ?? "";

              return GestureDetector(
                onTap: () {
                  final reportContent = Map<String, dynamic>.from(report['data'] as Map);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ReportDetailsScreen(reportData: reportContent)),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      // أيقونة التاريخ الجانبية
                      _buildDateBadge(report['date']),
                      const SizedBox(width: 15),
                      
                      // تفاصيل الكورس والمحاضرة
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<String>(
                              future: _getCourseName(courseId),
                              builder: (context, nameSnapshot) {
                                return Text(
                                  nameSnapshot.data ?? "Loading...",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Lecture ID: ${report['lectureId']}",
                              style: TextStyle(color: primaryBlue.withOpacity(0.8), fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 14, color: Colors.white38),
                                const SizedBox(width: 5),
                                Text(
                                  data['lectureInfo']['timeSlot'] ?? "",
                                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // سهم الانتقال
                      const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 18),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ويدجت لعرض التاريخ بشكل "Badge" أنيق
  Widget _buildDateBadge(String dateStr) {
    // نفترض التاريخ YYYY-MM-DD
    List<String> parts = dateStr.split('-');
    String day = parts.length > 2 ? parts[2] : "00";
    String month = parts.length > 1 ? _getMonthName(parts[1]) : "JAN";

    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(day, style: const TextStyle(color: primaryBlue, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(month, style: const TextStyle(color: primaryBlue, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _getMonthName(String m) {
    const months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
    int idx = int.tryParse(m) ?? 1;
    return months[idx - 1];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_chart_outlined_rounded, size: 100, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 15),
          const Text("No reports archived for this room", style: TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }
}