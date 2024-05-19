import 'dart:async';
import 'package:flutter/material.dart';
import 'package:light_sensor/light_sensor.dart';

class LightSensorPage extends StatefulWidget {
  @override
  _LightSensorPageState createState() => _LightSensorPageState();
}

class _LightSensorPageState extends State<LightSensorPage> {
  double _lightIntensity = 0.0;
  bool _showHighIntensityPopup = true; 
  bool _showLowIntensityPopup = true; 
  late StreamSubscription<int> _lightSubscription;

  @override
  void initState() {
    super.initState();
    _startListeningToLightSensor();
  }

  @override
  void dispose() {
    _lightSubscription.cancel();
    super.dispose();
  }

  void _startListeningToLightSensor() {
    LightSensor.hasSensor().then((hasSensor) {
      if (hasSensor) {
        _lightSubscription = LightSensor.luxStream().listen((int luxValue) {
          setState(() {
            _lightIntensity = luxValue.toDouble();
            checkAndTriggerPopups();
          });
        });
      } else {
        print("Device does not have a light sensor");
      }
    });
  }

  void checkAndTriggerPopups() {
    // Check for the specific intensity values to trigger popups
    if (_lightIntensity >= 200.0 && _showHighIntensityPopup) {
      _showPopup('High Light Intensity',
          'Light intensity level is at 200 lux(The highest).');
      _showHighIntensityPopup =
          false; // Prevent further high intensity popups until condition resets
    } else if (_lightIntensity >= 200.0) {
      _showHighIntensityPopup = true; // Reset the flag when not at 40000
    }

    if (_lightIntensity == 0 && _showLowIntensityPopup) {
      _showPopup('Low Light Intensity',
          'Light intensity level is at 0 lux ( The lowest).');
      _showLowIntensityPopup =
          false; // Prevent further low intensity popups until condition resets
    } else if (_lightIntensity != 0) {
      _showLowIntensityPopup = true; // Reset the flag when not at 0
    }
  }

  void _showPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.hintColor,
        title: Text(
          'Light Sensor',
          style: TextStyle(color: theme.primaryColor),
        ),
        iconTheme: IconThemeData(
          color: Colors.black,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Image.asset('images/images.jpeg',height: MediaQuery.of(context).size.height * 0.5,),
              SizedBox(height: 20,),
              Text(
              'Light Intensity',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20,),
              SizedBox(
              width: 250,
              height: 20,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromARGB(185, 26, 11, 114),
                ),
                value: _lightIntensity / 200,
              ),
            ),
            SizedBox(height: 20),
            
            SizedBox(height: 10),
            Text(
              '${_lightIntensity.toStringAsFixed(2)} lux',
              style: TextStyle(
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
