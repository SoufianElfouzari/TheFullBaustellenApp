// Import Statements
// ignore_for_file: avoid_print

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:baustellenappchat1/Constants/colors.dart';
import '/Screens/InsideChat/Mobile/inside_chat.dart';
import 'package:flutter/material.dart';
import 'dart:async'; // For Timer
import '/DataBase/appwrite_constant.dart';
// For date formatting

/// ChatOverviewScreen: Displays a list of chat conversations or all users
class ChatOverviewScreen extends StatefulWidget {
  final Client client;
  final String currentUserID;

  const ChatOverviewScreen({
    super.key,
    required this.client,
    required this.currentUserID,
  });

  @override
  State<ChatOverviewScreen> createState() => _ChatOverviewScreenState();
}

class _ChatOverviewScreenState extends State<ChatOverviewScreen> {
  final List<ChatConversation> conversations = [];
  late Databases databases;
  RealtimeSubscription? chatSubscription;
  bool isLoading = true;
  String? errorMessage;
  Timer? _globalTimer;

  @override
  void initState() {
    super.initState();
    databases = Databases(widget.client);
    fetchChats();
    setupRealtimeUpdates();

    // Initialize a global timer to update every minute
    _globalTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        // Trigger a rebuild to update all time labels
      });
    });
  }

  @override
  void dispose() {
    chatSubscription?.close();
    _globalTimer?.cancel();
    super.dispose();
  }

  /// Parses the createdAt string into a DateTime object
  DateTime _parseDatetime(String? datetimeString) {
    if (datetimeString == null || datetimeString.isEmpty) {
      print('createdAt string is null or empty. Returning default date.');
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    try {
      // Parse the ISO 8601 string directly
      DateTime parsedDate = DateTime.parse(datetimeString).toLocal();
      print('Parsed datetime using ISO 8601: $parsedDate');
      return parsedDate;
    } catch (e) {
      print('ISO 8601 parsing failed: $e');
      // Return default date if parsing fails
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  /// Fetches chat conversations and all users from Appwrite
  Future<void> fetchChats() async {
    try {
      // Fetch all users excluding the current user
      final usersResponse = await databases.listDocuments(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.usercollectionId,
      );

      List<ChatConversation> allUsers = [];

      for (var doc in usersResponse.documents) {
        String userID = doc.$id;
        if (userID == widget.currentUserID) {
          continue; // Skip the current user
        }

        String name = doc.data['Name'] ?? 'Unknown';
        String? avatarUrl = doc.data['avatarUrl'];

        allUsers.add(ChatConversation(
          id: userID,
          name: name,
          lastMessage: '',
          lastMessageTime: DateTime.fromMillisecondsSinceEpoch(0),
          avatarUrl: avatarUrl,
          isImage: false,
          unreadCount: 0, // Initialize as 0
        ));
      }

      // Fetch messages where current user is sender or receiver
      final senderResponse = await databases.listDocuments(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.messagecollectionID,
        queries: [
          Query.equal('SenderID', widget.currentUserID),
        ],
      );

      final receiverResponse = await databases.listDocuments(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.messagecollectionID,
        queries: [
          Query.equal('RecieverID', widget.currentUserID),
        ],
      );

      // Combine messages
      final allMessages = [
        ...senderResponse.documents,
        ...receiverResponse.documents
      ];
      print('Total messages fetched: ${allMessages.length}');
      for (var message in allMessages) {
        print('Message Data: ${message.data}');
      }

      // Process messages to group them into conversations
      Map<String, List<Document>> conversationsMap = {};

      for (var doc in allMessages) {
        String? senderID = doc.data['SenderID'];
        String? receiverID = doc.data['RecieverID'];
        if (senderID == null || receiverID == null) {
          continue;
        }

        String otherUserID;
        if (senderID == widget.currentUserID) {
          otherUserID = receiverID;
        } else {
          otherUserID = senderID;
        }

        if (otherUserID.isEmpty) {
          continue;
        }

        if (!conversationsMap.containsKey(otherUserID)) {
          conversationsMap[otherUserID] = [];
        }

        conversationsMap[otherUserID]!.add(doc);
      }

      // Now merge conversations with users
      List<ChatConversation> fetchedConversations = [];

      for (var user in allUsers) {
        String userID = user.id;

        if (conversationsMap.containsKey(userID)) {
          List<Document> messages = conversationsMap[userID]!;

          // Sort messages by date to get the latest message
          messages.sort((a, b) {
            String? datetimeA = a.data['\$createdAt']; // Use 'createdAt' field
            String? datetimeB = b.data['\$createdAt'];

            DateTime dateA = _parseDatetime(datetimeA);
            DateTime dateB = _parseDatetime(datetimeB);
            return dateB.compareTo(dateA);
          });

          // Get the latest message
          var latestMessageDoc = messages.first;
          bool isImage = latestMessageDoc.data['Image'] ?? false;
          String lastMessage;
          if (isImage) {
            lastMessage = 'Foto';
          } else {
            lastMessage = latestMessageDoc.data['Text'] ?? '';
          }
          String? datetimeString =
              latestMessageDoc.data['\$createdAt']; // Use 'createdAt'
          DateTime lastMessageTime = _parseDatetime(datetimeString);

          int unreadCount = messages.where((msg) {
            return msg.data['isRead'] == false &&
                msg.data['SenderID'] == userID;
          }).length;

          // Update user with conversation details
          fetchedConversations.add(ChatConversation(
            id: userID,
            name: user.name,
            lastMessage: lastMessage,
            lastMessageTime: lastMessageTime,
            avatarUrl: user.avatarUrl,
            isImage: isImage,
            unreadCount: unreadCount, // Set unread count
          ));
        } else {
          // No conversation, keep the user details with unreadCount = 0
          fetchedConversations.add(user);
        }
      }

      // Sort the conversations by lastMessageTime descending, then by name
      fetchedConversations.sort((a, b) {
        if (a.lastMessageTime.isAfter(b.lastMessageTime)) {
          return -1;
        } else if (a.lastMessageTime.isBefore(b.lastMessageTime)) {
          return 1;
        } else {
          return a.name.compareTo(b.name);
        }
      });

      setState(() {
        conversations.clear();
        conversations.addAll(fetchedConversations);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching chats: $e';
        isLoading = false;
      });
    }
  }

  /// Sets up real-time updates for chat conversations
  void setupRealtimeUpdates() {
    final realtime = Realtime(widget.client);

    chatSubscription = realtime.subscribe([
      'databases.${AppwriteConstants.dbId}.collections.${AppwriteConstants.messagecollectionID}.documents',
    ]);

    chatSubscription!.stream.listen((event) {
      handleRealtimeEvent(event);
    });
  }

  /// Handles real-time events from Appwrite
  void handleRealtimeEvent(RealtimeMessage event) async {
    final eventType = event.events.first;
    final payload = event.payload;

    // Check if the message involves the current user
    if (payload['SenderID'] != widget.currentUserID &&
        payload['RecieverID'] != widget.currentUserID) {
      return;
    }

    String otherUserID = payload['SenderID'] == widget.currentUserID
        ? payload['RecieverID']
        : payload['SenderID'];

    if (eventType.contains('.create') || eventType.contains('.update')) {
      await addOrUpdateConversationFromEvent(payload, otherUserID, eventType);
    } else if (eventType.contains('.delete')) {
      // Handle message deletion if necessary
    }
  }

  /// Adds or updates a conversation based on real-time events
  Future<void> addOrUpdateConversationFromEvent(
      Map<String, dynamic> data, String otherUserID, String eventType) async {
    String? datetimeString = data['\$createdAt']; // Use 'createdAt' field
    DateTime messageTime = _parseDatetime(datetimeString);
    bool isImage = data['Image'] ?? false;
    String lastMessage;
    if (isImage) {
      lastMessage = 'Foto';
    } else {
      lastMessage = data['Text'] ?? '';
    }

    bool isUnread = data['isRead'] == false && data['SenderID'] == otherUserID;

    // Get the other user's name and avatar
    String name = await getUserName(otherUserID);
    String? avatarUrl = await getUserAvatarUrl(otherUserID);

    // Check if the conversation already exists in the list
    int index = conversations.indexWhere((conv) => conv.id == otherUserID);

    if (index != -1) {
      ChatConversation existingConv = conversations[index];
      if (eventType.contains('.create')) {
        // New message created
        setState(() {
          conversations[index] = ChatConversation(
            id: otherUserID,
            name: name,
            lastMessage: lastMessage,
            lastMessageTime: messageTime,
            avatarUrl: avatarUrl,
            isImage: isImage,
            unreadCount: isUnread
                ? existingConv.unreadCount + 1
                : existingConv.unreadCount,
          );
        });
      } else if (eventType.contains('.update')) {
        // Message updated (likely marked as read)
        if (data['isRead'] == true && data['SenderID'] == otherUserID) {
          setState(() {
            conversations[index] = ChatConversation(
              id: otherUserID,
              name: name,
              lastMessage: lastMessage,
              lastMessageTime: messageTime,
              avatarUrl: avatarUrl,
              isImage: isImage,
              unreadCount: existingConv.unreadCount > 0
                  ? existingConv.unreadCount - 1
                  : 0,
            );
          });
        } else if (isUnread) {
          // New unread message via update (rare case)
          setState(() {
            conversations[index] = ChatConversation(
              id: otherUserID,
              name: name,
              lastMessage: lastMessage,
              lastMessageTime: messageTime,
              avatarUrl: avatarUrl,
              isImage: isImage,
              unreadCount: existingConv.unreadCount + 1,
            );
          });
        }
      }
    } else {
      // Add new conversation
      setState(() {
        conversations.add(ChatConversation(
          id: otherUserID,
          name: name,
          lastMessage: lastMessage,
          lastMessageTime: messageTime,
          avatarUrl: avatarUrl,
          isImage: isImage,
          unreadCount: isUnread ? 1 : 0,
        ));
      });
    }

    // Sort the conversations by lastMessageTime descending, then by name
    setState(() {
      conversations.sort((a, b) {
        if (a.lastMessageTime.isAfter(b.lastMessageTime)) {
          return -1;
        } else if (a.lastMessageTime.isBefore(b.lastMessageTime)) {
          return 1;
        } else {
          return a.name.compareTo(b.name);
        }
      });
    });
  }

  /// Gets the user's name from the database
  Future<String> getUserName(String userID) async {
    try {
      final response = await databases.getDocument(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.usercollectionId,
        documentId: userID,
      );
      return response.data['Name'] ?? 'Unknown';
    } catch (e) {
      print('Error fetching user name: $e');
      return 'Unknown';
    }
  }

  /// Gets the user's avatar URL from the database
  Future<String?> getUserAvatarUrl(String userID) async {
    try {
      final response = await databases.getDocument(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.usercollectionId,
        documentId: userID,
      );
      return response.data['avatarUrl'];
    } catch (e) {
      print('Error fetching user avatar: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Display loading indicator while fetching data
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Display error message if any
    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
        ),
        body: Center(child: Text(errorMessage!)),
      );
    }

    int _selectedIndex = 0;

    final List<String> items = [
      'All',
      'Personal',
      'Design',
      'Work',
      'Favourites',
      'test',
      'test',
      'test',
    ];

    // Display list of chat conversations or users
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Row(
              children: [
                const Text(
                  "Chats",
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.search,
                  size: 50,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Container(
                          width: 460,
                          height: 60,
                          decoration: BoxDecoration(
                            color:
                                AppColors.inactiveIconColor.withOpacity(0.35),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(30),
                              bottomLeft: Radius.circular(30),
                            ),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection:
                                Axis.horizontal, // Enable horizontal scrolling
                            child: Row(
                              children: List.generate(items.length, (index) {
                                final isSelected = _selectedIndex == index;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedIndex =
                                          index; // Update selected index
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 14), // Add left padding
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 15,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors
                                                .white // White background for selected item
                                            : Colors
                                                .transparent, // No background for unselected
                                        borderRadius: BorderRadius.circular(
                                            20), // Rounded container
                                      ),
                                      child: Text(
                                        items[index],
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors
                                                  .black // Black text for selected item
                                              : const Color.fromARGB(255, 141, 141,
                                                  141), // Grey text for unselected
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      return ChatListItem(
                        conversation: conversations[index],
                        currentUserID: widget.currentUserID,
                        client: widget.client,
                        hasConversation:
                            conversations[index].lastMessage.isNotEmpty,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ChatListItem: Represents a single chat conversation or user in the list
class ChatListItem extends StatelessWidget {
  final ChatConversation conversation;
  final String currentUserID;
  final Client client;
  final bool hasConversation;

  const ChatListItem({
    super.key,
    required this.conversation,
    required this.currentUserID,
    required this.client,
    required this.hasConversation,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.only(right: 30, left: 30, top: 30),
        child: SizedBox(
          width: 500,
          height: 76,
          child: Row(
            children: [
              conversation.avatarUrl != null
                  ? CircleAvatar(
                      radius: 38,
                      backgroundImage: NetworkImage(conversation.avatarUrl!),
                    )
                  : CircleAvatar(
                      radius: 38,
                      child: Text(
                        conversation.name.isNotEmpty
                            ? conversation.name[0]
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 21,
                        ),
                      ),
                    ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasConversation)
                        conversation.isImage
                            ? const Row(
                                children: [
                                  Icon(Icons.camera_alt, size: 16),
                                  SizedBox(width: 4),
                                  Text('Foto'),
                                ],
                              )
                            : Text(
                                conversation.lastMessage,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (hasConversation)
                      Text(
                        formatLastMessageTime(conversation.lastMessageTime),
                        style: const TextStyle(
                            color: AppColors.inactiveIconColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800),
                      ),
                    if (conversation.unreadCount > 0)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${conversation.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InsideChat(
              client: client,
              userID: currentUserID,
              receiverID: conversation.id,
              receiverName: conversation.name,
            ),
          ),
        );
      },
    );
  }
}

/// ChatConversation: Model representing a chat conversation or user
class ChatConversation {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String? avatarUrl;
  final bool isImage;
  final int unreadCount; // Unread messages count

  ChatConversation({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.lastMessageTime,
    this.avatarUrl,
    required this.isImage,
    this.unreadCount = 0, // Defaults to 0
  });
}

/// Formats the last message time into a user-friendly string
String formatLastMessageTime(DateTime messageTime) {
  final now = DateTime.now();
  final difference = now.difference(messageTime);
  print('Now: $now, messageTime: $messageTime, difference: $difference');

  if (difference.isNegative) {
    // If messageTime is in the future, treat it as "Now"
    return 'Now';
  }

  if (difference.inSeconds < 60) {
    return 'Now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} min';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} h';
  } else if (difference.inDays == 1) {
    return 'Yesterday';
  } else {
    return '${messageTime.day.toString().padLeft(2, '0')}.${messageTime.month.toString().padLeft(2, '0')}';
  }
}
