import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:baustellenapp/DataBase/appwrite_constant.dart';

class UserCollectionScreen extends StatefulWidget {
  final bool isAdmin;
  UserCollectionScreen({required this.isAdmin});

  @override
  _UserCollectionScreenState createState() => _UserCollectionScreenState();
}

class _UserCollectionScreenState extends State<UserCollectionScreen> {
  final Client client = Client();
  late final Databases databases;
  List<Document> userDocuments = [];
  bool isLoading = true;

  _UserCollectionScreenState() {
    databases = Databases(client);
  }

  @override
  void initState() {
    super.initState();
    client
        .setEndpoint(AppwriteConstants.endPoint) // Replace with your Appwrite endpoint
        .setProject(AppwriteConstants.projectId); // Replace with your Project ID
    if (widget.isAdmin) {
      fetchUserDocuments();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchUserDocuments() async {
    try {
      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.usercollectionId,
      );
      setState(() {
        userDocuments = response.documents;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          'Mitarbeiter',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.grey,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.deepPurple,
                strokeWidth: 3.0,
              ),
            )
          : !widget.isAdmin
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, size: 80, color: Colors.grey),
                      SizedBox(height: 20),
                      Text(
                        'Not enough rights to view this information.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : userDocuments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_circle, size: 80, color: Colors.grey),
                          SizedBox(height: 20),
                          Text(
                            'No users found.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListView.builder(
                        itemCount: userDocuments.length,
                        itemBuilder: (context, index) {
                          final userDocument = userDocuments[index];
                          return Card(
                            elevation: 3,
                            margin: EdgeInsets.symmetric(vertical: 16), // Increased vertical margin
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Row for person icon, name and phone
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.account_circle_outlined,
                                        size: 50,
                                        color: Colors.deepPurple,
                                      ),
                                      SizedBox(width: 12), // Space between icon and text
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              userDocument.data['Name'] ?? 'No Name',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 2), // Reduced space between name and phone
                                            Text(
                                              userDocument.data['Phone'] ?? 'No Phone',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16), // Space between the two rows
                                  // Row for location and email icons with text
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 24,
                                        color: Colors.deepPurple,
                                      ),
                                      SizedBox(width: 8), // Space between icon and text
                                      Expanded(
                                        child: Text(
                                          userDocument.data['Location'] ?? 'No Location',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 5), // Space between location and email
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.email,
                                        size: 24,
                                        color: Colors.deepPurple,
                                      ),
                                      SizedBox(width: 8), // Space between icon and text
                                      Expanded(
                                        child: Text(
                                          userDocument.data['Email'] ?? 'No Email',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}