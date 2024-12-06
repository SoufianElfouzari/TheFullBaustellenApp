import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:baustellenapp/DataBase/appwrite_constant.dart'; // Re-added import for constants

class Kalender extends StatefulWidget {
  final String userID; // Declare userID as a final variable

  Kalender({super.key, required this.userID}); // Mark userID as required

  @override
  _KalenderState createState() => _KalenderState();
}

class _KalenderState extends State<Kalender> {
  late Client _client;
  late Databases _databases;
  late final ValueNotifier<List<Map<String, dynamic>>> _selectedEvents;
  DateTime? _selectedDay;
  final Map<DateTime, List<Map<String, dynamic>>> _events = {};
  final List<Map<String, dynamic>> _announcements = [];
  List<Document> userList = [];
  Map<String, String> userMap = {}; // Map to store userID to Name
  List<String> assignedWorkers = [];

  @override
  void initState() {
    super.initState();
    _initializeAppwrite();
    _fetchUsers(); // Fetch users from Appwrite
    _selectedEvents = ValueNotifier([]);
  }

  void _initializeAppwrite() {
    _client = Client()
      ..setEndpoint(AppwriteConstants.endPoint)
      ..setProject(AppwriteConstants.projectId);
    _databases = Databases(_client);
    _fetchEvents(); // Fetch tasks when initializing
    _fetchAnnouncements(); // Fetch announcements when initializing
    _updateSelectedEvents();
  }

  // Fetch tasks from Appwrite
  void _fetchEvents() async {
    int batchSize = 25; // Die Anzahl der Dokumente, die du pro Anfrage laden möchtest
    int page = 0; // Die Seite, ab der du anfängst
    bool hasMoreDocuments = true;

    try {
      while (hasMoreDocuments) {
        final response = await _databases.listDocuments(
          databaseId: AppwriteConstants.dbId,
          collectionId: AppwriteConstants.task,
          queries: [
            Query.limit(batchSize),
            Query.offset(page * batchSize)
          ],
        );

        print('Documents fetched: ${response.documents.length}');

        if (response.documents.length < batchSize) {
          hasMoreDocuments = false;
        }

        for (var doc in response.documents) {
          DateTime date = DateTime.parse(doc.data['date']);
          String text = doc.data['text'] ?? 'No Task';
          String priority = doc.data['priority'] ?? 'Normal';
          String time = doc.data['time'] ?? 'No Time';
          String creatorId = doc.data['SenderID'] ?? 'No Sender';
          String documentId = doc.$id;

          List<String> recieverIds = [];
          if (doc.data['RecieverID'] != null && doc.data['RecieverID'] is String) {
            recieverIds = (doc.data['RecieverID'] as String).split(',').map((id) => id.trim()).toList();
          }

          print('Task details: text=$text, priority=$priority, time=$time, creator=$creatorId, recievers=$recieverIds');

          _events[date] = (_events[date] ?? [])..add({
            'text': text,
            'priority': priority,
            'time': time,
            'creator': creatorId,
            'recievers': recieverIds,
            'documentId': documentId,
          });
        }

        page++;
      }

      setState(() {
        _updateSelectedEvents(); // Aktualisiere das UI
      });
    } catch (e) {
      print('Error fetching tasks: $e');
    }
  }

