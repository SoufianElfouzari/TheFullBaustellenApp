// ignore_for_file: avoid_print, use_build_context_synchronously, deprecated_member_use

import 'package:baustellenapp/Screens/ContactProfile/Mobile/contact_profile.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:baustellenapp/DataBase/appwrite_constant.dart'; // Ensure this contains your AppwriteConstants
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart'; // Optional for caching

class InsideChat extends StatefulWidget {
  final Client client;
  final String userID; 
  final String receiverID; 
  final String receiverName; 
  const InsideChat({
    super.key, 
    required this.client,
    required this.userID, 
    required this.receiverID, 
    required this.receiverName,  
  });

  @override
  State<InsideChat> createState() => _ChatState();
}

class _ChatState extends State<InsideChat> {
  List<Map<String, dynamic>> chat = []; // List for chat messages with sender ID
  TextEditingController controller = TextEditingController(); // Controller for the text field
  late Databases databases; // Declare the database
  late final Realtime realtime;
  RealtimeSubscription? _realtimeSubscription;
  final ScrollController _scrollController = ScrollController(); // ScrollController for auto-scrolling

  @override
  void initState() {
    super.initState();
    databases = Databases(widget.client);
    realtime = Realtime(widget.client); // Initialize Realtime
    _subscribeToUserUpdates();
    _loadChat(); // Load chat and mark messages as read
  }

  Future<void> _loadChat() async {
    await fetchMessages();
    await markMessagesAsRead();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Important: Release the controller
    _realtimeSubscription?.close(); // Close the real-time subscription
    super.dispose();
  }

  Future<void> fetchMessages() async {
    try {
      // Query for messages from user to receiver
      final response1 = await databases.listDocuments(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.messagecollectionID,
        queries: [
          Query.equal('SenderID', widget.userID),
          Query.equal('RecieverID', widget.receiverID), // Keep the spelling as in the database
          Query.orderDesc('Datum'), // Sort by newest first
          Query.limit(100), // Adjust the limit accordingly
        ],
      );

      // Query for messages from receiver to user
      final response2 = await databases.listDocuments(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.messagecollectionID,
        queries: [
          Query.equal('SenderID', widget.receiverID),
          Query.equal('RecieverID', widget.userID), // Keep the spelling as in the database
          Query.orderDesc('Datum'), // Sort by newest first
          Query.limit(100), // Adjust the limit accordingly
        ],
      );

      List<Map<String, dynamic>> fetchedChat = [];

      // Add messages from both queries
      for (var doc in [...response1.documents, ...response2.documents]) {
        bool isImage = doc.data['Image'] ?? false;
        String messageText = isImage ? doc.data['ImageID'] ?? '' : doc.data['Text'] ?? 'Unknown';
        String senderID = doc.data['SenderID'] ?? 'No Sender';
        String receiverID = doc.data['RecieverID'] ?? 'No Receiver'; // Keep the spelling as in the database

        fetchedChat.add({
          'text': messageText,
          'userID': senderID,
          'recieverID': receiverID,
          'id': doc.$id,
          'Datum': doc.data['Datum'] ?? '', // ISO8601 string or empty
          'Image': isImage,
          'ImageID': doc.data['ImageID'] ?? '',
        });
      }

      // Sort the combined messages by date
      fetchedChat.sort((a, b) {
        DateTime dateA = DateTime.tryParse(a['Datum']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        DateTime dateB = DateTime.tryParse(b['Datum']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateA.compareTo(dateB);
      });

      setState(() {
        chat = fetchedChat;
        print("Messages loaded: $chat");
      });

      // Optional: Scroll to the newest message after loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && chat.isNotEmpty) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

    } catch (e) {
      print('Error fetching messages: $e');
    }
  }

  Future<void> markMessagesAsRead() async {
    try {
      // Query for unread messages from the receiver
      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.messagecollectionID,
        queries: [
          Query.equal('SenderID', widget.receiverID),
          Query.equal('RecieverID', widget.userID),
          Query.equal('isRead', false),
        ],
      );

      // Update each unread message to set 'isRead' to true
      for (var doc in response.documents) {
        await databases.updateDocument(
          databaseId: AppwriteConstants.dbId,
          collectionId: AppwriteConstants.messagecollectionID,
          documentId: doc.$id,
          data: {'isRead': true},
        );
      }

      print("Marked ${response.documents.length} messages as read.");
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  void sendMessage() {
    if (controller.text.isNotEmpty) {
      _addComment(controller.text);
      controller.clear(); // Clear the text field
    }
  }

  void _subscribeToUserUpdates() {
    try {
      _realtimeSubscription = realtime.subscribe([
        'databases.${AppwriteConstants.dbId}.collections.${AppwriteConstants.messagecollectionID}.documents'
      ]);

      _realtimeSubscription!.stream.listen((event) {
        print("Real-time event received: ${event.events}, Payload: ${event.payload}");
        if (mounted) {
          _processRealtimeEvent(event);
        }
      }, onError: (error) {
        print("Real-time subscription error: $error");
      });
    } catch (e) {
      print("Error subscribing to real-time updates: $e");
    }
  }

  void _processRealtimeEvent(RealtimeMessage event) {
    final Map<String, dynamic> eventData = event.payload;
    final String eventType = event.events.first;

    String senderID = eventData['SenderID'] ?? '';
    String receiverID = eventData['RecieverID'] ?? ''; // Keep the spelling as in the database

    // Check if the message is relevant to the current chat
    if ((senderID == widget.userID && receiverID == widget.receiverID) ||
        (senderID == widget.receiverID && receiverID == widget.userID)) {
      if (eventType.contains('create')) {
        bool isImage = eventData['Image'] ?? false;
        String messageText = isImage ? eventData['ImageID'] ?? '' : eventData['Text'] ?? 'Unknown';

        setState(() {
          chat.add({
            'text': messageText,
            'userID': senderID,
            'recieverID': receiverID, // Keep the spelling as in the database
            'id': eventData['\$id'],
            'Datum': eventData['Datum'] ?? '', // ISO8601 string or empty
            'Image': isImage,
            'ImageID': eventData['ImageID'] ?? '',
          });
          print("New message added: ${isImage ? 'Image' : eventData['Text']}");
        });

        // Scroll to the newest message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

      } else if (eventType.contains('update')) {
        // Optional: Handle updates if necessary
      } else if (eventType.contains('delete')) {
        setState(() {
          chat.removeWhere((msg) => msg['id'] == eventData['\$id']);
          print("Message deleted: ${eventData['\$id']}");
        });
      }
    }
  }

  Future<void> _addComment(String messageText) async {
    if (messageText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nachricht darf nicht leer sein.')),
      );
      return;
    }

    try {
      await databases.createDocument(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.messagecollectionID,
        documentId: 'unique()', // Unique ID for the document
        data: {
          'Text': messageText,
          'SenderID': widget.userID,
          'RecieverID': widget.receiverID, // Keep the spelling as in the database
          'Image': false,
          'Datum': DateTime.now().toIso8601String(), // Date as ISO8601 string
          'ImageID': null,
          'isRead': false, // Initialize as unread
        },
      );
      print("Message saved in the database.");
    } catch (e) {
      print('Error adding Message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nachricht konnte nicht gespeichert werden: $e')),
      );
    }
  }

