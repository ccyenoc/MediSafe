import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}


class _SchedulePageState extends State<SchedulePage> {
  DateTime selectedDate = DateTime.now();
  DateTime? repeatUntil;   // ✅ HERE

  final NotificationService notificationService = NotificationService();

  @override
void initState() {
  super.initState();
  notificationService.init();
}

  Stream<QuerySnapshot> _getSchedulesForSelectedDate() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return const Stream.empty();
  }

  final startOfDay = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
  );

  final endOfDay = startOfDay.add(const Duration(days: 1));

  return FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .collection('schedules')
    .where('isActive', isEqualTo: true)
    .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
    .where('time', isLessThan: Timestamp.fromDate(endOfDay))
    .orderBy('time')
    .snapshots();
}

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(context),
      bottomNavigationBar: const MedicalBottomNav(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ✅ ADD BUTTON ABOVE CALENDAR (since chatbot bottom right)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF1E3F8F),
    foregroundColor: Colors.white, // 👈 makes text + icon white
  ),
  onPressed: () {
    _showAddScheduleDialog();
  },
  icon: const Icon(Icons.add),
  label: const Text("Add Schedule"),
),
              ),
            ),

            const SizedBox(height: 12),


            const SizedBox(height: 16),
            _weekSelector(context),
            const SizedBox(height: 24),

           StreamBuilder<QuerySnapshot>(
  stream: _getSchedulesForSelectedDate(),
  builder: (context, snapshot) {

    // 🔄 LOADING STATE
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // ❌ ERROR STATE
    if (snapshot.hasError) {
      return Center(
        child: Text("Error: ${snapshot.error}"),
      );
    }

    // 📭 EMPTY STATE
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Column(
        children: [
          _scheduleSectionFromData("Morning", [], Colors.lightBlue.shade50),
          _scheduleSectionFromData("Afternoon / Evening", [], Colors.yellow.shade50),
          _scheduleSectionFromData("Night", [], Colors.grey.shade200),
        ],
      );
    }

    final docs = snapshot.data!.docs;

    List<QueryDocumentSnapshot> morning = [];
    List<QueryDocumentSnapshot> afternoon = [];
    List<QueryDocumentSnapshot> night = [];

    for (var doc in docs) {
      final timestamp = doc['time'] as Timestamp;
      final dateTime = timestamp.toDate();
      final hour = dateTime.hour;

      if (hour < 12) {
        morning.add(doc);
      } else if (hour < 18) {
        afternoon.add(doc);
      } else {
        night.add(doc);
      }
    }

    return Column(
      children: [
        _scheduleSectionFromData("Morning", morning, Colors.lightBlue.shade50),
        _scheduleSectionFromData("Afternoon / Evening", afternoon, Colors.yellow.shade50),
        _scheduleSectionFromData("Night", night, Colors.grey.shade200),
      ],
    );
  },
),


            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // 🔵 APP BAR
  PreferredSizeWidget _appBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF1E3F8F),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        color: Colors.white,
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
  "Schedule",
  style: TextStyle(
    fontSize: 22,
    color: Colors.white, // 👈 white title
    fontWeight: FontWeight.w600,
  ),
),
centerTitle: false, // 👈 left aligned
    );
  }

  // 📅 WEEK SELECTOR (CLICKABLE + CALENDAR)
  Widget _weekSelector(BuildContext context) {
  // ✅ Always calculate Monday of selected week
  final startOfWeek =
      selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

  // ✅ Generate full 7-day week (Mon → Sun)
  final weekDates = List.generate(
    7,
    (index) => startOfWeek.add(Duration(days: index)),
  );

  final weekNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFF1E3F8F)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final date = weekDates[index];
              final isSelected = _isSameDay(date, selectedDate);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = date;
                  });
                },
                child: Column(
                  children: [
                    Text(
                      weekNames[index],
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF3D6DF2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        date.day.toString(),
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),

        // 📆 Calendar button
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate:
                  DateTime.now().subtract(const Duration(days: 365)),
              lastDate:
                  DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Colors.red,
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                    ),
                    dialogBackgroundColor: Colors.white,
                  ),
                  child: child!,
                );
              },
            );

            if (picked != null) {
              setState(() {
                selectedDate = picked; // ✅ This auto recalculates week
              });
            }
          },
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Colors.red,
              size: 20,
            ),
          ),
        ),
      ],
    ),
  );
}

  // 💊 SCHEDULE SECTION
  Widget _scheduleSection({
    required String title,
    required String time,
    required String note,
    required Color pillColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),

          Container(
  height: 150, // 👈 this limits the card height
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: const Color(0xFF1E3F8F)),
  ),
  child: SingleChildScrollView(
    padding: const EdgeInsets.all(12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // 👇 add more pills later → scroll activates automatically
              _pill(pillColor),
              const SizedBox(height: 8),
              _pill(pillColor),
            ],
          ),
        ),

        // VERTICAL LINE
        Container(
          width: 1,
          height: 120,
          color: const Color(0xFF1E3F8F),
          margin: const EdgeInsets.symmetric(horizontal: 12),
        ),

        // NOTES
        Container(
          width: 110,
          height: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: pillColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF1E3F8F)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Notes",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                note,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    ),
  ),
),

        ],
      ),
    );
  }

  // 🧩 PILL
  Widget _pill(Color color) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E3F8F)),
      ),
    );
  }

  // 🔧 DATE COMPARE
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showAddScheduleDialog() {
  final TextEditingController medicineController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  DateTime selectedDialogDate = selectedDate;
  int hour = 8;
  int minute = 0;
  String period = "AM";
  bool isRecurring = false;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      String? errorMessage;
      return StatefulBuilder(
      
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF1E3F8F)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back),
                    ),

                    const SizedBox(height: 10),

                    const Text("Select Date"),
                    const SizedBox(height: 8),

                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDialogDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Colors.red,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                                dialogBackgroundColor: Colors.white,
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (picked != null) {
                          setDialogState(() {
                            selectedDialogDate = picked;
                          });
                        }
                      },
                      child: Container(
                        height: 45,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF1E3F8F)),
                        ),
                        child: Text(
                          "${selectedDialogDate.day}/${selectedDialogDate.month}/${selectedDialogDate.year}",
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text("Scheduled Time"),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        _timeBox(
                          value: hour.toString().padLeft(2, '0'),
                          onTap: () async {
                            final picked = await showTimePicker(
  context: context,
  initialTime: TimeOfDay(hour: hour, minute: minute),
  builder: (context, child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: Colors.red,          // top header color
          onPrimary: Colors.white,      // text on header
          surface: Colors.white,        // dialog background
          onSurface: Colors.black,      // clock text
        ),
        timePickerTheme: const TimePickerThemeData(
          backgroundColor: Colors.white,
          hourMinuteTextColor: Colors.black,
          dayPeriodTextColor: Colors.red,
        ),
      ),
      child: child!,
    );
  },
);


                            if (picked != null) {
                              setDialogState(() {
                                hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
                                minute = picked.minute;
                                period = picked.period == DayPeriod.am ? "AM" : "PM";
                              });
                            }
                          },
                        ),

                        const Text(":"),

                        _timeBox(
                          value: minute.toString().padLeft(2, '0'),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(hour: hour, minute: minute),
                            );

                            if (picked != null) {
                              setDialogState(() {
                                hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
                                minute = picked.minute;
                                period = picked.period == DayPeriod.am ? "AM" : "PM";
                              });
                            }
                          },
                        ),

                        _timeBox(
                          value: period,
                          onTap: () {
                            setDialogState(() {
                              period = period == "AM" ? "PM" : "AM";
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const Text("Medicine"),


                    Container(
                      height: 45,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF1E3F8F)),
                      ),
                      child: TextField(
  controller: medicineController,
  onChanged: (value) {
    if (errorMessage != null) {
      setDialogState(() {
        errorMessage = null;
      });
    }
  },
  decoration: const InputDecoration(
    border: InputBorder.none,
    hintText: "Type medicine name",
    isCollapsed: true,
  ),
),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            _showScanHistoryBottomSheet(setDialogState, medicineController);
                          },
                          child: const Text("Scan History"),
                        ),
                    
                      ],
                    ),

                     const SizedBox(height: 8),

