import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile_final/main.dart'; // Ensure you have the flutterLocalNotificationsPlugin defined here
import 'package:sensors_plus/sensors_plus.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class StepCounterPage extends StatefulWidget {
  @override
  _StepCounterPageState createState() => _StepCounterPageState();
}

class _StepCounterPageState extends State<StepCounterPage> {
  int _stepCount = 0;
  int _otherMovementCount = 0;
  bool _walkingDetected = false; // Flag to track walking detection
  bool _movementDetected = false; // Flag to track general movement detection
  bool _walkingNotificationShown =
      false; // Flag to track if walking notification has been shown
  bool _movementNotificationShown =
      false; // Flag to track if movement notification has been shown
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  String _status = '?';
  bool _isCounting = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  _requestPermission() async {
    PermissionStatus status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      initPlatformState();
      _startListeningToAccelerometer();
    } else {
      print('Permission denied');
      // Handle denied permission
    }
  }

  void onStepCount(StepCount event) {
    print(event);
    setState(() {
      _stepCount = event.steps;
    });
    _triggerWalkingNotification();
    _walkingNotificationShown = true;
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    print(event);
    setState(() {
      _status = event.status;
    });
  }

  void onPedestrianStatusError(error) {
    print('onPedestrianStatusError: $error');
    setState(() {
      _status = 'Pedestrian Status not available';
    });
  }

  void onStepCountError(error) {
    print('onStepCountError: $error');
    setState(() {
      _stepCount = 0;
    });
  }

  void initPlatformState() {
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _pedestrianStatusStream
        .listen(onPedestrianStatusChanged)
        .onError(onPedestrianStatusError);

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepCount).onError(onStepCountError);
  }

  void _startListeningToAccelerometer() {
    Timer? movementTimer; // Timer to track general movement inactivity

    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        if (event.x.abs() > 2.0 ||
            event.y.abs() > 2.0 ||
            event.z.abs() > 10.0) {
          _otherMovementCount++;
          _movementDetected = true;
          _triggerMovementNotification();
          _movementNotificationShown = true;

          // Reset the movement timer
          movementTimer?.cancel();
          movementTimer = Timer(const Duration(seconds: 10), () {
            if (mounted) {
              setState(() {
                _movementDetected = false;
                _movementNotificationShown = false;
              });
            }
          });
        }
      });
    });
  }

  void _triggerWalkingNotification() async {
    if (!_walkingNotificationShown) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'Walking_channel', // Change this to match your channel ID
        'Walking Notifications', // Replace with your own channel name
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        0,
        'Walking Alert!',
        'You have started walking',
        platformChannelSpecifics,
      );
      print('Walking detected! Alerting user...');
      _walkingNotificationShown = true; // Set notification shown flag
    }
  }

  void _triggerMovementNotification() async {
    if (!_movementNotificationShown) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'Movement_channel', // Change this to match your channel ID
        'Movement Notifications', // Replace with your own channel name
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        1, // Use a different ID to avoid notification conflicts
        'Movement Alert!',
        'Device is being moved',
        platformChannelSpecifics,
      );
      print('Movement detected! Alerting user...');
      _movementNotificationShown = true; // Set notification shown flag
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.hintColor,
        title: Text(
          'Step Counter',
          style: TextStyle(color: theme.primaryColor),
        ),
        iconTheme: IconThemeData(
          color: theme.primaryColor,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Steps Taken:',
              style: TextStyle(fontSize: 20, color: Colors.black),
            ),
            Text(
              '$_stepCount',
              style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor),
            ),
            const SizedBox(height: 20),
            Text(
              'Other Movements:',
              style: TextStyle(fontSize: 20, color: Colors.black),
            ),
            Text(
              '$_otherMovementCount',
              style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor),
            ),
            const SizedBox(height: 20),
            _walkingDetected
                ? Text(
                    'Walking',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green, // Highlight in green for walking
                    ),
                  )
                : Text(
                    'Stopped Walking',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red, // Use red color for no walking
                    ),
                  ),
            const SizedBox(height: 20),
            _movementDetected
                ? Text(
                    'Device in Motion',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green, // Highlight in green for motion
                    ),
                  )
                : Text(
                    'Device Still',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red, // Use red color for no motion
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