  // Function to open the image source selection
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bildquelle auswählen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () async {
                  Navigator.of(context).pop(); // Close the dialog
                  final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    final bytes = await pickedFile.readAsBytes();
                    await _uploadImage(bytes); // Upload the image
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('Datei auswählen'),
                onTap: () async {
                  Navigator.of(context).pop(); // Close the dialog
                  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    final bytes = await pickedFile.readAsBytes();
                    await _uploadImage(bytes); // Upload the image
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadImage(Uint8List imageBytes) async {
    try {
      Storage storage = Storage(widget.client);

      // Create the file first to get the ID
      final result = await storage.createFile(
        bucketId: AppwriteConstants.storageBucketId,
        fileId: 'unique()', // Generate a unique file ID
        file: InputFile(
          bytes: imageBytes,
          filename: 'chat_image_${DateTime.now().millisecondsSinceEpoch}.png', // Unique filename
        ),
      );

      // Save image message in the database
      await databases.createDocument(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.messagecollectionID,
        documentId: 'unique()', // Unique ID for the document
        data: {
          'Image': true,
          'ImageID': result.$id,
          'SenderID': widget.userID,
          'RecieverID': widget.receiverID, // Keep the spelling as in the database
          'Datum': DateTime.now().toIso8601String(), // Date as ISO8601 string
          'isRead': false, // Initialize as unread
        },
      );
      print("Image message saved in the database.");
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Hochladen: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ContactProfile(userId: widget.userID)));
          },
          child: Text(
            widget.receiverName, 
            style: const TextStyle(
              fontWeight: FontWeight.bold, 
              color: Colors.black
            )
          )
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop(); // Go back to the previous screen
          },
          icon: const Icon(Icons.arrow_back, size: 30, color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.video_call, size: 30, color: Colors.black),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.call, size: 30, color: Colors.black),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // Added
              reverse: false, // Display messages from top to bottom
              itemCount: chat.length,
              itemBuilder: (context, index) {
                final message = chat[index];
                bool isSender = message["userID"] == widget.userID; // Check if the message is from the current user
                bool isImage = message["Image"] == true; // Check if it's an image message

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: isSender ? Alignment.centerRight : Alignment.centerLeft, // Right for sender, left for receiver
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: isSender ? Colors.blueAccent.shade100 : Colors.greenAccent.shade100, // Different colors for sender and receiver
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      child: isImage
                          ? CachedNetworkImage(
                              imageUrl: 'https://cloud.appwrite.io/v1/storage/buckets/${AppwriteConstants.storageBucketId}/files/${message["ImageID"]}/view?project=${AppwriteConstants.projectId}&mode=admin',
                              placeholder: (context, url) => const CircularProgressIndicator(),
                            ) // Display the image if it's an image message
                          : Text(
                              message["text"],
                              style: const TextStyle(
                                color: Colors.black, // Change to black for better readability
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 7,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _showImageSourceDialog, // Open the image source selection
                  icon: const Icon(Icons.camera_alt, color: Colors.deepPurpleAccent, size: 28),
                ),
                IconButton(
                  onPressed: () {}, // Function for voice recording (can be adjusted)
                  icon: const Icon(Icons.mic, color: Colors.deepPurpleAccent, size: 28),
                ),
                Expanded(
                  child: Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: controller,
                      onChanged: (text) {
                        setState(() {}); // Update the state when the text changes
                        print("Text changed: $text");
                      },
                      decoration: const InputDecoration(
                        hintText: "Nachricht schreiben...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                // Show send button only when the text field is not empty
                if (controller.text.isNotEmpty) 
                  IconButton(
                    onPressed: sendMessage,
                    icon: const Icon(Icons.send, color: Colors.deepPurpleAccent, size: 28),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}