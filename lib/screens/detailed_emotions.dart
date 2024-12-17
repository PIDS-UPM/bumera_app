import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class DetailedEmotionsPage extends StatefulWidget {
  final String studentDni;
  final String studentName;

  DetailedEmotionsPage({Key? key, required this.studentDni, required this.studentName}) : super(key: key);

  @override
  _DetailedEmotionsPageState createState() => _DetailedEmotionsPageState();
}

class _DetailedEmotionsPageState extends State<DetailedEmotionsPage> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  // Obtener datos de emociones desde Firebase
  Future<List<Map<String, dynamic>>> getEmotionsForStudent(String studentDni) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('emotions')
        .where('student_id', isEqualTo: studentDni)
        .where('context', isEqualTo: 'general') 
        .get();

    List<Map<String, dynamic>> emotionsData = [];
    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      emotionsData.add({
        'emotion': data['emotion'],
        'timestamp': data['timestamp'], 
      });
    }
    return emotionsData;
  }

  // Procesar datos para agrupar emociones por fecha
  List<EmotionWithDate> processEmotionsData(List<Map<String, dynamic>> emotionsData) {
    const allowedEmotions = ['angry', 'disgust', 'fear', 'happy', 'sad', 'surprise', 'neutral'];
    Map<String, Map<String, int>> groupedData = {};
    Set<String> allDates = {};

    for (var data in emotionsData) {
      final date = DateFormat('yyyy-MM-dd').format(DateTime.parse(data['timestamp']));
      final emotion = data['emotion'];

      if (!allowedEmotions.contains(emotion)) continue;

      if (_startDate != null && _endDate != null) {
        DateTime timestamp = DateTime.parse(data['timestamp']);
        if (timestamp.isBefore(_startDate!) || timestamp.isAfter(_endDate!)) {
          continue;
        }
      }

      allDates.add(date);
      if (!groupedData.containsKey(date)) {
        groupedData[date] = {};
      }

      groupedData[date]![emotion] = (groupedData[date]![emotion] ?? 0) + 1;
    }

    for (String date in allDates) {
      if (!groupedData.containsKey(date)) {
        groupedData[date] = {};
      }
      for (String emotion in allowedEmotions) {
        groupedData[date]![emotion] = groupedData[date]![emotion] ?? 0;
      }
    }

    List<EmotionWithDate> emotionList = [];
    groupedData.forEach((date, emotions) {
      emotions.forEach((emotion, frequency) {
        emotionList.add(EmotionWithDate(
          emotion: emotion,
          date: date,
          frequency: frequency,
        ));
      });
    });

    emotionList.sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));
    return emotionList;
  }

  List<LineSeries<EmotionWithDate, String>> generateEmotionSeries(
      List<EmotionWithDate> emotionData, Map<String, Color> emotionColors, Set<String> allDates) {
    List<LineSeries<EmotionWithDate, String>> emotionSeries = [];

    emotionColors.forEach((emotion, color) {
      List<EmotionWithDate> dataForEmotion = emotionData
          .where((item) => item.emotion == emotion)
          .toList();
      if (dataForEmotion.isEmpty) {
        dataForEmotion = allDates.map((date) {
          return EmotionWithDate(emotion: emotion, date: date, frequency: 0);
        }).toList();
      } else {
        Set<String> existingDates = dataForEmotion.map((e) => e.date).toSet();
        for (String date in allDates.difference(existingDates)) {
          dataForEmotion.add(EmotionWithDate(emotion: emotion, date: date, frequency: 0));
        }
      }

      dataForEmotion.sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));

      emotionSeries.add(LineSeries<EmotionWithDate, String>(
        name: emotion,
        color: color,
        dataSource: dataForEmotion,
        xValueMapper: (EmotionWithDate data, _) => data.date,
        yValueMapper: (EmotionWithDate data, _) => data.frequency,
        markerSettings: const MarkerSettings(isVisible: true),
        isVisible: emotion == "happy",
      ));
    });

    return emotionSeries;
  }

  final Map<String, Color> emotionColors = {
    'happy': Colors.yellow,
    'sad': Colors.blue,
    'angry': Colors.red,
    'surprise': Colors.green,
    'fear': Colors.purple,
    'disgust': Colors.orange,
    'neutral': Colors.grey,
  };

  Future<void> _selectDateRange(BuildContext context) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _startDateController.text = DateFormat('yyyy-MM-dd').format(_startDate!);
        _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate!);
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _startDate = DateTime.now().subtract(const Duration(days: 7));
    _endDate = DateTime.now();

    _startDateController.text = DateFormat('yyyy-MM-dd').format(_startDate!);
    _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Emotions',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6750A4),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getEmotionsForStudent(widget.studentDni),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching data'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No emotions data available for this student.'));
          }

          final emotions = snapshot.data!;
          List<EmotionWithDate> emotionData = processEmotionsData(emotions);
          final Set<String> allDates = emotionData.map((e) => e.date).toSet();
          final List<LineSeries<EmotionWithDate, String>> emotionSeries =
              generateEmotionSeries(emotionData, emotionColors, allDates);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.studentName}'s emotions",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6750A4),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _startDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                        ),
                        onTap: () => _selectDateRange(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _endDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(),
                        ),
                        onTap: () => _selectDateRange(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SfCartesianChart(
                    title: ChartTitle(text: 'Frequency of Emotions'),
                    legend: Legend(
                      isVisible: true,
                      overflowMode: LegendItemOverflowMode.wrap,
                    ),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    primaryXAxis: CategoryAxis(),
                    primaryYAxis: NumericAxis(),
                    series: emotionSeries,
                  ),
                ),
                const Text('Please select the emotions to visualize'),
              ],
            ),
          );
        },
      ),
    );
  }
}

class EmotionWithDate {
  final String emotion;
  final String date;
  final int frequency;

  EmotionWithDate({required this.emotion, required this.date, required this.frequency});
}
