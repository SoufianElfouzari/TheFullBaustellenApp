// ignore_for_file: avoid_print, non_constant_identifier_names

import 'package:baustellenapp/DataBase/appwrite_constant.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';

class ProjectDetail extends StatefulWidget {
  final String projectName;
  final String projectAdress;
  final String? projectLeader;
  final String currentBaustelleId;
  final String userID;

  const ProjectDetail({
    super.key,
    required this.projectName,
    required this.projectAdress,
    this.projectLeader,
    required this.currentBaustelleId,
    required this.userID
  });

  @override
  // ignore: library_private_types_in_public_api
  _ProjectDetailState createState() => _ProjectDetailState();
}

class _ProjectDetailState extends State<ProjectDetail> {
  late Client client;
  late Account account;
  late Databases databases;
  List<Document> userList = [];
  List<Document> comments = [];
  String newComment = '';
  List<String> assignedWorkers = [];
  bool admin = false;

  @override
  void initState() {
    super.initState();
    _initializeAppwrite();
    _fetchData();
    _checkAssignedWorkers();
  }

  void _initializeAppwrite() {
    client = Client()
      ..setEndpoint(AppwriteConstants.endPoint)
      ..setProject(AppwriteConstants.projectId);

    account = Account(client);
    databases = Databases(client);
  }

  Future<void> _fetchData() async {
    await _checkAdminRole();
    await _fetchUsers();
    await _fetchComments();
    await _checkAssignedWorkers();
  }

  Future<void> _fetchUsers() async {
    try {
      var response = await databases.listDocuments(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.usercollectionId,
      );

      setState(() {
        userList = response.documents;
      });
    } catch (e) {
      // ignore: duplicate_ignore
      // ignore: avoid_print
      print('Error fetching users: $e');
    }
  }

  Future<void> _fetchComments() async {
    try {
      var response = await databases.listDocuments(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.benutzer1CollectionID,
      );

      setState(() {
        comments = response.documents
            .where((doc) => doc.data['baustelleId'] == widget.currentBaustelleId)
            .toList();
      });
    } catch (e) {
      print('Error fetching comments: $e');
    }
  }

