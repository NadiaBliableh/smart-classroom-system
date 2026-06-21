import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class StudentAttendanceScreen extends StatelessWidget {
  final String lectureId;
  final String lectureName;

  const StudentAttendanceScreen({
    super.key,
    required this.lectureId,
    required this.lectureName,
  });

  static const Color bgColor = Color(0xFF0E1325);
  static const Color cardColor = Color(0xFF1A2142);
  static const Color primaryBlue = Color(0xFF4DA3FF);
  static const Color accentGreen = Color(0xFF00E676);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          children: [
            const Text("Attendance List", style: TextStyle(fontSize: 14, color: Colors.white54)),
            Text(lectureName, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder(
       
        stream: FirebaseDatabase.instance.ref().child('enrollments/$lectureId').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No students enrolled", style: TextStyle(color: Colors.white)));
          }

          final enrolledStudents = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final studentIds = enrolledStudents.keys.toList();

          return StreamBuilder(
            // مراقبة الحضور الفعلي
            stream: FirebaseDatabase.instance.ref().child('attendance/$lectureId').onValue,
            builder: (context, attendSnapshot) {
              final attendanceData = attendSnapshot.hasData && attendSnapshot.data!.snapshot.value != null
                  ? Map<String, dynamic>.from(attendSnapshot.data!.snapshot.value as Map)
                  : {};

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: studentIds.length,
                itemBuilder: (context, index) {
                  final sId = studentIds[index];
                  final isPresent = attendanceData.containsKey(sId);

                  return FutureBuilder(
                    future: FirebaseDatabase.instance.ref().child('students/$sId').get(),
                    builder: (context, studentSnap) {
                      if (!studentSnap.hasData) return const SizedBox();

                      final student = Map<String, dynamic>.from(studentSnap.data!.value as Map);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isPresent ? accentGreen.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: bgColor,
                              child: Text(student['name'][0], style: const TextStyle(color: primaryBlue)),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student['name'],
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "ID: $sId",
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isPresent ? accentGreen.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                isPresent ? "PRESENT" : "ABSENT",
                                style: TextStyle(
                                  color: isPresent ? accentGreen : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}