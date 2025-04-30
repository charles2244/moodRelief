import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const CalendarWidget({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFD2CCF8), // Background color
        borderRadius: BorderRadius.circular(18), // <-- Rounded corners
      ),
      child: TableCalendar(
        focusedDay: selectedDate,
        firstDay: DateTime.utc(2020, 1, 1).add(Duration(hours: 8)),
        lastDay: DateTime.utc(2030, 12, 31).add(Duration(hours: 8)),
        selectedDayPredicate: (day) => isSameDay(day, selectedDate),
        onDaySelected: (selectedDay, focusedDay) => onDateSelected(selectedDay),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronVisible: true,
          rightChevronVisible: true,
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: const BoxDecoration(
            color: Colors.purple,
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          todayTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          weekendTextStyle: const TextStyle(color: Colors.deepPurple),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekendStyle: TextStyle(color: Colors.deepPurple),
        ),
      ),
    );
  }
}
