import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'event_model.dart';
import 'local_storage.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Event> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  // 加载事件
  Future<void> _loadEvents() async {
    final events = await LocalStorage.loadEvents();
    setState(() {
      _events = events;
      // 对事件列表按日期倒序排序
      _events.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  // 保存事件
  Future<void> _saveEvents() async {
    await LocalStorage.saveEvents(_events);
  }

  // 获取指定日期的事件列表
  List<Event> _getEventsForDay(DateTime day) {
    final eventsForDay = _events.where((event) => isSameDay(event.date, day)).toList();
    // 对当天的事件列表按日期倒序排序
    eventsForDay.sort((a, b) => b.date.compareTo(a.date));
    return eventsForDay;
  }

  // 一键打卡
  void _punchCard() {
    final punchDate = _selectedDay ?? DateTime.now();
    final newEvent = Event(name: 'F', date: DateTime(punchDate.year, punchDate.month, punchDate.day, DateTime.now().hour, DateTime.now().minute, DateTime.now().second));
    setState(() {
      _events.add(newEvent);
      // 对事件列表按日期倒序排序
      _events.sort((a, b) => b.date.compareTo(a.date));
    });
    _saveEvents();
  }

  // 修改事件
  Future<void> _editEvent(Event event) async {
    final editedName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('修改事件'),
        content: TextField(
          controller: TextEditingController(text: event.name),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final value = (context as Element).findAncestorWidgetOfExactType<TextField>()?.controller?.text;
              Navigator.pop(context, value);
            },
            child: Text('确定'),
          ),
        ],
      ),
    );
    if (editedName != null) {
      setState(() {
        final index = _events.indexOf(event);
        _events[index] = Event(name: editedName, date: event.date);
        // 对事件列表按日期倒序排序
        _events.sort((a, b) => b.date.compareTo(a.date));
      });
      _saveEvents();
    }
  }

  // 删除事件
  void _deleteEvent(Event event) {
    setState(() {
      _events.remove(event);
    });
    _saveEvents();
  }

  @override
  Widget build(BuildContext context) {
    final currentEvents = _getEventsForDay(_selectedDay ?? _focusedDay);
    return Scaffold(
      appBar: AppBar(
        title: Text('一键打卡'),
      ),
      body: Column(
        children: [
          TableCalendar(
            // locale: 'zh_CN',
            firstDay: DateTime.utc(2020, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: _getEventsForDay,
            calendarBuilders: CalendarBuilders(
              selectedBuilder: (context, date, events) => Container(
                margin: const EdgeInsets.all(4.0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  date.day.toString(),
                  style: TextStyle(color: Colors.white),
                ),
              ),
              todayBuilder: (context, date, events) => Container(
                margin: const EdgeInsets.all(4.0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  date.day.toString(),
                  style: TextStyle(color: Colors.black),
                ),
              ),
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          Expanded(
            child: currentEvents.isEmpty
               ? Center(
                  child: Text('无事件'),
                )
                : ListView.builder(
                    itemCount: currentEvents.length,
                    itemBuilder: (context, index) {
                      final event = currentEvents[index];
                      return Dismissible(
                        key: Key(event.date.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (direction) {
                          _deleteEvent(event);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('事件已删除'),
                            ),
                          );
                        },
                        child: ListTile(
                          title: Text(event.name),
                          subtitle: Text(event.date.toString().substring(0, 19)),
                          onTap: () => _editEvent(event),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _punchCard,
        child: Icon(Icons.cruelty_free_outlined),
      ),
    );
  }
}

// 辅助函数，判断两个日期是否为同一天
bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) {
    return false;
  }
  return a.year == b.year && a.month == b.month && a.day == b.day;
}