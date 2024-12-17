import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detailed_incidence.dart';
import 'add_incidence.dart';

class BullyingHistoryPage extends StatefulWidget {
  const BullyingHistoryPage({super.key});

  @override
  _BullyingHistoryPageState createState() => _BullyingHistoryPageState();
}

class _BullyingHistoryPageState extends State<BullyingHistoryPage> {
  final Stream<QuerySnapshot> incidentsStream =
      FirebaseFirestore.instance.collection('incidents').snapshots();

  String searchQuery = ""; 
  Map<String, String> teacherCache = {}; 
  Map<String, String> studentCache = {}; 

  Future<String> getTeacherName(String teacherId) async {
    if (teacherId.isEmpty) return "Not available";
    if (teacherCache.containsKey(teacherId)) return teacherCache[teacherId]!;
    DocumentSnapshot teacherSnapshot = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(teacherId)
        .get();
    Map<String, dynamic>? data =
        teacherSnapshot.data() as Map<String, dynamic>?;
    String name = data != null
        ? '${data['first_name']} ${data['last_name']}'
        : "Not available";
    teacherCache[teacherId] = name; 
    return name;
  }

  Future<List<String>> getStudentNames(List<dynamic> studentIds) async {
    List<String> names = [];
    for (String studentId in studentIds) {
      if (studentCache.containsKey(studentId)) {
        names.add(studentCache[studentId]!);
      } else {
        DocumentSnapshot studentSnapshot = await FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .get();
        Map<String, dynamic>? data =
            studentSnapshot.data() as Map<String, dynamic>?;
        if (data != null) {
          String name = '${data['first_name']} ${data['last_name']}';
          studentCache[studentId] = name; 
          names.add(name);
        }
      }
    }
    return names;
  }

  Future<List<QueryDocumentSnapshot>> _filterDocuments(
      List<QueryDocumentSnapshot> documents) async {
    List<QueryDocumentSnapshot> filteredDocs = [];

    for (var document in documents) {
      Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
      String description = (data['description'] ?? '').toLowerCase();
      String teacherName = await getTeacherName(data['teacher_id'] ?? "");
      List<String> studentNames = await getStudentNames(data['student_ids'] ?? []);

      if (description.contains(searchQuery) ||
          teacherName.toLowerCase().contains(searchQuery) ||
          studentNames.any((name) => name.toLowerCase().contains(searchQuery))) {
        filteredDocs.add(document);
      }
    }

    return filteredDocs;
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text(
        'Bullying History',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: const Color(0xff6750a4),
      iconTheme: const IconThemeData(color: Colors.white), 
    ),
    body: Column(
      children: [
        // Campo de búsqueda
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search incidents...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: incidentsStream,
            builder: (BuildContext context,
                AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading data.'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              return FutureBuilder<List<QueryDocumentSnapshot>>(
                future: _filterDocuments(snapshot.data!.docs),
                builder: (context, asyncSnapshot) {
                  if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (asyncSnapshot.hasError) {
                    return const Center(child: Text('Error processing data.'));
                  }

                  var filteredDocs = asyncSnapshot.data ?? [];

                  return Scrollbar(
                    thumbVisibility: true, 
                    child: ListView.builder(
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> data =
                            filteredDocs[index].data()! as Map<String, dynamic>;

                        return FutureBuilder(
                          future: Future.wait([
                            getTeacherName(data['teacher_id'] ?? ""),
                            getStudentNames(data['student_ids'] ?? [])
                          ]),
                          builder:
                              (context, AsyncSnapshot<List<dynamic>> snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            String teacherName = snapshot.data![0];
                            List<String> studentNames =
                                List<String>.from(snapshot.data![1]);

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  data['description'] ?? 'No description',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      'Assigned Teacher: $teacherName',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Students: ${studentNames.join(", ")}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    color: Color(0xff6750a4)),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => IncidentDetailPage(
                                        incidentId: filteredDocs[index].id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      backgroundColor: const Color(0xff6750a4),
      child: const Icon(Icons.add, color: Colors.white), 
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddIncidencePage(),
          ),
        );
      },
    ),
  );
}

}
