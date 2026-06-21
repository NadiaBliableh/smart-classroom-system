import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'room_dashboard_screen.dart';
import 'lecture_reports_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String userRole;

  const HomeScreen({super.key, required this.userName, required this.userRole});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'classrooms',
  );
  String? expandedRoomId;

  static const Color bgColor = Color(0xFF0E1325);
  static const Color cardColor = Color(0xFF1A2142);
  static const Color primaryBlue = Color(0xFF4DA3FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          "Smart Classrooms",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.account_circle,
              color: primaryBlue,
              size: 34,
            ),
            // 1. تحسين شكل المربع (زوايا وبرواز خفيف)
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            color: cardColor,
            elevation: 8, // يعطي ظلاً خلف المربع ليبرز عن الصفحة
            onSelected: (value) async {
              if (value == 'logout') {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  // 2. تمييز منطقة الاسم بلون مختلف قليلاً (اختياري)
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.userRole,
                        style: const TextStyle(
                          color:
                              primaryBlue, // جعل الرتبة باللون الأزرق لتبدو أوضح
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const PopupMenuDivider(height: 1), // فاصل أنحف وأرتب
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent.withOpacity(0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Logout",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: StreamBuilder(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final Map<dynamic, dynamic> rooms =
                snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

            final roomKeys = rooms.keys.cast<String>().toList();

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: roomKeys.length,
              itemBuilder: (context, index) {
                final key = roomKeys[index];
                final room = rooms[key];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _buildRoomCard(
                    key,
                    room['name'] ?? 'Unknown',
                    room['status'] ?? 'Off',
                  ),
                );
              },
            );
          }

          return const Center(
            child: CircularProgressIndicator(color: primaryBlue),
          );
        },
      ),
    );
  }

  Widget _buildRoomCard(String id, String name, String status) {
    final bool isOn = status.toLowerCase() == 'active';
    final bool isExpanded = expandedRoomId == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          // إذا ضغط على نفس الغرفة يغلقها، وإذا ضغط على غيرها يفتح الجديدة ويغلق القديمة
          expandedRoomId = isExpanded ? null : id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutBack, // حركة ارتدادية خفيفة تعطي طابع مودرن
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded
                ? primaryBlue
                : (isOn ? primaryBlue.withOpacity(0.5) : Colors.white12),
            width: 1.5,
          ),
          boxShadow: isExpanded || isOn
              ? [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            // الجزء العلوي (المعلومات الأساسية)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOn
                        ? primaryBlue.withOpacity(0.15)
                        : Colors.white10,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.meeting_room_rounded,
                    size: 28,
                    color: isOn ? primaryBlue : Colors.white38,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isExpanded ? "Choose action" : "Tap to manage",
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // أيقونة تتغير حركتها عند التوسع
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0, // يلف السهم للأسفل عند الفتح
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white24,
                    size: 16,
                  ),
                ),
              ],
            ),

            // الجزء المخفي (الخيارات التي تظهر عند الـ Expand)
            AnimatedCrossFade(
              firstChild: const SizedBox(
                width: double.infinity,
              ), // حالة الإغلاق
              secondChild: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Divider(color: Colors.white10, height: 1),
                  ),
                  Row(
                    children: [
                      // الزر الأول: داشبورد
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.dashboard_rounded,
                          label: "Dashboard",
                          color: primaryBlue,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoomDashboardScreen(roomId: id),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // الزر الثاني: تقارير
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.history_edu_rounded,
                          label: "Reports",
                          color: Colors.purpleAccent,
                          // داخل HomeScreen -> _buildActionButton الخاص بـ Reports
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    LectureReportsListScreen(roomId: id),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  // ويدجت مساعد لبناء الأزرار داخل الكارت
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