const Text("Notes"),
const SizedBox(height: 8),

Container(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFF1E3F8F)),
  ),
  child: TextField(
    controller: noteController,
    maxLines: 3,
    decoration: const InputDecoration(
      border: InputBorder.none,
      hintText: "Add note (e.g. After meal)",
    ),
  ),
),


                    Row(
  children: [
    Checkbox(
      value: isRecurring,
      onChanged: (value) {
        setDialogState(() {
          isRecurring = value ?? false;

          if (!isRecurring) {
            repeatUntil = null;
          }
        });
      },
    ),
    const Text("Repeat Daily"),
  ],
),



// 👇 SHOW DEADLINE ONLY IF RECURRING
if (isRecurring) ...[
  const SizedBox(height: 10),

  const Text("Repeat Until"),
  const SizedBox(height: 6),
  

  GestureDetector(
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDialogDate,
        firstDate: selectedDialogDate,
        lastDate: selectedDialogDate.add(const Duration(days: 365)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.red,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setDialogState(() {
          repeatUntil = picked;
        });
      }
    },
    child: Container(
      height: 45,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E3F8F)),
      ),
      child: Text(
        repeatUntil == null
            ? "Select end date"
            : "${repeatUntil!.day}/${repeatUntil!.month}/${repeatUntil!.year}",
      ),
    ),
  ),
],

