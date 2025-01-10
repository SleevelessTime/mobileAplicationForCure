import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MachineStatusPage extends StatefulWidget {
  @override
  _MachineStatusPageState createState() => _MachineStatusPageState();
}

class _MachineStatusPageState extends State<MachineStatusPage> {
  late Future<List<Makine>> futureMakineList;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    futureMakineList = fetchAllData();
  }

  Future<List<Makine>> fetchAllData() async {
    try {
      final makineData = await fetchMakineData();
      final makineHataData = await fetchMakineHataData();

      if (makineData.isEmpty || makineHataData.isEmpty) {
        throw Exception('Makine verisi veya hata verisi boş.');
      }

      List<Makine> makineList = [];
      for (var makine in makineData) {
        List<MakineHata> hatalar = makineHataData
            .where((hata) => hata['AtelID'] == makine['AtelID'])
            .map<MakineHata>((hata) => MakineHata.fromJson(hata))
            .toList();

        makineList.add(Makine.fromJson(makine, hatalar));
      }
      return makineList;
    } catch (e) {
      print('Error fetching data: $e');
      throw Exception('Failed to fetch all data');
    }
  }

  Future<List<dynamic>> fetchMakineData() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:5000/makine'));
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to load makine data');
      }
    } catch (e) {
      print('Error fetching makine data: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> fetchMakineHataData() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:5000/makineHata'));
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to load makine hata data');
      }
    } catch (e) {
      print('Error fetching makine hata data: $e');
      rethrow;
    }
  }

  Future<void> updateHataDurumu(int hataID, String yeniDurum) async {
  try {
    final response = await http.put(
      Uri.parse('http://127.0.0.1:5001/makineHata/$hataID'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'HataDurumu': yeniDurum,
        'EnSonHataVermeZamani': yeniDurum == 'Daha Cozulmedi' ? DateTime.now().toIso8601String() : null
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        futureMakineList = fetchAllData();
      });
    } else {
      throw Exception('Hata durumu güncelleme başarısız oldu');
    }
  } catch (e) {
    print('Hata durumu güncelleme hatası: $e');
  }
}

Future<void> addHata(int atelID) async {
  showDialog(
    context: context,
    builder: (context) {
      final TextEditingController messageController = TextEditingController();
      return AlertDialog(
        title: Text('Yeni Hata Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                labelText: 'Hata Mesajı',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final hataMesaji = messageController.text;
              if (hataMesaji.isNotEmpty) {
                try {
                  final response = await http.post(
                    Uri.parse('http://127.0.0.1:5001/makineHata/$atelID'),
                    headers: <String, String>{
                      'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: jsonEncode(<String, dynamic>{
                      'HataMesaji': hataMesaji,
                      'HataDurumu': 'Daha Cozulmedi',
                      'EnSonHataVermeZamani': DateTime.now().toIso8601String(),
                    }),
                  );

                  if (response.statusCode == 201) {
                    Navigator.of(context).pop();
                    setState(() {
                      futureMakineList = fetchAllData();
                    });
                  } else {
                    throw Exception('Hata ekleme başarısız oldu');
                  }
                } catch (e) {
                  print('Hata ekleme hatası: $e');
                }
              }
            },
            child: Text('Ekle'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('İptal'),
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Makine Durumları'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Atel ID\'ye göre ara',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Makine>>(
              future: futureMakineList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No data available'));
                } else {
                  List<Makine> makineList = snapshot.data!;
                  List<Makine> filteredList = makineList.where((makine) {
                    return makine.atelID.toString().contains(searchQuery);
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      Makine makine = filteredList[index];
                      return ListTile(
                        title: GestureDetector(
                          onLongPress: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Versiyon: ${makine.atelModeli ?? 'No model'}'),
                              ),
                            );
                          },
                          child: Text('${makine.atelAdi ?? 'No name'} (ID: ${makine.atelID})'),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: makine.hatalar.map((hata) {
                            String currentDurum = hata.hataDurumu ?? 'Daha Cozulmedi'; // Null check

                            // Ensure the currentDurum is one of the valid values
                            if (!['Cozuldu', 'Isleme Alindi', 'Daha Cozulmedi'].contains(currentDurum)) {
                              currentDurum = 'Daha Cozulmedi';
                            }

                            return Container(
                              color: _getColorFromDurum(currentDurum),
                              padding: const EdgeInsets.all(4.0),
                              margin: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${hata.hataMesaji ?? 'No message'}'),
                                        SizedBox(height: 4.0),
                                        Text(
                                          'Son Hata Verme Zamanı: ${hata.enSonHataVermeZamani ?? 'No error time'}',
                                          style: TextStyle(fontSize: 12.0, color: Color.fromARGB(255, 0, 0, 0)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 170, // DropdownButton genişliğini ayarlama
                                    child: DropdownButton<String>(
                                      value: currentDurum,
                                      onChanged: (String? yeniDurum) {
                                        if (yeniDurum != null) {
                                          // Find the index of the current hata
                                          final index = makine.hatalar.indexWhere((h) => h.hataID == hata.hataID);
                                          if (index != -1) {
                                            setState(() {
                                              // Update only the specific hata
                                              makine.hatalar[index].hataDurumu = yeniDurum;
                                            });
                                            updateHataDurumu(hata.hataID, yeniDurum);
                                          }
                                        }
                                      },
                                      items: <String>[
                                        'Cozuldu', 
                                        'Isleme Alindi', 
                                        'Daha Cozulmedi'
                                      ].map<DropdownMenuItem<String>>((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      isExpanded: true,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            addHata(makine.atelID);
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorFromDurum(String hataDurumu) {
    switch (hataDurumu) {
      case 'Cozuldu':
        return Colors.green;
      case 'Isleme Alindi':
        return Colors.yellow;
      case 'Daha Cozulmedi':
        return Colors.red;
      default:
        return Colors.white;
    }
  }
}

class Makine {
  final int atelID;
  final String? atelAdi;
  final int atelSeriNumarasi;
  final String? atelModeli;
  List<MakineHata> hatalar;

  Makine({
    required this.atelID,
    this.atelAdi,
    required this.atelSeriNumarasi,
    this.atelModeli,
    required this.hatalar,
  });

  factory Makine.fromJson(Map<String, dynamic> json, List<MakineHata> hatalar) {
    return Makine(
      atelID: json['AtelID'] ?? 0,
      atelAdi: json['AtelAdı'] ?? 'No name',
      atelSeriNumarasi: json['AtelSerial'] ?? 0,
      atelModeli: json['AtelModel'] ?? 'No model',
      hatalar: hatalar,
    );
  }
}

class MakineHata {
  final int hataID; // Bu alan eklendi
  final int atelID;
  final String? sonErisim;
  final String? hataMesaji;
  String? hataDurumu; // final yerine var olarak değiştirildi
  final String? enSonHataVermeZamani;

  MakineHata({
    required this.hataID, // Bu alan eklendi
    required this.atelID,
    this.sonErisim,
    this.hataMesaji,
    this.hataDurumu,
    this.enSonHataVermeZamani,
  });

  factory MakineHata.fromJson(Map<String, dynamic> json) {
    return MakineHata(
      hataID: json['HataID'] ?? 0, // Bu alan eklendi
      atelID: json['AtelID'] ?? 0,
      sonErisim: json['SonErisim'] ?? 'No access time',
      hataMesaji: json['HataMesaji'] ?? 'No message',
      hataDurumu: json['HataDurumu']?.trim() ?? 'Daha Cozulmedi',
      enSonHataVermeZamani: json['EnSonHata'] ?? 'No error time',
    );
  }
}
