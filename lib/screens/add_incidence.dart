import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddIncidencePage extends StatefulWidget {
  const AddIncidencePage({Key? key}) : super(key: key);

  @override
  _AddIncidencePageState createState() => _AddIncidencePageState();
}

class _AddIncidencePageState extends State<AddIncidencePage> {
  final _formKey = GlobalKey<FormState>();
  String? selectedTeacher;
  List<String> selectedStudents = [];
  String? selectedPlace;
  DateTime? selectedDate;
  String? description;

  String? errorMessage;

  Future<List<Map<String, dynamic>>> _getTeachers() async {
    try {
      final teachers =
          await FirebaseFirestore.instance.collection('teachers').get();
      return teachers.docs.map((doc) {
        final teachersData = doc.data();
        return {
          'id': doc.id,
          'name':
              '${teachersData['first_name'] ?? ''} ${teachersData['last_name'] ?? ''}'
                  .trim()
        };
      }).toList();
    } catch (e) {
      print('Error fetching teachers: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getStudents() async {
    try {
      final students =
          await FirebaseFirestore.instance.collection('students').get();
      return students.docs.map((doc) {
        final studentsData = doc.data();
        return {
          'id': doc.id,
          'name':
              '${studentsData['first_name'] ?? ''} ${studentsData['last_name'] ?? ''}'
                  .trim()
        };
      }).toList();
    } catch (e) {
      print('Error fetching students: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getPlaces() async {
    try {
      final places =
          await FirebaseFirestore.instance.collection('places').get();
      return places.docs.map((doc) {
        final placesData = doc.data();
        return {'id': doc.id, 'name': placesData['name'] ?? ''};
      }).toList();
    } catch (e) {
      print('Error fetching places: $e');
      return [];
    }
  }

  Future<void> _saveIncidence() async {
    if (_formKey.currentState!.validate() &&
        selectedTeacher != null &&
        selectedStudents.isNotEmpty &&
        selectedPlace != null &&
        selectedDate != null) {
      _formKey.currentState!.save();
      setState(() {
        errorMessage = null;
      });

      try {
        await FirebaseFirestore.instance.collection('incidents').add({
          'teacher_id': selectedTeacher,
          'student_ids': selectedStudents,
          'place_id': selectedPlace,
          'date': selectedDate?.toIso8601String(),
          'description': description,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident added successfully!')),
        );

        Navigator.pop(context);
      } catch (e) {
        print('Error saving incident: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add incident.')),
        );
      }
    } else {
      setState(() {
        errorMessage = 'Please fill out all fields before saving.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Incident'),
        backgroundColor: const Color(0xff6750a4),
        foregroundColor: Colors.white, 
      ),
      body: FutureBuilder<List<List<Map<String, dynamic>>>>(
        future: Future.wait([
          _getTeachers(),
          _getStudents(),
          _getPlaces(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading data: ${snapshot.error}'));
          }

          final teachers = snapshot.data?[0] ?? [];
          final students = snapshot.data?[1] ?? [];
          final places = snapshot.data?[2] ?? [];

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: 'Select Teacher'),
                  value: selectedTeacher,
                  items: teachers.map((teacher) {
                    return DropdownMenuItem<String>(
                      value: teacher['id'],
                      child: Text(teacher['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedTeacher = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a teacher' : null,
                ),
                const SizedBox(height: 16),

                // Dropdown para añadir estudiantes
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Add Student'),
                  items: students.map((student) {
                    return DropdownMenuItem<String>(
                      value: student['id'],
                      child: Text(student['name'] ?? 'Unnamed'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        if (!selectedStudents.contains(value)) {
                          selectedStudents
                              .add(value); 
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8.0,
                  children: selectedStudents.map((studentId) {
                    final studentName = students.firstWhere(
                        (student) => student['id'] == studentId)['name'];
                    return Chip(
                      label: Text(studentName),
                      onDeleted: () {
                        setState(() {
                          selectedStudents.remove(
                              studentId);
                        });
                      },
                    );
                  }).toList(),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select Place'),
                  value: selectedPlace,
                  items: places.map((place) {
                    return DropdownMenuItem<String>(
                      value: place['id'],
                      child: Text(place['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPlace = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a place' : null,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(selectedDate == null
                      ? 'Select Date and Time'
                      : '${selectedDate!.toLocal()}'.split(' ')[0] +
                          ' ' +
                          TimeOfDay.fromDateTime(selectedDate!).format(context)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          selectedDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),

                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: null, 
                  minLines: 1, 
                  keyboardType: TextInputType.multiline, 
                  onChanged: (value) {
                    description = value; 
                  },
                  onSaved: (value) {
                    description = value; 
                  },
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a description'
                      : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saveIncidence,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff6750a4),
                  ),
                  child: const Text('Register Incident', style: TextStyle(color: Colors.white)),
                ),
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
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