  Future<void> _checkAdminRole() async {
    try {
      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.usercollectionId,
      );

      for (var doc in response.documents) {
        if (doc.$id == widget.userID) {
          admin = doc.data['Admin'];
          break;
        }
      }
    } catch (e) {
      print('Error fetching admin roles: $e');
    }
  }

  Future<void> _checkAssignedWorkers() async {
    setState(() {
      assignedWorkers.clear(); // Clear the list before checking
      for (var assignedCurrentWorker in userList) {
        if (assignedCurrentWorker.data["AssignedTo"] == widget.currentBaustelleId) {
          assignedWorkers.add(assignedCurrentWorker.data["Name"]);
        }
      }
    });
  }

  Future<void> _addComment(String commentText) async {
    if (commentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment cannot be empty.')),
      );
      return;
    }

    try {
      await databases.createDocument(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.benutzer1CollectionID,
        documentId: 'unique()', // Unique ID for the document
        data: {
          'text': commentText,
          'baustelleId': widget.currentBaustelleId,
        },
      );

      _fetchComments(); // Refresh comments after adding
      setState(() {
        newComment = ''; // Clear the input field
      });

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comment saved: $commentText')),
      );
    } catch (e) {
      print('Error adding comment: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save comment: $e')),
      );
    }
  }

  Future<void> _editComment(String documentId, String commentText) async {
    if (commentText.isEmpty) return;

    try {
      await databases.updateDocument(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.benutzer1CollectionID,
        documentId: documentId,
        data: {
          'text': commentText,
        },
      );

      _fetchComments(); // Refresh comments after editing
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comment updated: $commentText')),
      );
    } catch (e) {
      print('Error editing comment: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update comment: $e')),
      );
    }
  }

  Future<void> _deleteComment(String documentId) async {
    try {
      await databases.deleteDocument(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.benutzer1CollectionID,
        documentId: documentId,
      );

      _fetchComments(); // Refresh comments after deleting
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment deleted')),
      );
    } catch (e) {
      print('Error deleting comment: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete comment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue, size: 30),
                const SizedBox(width: 10),
                Text('Projektleiter: ${widget.projectLeader ?? 'Not assigned'}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 30),
                const SizedBox(width: 10),
                Text('Location: ${widget.projectAdress}', style: const TextStyle(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 20),

            // Worker selection for admins
            if (admin) ...[
              const Text('Select Workers:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              MultiSelectDialogField(
                items: userList.map((user) {
                  return MultiSelectItem<Document>(user, user.data['Name']);
                }).toList(),
                title: const Text("Choose Workers"),
                selectedColor: Colors.blue,
                buttonText: const Text(
                  "Add Workers",
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
                onConfirm: (List<Document> selectedWorkers) async {
  setState(() {
    assignedWorkers = selectedWorkers.map((worker) => worker.data['Name'] as String).toList();
  });
  
    _checkAssignedWorkers();
  
  // Get the list of worker IDs to save in the project
  List<String> UserIds = selectedWorkers.map((worker) => worker.$id).toList();

  // Save the assignment in Appwrite for workers and update the project
  for (var User in selectedWorkers) {
    String UserId = User.$id;
    await _updateWorkerAssignment(UserId); // Assign worker
  }

  // Update the project (Baustelle) with the list of assigned workers
  await _updateBaustelleWorkers(UserIds); // Save worker IDs to Baustelle collection

  // ignore: use_build_context_synchronously
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Assigned Workers: ${assignedWorkers.join(', ')}')),
  );
},
              ),
            ] else ...[
              const SizedBox(height: 10),
              const Text(
                'You do not have permission to select workers.',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ],

            const SizedBox(height: 20),

            // Display the list of assigned workers
            if (assignedWorkers.isNotEmpty) ...[
              const Text('Assigned Workers:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: assignedWorkers.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(assignedWorkers[index]),
                  );
                },
              ),
            ] else
              const Text('No workers assigned.'),

            const SizedBox(height: 20),

            // Comment section for admins
            const Text('Add Comment:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter your comment here',
              ),
              onChanged: (value) {
                setState(() {
                  newComment = value; // Store the entered comment
                });
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _addComment(newComment); // Save the comment to Appwrite
              },
              child: const Text('Save Comment'),
            ),
            const SizedBox(height: 20),

            // Display comments
            const Text('Comments:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return ListTile(
                  title: Text(comment.data['text']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showEditDialog(comment.$id); // Open dialog to edit comment
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _deleteComment(comment.$id); // Delete comment
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

Future<void> _updateWorkerAssignment(String UserId) async {
  try {
    await databases.updateDocument(
      databaseId: AppwriteConstants.dbId,
      collectionId: AppwriteConstants.usercollectionId, // The user/worker collection
      documentId: UserId, // The worker's document ID
      data: {
        'Assigned': true, // Mark as assigned
        'AssignedTo': widget.currentBaustelleId, // Set the baustelle ID (project ID)
      },
    );
    print('Worker $UserId updated successfully.');
  } catch (e) {
    print('Error updating worker $UserId: $e');
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to assign worker: $e')),
    );
  }
}
Future<void> _updateBaustelleWorkers(List<String> UserIds) async {
  try {
    // Fetch the current project document

    // Update the project document with the new list of assigned workers
    await databases.updateDocument(
      databaseId: AppwriteConstants.dbId,
      collectionId: AppwriteConstants.baustellenoverviewCollectionId,
      documentId: widget.currentBaustelleId,
      data: {
        'Assigned': UserIds[0], // List of worker IDs
      },
    );

    print('Workers updated successfully for Baustelle ${widget.projectName}');
  } catch (e) {
    print('Error updating workers for Baustelle: $e');
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to update workers for the project: $e')),
    );
  }
}

  void _showEditDialog(String documentId) {
    String commentText = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Comment'),
          content: TextField(
            onChanged: (value) {
              commentText = value; // Store the new comment text
            },
            decoration: const InputDecoration(hintText: "Enter new comment"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _editComment(documentId, commentText); // Update the comment
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without saving
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}