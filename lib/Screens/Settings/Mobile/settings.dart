import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:baustellenapp/Screens/Login/Mobile/login_mobile.dart';
import 'package:baustellenapp/Screens/Support/Mobile/support_mobile.dart';
import 'package:baustellenapp/Screens/UserCollection/Mobile/user_collection_mobile.dart';
import 'package:flutter/material.dart';
import 'package:baustellenapp/DataBase/appwrite_constant.dart';
import 'package:baustellenapp/Screens/ContactProfile/Mobile/contact_profile.dart';

class SettingsScreen extends StatefulWidget {
  final Document currentUserDocument;
  const SettingsScreen({super.key, required this.currentUserDocument});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Client client = Client();

  bool light = true;
  bool light2 = true;

  @override
  void initState() {
    super.initState();
    client
        .setEndpoint(AppwriteConstants.endPoint) // Replace with your Appwrite endpoint
        .setProject(AppwriteConstants.projectId); // Replace with your Project ID
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 58.0),
                child: Icon(Icons.account_circle, size: 98,),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 7.0, bottom: 3.0,),
                child: Text(widget.currentUserDocument.data["Name"],
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 22.0),
                child: Text(widget.currentUserDocument.data["Email"],
                  style: const TextStyle(
                      color: Color.fromARGB(255, 140, 138, 138),
                      fontWeight: FontWeight.w600
                  ),),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 42.0),
                child: SizedBox(
                  width: 120, height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContactProfile(userId: widget.currentUserDocument.$id),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      backgroundColor: Colors.black,
                    ),
                    child: const Text("Edit Profile",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: Padding(
                  padding: EdgeInsets.only(right: 258.0),
                  child: Text("Inventories",
                    style: TextStyle(
                        color: Color.fromARGB(255, 140, 138, 138),
                        fontWeight: FontWeight.w800,
                        fontSize: 13
                    ),),
                ),
              ),
              SizedBox(width: 380, height: 136,
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => UserCollectionScreen(isAdmin: true,)));
                        },
                        leading: const Icon(Icons.store),
                        title: const Padding(
                          padding: EdgeInsets.only(left: 3.0),
                          child: Text("Meine Mitarbeiter",
                            style: TextStyle(
                                fontWeight: FontWeight.w600
                            ),),
                        ),
                        trailing: const Icon(Icons.arrow_forward, color: Color.fromARGB(
                            255, 147, 146, 146),),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(7.5),
                        child: Container(
                          width: 337, height: 1, color: const Color.fromARGB(255, 203, 198, 209),
                        ),
                      ),
                      ListTile(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const Support()));
                        },
                        leading: const Icon(Icons.support),
                        title: const Padding(
                          padding: EdgeInsets.only(left: 6.0),
                          child: Text("Support",
                            style: TextStyle(
                                fontWeight: FontWeight.w600
                            ),),
                        ),
                        trailing: const Icon(Icons.arrow_forward, color: Color.fromARGB(
                            255, 147, 146, 146),),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0, top: 12.0,),
                child: Padding(
                  padding: EdgeInsets.only(right: 254.0),
                  child: Text("Preferences",
                    style: TextStyle(
                        color: Color.fromARGB(255, 140, 138, 138),
                        fontWeight: FontWeight.w800,
                        fontSize: 13
                    ),),
                ),
              ),
              SizedBox(width: 380, height: 280,
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        leading: const Icon(Icons.notification_add),
                        title: const Padding(
                          padding: EdgeInsets.only(left: 2.0),
                          child: Text("Push notifications",
                            style: TextStyle(
                                fontWeight: FontWeight.w600
                            ),),
                        ),
                        trailing: Switch(value: light, onChanged: (bool value) {
                          setState(() {
                            light = value;
                          });
                        },
                          activeColor: Colors.green,),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(7.5),
                        child: Container(
                          width: 337, height: 1, color: const Color.fromARGB(255, 203, 198, 209),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.face),
                        title: const Padding(
                          padding: EdgeInsets.only(left: 6.0),
                          child: Text("Face ID",
                            style: TextStyle(
                                fontWeight: FontWeight.w600
                            ),),
                        ),
                        trailing: Switch(value: light2, onChanged: (bool value) {
                          setState(() {
                            light2 = value;
                          });
                        },
                          activeColor: Colors.green,),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(7.5),
                        child: Container(
                          width: 337, height: 1, color: const Color.fromARGB(255, 203, 198, 209),
                        ),
                      ),
                      const ListTile(
                        leading: Icon(Icons.more),
                        title: Text("PIN Code",
                          style: TextStyle(
                              fontWeight: FontWeight.w600
                          ),),
                        trailing: Icon(Icons.arrow_forward, color: Color.fromARGB(
                            255, 147, 146, 146),),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(7.5),
                        child: Container(
                          width: 337, height: 1, color: const Color.fromARGB(255, 203, 198, 209),
                        ),
                      ),
                      ListTile(
                        onTap: logout,
                        leading: const Icon(Icons.door_back_door),
                        title: const Text("Logout",
                          style: TextStyle(
                              color: Color.fromARGB(255, 167, 23, 23),
                              fontWeight: FontWeight.w600
                          ),),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}