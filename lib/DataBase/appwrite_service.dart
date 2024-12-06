import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:baustellenapp/DataBase/appwrite_constant.dart';

class AppwriteService {
  final Client client;
  late Databases databases;

  AppwriteService()
      : client = Client()
          ..setEndpoint(AppwriteConstants.endPoint)
          ..setProject(AppwriteConstants.projectId) {
    databases = Databases(client);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.usercollectionId,
        queries: [Query.equal('Email', email)],
      );

      if (response.documents.isEmpty) {
        throw Exception('Benutzer nicht gefunden.');
      }

      // Extract the first matching user document
      final Document userDoc = response.documents.first;

      // Return the user document and its ID
      return {
        'userDoc': userDoc,
        'userID': userDoc.$id, // Extract the user ID
      };
    } catch (e) {
      throw Exception('Fehler beim Anmelden: ${e.toString()}');
    }
  }
}
