import 'package:flutter/material.dart';
import '../colors/gradient.dart';
import '../widgets/bottom_nav.dart';

class MedicineInfoPage extends StatelessWidget {
  const MedicineInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const MedicalBottomNav(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(context),
            const SizedBox(height: 70),
            _titleSection(),
            const SizedBox(height: 16),
            _addScheduleButton(context),
            const SizedBox(height: 24),
            _functionSection(),
            _sideEffectDosage(),
            const SizedBox(height: 16),
            _recipientSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _addScheduleButton(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3F8F),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () {
          _showAddScheduleDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text("Add To Schedule"),
      ),
    ),
  );
}

void _showAddScheduleDialog(BuildContext context) {
  final TextEditingController medicineController =
      TextEditingController(text: "Panadol"); // 🔥 Auto-filled

  DateTime selectedDate = DateTime.now();
  int hour = 8;
  int minute = 0;
  String period = "AM";

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Add Schedule",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text("Select Date"),
                    const SizedBox(height: 8),

                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365)),
                        );

                        if (picked != null) {
                          setStateDialog(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        height: 45,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFF1E3F8F)),
                        ),
                        child: Text(
                          "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text("Time"),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [

                        _timeBox(
                          value: hour.toString().padLeft(2, '0'),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                  hour: hour, minute: minute),
                            );

                            if (picked != null) {
                              setStateDialog(() {
                                hour = picked.hourOfPeriod == 0
                                    ? 12
                                    : picked.hourOfPeriod;
                                minute = picked.minute;
                                period = picked.period ==
                                        DayPeriod.am
                                    ? "AM"
                                    : "PM";
                              });
                            }
                          },
                        ),

                        const Text(":"),

                        _timeBox(
                          value:
                              minute.toString().padLeft(2, '0'),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                  hour: hour, minute: minute),
                            );

                            if (picked != null) {
                              setStateDialog(() {
                                hour = picked.hourOfPeriod == 0
                                    ? 12
                                    : picked.hourOfPeriod;
                                minute = picked.minute;
                                period = picked.period ==
                                        DayPeriod.am
                                    ? "AM"
                                    : "PM";
                              });
                            }
                          },
                        ),

                        _timeBox(
                          value: period,
                          onTap: () {
                            setStateDialog(() {
                              period =
                                  period == "AM" ? "PM" : "AM";
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const Text("Medicine"),
                    const SizedBox(height: 8),

                    Container(
                      height: 45,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF1E3F8F)),
                      ),
                      child: TextField(
                        controller: medicineController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF1E3F8F),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          // 🔥 You can connect this to Firestore later
                          Navigator.pop(context);
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


  // 🔵 Header
  Widget _header(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 220,
          decoration: const BoxDecoration(
            gradient: AppGradients.blueGradient,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(40),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const CircleAvatar(backgroundColor: Colors.white),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          left: 0,
          right: 0,
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 56,
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // 🧠 Title
  Widget _titleSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "Panadol",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              child: Text("?"),
            )
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "short description",
          style: TextStyle(fontStyle: FontStyle.italic),
        )
      ],
    );
  }

// 📄 Function (no card)
// 📄 Function (no card, wraps content)
Widget _functionSection() {
  return Container(
    width: double.infinity, // ensures it takes full width
    margin: const EdgeInsets.symmetric(horizontal: 12).copyWith(bottom: 16), // horizontal + bottom spacing
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, // left-align text
      children: const [
        Text(
          "Function",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        Text(
          "Pain relief and fever reduction",
          style: TextStyle(fontSize: 14),
        ),
      ],
    ),
  );
}



  // ⚠️ Side effect + dosage
  Widget _sideEffectDosage() {
    return Row(
      children: [
        Expanded(
          child: _sectionCard(
            title: "Side Effect",
            height: 90,
            child: const Text("Nausea, rash"),
          ),
        ),
        Expanded(
          child: _sectionCard(
            title: "Dosage",
            height: 90,
            child: const Text("500mg – 1000mg"),
          ),
        ),
      ],
    );
  }

  // 👥 Recipient / Not for
  Widget _recipientSection() {
    return Row(
      children: [
        Expanded(
          child: _sectionCard(
            title: "Recipient Population",
            height: 120,
            child: Column(
              children: [
                _pill("Adults", Colors.blue.shade100),
                _pill("Children", Colors.blue.shade100),
              ],
            ),
          ),
        ),
        Expanded(
          child: _sectionCard(
            title: "Not For These People",
            height: 120,
            child: Column(
              children: [
                _pill("Liver disease", Colors.red.shade300),
                _pill("Alcohol abuse", Colors.red.shade300),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🧱 Reusable card
  Widget _sectionCard({
  required String title,
  required double height,
  required Widget child,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: height,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black),
          ),
          // ✅ Make content scrollable inside the card
          child: SingleChildScrollView(
            child: child,
          ),
        ),
      ],
    ),
  );
}

  // 💊 Pill widget
  Widget _pill(String text, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(text),
    );
  }

}
