import 'dart:io';

import 'package:bayanihands/hands.dart';
import 'package:bayanihands/voice.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'dart:async';
import 'package:lan_scanner/lan_scanner.dart';
import 'package:network_info_plus/network_info_plus.dart';

String API_URL = '';

Future pingServer() async {
  final scanner = LanScanner();
  var wifiIP = await NetworkInfo().getWifiIP();
  var subnet = ipToCSubnet(wifiIP!);
  final List<Host> hosts = await scanner.quickIcmpScanAsync(subnet);
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 1);

  for (var host in hosts) {
    try {
      client
          .get(host.internetAddress.host, 5000, "api/ping")
          .then((req) => req.close())
          .then((res) {
        if (res.statusCode == 200) {
          API_URL = 'http://${host.internetAddress.host}:5000';
        }
      });
    } catch (e) {
      print(e);
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await pingServer();
  FlutterNativeSplash.remove();
  runApp(MaterialApp(
    theme: ThemeData.dark(),
    home: const AboutScreen(),
  ));
}

class Result {
  String text;
  final DateTime start;
  final DateTime end;
  int get wordCount => text.split(' ').length;
  double get duration => end.difference(start).inMilliseconds / 1000.0;

  Result(this.text, this.start, this.end);
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BayaniHands'),
      ),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SingleChildScrollView(
              child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'BayaniHands is an application which allows users, who are usually visually impaired or may interact with people of those impairments. It allows users to translate sign landuage and speech into text. The application utilizes the cellphone’s camera and microphone. It allows hearing impaired individuals to feel included and understood by society.',
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(fontSize: 20),
            ),
          )),
          ElevatedButton(
            child: const Text('START'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          )
        ]),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Padding(
            padding: EdgeInsets.only(top: 30),
            child: Center(
                child: SingleChildScrollView(
                    child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Established in 2023, we are Senior High School students from San Pablo City Science Integrated. During the past months, we have accomplished a lot regarding the advancement of technology for the hearing impaired. We aim to promote inclusivity among impaired individuals and make them feel belonging to society.',
                textAlign: TextAlign.justify,
                softWrap: true,
                style: TextStyle(fontSize: 20),
              ),
            ))),
          ),
          Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FutureBuilder(
                        future: availableCameras(),
                        builder: ((context, snapshot) {
                          if (!snapshot.hasData) {
                            // while data is loading:
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else {
                            // data loaded:
                            final firstCamera = snapshot.data!.first;
                            return ElevatedButton(
                              child: const Text('Sign Language Recognition'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => TakePictureScreen(
                                            camera: firstCamera,
                                          )),
                                );
                              },
                            );
                          }
                        })),
                    ElevatedButton(
                      child: const Text('Voice Recognition'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RecordVoiceScreen()),
                        );
                      },
                    )
                  ]))
        ]),
      ),
    );
  }
}
