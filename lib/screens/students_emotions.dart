import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detailed_emotions.dart';

class StudentsEmotions extends StatefulWidget {
  const StudentsEmotions({super.key});

  @override
  _StudentsEmotionsState createState() => _StudentsEmotionsState();
}

class _StudentsEmotionsState extends State<StudentsEmotions> {
  // Controlador para el texto del buscador
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = ''; // Variable para almacenar la consulta de búsqueda

  // Obtener el nombre completo del estudiante
  Future<String> getStudentName(String studentId) async {
    DocumentSnapshot studentSnapshot = await FirebaseFirestore.instance
        .collection('students')
        .doc(studentId)
        .get();

    if (studentSnapshot.exists) {
      Map<String, dynamic> data = studentSnapshot.data() as Map<String, dynamic>;
      return '${data['first_name']} ${data['last_name']}';
    } else {
      return 'Unknown Student';
    }
  }

  List<DocumentSnapshot> _filterStudents(List<DocumentSnapshot> students) {
    if (_searchQuery.isEmpty) {
      return students;
    } else {
      return students.where((student) {
        String fullName = '${student['first_name']} ${student['last_name']}';
        return fullName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Students Emotions',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xff6750a4),
        iconTheme: const IconThemeData(color: Colors.white), // White back arrow
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('students').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching data'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No students data available'));
          }

          final studentsData = snapshot.data!.docs;

          final filteredStudents = _filterStudents(studentsData);

          filteredStudents.sort((a, b) {
            String lastNameA = a['last_name'].toLowerCase();
            String lastNameB = b['last_name'].toLowerCase();
            return lastNameA.compareTo(lastNameB);
          });

          return ListView.builder(
            itemCount: filteredStudents.length,
            itemBuilder: (context, index) {
              final studentData = filteredStudents[index];
              final studentId = studentData.id; // El ID del documento es el DNI del estudiante

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                elevation: 5, // Sombras para darle profundidad
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0), // Bordes redondeados
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  title: FutureBuilder(
                    future: getStudentName(studentId), // Obtener el nombre completo usando el DNI (ID del documento)
                    builder: (context, AsyncSnapshot<String> snapshot) {
                      if (!snapshot.hasData) {
                        return const Text(
                          'Loading...',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        );
                      }

                      final studentName = snapshot.data!;
                      return Row(
                        children: [
                          Text(
                            studentName,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color.fromARGB(255, 4, 4, 4),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  trailing: Icon(
                    Icons.arrow_forward,
                    color: const Color(0xff6750a4),
                  ),
                  onTap: () {
                    // Al hacer clic, pasamos el studentId (que es el DNI) a la siguiente página
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailedEmotionsPage(
                          studentDni: studentId, 
                          studentName: studentData['first_name'], 
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
  }
}
