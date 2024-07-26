import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(DateReminderApp());
}

class DateReminderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: Colors.cyanAccent,
        textTheme: TextTheme(
          bodyLarge:  TextStyle(color: Color(0xFF800080)),
        ),
      ),
      home: DateReminderScreen(),
    );
  }
}

class DateReminderScreen extends StatefulWidget {
  @override
  _DateReminderScreenState createState() => _DateReminderScreenState();
}

class _DateReminderScreenState extends State<DateReminderScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  Map<DateTime, String> _selectedDatesWithMessages = {};

  @override
  void initState() {
    super.initState();
    final initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _scheduleNotification(DateTime date, String message) async {
    final scheduledNotificationDateTime = date.subtract(Duration(days: 1));
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your channel id',
      'your channel name',
     // 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    final platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.schedule(
      0,
      'Reminder',
      message,
      scheduledNotificationDateTime,
      platformChannelSpecifics,
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    TextEditingController messageController = TextEditingController();
    bool isEdit = false;

    if (_selectedDatesWithMessages.containsKey(selectedDay)) {
      messageController.text = _selectedDatesWithMessages[selectedDay]!;
      isEdit = true;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFFE6E6FA),
          title: Text(
            isEdit ? 'Edit Message for ${DateFormat.yMMMd().format(selectedDay)}' : 'Enter Message for ${DateFormat.yMMMd().format(selectedDay)}',
            style: TextStyle(color: Color(0xFF800080)),
          ),
          content: TextField(
            controller: messageController,
            decoration: InputDecoration(hintText: 'Enter your message here'),
            style: TextStyle(color: Color(0xFF800080)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: Color(0xFF800080))),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedDatesWithMessages[selectedDay] = messageController.text;
                });
                _scheduleNotification(selectedDay, messageController.text);
                Navigator.of(context).pop();
              },
              child: Text('Save', style: TextStyle(color: Color(0xFF800080))),
            ),
          ],
        );
      },
    );

    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _editMessage(DateTime date) {
    _onDaySelected(date, _focusedDay);
  }

  void _deleteDate(DateTime date) {
    setState(() {
      _selectedDatesWithMessages.remove(date);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Date Reminder App'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          SizedBox(height: 16.0),
          Text(
            'Selected Date: ${DateFormat.yMMMd().format(_selectedDay)}',
            style: TextStyle(fontSize: 18.0, color: Color(0xFF800080)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _selectedDatesWithMessages.length,
              itemBuilder: (context, index) {
                DateTime date = _selectedDatesWithMessages.keys.elementAt(index);
                String message = _selectedDatesWithMessages[date] ?? '';
                return ListTile(
                  title: Text('${DateFormat.yMMMd().format(date)}: $message', style: TextStyle(color: Color(0xFF800080))),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Color(0xFF800080)),
                        onPressed: () {
                          _editMessage(date);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Color(0xFF800080)),
                        onPressed: () {
                          _deleteDate(date);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
