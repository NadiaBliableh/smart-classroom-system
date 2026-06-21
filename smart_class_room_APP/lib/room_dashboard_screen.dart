import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'student_attendance_screen.dart';

class RoomDashboardScreen extends StatelessWidget {
  final String roomId;

  const RoomDashboardScreen({super.key, required this.roomId});
  static List<double> tempHistory = [];
  static List<int> brightnessHistory = [];
  static String currentMonitoringLecture = "";

  static const Color bgColor = Color(0xFF0E1325);
  static const Color cardColor = Color(0xFF1A2142);
  static const Color primaryBlue = Color(0xFF4DA3FF);
  static const Color accentGreen = Color(0xFF00E676);
  static String lastReportedLectureId = "";

  bool _isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 600;
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = _isTablet(context);
    final DatabaseReference roomRef = FirebaseDatabase.instance.ref().child(
      'classrooms/$roomId',
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "$roomId Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 26 : 20,
          ),
        ),
        centerTitle: true,
        toolbarHeight: isTablet ? 70 : kToolbarHeight,
      ),
      body: StreamBuilder(
        stream: roomRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: CircularProgressIndicator(color: primaryBlue),
            );
          }

          final data = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          _getCurrentLecture(roomId).then((lecture) {
            if (lecture != null) {
              String lectureId = lecture['lectureId'];
              if (currentMonitoringLecture != lectureId) {
                currentMonitoringLecture = lectureId;
                tempHistory.clear();
                brightnessHistory.clear();
              }
              if (data['temperature']?['currentTemp'] != null) {
                tempHistory.add(
                  (data['temperature']?['currentTemp'] as num).toDouble(),
                );
              }
              if (data['lighting']?['brightness'] != null) {
                brightnessHistory.add(
                  (data['lighting']?['brightness'] as num).toInt(),
                );
              }
            }
          });

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 30 : 20,
              vertical: isTablet ? 16 : 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(
                  data['name'] ?? "Unknown",
                  data['status'] ?? "offline",
                  isTablet,
                ),
                SizedBox(height: isTablet ? 30 : 25),
                _buildCurrentLectureCardAuto(data, isTablet),
                SizedBox(height: isTablet ? 36 : 30),
                Text(
                  "SYSTEM MODULES",
                  style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: isTablet ? 16 : 13,
                  ),
                ),
                SizedBox(height: isTablet ? 20 : 15),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: isTablet ? 20 : 15,
                    mainAxisSpacing: isTablet ? 20 : 15,
                    childAspectRatio: isTablet ? 1.45 : 1.2,
                  ),
                  children: [
                    _buildModuleCard(
                      context: context,
                      title: "Lighting",
                      value: data['lighting']?['mode']?.toUpperCase() ?? "-",
                      subValue: "Status: ${data['lighting']?['status']?.toUpperCase() ?? "-"}",
                      icon: Icons.lightbulb_rounded,
                      color: Colors.amber,
                      onTap: () => _showLightingSheet(context),
                      isTablet: isTablet,
                    ),
                    _buildModuleCard(
                      context: context,
                      title: "Climate",
                      value: "${data['temperature']?['currentTemp']}°C",
                      subValue: "Target: ${data['temperature']?['targetTemp']}°C",
                      icon: Icons.device_thermostat_rounded,
                      color: Colors.cyanAccent,
                      onTap: () => _showTemperatureBottomSheet(context),
                      isTablet: isTablet,
                    ),
                    _buildModuleCard(
                      context: context,
                      title: "Smart Chairs",
                      value: data['smartChairs']?['mode']?.toUpperCase() ?? "-",
                      subValue: "${data['smartChairs']?['occupied']} / ${data['smartChairs']?['total']} Seats",
                      icon: Icons.event_seat_rounded,
                      color: Colors.tealAccent,
                      onTap: () => _showSmartChairsSheet(context),
                      isTablet: isTablet,
                    ),
                    _buildModuleCard(
                      context: context,
                      title: "Security",
                      value: data['accessControl']?['doorStatus'] == 'locked' ? "LOCKED" : "OPEN",
                      subValue: "Last: ${data['accessControl']?['lastEntry']?.split(' ')[1] ?? "-"}",
                      icon: data['accessControl']?['doorStatus'] == 'locked'
                          ? Icons.lock_rounded
                          : Icons.lock_open_rounded,
                      color: data['accessControl']?['doorStatus'] == 'locked'
                          ? Colors.redAccent
                          : accentGreen,
                      onTap: () => _showAccessControl(context, data),
                      isTablet: isTablet,
                    ),
                    _buildModuleCard(
                      context: context,
                      title: "Window",
                      value: data['window']?['status'] == 'open' ? "OPEN" : "CLOSED",
                      subValue: data['window']?['status'] == 'open'
                          ? "Ventilating"
                          : "Sealed",
                      icon: data['window']?['status'] == 'open'
                          ? Icons.sensor_window_rounded
                          : Icons.window_rounded,
                      color: data['window']?['status'] == 'open'
                          ? Colors.lightBlueAccent
                          : Colors.blueGrey,
                      onTap: () => _showWindowSheet(
                          context, data['window']?['status'] ?? 'closed'),
                      isTablet: isTablet,
                    ),
                    _buildModuleCard(
                      context: context,
                      title: "Audio",
                      value: "${data['audio']?['volume']}%",
                      subValue: "State: ${data['audio']?['status']}",
                      icon: Icons.surround_sound_rounded,
                      color: Colors.purpleAccent,
                      onTap: () => _showAudioSettings(context, data['audio']),
                      isTablet: isTablet,
                    ),
                  ],
                ),
                const SizedBox(height: 15),
              ],
            ),
          );
        },
      ),
    );
  }

  void _updateStatus(String rId, String path, dynamic newValue) {
    FirebaseDatabase.instance.ref().child('classrooms/$rId/$path').set(newValue);
  }

  Widget _buildHeader(String name, String status, bool isTablet) {
    bool isActive = status == "active";
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 30 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: isTablet ? 11 : 8,
                  height: isTablet ? 11 : 8,
                  decoration: BoxDecoration(
                    color: isActive ? accentGreen : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: isTablet ? 10 : 8),
                Text(
                  isActive ? "System Online" : "System Offline",
                  style: TextStyle(
                    color: isActive ? accentGreen : Colors.red,
                    fontSize: isTablet ? 18 : 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.all(isTablet ? 14 : 10),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.settings_input_component_rounded,
            color: primaryBlue,
            size: isTablet ? 30 : 24,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentLectureCardAuto(Map<String, dynamic> roomFullData, bool isTablet) {
    return FutureBuilder(
      future: _getCurrentLecture(roomId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryBlue));
        }

        final lecture = snapshot.data;

        if (lecture == null) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(isTablet ? 20 : 15),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Icon(Icons.event_busy_rounded,
                    color: Colors.white24, size: isTablet ? 32 : 24),
                SizedBox(width: isTablet ? 20 : 15),
                Text(
                  "No Active Lecture Now",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: isTablet ? 19 : 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        final now = DateTime.now();
        final currentTime =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
        final String lectureId = lecture['lectureId'] ?? "";

        if (currentTime == lecture['endTime'] && lastReportedLectureId != lectureId) {
          lastReportedLectureId = lectureId;
          _generateLectureReport(roomId, roomFullData, lecture);
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentAttendanceScreen(
                  lectureId: lecture['lectureId'] ?? "L001",
                  lectureName: "Current Attendance",
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isTablet ? 26 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue.withOpacity(0.2), cardColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryBlue.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CURRENT LECTURE",
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: isTablet ? 14 : 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      SizedBox(height: isTablet ? 14 : 10),
                      FutureBuilder(
                        future: Future.wait([
                          FirebaseDatabase.instance
                              .ref()
                              .child('courses/${lecture['courseId']}/name')
                              .get(),
                          FirebaseDatabase.instance
                              .ref()
                              .child('doctors/${lecture['doctorId']}/name')
                              .get(),
                        ]),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return Text("Loading...",
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: isTablet ? 16 : 14));
                          }
                          final courseName = snap.data![0].value.toString();
                          final doctorName = snap.data![1].value.toString();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(courseName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isTablet ? 22 : 18,
                                    fontWeight: FontWeight.bold,
                                  )),
                              SizedBox(height: isTablet ? 6 : 4),
                              Text("Dr. $doctorName",
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: isTablet ? 17 : 14,
                                  )),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: isTablet ? 16 : 12),
                      Row(
                        children: [
                          Icon(Icons.access_time_filled_rounded,
                              color: accentGreen, size: isTablet ? 20 : 16),
                          SizedBox(width: isTablet ? 8 : 6),
                          Text(
                            "${lecture['startTime']} - ${lecture['endTime']}",
                            style: TextStyle(
                              color: accentGreen,
                              fontSize: isTablet ? 16 : 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(isTablet ? 12 : 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      color: primaryBlue, size: isTablet ? 22 : 18),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subValue,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
            color: cardColor, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 11 : 8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: isTablet ? 32 : 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 22 : 18,
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(height: isTablet ? 4 : 2),
                Text(title,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: isTablet ? 16 : 13,
                    )),
                Text(subValue,
                    style: TextStyle(
                      color: color.withOpacity(0.7),
                      fontSize: isTablet ? 14 : 11,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSmartChairsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10)),
              ),
              const Text(
                "Smart Chairs Mode",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildModeTile("Lecture Mode", Icons.school_rounded, "lecture"),
              _buildModeTile(
                  "Exam Mode", Icons.assignment_turned_in_rounded, "exam"),
              _buildModeTile(
                  "Groups / Pair Mode", Icons.groups_rounded, "group"),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeTile(String title, IconData icon, String modeValue) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance
          .ref()
          .child('classrooms/$roomId/smartChairs/mode')
          .onValue,
      builder: (context, snapshot) {
        final currentMode =
            snapshot.hasData ? snapshot.data!.snapshot.value?.toString() : null;
        final isActive = currentMode == modeValue;

        return GestureDetector(
          onTap: () {
            FirebaseDatabase.instance
                .ref()
                .child('classrooms/$roomId/smartChairs/mode')
                .set(modeValue);
            Navigator.pop(context);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isActive ? primaryBlue.withOpacity(0.15) : bgColor,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: isActive ? primaryBlue : Colors.white10),
            ),
            child: Row(
              children: [
                Icon(icon,
                    color: isActive ? primaryBlue : Colors.white54, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                if (isActive)
                  const Icon(Icons.check_circle_rounded,
                      color: primaryBlue, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLightingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StreamBuilder(
          stream: FirebaseDatabase.instance
              .ref()
              .child('classrooms/$roomId/lighting/mode')
              .onValue,
          builder: (context, modeSnapshot) {
            final currentMode =
                modeSnapshot.data?.snapshot.value?.toString() ?? '';

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  const Text(
                    "Lighting Control",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildBrightnessInfo(),
                  _buildLightingModeTile(
                      "Auto Mode", Icons.auto_awesome_rounded, "auto"),
                  _buildLightingModeTile(
                      "Projector Mode", Icons.slideshow_rounded, "projector"),
                  _buildLightingModeTile(
                      "Manual Mode", Icons.tune_rounded, "manual"),
                  const SizedBox(height: 10),
                  // ✅ استخدام الـ Widget المنفصل بدل StatefulBuilder
                  if (currentMode == 'projector')
                    _ProjectorBrightnessSlider(roomId: roomId),
                  _buildManualSwitch(),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLightingModeTile(String title, IconData icon, String modeValue) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance
          .ref()
          .child('classrooms/$roomId/lighting/mode')
          .onValue,
      builder: (context, snapshot) {
        final currentMode = snapshot.data?.snapshot.value?.toString();
        final isActive = currentMode == modeValue;

        return GestureDetector(
          onTap: () {
            FirebaseDatabase.instance
                .ref()
                .child('classrooms/$roomId/lightingCommand')
                .set({"mode": modeValue});
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isActive ? Colors.amber.withOpacity(0.15) : bgColor,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: isActive ? Colors.amber : Colors.white10),
            ),
            child: Row(
              children: [
                Icon(icon,
                    color: isActive ? Colors.amber : Colors.white54, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                if (isActive)
                  const Icon(Icons.check_circle_rounded, color: Colors.amber),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildManualSwitch() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance
          .ref()
          .child('classrooms/$roomId/lighting')
          .onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null)
          return const SizedBox();

        final lighting = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map);

        if (lighting['mode'] != 'manual') return const SizedBox();

        final isOn = lighting['status'] == 'on';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Icon(isOn ? Icons.lightbulb : Icons.lightbulb_outline,
                  color: isOn ? Colors.amber : Colors.white54),
              const SizedBox(width: 14),
              const Expanded(
                  child: Text("Light Power",
                      style: TextStyle(color: Colors.white))),
              Switch(
                value: isOn,
                activeColor: Colors.amber,
                onChanged: (value) {
                  FirebaseDatabase.instance
                      .ref()
                      .child('classrooms/$roomId/lightingCommand')
                      .set({"status": value ? 'on' : 'off'});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrightnessInfo() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance
          .ref()
          .child('classrooms/$roomId/lighting')
          .onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null)
          return const SizedBox();

        final lighting = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map);
        final brightness = lighting['brightness'] ?? 0;

        return Container(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text("Brightness Level:  ",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500)),
                    SizedBox(height: 2),
                  ],
                ),
              ),
              Text("$brightness%",
                  style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  void _showTemperatureBottomSheet(BuildContext context) {
    final tempRef =
        FirebaseDatabase.instance.ref().child('classrooms/$roomId/temperature');

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (_) {
        return StreamBuilder(
          stream: tempRef.onValue,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                      child: CircularProgressIndicator(color: primaryBlue)));
            }

            final data = Map<String, dynamic>.from(
                snapshot.data!.snapshot.value as Map);
            final mode = data['mode'] ?? 'auto';
            final fanStatus = data['fanStatus'] ?? 'off';
            final fanLevel = data['fanLevel'] ?? 0;

            return Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Climate Control",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 25),
                  GestureDetector(
                    onTap: () {
                      final newMode = mode == 'auto' ? 'manual' : 'auto';
                      FirebaseDatabase.instance
                          .ref()
                          .child('classrooms/$roomId/temperatureCommand')
                          .set({"mode": newMode});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(15)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: const [
                            Icon(Icons.settings_rounded,
                                color: Colors.orangeAccent),
                            SizedBox(width: 12),
                            Text("Mode",
                                style: TextStyle(color: Colors.white)),
                          ]),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: mode == 'manual'
                                  ? primaryBlue
                                  : Colors.white12,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              mode.toUpperCase(),
                              style: TextStyle(
                                  color: mode == 'manual'
                                      ? bgColor
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(15)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: const [
                          Icon(Icons.air_rounded, color: Colors.cyanAccent),
                          SizedBox(width: 12),
                          Text("Fan Status",
                              style: TextStyle(color: Colors.white)),
                        ]),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: fanStatus == 'on'
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(fanStatus.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 17),
                  const Text("Fan Control (Manual)",
                      style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Fan Speed Level: $fanLevel",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            final isActive = fanLevel == index;
                            final isManual = mode == 'manual';

                            return GestureDetector(
                              onTap: isManual
                                  ? () {
                                      FirebaseDatabase.instance
                                          .ref()
                                          .child(
                                              'classrooms/$roomId/temperatureCommand')
                                          .set({
                                        "fanSpeed": index,
                                        "fanOff": index == 0,
                                      });
                                    }
                                  : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? primaryBlue
                                      : isManual
                                          ? Colors.white12
                                          : Colors.white10,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    index.toString(),
                                    style: TextStyle(
                                      color: isManual
                                          ? (isActive ? bgColor : Colors.white)
                                          : Colors.white38,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAccessControl(BuildContext context, Map data) {
    final doorStatus = data['accessControl']?['doorStatus'] ?? 'locked';
    final lastEntry = data['accessControl']?['lastEntry'] ?? 'No Entry';

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Door Status",
                      style:
                          TextStyle(fontSize: 16, color: Colors.white70)),
                  Switch(
                    value: doorStatus == "remote_open",
                    activeColor: primaryBlue,
                    onChanged: (value) {
                      _updateStatus(roomId, 'accessControl/doorStatus',
                          value ? "remote_open" : "locked");
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(15)),
                child: Row(
                  children: [
                    const Icon(Icons.login, color: primaryBlue),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text("Last Entry: $lastEntry",
                            style:
                                const TextStyle(color: Colors.white))),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    minimumSize: const Size(double.infinity, 50)),
                onPressed: () {
                  Navigator.pop(context);
                  _showAccessLogs(context);
                },
                child: const Text("VIEW ACCESS LOGS",
                    style: TextStyle(
                        color: bgColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAccessLogs(BuildContext context) {
    final logsRef =
        FirebaseDatabase.instance.ref().child('accessLogs/$roomId');

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: StreamBuilder(
            stream: logsRef.onValue,
            builder: (context, snapshot) {
              if (!snapshot.hasData ||
                  snapshot.data!.snapshot.value == null) {
                return const Center(
                    child: Text("No Logs",
                        style: TextStyle(color: Colors.white)));
              }

              final logs = Map<String, dynamic>.from(
                  snapshot.data!.snapshot.value as Map);
              final list = logs.entries.toList();

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final log =
                      Map<String, dynamic>.from(list[index].value);
                  final userId = log['userId'].toString();
                  final time = log['time'];
                  final method = log['method'] ?? "Unknown";

                  return FutureBuilder(
                    future: Future.wait([
                      FirebaseDatabase.instance
                          .ref()
                          .child('students/$userId')
                          .get(),
                      FirebaseDatabase.instance
                          .ref()
                          .child('doctors/$userId')
                          .get(),
                    ]),
                    builder: (context,
                        AsyncSnapshot<List<DataSnapshot>> snap) {
                      if (!snap.hasData)
                        return const ListTile(
                            title: Text("Loading...",
                                style: TextStyle(color: Colors.white)));

                      String name = "Unknown";
                      String role = "";

                      if (snap.data![0].value != null) {
                        final student = Map<String, dynamic>.from(
                            snap.data![0].value as Map);
                        name = student['name'];
                        role = "Student";
                      } else if (snap.data![1].value != null) {
                        final doctor = Map<String, dynamic>.from(
                            snap.data![1].value as Map);
                        name = doctor['name'];
                        role = "Doctor";
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(15)),
                        child: Row(
                          children: [
                            const Icon(Icons.person,
                                color: primaryBlue, size: 26),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                  const SizedBox(height: 3),
                                  Text("ID: $userId • $role",
                                      style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Text("Method: $method",
                                      style: const TextStyle(
                                          color: primaryBlue,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                            Text(time,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showWindowSheet(BuildContext context, String currentStatus) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10)),
              ),
              const Text(
                "Window Control",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildWindowOptionTile(
                context: context,
                title: "Open",
                icon: Icons.sensor_window_rounded,
                value: "open",
                currentStatus: currentStatus,
                activeColor: Colors.lightBlueAccent,
              ),
              _buildWindowOptionTile(
                context: context,
                title: "Closed",
                icon: Icons.window_rounded,
                value: "closed",
                currentStatus: currentStatus,
                activeColor: Colors.lightBlueAccent,
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWindowOptionTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String value,
    required String currentStatus,
    required Color activeColor,
  }) {
    final isActive = currentStatus == value;

    return GestureDetector(
      onTap: () {
        FirebaseDatabase.instance
            .ref()
            .child('classrooms/$roomId/window/status')
            .set(value);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.15) : bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? activeColor : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? activeColor : Colors.white54, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white70,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            if (isActive)
              Icon(Icons.check_circle_rounded, color: activeColor, size: 20),
          ],
        ),
      ),
    );
  }

  void _showAudioSettings(BuildContext context, Map? audioData) {
    final audioRef =
        FirebaseDatabase.instance.ref().child('classrooms/$roomId/audio');

    int volume = audioData?['volume'] ?? 50;
    String status = audioData?['status'] ?? "stopped";
    String announcement = audioData?['announcement'] ?? "";
    TextEditingController controller =
        TextEditingController(text: announcement);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Audio Control",
                      style:
                          TextStyle(color: Colors.white, fontSize: 20)),
                  const SizedBox(height: 20),
                  Slider(
                    value: volume.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: "$volume%",
                    onChanged: (value) {
                      setState(() {
                        volume = value.toInt();
                      });
                      audioRef.update({'volume': volume});
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Audio Status",
                          style: TextStyle(color: Colors.white)),
                      Switch(
                        value: status == "playing",
                        onChanged: (value) {
                          setState(() {
                            status = value ? "playing" : "stopped";
                          });
                          audioRef.update({'status': status});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Enter announcement",
                      hintStyle: TextStyle(color: Colors.white38),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      audioRef.update({
                        'announcement': controller.text,
                        'status': "playing"
                      });
                      Navigator.pop(context);
                    },
                    child: const Text("SEND"),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _generateLectureReport(String roomId,
      Map<String, dynamic> roomData, Map<String, dynamic> lecture) async {
    final String lectureId = lecture['lectureId'];
    final now = DateTime.now();
    final String formattedDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final String formattedTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    double avgTemp = tempHistory.isNotEmpty
        ? tempHistory.reduce((a, b) => a + b) / tempHistory.length
        : (roomData['temperature']?['currentTemp']?.toDouble() ?? 0.0);

    double avgBrightness = brightnessHistory.isNotEmpty
        ? brightnessHistory.reduce((a, b) => a + b) / brightnessHistory.length
        : (roomData['lighting']?['brightness']?.toDouble() ?? 0.0);

    final attendanceSnap = await FirebaseDatabase.instance
        .ref()
        .child('attendance/$lectureId')
        .get();
    final attendanceMap = attendanceSnap.exists
        ? Map<String, dynamic>.from(attendanceSnap.value as Map)
        : {};

    final reportData = {
      "lectureInfo": {
        "lectureId": lectureId,
        "courseId": lecture['courseId'],
        "day": _getDayName(now.weekday),
        "date": formattedDate,
        "timeSlot": "${lecture['startTime']} - ${lecture['endTime']}",
      },
      "environmentStats": {
        "temperature": {
          "average": avgTemp.toStringAsFixed(1),
          "final": roomData['temperature']?['currentTemp'],
          "history": tempHistory,
        },
        "lighting": {
          "averageBrightness": avgBrightness.toStringAsFixed(1),
          "finalMode": roomData['lighting']?['mode'],
          "history": brightnessHistory,
        },
      },
      "attendance": {"present": attendanceMap.length, "log": attendanceMap},
      "generatedAt": "$formattedDate $formattedTime",
    };

    await FirebaseDatabase.instance
        .ref()
        .child('lectureReports/$roomId/$lectureId/$formattedDate')
        .set(reportData);

    tempHistory.clear();
    brightnessHistory.clear();
  }
}

// ✅ Widget منفصل للـ Brightness Slider - هاد هو التعديل الأساسي
// السبب: StatefulBuilder داخل StreamBuilder كان بيعمل reset للقيمة
// كل مرة بتيجي بيانات جديدة من Firebase، هون بنحفظ الحالة بـ initState بس مرة وحدة
class _ProjectorBrightnessSlider extends StatefulWidget {
  final String roomId;

  const _ProjectorBrightnessSlider({required this.roomId});

  @override
  State<_ProjectorBrightnessSlider> createState() =>
      _ProjectorBrightnessSliderState();
}

class _ProjectorBrightnessSliderState
    extends State<_ProjectorBrightnessSlider> {
  double? _localBrightness;
  bool _isDragging = false;

  static const Color bgColor = Color(0xFF0E1325);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance
          .ref()
          .child('classrooms/${widget.roomId}/lighting/projector_brightness') // ← هون
          .onValue,
      builder: (context, snapshot) {
        final firebaseBrightness =
            (snapshot.data?.snapshot.value as num?)?.toDouble() ?? 50.0;

        // ✅ نحدث القيمة المحلية بس لما المستخدم مش شايل إصبعه على السلايدر
        if (!_isDragging) {
          _localBrightness = firebaseBrightness;
        }

        final displayValue = _localBrightness ?? firebaseBrightness;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.slideshow_rounded,
                      color: Colors.amber, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    "Projector Brightness",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    "${displayValue.toInt()}%",
                    style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ],
              ),
              Slider(
                value: displayValue,
                min: 0,
                max: 100,
                divisions: 20,
                activeColor: Colors.amber,
                inactiveColor: Colors.amber.withOpacity(0.2),
                label: "${displayValue.toInt()}%",
                onChangeStart: (_) {
                  // ✅ المستخدم بدأ يحرك السلايدر
                  setState(() => _isDragging = true);
                },
                onChanged: (value) {
                  // ✅ بنحدث القيمة محلياً بس بدون Firebase
                  setState(() => _localBrightness = value);
                },
                onChangeEnd: (value) {
                  // ✅ لما خلص التحريك نرسل لـ Firebase ونوقف الـ lock
                  setState(() => _isDragging = false);
                  FirebaseDatabase.instance
                      .ref()
                      .child(
                          'classrooms/${widget.roomId}/lightingCommand')
                       .set({"projector_brightness": value.toInt()}); // ← هون التغيير
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Helper Functions ──────────────────────────────────────────────────────

Future<Map<String, dynamic>?> _getCurrentLecture(String roomId) async {
  final now = DateTime.now();
  final today = _getDayName(now.weekday);
  final currentTime =
      "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

  final snapshot =
      await FirebaseDatabase.instance.ref().child('lectures').get();
  if (!snapshot.exists) return null;

  final lectures = Map<String, dynamic>.from(snapshot.value as Map);

  for (var entry in lectures.entries) {
    final lecture = Map<String, dynamic>.from(entry.value);
    if (lecture['roomId'] != roomId) continue;
    if (!(lecture['days'] as List).contains(today)) continue;
    if (currentTime.compareTo(lecture['startTime']) >= 0 &&
        currentTime.compareTo(lecture['endTime']) <= 0) {
      lecture['lectureId'] = entry.key;
      return lecture;
    }
  }
  return null;
}

String _getDayName(int weekday) {
  switch (weekday) {
    case 7:
      return "Sunday";
    case 1:
      return "Monday";
    case 2:
      return "Tuesday";
    case 3:
      return "Wednesday";
    case 4:
      return "Thursday";
    case 5:
      return "Friday";
    case 6:
      return "Saturday";
    default:
      return "";
  }
}