import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  // Función para obtener los datos del usuario desde Firestore
  Future<Map<String, dynamic>?> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser; // Usuario autenticado
    if (user == null) return null;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('teachers') // Cambia a la colección correspondiente
        .where('email', isEqualTo: user.email)
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
          'User Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff6750a4),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                'Error: User data not found.',
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            );
          }

          final userData = snapshot.data!;
          final isTutor = userData['is_tutor'] ?? false;
          final tutorClass = userData['tutor_class_id'] ?? 'No class assigned';
          final subjects = userData['subjects'] as List<dynamic>? ?? [];

          final role = isTutor ? 'Tutor' : 'Teacher';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xff6750a4),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${userData['first_name']} ${userData['last_name']}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff4e4e4e),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    role,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff6750a4),
                    ),
                  ),
                  if (isTutor)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Tutor of Class: $tutorClass',
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),

                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Email:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff4e4e4e),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            userData['email'] ?? 'No email found',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Subjects:',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff4e4e4e),
                    ),
                  ),
                  const SizedBox(height: 10),
                  subjects.isEmpty
                      ? const Text(
                          'No subjects assigned.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: subjects.length,
                          itemBuilder: (context, index) {
                            final subject = subjects[index] as Map<String, dynamic>;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              elevation: 3,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16.0),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xff6750a4),
                                  child: Text(
                                    subject['name'][0], 
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  subject['name'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Class ID: ${subject['class_id']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
