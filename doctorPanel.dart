import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class DoctorPanel extends StatefulWidget {
  final String doctorID;

  DoctorPanel({required this.doctorID});

  @override
  _DoctorPanelState createState() => _DoctorPanelState();
}

class _DoctorPanelState extends State<DoctorPanel> {
  List<Map<String, dynamic>> patients = [];
  List<Map<String, dynamic>> filteredPatients = [];
  String selectedPatientTc = '';
  TextEditingController angleController = TextEditingController();
  TextEditingController responseController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  double? lastSubmittedAngle;

  @override
  void initState() {
    super.initState();
    fetchPatients();
  }

  Future<void> fetchPatients() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:5000/kullaniciBilgileri'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      setState(() {
        patients = data.map((item) => item as Map<String, dynamic>).toList();
        filteredPatients = patients;
      });
    } else {
      throw Exception('Failed to load patient data');
    }
  }

  void _onPatientSelected(String tc) {
    setState(() {
      selectedPatientTc = tc;
    });
  }

  void _filterPatients(String query) {
    setState(() {
      filteredPatients = patients.where((patient) {
        final tc = patient['TC'] ?? '';
        return tc.contains(query);
      }).toList();
    });
  }

  Future<void> _submitFeedback() async {
    if (responseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter feedback')));
      return;
    }

    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/submitFeedback'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'DoktorID': widget.doctorID,
        'TC': selectedPatientTc,
        'doktorGeribildirim': responseController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Feedback submitted successfully')));
      responseController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit feedback')));
    }
  }

  Future<void> _submitAngle() async {
    if (angleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter an angle value')));
      return;
    }

    final angleValue = double.tryParse(angleController.text);
    if (angleValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid angle value')));
      return;
    }

    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/submitAngle'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'TC': selectedPatientTc,
        'AcıDeger': angleValue,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Angle value submitted successfully')));
      setState(() {
        lastSubmittedAngle = angleValue;
      });
      angleController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit angle value')));
    }
  }

  // Apply Angle butonunu kaldırdık
  // Future<void> _applyAngle() async {
  //   if (lastSubmittedAngle == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No angle value to apply')));
  //     return;
  //   }

  //   final response = await http.post(
  //     Uri.parse('http://127.0.0.1:5006/applyAngle'),
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode({
  //       'TC': selectedPatientTc,
  //       'AcıDeger': lastSubmittedAngle,
  //     }),
  //   );

  //   if (response.statusCode == 200) {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Angle applied successfully')));
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to apply angle')));
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor Panel'),
        backgroundColor: Colors.teal,
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey[200],
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by TC',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _filterPatients,
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: filteredPatients
                          .map((patient) {
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 4,
                          child: ListTile(
                            contentPadding: EdgeInsets.all(12.0),
                            title: Text(patient['Isim']!),
                            subtitle: Text('TC: ${patient['TC']}'),
                            onTap: () => _onPatientSelected(patient['TC']!),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: selectedPatientTc.isEmpty
                ? Center(child: Text('Select a patient', style: TextStyle(fontSize: 18, color: Colors.grey)))
                : PatientDetailPanel(
                    patient: patients.firstWhere((p) => p['TC'] == selectedPatientTc),
                    angleController: angleController,
                    responseController: responseController,
                    onSubmitFeedback: _submitFeedback,
                    onSubmitAngle: _submitAngle,
                    // onApplyAngle: _applyAngle, // Bu satırı kaldırdık
                  ),
          ),
        ],
      ),
    );
  }
}

class PatientDetailPanel extends StatefulWidget {
  final Map<String, dynamic> patient;
  final TextEditingController angleController;
  final TextEditingController responseController;
  final VoidCallback onSubmitFeedback;
  final VoidCallback onSubmitAngle;
  // final VoidCallback onApplyAngle; // Bu satırı kaldırdık

  PatientDetailPanel({
    required this.patient,
    required this.angleController,
    required this.responseController,
    required this.onSubmitFeedback,
    required this.onSubmitAngle,
    // required this.onApplyAngle, // Bu satırı kaldırdık
  });

  @override
  _PatientDetailPanelState createState() => _PatientDetailPanelState();
}

class _PatientDetailPanelState extends State<PatientDetailPanel> {
  List<Map<String, dynamic>> feedbackMessages = [];
  String selectedFeedback = '';

  @override
  void initState() {
    super.initState();
    _fetchFeedback();
  }

  @override
  void didUpdateWidget(covariant PatientDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.patient['TC'] != oldWidget.patient['TC']) {
      setState(() {
        selectedFeedback = '';
      });
      _fetchFeedback();
    }
  }

  Future<void> _fetchFeedback() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:5000/feedback?KullaniciID=${widget.patient['KullaniciID']}'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      setState(() {
        feedbackMessages = data.map((item) => item as Map<String, dynamic>).toList();
      });
    } else {
      throw Exception('Failed to load feedback data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patient TC: ${widget.patient['TC']}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Name: ${widget.patient['Isim']} ${widget.patient['Soyadı']}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Gender: ${widget.patient['Cinsiyet']}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 8),
          Text(
            'Weight: ${widget.patient['Kilo']} kg',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 8),
          Text(
            'Height: ${widget.patient['Boy']} cm',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 16),
          GestureDetector(
            onTap: () => _launchPhone(widget.patient['TelefonNo']!),
            child: Text(
              'Phone: ${widget.patient['TelefonNo']}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.blue),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Adjust Angle Value',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          TextField(
            controller: widget.angleController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter angle value',
              prefixIcon: Icon(Icons.arrow_forward),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.onSubmitAngle,
            child: Text('Submit Angle'),
          ),
          SizedBox(height: 16),
          Text(
            'Patient Feedback',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: feedbackMessages.isNotEmpty
                ? feedbackMessages.map((message) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4.0),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12.0),
                        title: Text(message['hastaGeriBildirim'] ?? 'No feedback'),
                        onTap: () {
                          setState(() {
                            selectedFeedback = message['hastaGeriBildirim'] ?? 'No feedback';
                          });
                        },
                      ),
                    );
                  }).toList()
                : [Center(child: Text('No feedback available'))],
            ),
          ),
          if (selectedFeedback.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              'Selected Feedback:',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(16.0),
              color: Colors.blue[50],
              child: Text(
                selectedFeedback,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
          SizedBox(height: 16),
          Text(
            'Provide Feedback',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          TextField(
            controller: widget.responseController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter your feedback',
              prefixIcon: Icon(Icons.comment),
            ),
            maxLines: 3,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.onSubmitFeedback,
            child: Text('Submit Feedback'),
          ),
        ],
      ),
    );
  }

  void _launchPhone(String phone) async {
    final url = 'tel:$phone';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
