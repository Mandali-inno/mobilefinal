import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_final/main.dart';
import 'package:sensors_plus/sensors_plus.dart';

class StepCounterPage extends StatefulWidget {
  @override
  _StepCounterPageState createState() => _StepCounterPageState();
}

class _StepCounterPageState extends State<StepCounterPage> {
  int _stepCount = 0;
  bool _motionDetected = false; // Flag to track motion detection
  bool _notificationShown =
      false; // Flag to track if notification has been shown
  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    _startListeningToAccelerometer();
  }

  @override
  void dispose() {
    _accelerometerSubscription.cancel();
    super.dispose();
  }

  void _startListeningToAccelerometer() {
    Timer? motionTimer; // Timer to track motion inactivity

    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      if (event.z.abs() > 10.0) {
        setState(() {
          _stepCount++;
          _motionDetected = true; // Set motion detected flag
          // Trigger notification/alert here
          _triggerNotification();
          _notificationShown = true; // Set notification shown flag
          // Reset the motion timer
          motionTimer?.cancel();
          motionTimer = Timer(const Duration(seconds: 10), () {
            if (mounted) {
              setState(() {
                _motionDetected = false;
                _notificationShown = false;
              });
            }
          });
        });
      }
    });
  }

  void _triggerNotification() async {
    if (!_notificationShown) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'StepCounter_channel', // Change this to match your channel ID
        'StepCounter Notifications', // Replace with your own channel name
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        0,
        'Hello!',
        'Motion detected! Keep It Up',
        platformChannelSpecifics,
      );
      print('Motion detected! Alerting user...');
      _notificationShown = true; // Set notification shown flag
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
            Lottie.asset(
              'lib/assets/Animation - 1712341175314.json',
              width: 400,
              height: 400,
            ),
            Text(
              'Step Count:',
              style: TextStyle(fontSize: 20, color: theme.hintColor),
            ),
            Text(
              '$_stepCount',
              style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: theme.hintColor),
            ),
            SizedBox(height: 20),
            _motionDetected
                ? Text(
                    'Motion Detected!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red, // Highlight in red for emphasis
                    ),
                  )
                : Text(
                    'At rest',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green, // Use green color for rest
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
