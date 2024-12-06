import 'package:baustellenapp/Constants/colors.dart';
import 'package:baustellenapp/DataBase/appwrite_constant.dart';
import 'package:baustellenapp/Screens/ProjectDetails/Mobile/project_details.dart';
import 'package:baustellenapp/Widgets/trapezium_clippers.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';

Client client = Client()
  ..setEndpoint(AppwriteConstants.endPoint) // Your Appwrite API endpoint
  ..setProject(AppwriteConstants.projectId); // Your project ID

Databases databases = Databases(client); // Initialize the Appwrite database service

class Overview extends StatefulWidget {
  final Client client;
  final String userID;

  const Overview({
    super.key,
    required this.client,
    required this.userID,
  });

  @override
  // ignore: library_private_types_in_public_api
  _OverviewState createState() => _OverviewState();
}

class _OverviewState extends State<Overview> {
  late Databases databases;
  late Future<List<Map<String, String>>> projectNames;
  String userAddress = '';
  

  @override
  void initState() {
    super.initState();
    databases = Databases(widget.client);
    _initializeData();
  }

  Future<void> _initializeData() async {
    await fetchUserAddress(); // Ensure userAddress is fetched
    setState(() {
      projectNames = fetchProjectNames(); // Now fetch project names
    });
  }

  Future<void> fetchUserAddress() async {
    try {
      final response = await databases.getDocument(
        databaseId: AppwriteConstants.dbId,
        collectionId: AppwriteConstants.usercollectionId,
        documentId: widget.userID,
      );
      setState(() {
        userAddress = response.data['Adresse'] ?? '';
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching user address: $e');
    }
  }

  Future<List<Map<String, String>>> fetchProjectNames() async {
  try {
    final response = await databases.listDocuments(
      databaseId: AppwriteConstants.dbId,
      collectionId: AppwriteConstants.baustellenoverviewCollectionId,
    );

    List<Map<String, String>> projects = [];
    for (var doc in response.documents) {
      String name = doc.data['Name'] ?? 'Unknown';
      String address = doc.data['Adress'] ?? 'No Address';
      String projectLeader = doc.data['Projektleiter'] ?? 'Unknown';
      String? imageID = doc.data['ImageID']; // Assuming ImageID exists in the collection

      // Construct the image URL if ImageID is available
      String imageUrl = imageID != null
          ? 'https://cloud.appwrite.io/v1/storage/buckets/${AppwriteConstants.storageBucketId}/files/$imageID/view?project=${AppwriteConstants.projectId}'
          : 'https://via.placeholder.com/150'; // Fallback URL

      projects.add({
        'name': name,
        'address': address,
        'projectLeader': projectLeader,
        'id': doc.$id,
        'imageUrl': imageUrl, // Add the image URL
      });
    }
    return projects;
  } catch (e) {
    print('Error fetching project names: $e');
    return [];
  }
}

  String normalizeAddress(String address) {
    return address
        .replaceAll('ß', 'ss')
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: FutureBuilder<List<Map<String, String>>>(
        future: projectNames,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final projects = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(
                      left: 40.0, right: 44.0, top: 38.0, bottom: 16.0),
                  child: Row(
                    children: [
                      Text(
                        "Hello!",
                        style: TextStyle(
                          color: AppColors.mainColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                      Spacer(),
                      Text(
                        "Project Overview",
                        style: TextStyle(
                          color: AppColors.spezialColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1.5,
                  color: Colors.black,
                ),
                projects.isEmpty
                    ? const Center(child: Text('No projects available'))
                    : ListView.builder(
  physics: const NeverScrollableScrollPhysics(),
  shrinkWrap: true,
  itemCount: projects.length,
  itemBuilder: (context, index) {
    bool isEven = index % 2 == 0;
    return GestureDetector(
      onTap: () async {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetail(
              projectName: projects[index]['name'] ?? 'Unknown',
              projectAdress: projects[index]['address'] ?? 'Unknown',
              currentBaustelleId: projects[index]['id'] ?? 'Unknown',
              userID: widget.userID,
            ),
          ),
        );
      },
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(width: 1.5, color: Colors.black),
            left: BorderSide(width: 1.5, color: Colors.black),
            right: BorderSide(width: 1.5, color: Colors.black),
          ),
        ),
        child: Column(
          children: isEven
              ? [
                  Stack(
                    children: <Widget>[
                      SizedBox(
                        height: 136, // Fixed height for consistent sizing
                        width: double.infinity, // Full width of the container
                        child: Image.network(
                          projects[index]['imageUrl'] ?? '',
                          fit: BoxFit.cover, // Ensures the image fully covers the box
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                        ),
                      ),
                      ClipPath(
                        clipper: TrapeziumClipper(),
                        child: Container(
                          color: AppColors.secondColor,
                          padding: const EdgeInsets.all(8.0),
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 140.0),
                                child: Text(
                                  projects[index]['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    color: AppColors.spezialColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w200,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 200.0),
                                child: Text(
                                  projects[index]['projectLeader'] ?? 'No Project Leader',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 210.0),
                                child: Text(
                                  projects[index]['address'] ?? 'No Address',
                                  style: const TextStyle(
                                    color: AppColors.inactiveIconColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ]
              : [
                  Stack(
  children: <Widget>[
    SizedBox(
      height: 136, // Fixed height for consistent sizing
      width: double.infinity, // Full width of the container
      child: Image.network(
        projects[index]['imageUrl'] ?? '',
        fit: BoxFit.cover, // Ensures the image fully covers the box
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
      ),
    ),
    ClipPath(
      clipper: TrapeziumClipper2(),
      child: Container(
        color: AppColors.secondColor,
        padding: const EdgeInsets.all(8.0),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 140.0),
              child: Text(
                projects[index]['name'] ?? 'Unknown',
                style: const TextStyle(
                  color: AppColors.spezialColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w200,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 200.0),
              child: Text(
                projects[index]['projectLeader'] ?? 'No Project Leader',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 210.0),
              child: Text(
                projects[index]['address'] ?? 'No Address',
                style: const TextStyle(
                  color: AppColors.inactiveIconColor,
                  fontSize: 14,
                ),
              ),
            ),
          ],
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

              ],
            ),
          );
        },
      ),
    );
  }
}
