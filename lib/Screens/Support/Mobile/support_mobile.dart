import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Support extends StatelessWidget {
  const Support({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE3E3E3),
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Color(0xFFE3E3E3),
        centerTitle: true,
        title: Text(
          "Support",
          style:
              TextStyle(color: Color(0xFFCDB38B), fontWeight: FontWeight.bold),
        ),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              bottom: 60.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.support_agent,
                  size: 160,
                  color: Color(0xFF551A8B),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Brauchen Sie Hilfe?",
                    style: TextStyle(
                        fontSize: 24,
                        color: Color(0xFFCDB38B),
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  "Kontaktieren Sie uns!",
                  style: TextStyle(
                      fontSize: 24,
                      color: Color(0xFFCDB38B),
                      fontWeight: FontWeight.bold),
                ),
                Spacer(),
                SizedBox(
                  width: 400,
                  height: 494,
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                    child: Column(
                      children: [
                        _containerList(
                            "Adresse", "Soufianstr. 187", Icons.location_on),
                        Padding(
                          padding: const EdgeInsets.all(7.5),
                          child: Container(
                            width: 337,
                            height: 1,
                            color: Color.fromARGB(255, 203, 198, 209),
                          ),
                        ),
                        _containerList(
                            "Telefonnummer", "012-3456-789", Icons.phone),
                        Padding(
                          padding: const EdgeInsets.all(7.5),
                          child: Container(
                            width: 337,
                            height: 1,
                            color: Color.fromARGB(255, 203, 198, 209),
                          ),
                        ),
                        _containerList(
                            "Email", "Soufian@omarnuh.seyfu", Icons.email),
                        Padding(
                          padding: const EdgeInsets.all(7.5),
                          child: Container(
                            width: 337,
                            height: 1,
                            color: Color.fromARGB(255, 203, 198, 209),
                          ),
                        ),
                        _containerList2("AGB", Icons.newspaper,
                            Icons.arrow_forward_ios_outlined),
                        Padding(
                          padding: const EdgeInsets.all(7.5),
                          child: Container(
                            width: 337,
                            height: 1,
                            color: Color.fromARGB(255, 203, 198, 209),
                          ),
                        ),
                        _containerList2("Impressum", Icons.newspaper,
                            Icons.arrow_forward_ios_outlined),
                        Padding(
                          padding: const EdgeInsets.all(7.5),
                          child: Container(
                            width: 337,
                            height: 1,
                            color: Color.fromARGB(255, 203, 198, 209),
                          ),
                        ),
                        _containerList2("Datenschutz Erklärung",
                            Icons.newspaper, Icons.arrow_forward_ios_outlined),
                        Padding(
                          padding: const EdgeInsets.all(7.5),
                          child: Container(
                            width: 337,
                            height: 1,
                            color: Color.fromARGB(255, 203, 198, 209),
                          ),
                        ),
                        _containerList2("App Richtlinien", Icons.newspaper,
                            Icons.arrow_forward_ios_outlined),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _containerList(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic),
      ),
      leading: Icon(
        icon,
        color: Color(0xFF551A8B),
      ),
    );
  }

  Widget _containerList2(
    String title,
    IconData icon,
    IconData trailing,
  ) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      leading: Icon(
        icon,
        color: Color(0xFF551A8B),
      ),
      trailing: Icon(trailing),
    );
  }
}