import 'package:flutter/material.dart';
import '../screens/bullying_history.dart';
import '../screens/students_emotions.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xff6750a4),
            ),
            child: Text(
              'Options',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('HOME'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.face),
            title: const Text('Students emotions'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentsEmotions(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.pan_tool),
            title: const Text('Bullying incidents'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BullyingHistoryPage(),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
