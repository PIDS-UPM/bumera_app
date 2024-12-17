import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_drawer.dart';
import 'profile_page.dart';
import '../widgets/notification_dialog.dart';
import '../services/notification_service.dart';
import 'detailed_class_statistics.dart';

class HomePage extends StatelessWidget {
  final String email;
  final NotificationService notificationService = NotificationService();

  HomePage({required this.email, Key? key}) : super(key: key);

  Future<Map<String, dynamic>?> _fetchProfessorData(String email) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('teachers')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BUMERA',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xff6750a4),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return NotificationDialog(
                    notifications: notificationService.notifications,
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchProfessorData(email),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                'Error: No se encontraron datos del profesor.',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final professorData = snapshot.data!;
          final subjects = professorData['subjects'] as List<dynamic>;

          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '👋 Welcome, ${professorData['first_name']}!',
                  style: const TextStyle(
                    fontSize: 26.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff4e4e4e),
                  ),
                ),
                const SizedBox(height: 24.0),
                const Center(
                  child: Text(
                    '📚 Your Classes',
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff6750a4),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  child: ListView.builder(
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff6750a4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                              side: const BorderSide(
                                  color: Color(0xff4e4e4e), width: 1),
                            ),
                            elevation: 5.0,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailedClassStatisticsPage(
                                  classId: subject['class_id'],
                                  subjectName: subject['name'],
                                ),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${subject['emoji'] ?? ''} ',
                                style: const TextStyle(fontSize: 22.0),
                              ),
                              Text(
                                '${subject['name']} (${subject['class_id']})',
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
