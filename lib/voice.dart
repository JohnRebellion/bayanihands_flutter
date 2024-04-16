import 'dart:async';
import 'dart:convert';
import 'package:bayanihands/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordVoiceScreen extends StatefulWidget {
  const RecordVoiceScreen({
    super.key,
  });

  @override
  RecordVoiceScreenState createState() => RecordVoiceScreenState();
}

class RecordVoiceScreenState extends State<RecordVoiceScreen> {
  var results = <Result>[];
  var _isRecording = false;
  var record = AudioRecorder();

  String? audioPath;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _showMyDialog(
      final String result, DateTime? start, DateTime? end) async {
    var textController = TextEditingController(text: result);
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Result'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: textController,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Approve'),
              onPressed: () {
                setState(() {
                  results = [
                    ...results,
                    Result(textController.value.text, start!, end!)
                  ];
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var result = '';
    DateTime startTime = DateTime.now();
    DateTime endTime = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Record voice')),
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Count: ${results.length}"),
                    Text(
                        "Average: ${(results.fold(0.0, (a, b) => a + b.duration) / results.length).toStringAsFixed(2)}")
                  ],
                ),
                SizedBox(
                    height: 200,
                    child: Table(
                      columnWidths: const <int, TableColumnWidth>{
                        0: IntrinsicColumnWidth(),
                        1: FlexColumnWidth(),
                        2: IntrinsicColumnWidth(),
                        3: IntrinsicColumnWidth(),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        const TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text("Time"),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text("Translation"),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text("Words"),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text("Duration"),
                            ),
                          ],
                        ),
                        ...results.map((result) {
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text(result.start.toString()),
                                    Text(result.end.toString()),
                                  ],
                                ),
                              ),
                              Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(result.text)),
                              Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(result.wordCount.toString())),
                              Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(result.duration.toString())),
                            ],
                          );
                        })
                      ],
                    ))
              ],
            )),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _isRecording ? Colors.red : Colors.green,
        onPressed: () async {
          setState(() {
            _isRecording = !_isRecording;
          });

          try {
            final hasPermission = await record.hasPermission();

            if (hasPermission && _isRecording) {
              final tmp = await getTemporaryDirectory();
              await record.start(const RecordConfig(),
                  path: '${tmp.path}/recording.m4a');
              startTime = DateTime.now();
            }

            if (!_isRecording) {
              final path = await record.stop();
              await record.dispose();
              record = AudioRecorder();
              var request = http.MultipartRequest(
                  'POST', Uri.parse('$API_URL/api/transcribe'));
              request.files
                  .add(await http.MultipartFile.fromPath('file', path!));

              var response = await request.send();

              var data = jsonDecode(await response.stream.bytesToString());

              if (data['result'] != null) {
                result += data['result'];
              }
              endTime = DateTime.now();
              _showMyDialog(result, startTime, endTime);
              result = '';
            }
          } catch (e) {
            print(e);
          }
        },
        child: _isRecording
            ? const Icon(Icons.stop)
            : const Icon(Icons.play_arrow),
      ),
    );
  }
}
