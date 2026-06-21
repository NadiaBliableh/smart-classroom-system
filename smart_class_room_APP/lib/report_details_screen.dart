import 'package:flutter/material.dart';

class ReportDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> reportData;

  const ReportDetailsScreen({super.key, required this.reportData});

  static const Color bgColor = Color(0xFF0E1325);
  static const Color cardColor = Color(0xFF1A2142);
  static const Color primaryBlue = Color(0xFF4DA3FF);

  @override
  Widget build(BuildContext context) {
    final env = reportData['environmentStats'] ?? {};
    final attendance = reportData['attendance'] ?? {};
    final lecture = reportData['lectureInfo'] ?? {};
    final log = Map<dynamic, dynamic>.from(attendance['log'] ?? {});

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Lecture Summary: ${lecture['lectureId']}"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. بطاقة المعلومات الأساسية (بشكل عرضي)
            _buildHeaderInfo(lecture),
            
            const SizedBox(height: 20),

            // 2. إحصائيات الحضور الكبيرة (Focus on Numbers)
            Row(
              children: [
                _buildBigStat("Present", "${attendance['present']}", Icons.check_circle, Colors.green),
                const SizedBox(width: 15),
                _buildBigStat("Avg Temp", "${env['temperature']?['average']}°C", Icons.thermostat, Colors.orange),
              ],
            ),

            const SizedBox(height: 25),

            // 3. قسم "حالة القاعة" (هل كانت الأجواء مناسبة؟)
            _buildEnvironmentSummary(env),

            const SizedBox(height: 25),

            // 4. سجل الحضور المرتب (Timeline)
            _buildAttendanceTimeline(log),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(Map info) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryBlue, Color(0xFF1274E7)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(info['courseId'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(info['date'] ?? "", style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const Icon(Icons.school, size: 40, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildBigStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentSummary(Map env) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.wb_cloudy_outlined, color: primaryBlue, size: 18),
              SizedBox(width: 10),
              Text("Environment Status", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: Colors.white10, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEnvDetail("Max Temp", "${env['temperature']?['final']}°C"),
              _buildEnvDetail("Lighting", "${env['lighting']?['averageBrightness']}%"),
              _buildEnvDetail("Mode", "${env['lighting']?['finalMode']}"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEnvDetail(String label, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _buildAttendanceTimeline(Map log) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ATTENDANCE LOG", style: TextStyle(color: Colors.white38, letterSpacing: 1.2, fontSize: 12)),
        const SizedBox(height: 15),
        if (log.isEmpty) const Center(child: Text("No one attended", style: TextStyle(color: Colors.white24))),
        ...log.entries.map((e) => _buildTimelineTile(e.key.toString(), e.value['time'], e.value['method'])),
      ],
    );
  }

  Widget _buildTimelineTile(String id, String time, String method) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(width: 12, height: 12, decoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle)),
              Expanded(child: Container(width: 2, color: Colors.white10)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(15)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Student ID: $id", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text("via $method", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                  Text(time, style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}