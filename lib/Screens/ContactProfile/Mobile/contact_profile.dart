// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:baustellenapp/DataBase/appwrite_constant.dart';

class ContactProfile extends StatefulWidget {
  final String userId;
  const ContactProfile({super.key, required this.userId});

  @override
  State<ContactProfile> createState() => _CContactProfileState();
}

class _CContactProfileState extends State<ContactProfile> {
  final Client client = Client();
  late final Databases databases;
  bool isLoading = true;
  bool isEditing = false; // Bearbeitungsmodus-Status
  Document? currentUserDocument;

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nummerController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _geburtsortController = TextEditingController();
  final TextEditingController _spracheController = TextEditingController();
  final TextEditingController _qualifikationenController = TextEditingController();
  bool jobcenter = false;

  @override
  void initState() {
    super.initState();
    client
        .setEndpoint(AppwriteConstants.endPoint)
        .setProject(AppwriteConstants.projectId);
    databases = Databases(client);
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final response = await databases.getDocument(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.usercollectionId,
        documentId: widget.userId,
      );
      setState(() {
        currentUserDocument = response;
        _nameController.text = response.data['Name'] ?? '';
        _emailController.text = response.data['Email'] ?? '';
        _nummerController.text = response.data['Nummer'] ?? '';
        _birthdayController.text = response.data['Birthday'] ?? '';
        _geburtsortController.text = response.data['Geburtsort'] ?? '';
        _spracheController.text = response.data['Sprache'] ?? '';
        _qualifikationenController.text = response.data['Qualifikationen'] ?? '';
        jobcenter = response.data['Jobcenter'] ?? false;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data: $e')),
      );
    }
  }

  Future<void> saveUserData() async {
    try {
      await databases.updateDocument(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.usercollectionId,
        documentId: widget.userId,
        data: {
          'Name': _nameController.text,
          'Email': _emailController.text,
          'Nummer': _nummerController.text,
          'Birthday': _birthdayController.text,
          'Geburtsort': _geburtsortController.text,
          'Sprache': _spracheController.text,
          'Qualifikationen': _qualifikationenController.text,
          'Jobcenter': jobcenter,
        },
      );
      setState(() {
        isEditing = false; // Nach dem Speichern den Bearbeitungsmodus deaktivieren
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daten erfolgreich gespeichert')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern der Daten: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back_outlined, color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isEditing = !isEditing; // Umschalten zwischen Bearbeiten und Ansehen
              });
            },
            icon: Icon(
              isEditing ? Icons.check : Icons.edit,
              color: Colors.black,
            ),
          ),
          if (isEditing)
            IconButton(
              onPressed: saveUserData, // Speichern, wenn im Bearbeitungsmodus
              icon: const Icon(Icons.save, color: Colors.black),
            ),
        ],
        toolbarHeight: 50,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const Column(
                    children: [
                      Icon(
                        Icons.account_circle,
                        size: 140,
                        color: Color.fromARGB(255, 35, 83, 124),
                      ),
                    ],
                  ),
                  _buildTextField(_nameController, "Name", CupertinoIcons.person),
                  _buildTextField(_emailController, "Email", CupertinoIcons.mail),
                  _buildTextField(_nummerController, "Telefonnummer", CupertinoIcons.phone),
                  _buildTextField(_birthdayController, "Geburtstag", Icons.calendar_month),
                  _buildTextField(_geburtsortController, "Geburtsort", Icons.location_city_outlined),
                  _buildTextField(_spracheController, "Sprachen", Icons.language_outlined),
                  _buildTextField(_qualifikationenController, "Qualifikationen", Icons.leaderboard_outlined),
                  SwitchListTile(
                    title: const Text('Jobcenter'),
                    value: jobcenter,
                    onChanged: isEditing ? (bool value) {
                      setState(() {
                        jobcenter = value;
                      });
                    } : null, // Nur änderbar im Bearbeitungsmodus
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        readOnly: !isEditing, // Nur änderbar, wenn im Bearbeitungsmodus
      ),
    );
  }
}