import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  final String kullaniciID;
  final String kullaniciAdi;

  HomePage({required this.kullaniciID, required this.kullaniciAdi});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ChartSeries<TimeSeriesLoginData, DateTime>> dailyData = [];
  List<ChartSeries<TimeSeriesLoginData, DateTime>> weeklyData = [];
  List<ChartSeries<TimeSeriesLoginData, DateTime>> monthlyData = [];
  bool _showWelcomeMessage = true;
  String _selectedView = 'daily';

  @override
  void initState() {
    super.initState();
    fetchDailyLogins();  // Günlük giriş verilerini çeker
    fetchWeeklyLogins(); // Haftalık giriş verilerini çeker
    fetchMonthlyLogins(); // Aylık giriş verilerini çeker
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _showWelcomeMessage = false;
      });
    });
  }

  Future<void> fetchDailyLogins() async {
    final response = await http.get(Uri.parse('http://localhost:5004/daily_logins/${widget.kullaniciID}'));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        dailyData = [
          LineSeries<TimeSeriesLoginData, DateTime>(
            dataSource: data.map<TimeSeriesLoginData>((item) {
              return TimeSeriesLoginData(
                DateTime.parse(item['Date']),
                item['Count'].toDouble(),
              );
            }).toList(),
            xValueMapper: (TimeSeriesLoginData login, _) => login.date,
            yValueMapper: (TimeSeriesLoginData login, _) => login.count,
          )
        ];
      });
    } else {
      throw Exception('Failed to load daily logins');
    }
  }

  Future<void> fetchWeeklyLogins() async {
    final response = await http.get(Uri.parse('http://localhost:5004/weekly_logins/${widget.kullaniciID}'));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        weeklyData = [
          LineSeries<TimeSeriesLoginData, DateTime>(
            dataSource: data.map<TimeSeriesLoginData>((item) {
              final weekStart = DateTime(item['Year'], 1, 1).add(Duration(days: (item['Week'] - 1) * 7));
              return TimeSeriesLoginData(
                weekStart,
                item['Count'].toDouble(),
              );
            }).toList(),
            xValueMapper: (TimeSeriesLoginData login, _) => login.date,
            yValueMapper: (TimeSeriesLoginData login, _) => login.count,
          )
        ];
      });
    } else {
      throw Exception('Failed to load weekly logins');
    }
  }

  Future<void> fetchMonthlyLogins() async {
    final response = await http.get(Uri.parse('http://localhost:5004/monthly_logins/${widget.kullaniciID}'));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        monthlyData = [
          LineSeries<TimeSeriesLoginData, DateTime>(
            dataSource: data.map<TimeSeriesLoginData>((item) {
              return TimeSeriesLoginData(
                DateTime(item['Year'], item['Month']),
                item['Count'].toDouble(),
              );
            }).toList(),
            xValueMapper: (TimeSeriesLoginData login, _) => login.date,
            yValueMapper: (TimeSeriesLoginData login, _) => login.count,
          )
        ];
      });
    } else {
      throw Exception('Failed to load monthly logins');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            if (_showWelcomeMessage)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Welcome ${widget.kullaniciAdi}', style: TextStyle(fontSize: 24)),
              ),
            SizedBox(height: 20), // Add some space before the chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9, // Ekran genişliğinin %90'ını kaplasın
                height: 250, // Reduce the height of the chart
                child: _selectedView == 'daily'
                    ? dailyData.isEmpty
                        ? Center(child: Text('No daily login data available'))
                        : SfCartesianChart(
                            series: dailyData,
                            primaryXAxis: DateTimeAxis(
                              edgeLabelPlacement: EdgeLabelPlacement.shift,
                              majorGridLines: MajorGridLines(width: 0),
                              dateFormat: DateFormat.MMMd(),  // Kullanılabilir hale geldi
                              intervalType: DateTimeIntervalType.days,  // Haftalık yerine günlük kullanılıyor
                              labelStyle: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                            primaryYAxis: NumericAxis(
                              labelFormat: '{value}',
                              majorGridLines: MajorGridLines(width: 0.5, color: Colors.grey[300]),
                              labelStyle: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                            tooltipBehavior: TooltipBehavior(enable: true),
                          )
                    : _selectedView == 'weekly'
                        ? weeklyData.isEmpty
                            ? Center(child: Text('No weekly login data available'))
                            : SfCartesianChart(
                                series: weeklyData,
                                primaryXAxis: DateTimeAxis(
                                  edgeLabelPlacement: EdgeLabelPlacement.shift,
                                  majorGridLines: MajorGridLines(width: 0),
                                  intervalType: DateTimeIntervalType.days,  // Günlük interval tipi kullanılıyor
                                  labelStyle: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                ),
                                primaryYAxis: NumericAxis(
                                  labelFormat: '{value}',
                                  majorGridLines: MajorGridLines(width: 0.5, color: Colors.grey[300]),
                                  labelStyle: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                ),
                                tooltipBehavior: TooltipBehavior(enable: true),
                              )
                        : monthlyData.isEmpty
                            ? Center(child: Text('No monthly login data available'))
                            : SfCartesianChart(
                                series: monthlyData,
                                primaryXAxis: DateTimeAxis(
                                  edgeLabelPlacement: EdgeLabelPlacement.shift,
                                  majorGridLines: MajorGridLines(width: 0),
                                  intervalType: DateTimeIntervalType.months,
                                  labelStyle: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                ),
                                primaryYAxis: NumericAxis(
                                  labelFormat: '{value}',
                                  majorGridLines: MajorGridLines(width: 0.5, color: Colors.grey[300]),
                                  labelStyle: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                ),
                                tooltipBehavior: TooltipBehavior(enable: true),
                              ),
              ),
            ),
            SizedBox(height: 20), // Add some space after the chart
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedView = 'daily';
                      });
                    },
                    child: Text('Daily'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedView = 'weekly';
                      });
                    },
                    child: Text('Weekly'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedView = 'monthly';
                      });
                    },
                    child: Text('Monthly'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimeSeriesLoginData {
  final DateTime date;
  final double count;

  TimeSeriesLoginData(this.date, this.count);
}