if (errorMessage != null) ...[
  const SizedBox(height: 12),
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.red.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      errorMessage!,
      style: const TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    ),
  ),
],


                    const SizedBox(height: 20),

                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3F8F),
                          foregroundColor: Colors.white,
                        ),

                        
                        onPressed: () async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  setDialogState(() {
  errorMessage = null;
});

  // ✅ VALIDATION
  if (medicineController.text.trim().isEmpty) {
  setDialogState(() {
    errorMessage = "Please enter medicine name";
  });
  return;
}

if (isRecurring && repeatUntil == null) {
  setDialogState(() {
    errorMessage = "Please select repeat end date";
  });
  return;
}


  if (selectedDialogDate == null) {
    ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text("Please select a date."),
    backgroundColor: Colors.red,
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.only(
      top: 100,
      left: 20,
      right: 20,
    ),
    duration: Duration(seconds: 2),
  ),
);
    return;
  }

  // Time is always selected because you default hour=8 minute=0
  // so no need to validate unless you remove defaults.

  int finalHour = hour;
  if (period == "PM" && hour != 12) finalHour += 12;
  if (period == "AM" && hour == 12) finalHour = 0;

  final firstScheduleDate = DateTime(
    selectedDialogDate.year,
    selectedDialogDate.month,
    selectedDialogDate.day,
    finalHour,
    minute,
  );

  if (firstScheduleDate.isBefore(DateTime.now())) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Scheduled time must be in the future."),
      backgroundColor: Colors.red,
    ),
  );
  return;
}

  final schedulesRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('schedules');

  // 🔵 NON-RECURRING
  if (!isRecurring) {
    final docRef = await schedulesRef.add({
      'medicineName': medicineController.text.trim(),
      'time': Timestamp.fromDate(firstScheduleDate),
      'notes': noteController.text.trim(),
      'isActive': true,
      'isTaken': false,
      'isRecurring': false,
      'repeatUntil': null,
    });

    await notificationService.scheduleNotification(
  id: docRef.id.hashCode,
  title: "Medication Reminder 💊",
  body: medicineController.text.trim(),
  scheduledDate: firstScheduleDate,
);
  }

  // 🔵 RECURRING DAILY
  else {
    if (repeatUntil == null) {
      ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text("Please select repeat end date."),
    backgroundColor: Colors.red,
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.only(
      top: 100,
      left: 20,
      right: 20,
    ),
    duration: Duration(seconds: 2),
  ),
);
      return;
    }

    DateTime currentDate = firstScheduleDate;

    while (!currentDate.isAfter(repeatUntil!)) {
      final docRef = await schedulesRef.add({
        'medicineName': medicineController.text.trim(),
        'time': Timestamp.fromDate(currentDate),
        'notes': noteController.text.trim(),
        'isActive': true,
        'isTaken': false,
        'isRecurring': true,
        'repeatUntil': Timestamp.fromDate(repeatUntil!),
      });

      await notificationService.scheduleNotification(
  id: docRef.id.hashCode,
  title: "Medication Reminder 💊",
  body: medicineController.text.trim(),
  scheduledDate: currentDate,
);

    

      currentDate = currentDate.add(const Duration(days: 1));
    }
  }

  Navigator.pop(context);

  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text("Schedule added successfully!"),
    backgroundColor: Colors.green,
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.only(
      top: 100,
      left: 20,
      right: 20,
    ),
    duration: Duration(seconds: 2),
  ),
);
},


                        child: const Text("Submit"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}


