import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class DetailedClassStatisticsPage extends StatefulWidget {
  final String classId;
  final String subjectName;

  const DetailedClassStatisticsPage({
    Key? key,
    required this.classId,
    required this.subjectName,
  }) : super(key: key);

  @override
  _DetailedClassStatisticsPageState createState() =>
      _DetailedClassStatisticsPageState();
}

class _DetailedClassStatisticsPageState
    extends State<DetailedClassStatisticsPage> {
  late Future<Map<String, dynamic>> _emotionDataFuture;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _startDate = DateTime.now().subtract(const Duration(days: 7));
    _endDate = DateTime.now();

    _startDateController.text = DateFormat('yyyy-MM-dd').format(_startDate!);
    _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate!);

    _emotionDataFuture = _fetchAndProcessEmotionsData();
  }

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

  Future<Map<String, dynamic>> _fetchAndProcessEmotionsData() async {
    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
        .collection('emotions')
        .where('id_class', isEqualTo: widget.classId)
        .where('subjects', isEqualTo: widget.subjectName)
        .where('context', isEqualTo: 'in_class')
        .get();

    List<EmotionWithDate> emotionData = [];
    Map<String, Map<String, int>> groupedData = {};
    Set<String> allDates = {};

    const validEmotions = ['attention', 'frustration', 'bored', 'distracted'];

    for (var doc in snapshot.docs) {
      String emotion = doc['emotion'];
      String date = _extractDate(doc['timestamp']);

      if (validEmotions.contains(emotion)) {
        groupedData.putIfAbsent(emotion, () => {});
        groupedData[emotion]![date] = (groupedData[emotion]![date] ?? 0) + 1;
        allDates.add(date);
      }
    }

    groupedData.forEach((emotion, dateMap) {
      dateMap.forEach((date, frequency) {
        emotionData.add(EmotionWithDate(emotion: emotion, date: date, frequency: frequency));
      });
    });

    Map<String, Color> emotionColors = {
      'attention': Colors.green,
      'frustration': Colors.red,
      'bored': Colors.orange,
      'distracted': Colors.blue,
    };

    return {
      'emotionData': emotionData,
      'allDates': allDates,
      'emotionColors': emotionColors,
    };
  }

  String _extractDate(String timestamp) {
    return timestamp.split(' ')[0];
  }

  List<LineSeries<EmotionWithDate, String>> _generateEmotionSeries(
    List<EmotionWithDate> emotionData,
    Map<String, Color> emotionColors,
    Set<String> allDates) {
  List<LineSeries<EmotionWithDate, String>> emotionSeries = [];

  emotionColors.forEach((emotion, color) {
    List<EmotionWithDate> dataForEmotion = emotionData
        .where((item) {
          final itemDate = DateTime.parse(item.date);
          return item.emotion == emotion &&
              (_startDate == null || itemDate.isAfter(_startDate!.subtract(const Duration(days: 1)))) &&
              (_endDate == null || itemDate.isBefore(_endDate!.add(const Duration(days: 1))));
        })
        .toList();

    Set<String> existingDates = dataForEmotion.map((e) => e.date).toSet();

    for (String date in allDates.difference(existingDates)) {
      final dateAsDateTime = DateTime.parse(date);
      if ((_startDate == null || dateAsDateTime.isAfter(_startDate!.subtract(const Duration(days: 1)))) &&
          (_endDate == null || dateAsDateTime.isBefore(_endDate!.add(const Duration(days: 1))))) {
        dataForEmotion.add(EmotionWithDate(
          emotion: emotion,
          date: date,
          frequency: 0,
        ));
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
      isVisible: emotion == "attention",
    ));
  });

  return emotionSeries;
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subjectName} Statistics', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xff6750a4),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white, 
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
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
                const SizedBox(width: 16),
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
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _emotionDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!['emotionData'].isEmpty) {
                  return const Center(child: Text('No data available'));
                }

                final emotionData = snapshot.data!['emotionData'] as List<EmotionWithDate>;
                final emotionColors = snapshot.data!['emotionColors'] as Map<String, Color>;
                final allDates = snapshot.data!['allDates'] as Set<String>;

                final List<LineSeries<EmotionWithDate, String>> emotionSeries =
                    _generateEmotionSeries(emotionData, emotionColors, allDates);

                return SfCartesianChart(
                  primaryXAxis: CategoryAxis(
                    labelRotation: -45,
                  ),
                  primaryYAxis: NumericAxis(
                    minimum: 0,
                    interval: 1,
                    labelFormat: '{value}',
                  ),
                  title: ChartTitle(text: 'Emotions Over Time'),
                  legend: Legend(isVisible: true),
                  tooltipBehavior: TooltipBehavior(enable: true),
                  series: emotionSeries,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EmotionWithDate {
  final String emotion;
  final String date;
  final int frequency;

  EmotionWithDate({
    required this.emotion,
    required this.date,
    required this.frequency,
  });
}
