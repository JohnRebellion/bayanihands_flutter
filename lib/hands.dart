import 'dart:async';
import 'dart:convert';
import 'package:bayanihands/main.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  var results = <Result>[];
  var _isRecording = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
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
      appBar: AppBar(title: const Text('Take a picture')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.done) {
            return SingleChildScrollView(
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
                CameraPreview(
                  _controller,
                  child: Container(
                    alignment: Alignment.topLeft,
                    child: TextButton(
                      child: const Icon(Icons.cameraswitch),
                      onPressed: () async {
                        final cameras = await availableCameras();
                        final camera = cameras.firstWhere(
                            (element) => element != _controller.description);
                        setState(() {
                          _controller = CameraController(
                            camera,
                            ResolutionPreset.medium,
                          );
                          _initializeControllerFuture =
                              _controller.initialize();
                        });
                      },
                    ),
                  ),
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
            ));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _isRecording ? Colors.red : Colors.green,
        onPressed: () async {
          try {
            if (!_isRecording) {
              startTime = DateTime.now();
            }

            setState(() {
              _isRecording = !_isRecording;
            });

            await _initializeControllerFuture;

            for (;;) {
              final image = await _controller.takePicture();

              if (!context.mounted) return;

              var request = http.MultipartRequest(
                  'POST', Uri.parse("$API_URL/api/detect"));
              request.files
                  .add(await http.MultipartFile.fromPath('file', image.path));

              var response = await request.send();

              var data = jsonDecode(await response.stream.bytesToString());

              if (data['result'] != null) {
                var alpha = data['result'];
                if (alpha == "space") {
                  alpha = " ";
                }

                result += alpha;
              }

              if (!_isRecording) {
                endTime = DateTime.now();
                _showMyDialog(result, startTime, endTime);
                result = '';
                break;
              }
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