Widget _timeBox({
  required String value,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 60,
      height: 45,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E3F8F)),
      ),
      child: Text(
        value,
        style: const TextStyle(fontSize: 16),
      ),
    ),
  );
}
  void _showScanHistoryBottomSheet(
    StateSetter setDialogState,
    TextEditingController controller,
) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  showModalBottomSheet(
    context: context,
    builder: (context) {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('scan_history')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No Scan History"));
          }

          return ListView(
            children: docs.map((doc) {
              return ListTile(
                title: Text(doc['medicineName']),
                onTap: () {
                  controller.text = doc['medicineName'];
                  Navigator.pop(context);
                },
              );
            }).toList(),
          );
        },
      );
    },
  );
}

Future<void> _deactivateExpiredSchedules() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final now = DateTime.now();

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('schedules')
      .where('isActive', isEqualTo: true)
      .get();

  for (var doc in snapshot.docs) {
    final repeatUntilTimestamp = doc.data()['repeatUntil'];

    if (repeatUntilTimestamp != null) {
      final repeatUntilDate = (repeatUntilTimestamp as Timestamp).toDate();

      if (now.isAfter(repeatUntilDate)) {
        await doc.reference.update({
          'isActive': false,
        });
      }
    }
  }
}


}

Widget _scheduleSectionFromData(
  String title,
  List<QueryDocumentSnapshot> schedules,
  Color pillColor,
) {
  if (schedules.isEmpty) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF1E3F8F)),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// LEFT SIDE
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "-",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: Text(
                            "No Schedule",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// VERTICAL DIVIDER
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: Colors.grey.shade400,
                  ),

                  /// NOTES BOX
                  Container(
                    width: 110,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: pillColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF1E3F8F),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          "Notes",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "-",
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


  /// 🔵 GROUP BY TIME
  Map<String, List<QueryDocumentSnapshot>> grouped = {};

  for (var doc in schedules) {
    final timestamp = doc['time'] as Timestamp;
    final dateTime = timestamp.toDate();

    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour == 0
            ? 12
            : dateTime.hour;

    final minute =
        dateTime.minute.toString().padLeft(2, '0');

    final period =
        dateTime.hour >= 12 ? "PM" : "AM";

    final timeKey = "$hour.$minute $period";

    grouped.putIfAbsent(timeKey, () => []);
    grouped[timeKey]!.add(doc);
  }
  

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 12),

        /// 🔵 SCROLLABLE AREA
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF1E3F8F)),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: grouped.entries.map((entry) {
  final time = entry.key;
  final docs = entry.value;

  // ✅ FIX: compute combinedNotes here
  final combinedNotes = docs
      .map((d) => (d.data() as Map<String, dynamic>)['notes'] ?? '')
      .map((note) => note.toString().trim())
      .where((note) => note.isNotEmpty)
      .join('\n');

  return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          /// LEFT SIDE
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  time,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                ...docs.map((doc) {
                                  return Container(
                                    height: 32,
                                    margin:
                                        const EdgeInsets.only(bottom: 8),
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 16),
                                    alignment: Alignment.centerLeft,
                                    decoration: BoxDecoration(
                                      color: pillColor.withOpacity(0.4),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            const Color(0xFF1E3F8F),
                                      ),
                                    ),
                                    child: Text(
                                      doc['medicineName'],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),

                          /// 🔵 VERTICAL DIVIDER
                          Container(
                            width: 1,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 12),
                            color: Colors.grey.shade400,
                          ),

                          /// 🔵 NOTES (MATCH HEIGHT)
                          Container(
                            width: 110,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  pillColor.withOpacity(0.3),
                              borderRadius:
                                  BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFF1E3F8F)),
                            ),
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.start,
                              children: [
                                const Text(
                                  "Notes",
                                  style: TextStyle(
                                      fontWeight:
                                          FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                
Text(
  combinedNotes.isEmpty ? "No notes" : combinedNotes,
  textAlign: TextAlign.center,
),

                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// 🔵 GREY LINE BETWEEN TIMES
                  if (entry.key != grouped.keys.last)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade300,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}


Widget _medicinePill(String name, Color color) {
  return Container(
    height: 36,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    alignment: Alignment.centerLeft,
    decoration: BoxDecoration(
      color: color.withOpacity(0.4),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF1E3F8F)),
    ),
    child: Text(name),
  );
}