  // Fetch announcements from Appwrite
  void _fetchAnnouncements() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.announcement,
      );

      for (var doc in response.documents) {
        DateTime date = DateTime.parse(doc.data['date']);
        String title = doc.data['title'] ?? 'No Title';
        String description = doc.data['description'] ?? 'No Description';
        String creator = doc.data['SenderID'] ?? 'No Sender';

        _announcements.add({
          'title': title,
          'description': description,
          'date': date.toIso8601String(),
          'creator': creator,
        });
      }
    } catch (e) {
      print('Error fetching announcements: $e');
    }
  }

  // Update selected events based on the selected day
  void _updateSelectedEvents() {
    if (_selectedDay != null) {
      _selectedEvents.value = _events[_selectedDay] ?? [];
    }
  }

  // Get announcements for the selected day
  List<Map<String, dynamic>> _getAnnouncementsForDay(DateTime? day) {
    if (day == null) return [];
    return _announcements.where((announcement) {
      DateTime announcementDate = DateTime.parse(announcement['date']);
      return announcementDate.year == day.year &&
          announcementDate.month == day.month &&
          announcementDate.day == day.day;
    }).toList();
  }

  // Fetch users and populate userMap
  Future<void> _fetchUsers() async {
    try {
      var response = await _databases.listDocuments(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.usercollectionId, // Replace with your user collection ID
      );

      setState(() {
        userList = response.documents;
        userMap = {
          for (var user in userList) user.$id: user.data['Name'] ?? 'Unbekannt'
        };
        print(userMap);
      });
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  // Helper function to get user name from userID
  String getUserName(String userId) {
    return userMap[userId] ?? 'Unbekannt';
  }

  // Helper function to get Reciever names from list of IDs
  String getRecieverNames(List<String> recieverIds) {
    if (recieverIds.isEmpty) return 'Keine Empfänger';
    List<String> names = recieverIds.map((id) => getUserName(id)).toList();
    return names.join(', ');
  }

  // Add task to Appwrite
  void _addTaskToAppwrite(Map<String, dynamic> task) async {
  try {
    // Temporary permissions: allow anyone to read and write
    List<String> permissions = [
      'read("any")',  // Anyone can read
      'write("any")', // Anyone can write
    ];

    await _databases.createDocument(
      databaseId: AppwriteConstants.dbId, // Your Appwrite database ID
      collectionId: AppwriteConstants.task, // Your collection ID
      documentId: ID.unique(), // Let Appwrite generate a unique ID
      data: task,
      permissions: permissions, // Temporary public permissions
    );
    print('Task added successfully!');

    _fetchEvents(); // Update the event list after adding the task
  } catch (e) {
    print('Error adding task: $e');
  }
}

  // Add announcement to Appwrite
  void _addAnnouncementToAppwrite(Map<String, dynamic> announcement) async {
    try {
      await _databases.createDocument(
        databaseId: AppwriteConstants.dbId, // Your Appwrite database ID
        collectionId: AppwriteConstants.announcement, // Your announcement collection ID
        documentId: ID.unique(), // Let Appwrite generate a unique ID
        data: announcement,
        permissions: [
          Permission.read(Role.any()), // Allow anyone to read
          Permission.write(Role.any()), // Allow anyone to write
        ],
      );
      print('Announcement added successfully!');
    } catch (e) {
      print('Error adding announcement: $e');
    }
  }

  // Delete task from Appwrite
  void _deleteTaskFromAppwrite(String documentId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.task,
        documentId: documentId,
      );
      print('Task deleted successfully!');
    } catch (e) {
      print('Error deleting task: $e');
    }
  }

  // Show Task Dialog for Adding/Editing Tasks
  void _showTaskDialog({String? existingTask, String? existingPriority, String? existingTime}) {
    final TextEditingController taskController = TextEditingController(text: existingTask);
    final TextEditingController timeController = TextEditingController(text: existingTime);
    String? selectedPriority = existingPriority ?? 'Mittelschwer'; // Default priority

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // To manage state within the dialog
          builder: (context, setState) {
            return AlertDialog(
              title: Text(existingTask == null ? 'Neue Aufgabe hinzufügen' : 'Aufgabe bearbeiten'),
              content: SingleChildScrollView( // To handle overflow
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: taskController,
                      decoration: InputDecoration(hintText: 'Aufgabentext eingeben'),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: timeController,
                      decoration: InputDecoration(hintText: 'Zeit eingeben (z.B. 14:00)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    SizedBox(height: 10),
                    DropdownButton<String>(
                      value: selectedPriority,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedPriority = newValue; // Update selected priority
                        });
                      },
                      items: <String>['Leicht', 'Mittelschwer', 'Schwer']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 10),
                    MultiSelectDialogField(
                      items: userList.map((user) {
                        return MultiSelectItem<Document>(user, user.data['Name']);
                      }).toList(),
                      title: const Text("Leute Hinzufügen"),
                      selectedColor: Colors.blue,
                      buttonText: const Text(
                        "Leute Hinzufügen",
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                      onConfirm: (List<Document> selectedWorkers) {
                        setState(() {
                          // Store the selected user IDs
                          assignedWorkers = selectedWorkers.map((worker) => worker.$id).toList();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Assigned Workers: ${assignedWorkers.join(', ')}'),
                          ));
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (taskController.text.isNotEmpty && _selectedDay != null) {
                      final newTask = {
                        'text': taskController.text,
                        'time': timeController.text,
                        'priority': selectedPriority ?? 'Mittelschwer',
                        'date': _selectedDay?.toIso8601String() ?? DateTime.now().toIso8601String(),
                        'SenderID': widget.userID,
                        'RecieverID': assignedWorkers.join(','), // Konvertiere die Liste in einen String
                      };

                      setState(() {
                        bool taskExists = _events[_selectedDay]?.any((task) => task['documentId'] == newTask['documentId']) ?? false;
                        if (!taskExists) {
                          if (_events[_selectedDay] == null) {
                            _events[_selectedDay!] = [];
                          }
                          _events[_selectedDay]!.add(newTask);
                        }
                        _updateSelectedEvents();
                      });

                      _addTaskToAppwrite(newTask); // Füge die Aufgabe hinzu
                      Navigator.of(context).pop(); // Schließe den Dialog
                    }
                  },
                  child: Text(existingTask == null ? 'Hinzufügen' : 'Speichern'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Abbrechen'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Show Announcement Dialog
  void _showAnnouncementDialog() {
    final TextEditingController titleController = TextEditingController(); // Controller for title
    final TextEditingController descriptionController = TextEditingController(); // Controller for description

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Neue Ankündigung hinzufügen'),
          content: SingleChildScrollView( // To handle overflow
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(hintText: 'Titel eingeben'), // Hint for title
                ),
                SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(hintText: 'Beschreibung eingeben'), // Hint for description
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                  final newAnnouncement = {
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'date': _selectedDay != null ? _selectedDay!.toIso8601String() : DateTime.now().toIso8601String(),
                    'creator': widget.userID, // Assuming the current user is the creator
                  };

                  setState(() {
                    _announcements.add(newAnnouncement);
                    print(_announcements);
                  });

                  _addAnnouncementToAppwrite(newAnnouncement);
                }

                Navigator.of(context).pop();
              },
              child: Text('Hinzufügen'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Abbrechen'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kalender'),
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10.0,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.now().subtract(Duration(days: 365)),
              lastDay: DateTime.now().add(Duration(days: 365)),
              focusedDay: _selectedDay ?? DateTime.now(),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _updateSelectedEvents();
                });
              },
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: _selectedEvents,
              builder: (context, events, _) {
                final announcements = _getAnnouncementsForDay(_selectedDay);

                return ListView(
                  children: [
                    if (announcements.isNotEmpty)
                      ...announcements.map((announcement) {
                        return Card(
                          child: ListTile(
                            title: Text(announcement['title'] ?? 'No Title'),
                            subtitle: Text(announcement['description'] ?? 'No Description'),
                            iconColor: Colors.amber,
                            leading: Icon(Icons.announcement),
                          ),
                        );
                      }).toList(),
                    ...events.map((event) {
                      String creatorId = event['creator'] ?? 'No Sender';
                      String creatorName = getUserName(creatorId);

                      List<String> recieverIds = List<String>.from(event['recievers'] ?? []);
                      String recieverNames = getRecieverNames(recieverIds);

                      return Card(
                        child: ListTile(
                          title: Text(event['text'] ?? 'No Task'),
                          subtitle: Text(
                            'Zeit: ${event['time'] ?? 'Keine Zeit'} | Priorität: ${event['priority'] ?? 'Keine Priorität'} | Erstellt: $creatorName | Empfänger: $recieverNames',
                          ),
                          iconColor: Colors.green,
                          leading: Icon(Icons.task),
                          trailing: IconButton(
                            onPressed: () {
                              setState(() {
                                _events[_selectedDay]?.remove(event);
                                _updateSelectedEvents();
                              });
                              _deleteTaskFromAppwrite(event['documentId']);
                            },
                            icon: Icon(Icons.delete),
                          ),
                          onTap: () {
                            _showTaskDialog(
                              existingTask: event['text'],
                              existingPriority: event['priority'],
                              existingTime: event['time'],
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedDay != null
          ? FloatingActionButton(
              onPressed: _showFabOptions,
              child: Icon(Icons.add, color: Colors.white),
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              tooltip: 'Optionen anzeigen',
            )
          : null,
    );
  }

  void _showFabOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.task),
              title: Text('Aufgabe hinzufügen'),
              onTap: () {
                Navigator.of(context).pop();
                _showTaskDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.announcement),
              title: Text('Ankündigung hinzufügen'),
              onTap: () {
                Navigator.of(context).pop();
                _showAnnouncementDialog();
              },
            ),
          ],
        );
      },
    );
  }
}