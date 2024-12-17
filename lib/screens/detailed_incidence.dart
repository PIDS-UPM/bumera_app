import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentDetailPage extends StatelessWidget {
  final String incidentId;

  const IncidentDetailPage({super.key, required this.incidentId});

  Future<Map<String, dynamic>> fetchIncidentDetails() async {
    DocumentSnapshot incidentSnapshot = await FirebaseFirestore.instance
        .collection('incidents')
        .doc(incidentId)
        .get();
    return incidentSnapshot.data()! as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchTeacherDetails(String teacherId) async {
    if (teacherId.isEmpty) return {};
    DocumentSnapshot teacherSnapshot = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(teacherId)
        .get();
    return teacherSnapshot.data()! as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchStudentDetails(
      List<dynamic> studentIds) async {
    List<Map<String, dynamic>> students = [];
    for (String studentId in studentIds) {
      DocumentSnapshot studentSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .get();
      Map<String, dynamic>? studentData =
          studentSnapshot.data() as Map<String, dynamic>?;
      if (studentData != null) {
        students.add(studentData);
      }
    }
    return students;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Incident Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xff6750a4),
        iconTheme: const IconThemeData(color: Colors.white), 
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchIncidentDetails(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          Map<String, dynamic> data = snapshot.data!;
          String teacherId = data['teacher_id'] ?? '';
          List<dynamic> studentIds = data['student_ids'] ?? [];

          return FutureBuilder(
            future: Future.wait([
              fetchTeacherDetails(teacherId),
              fetchStudentDetails(studentIds),
            ]),
            builder: (context,
                AsyncSnapshot<List<dynamic>> teacherAndStudentsSnapshot) {
              if (!teacherAndStudentsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              Map<String, dynamic> teacherData =
                  teacherAndStudentsSnapshot.data![0] as Map<String, dynamic>;
              List<Map<String, dynamic>> studentDataList =
                  teacherAndStudentsSnapshot.data![1]
                      as List<Map<String, dynamic>>;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: screenWidth,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Description',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff6750a4)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                data['description'] ?? 'Not available',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Location: ${data['place_id'] ?? 'Not available'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Date: ${data['date'] ?? 'Not available'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      width: screenWidth,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Teacher Information',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff6750a4)),
                              ),
                              const SizedBox(height: 8),
                              if (teacherData.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Name: ${teacherData['first_name']} ${teacherData['last_name']}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Birth Date: ${teacherData['birth_date'] ?? 'Not available'}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                )
                              else
                                const Text('Not available'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      width: screenWidth,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Students Information',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff6750a4)),
                              ),
                              const SizedBox(height: 8),
                              ...studentDataList.map((studentData) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Name: ${studentData['first_name']} ${studentData['last_name']}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      Text(
                                        'Birth Date: ${studentData['birth_date'] ?? 'Not available'}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        'Class: ${studentData['class_id'] ?? 'Not available'}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const Divider(),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
