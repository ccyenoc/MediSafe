import 'package:flutter/material.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _weekSelector(context),
            const SizedBox(height: 24),

            _scheduleSection(
              title: "Morning",
              time: "8.00 AM",
              note: "After Meal",
              pillColor: Colors.lightBlue.shade50,
            ),

            _scheduleSection(
              title: "Afternoon / Evening",
              time: "1.00 PM",
              note: "After Meal",
              pillColor: Colors.yellow.shade50,
            ),

            _scheduleSection(
              title: "Night",
              time: "8.00 PM",
              note: "",
              pillColor: Colors.grey.shade200,
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
    final startOfWeek =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

    final weekDates = List.generate(
      5,
      (index) => startOfWeek.add(Duration(days: index)),
    );

    final weekNames = ["Mon", "Tue", "Wed", "Thu", "Fri"];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E3F8F)),
      ),
      child: Row(
        children: [
          // DAYS
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
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
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF3D6DF2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          date.day.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
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

          // 📆 CALENDAR ICON (iPhone style)
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
  context: context,
  initialDate: selectedDate,
  firstDate: DateTime.now().subtract(const Duration(days: 365)),
  lastDate: DateTime.now().add(const Duration(days: 365)),
  builder: (context, child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: Colors.red,      // header & selected date
          onPrimary: Colors.white,  // text on header
          onSurface: Colors.black,  // body text
        ),
        dialogBackgroundColor: Colors.white,
      ),
      child: child!,
    );
  },
);


              if (picked != null) {
                setState(() {
                  selectedDate = picked;
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
}
