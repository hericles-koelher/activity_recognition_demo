import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Activity Recognition Demo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _logger = Logger();
  StreamSubscription? _subscription;
  Activity? _activity;
  List<ActivityData> _possibleActivities = [];

  @override
  void dispose() {
    _subscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Atividade Atual",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "Atividade: ${_activity?.type.name ?? "DESCONHECIDA"}",
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Confiança: ${_activity?.confidence ?? "DESCONHECIDA"}",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: ListView.separated(
                      itemCount: _possibleActivities.length,
                      itemBuilder: (_, index) {
                        var activityData = _possibleActivities[index];

                        return ListTile(
                          title: Text(activityData.activity.type.name),
                          subtitle: Text(
                            "Confiança: ${activityData.activity.confidence.name}",
                          ),
                          trailing: Text(
                            DateTime.fromMillisecondsSinceEpoch(
                              activityData.timestamp,
                            ).toString(),
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider(),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    var activityRecognitionPermission =
                        await Permission.activityRecognition.request();

                    if (activityRecognitionPermission.isGranted) {
                      _logger.d("Permissão concedida");

                      _subscription?.cancel();
                      _subscription = FlutterActivityRecognition
                          .instance.activityStream
                          .listen((event) {
                        _logger.i("Atividade em reconhecimento...");

                        _possibleActivities.add(ActivityData(
                            event, DateTime.now().millisecondsSinceEpoch));
                        if (event.confidence == ActivityConfidence.HIGH) {
                          _logger.i("Atividade de alta confiança detectada");
                          setState(() {
                            _activity = event;
                          });
                        }
                      });
                    } else {
                      _logger.d("Permissão negada");
                    }
                  },
                  child: const Text("Iniciar Monitoramento de Atividades"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ActivityData {
  final Activity activity;
  final int timestamp;

  ActivityData(this.activity, this.timestamp);
}
