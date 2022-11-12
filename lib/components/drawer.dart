import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 32, 0, 0),
        children: [
          ListTile(
            title: const Text("Home"),
            onTap: () {
              Navigator.pushNamed(context, "/");
            },
          ),
          ListTile(
            title: const Text("Broadcast"),
            onTap: () {
              Navigator.pushNamed(context, "/broadcast");
            }
          ),
          ListTile(
            title: const Text("Debug Info"),
            onTap: () {
              Navigator.pushNamed(context, "/debug");
            }
          )
        ],
      )
    );
  }
}
