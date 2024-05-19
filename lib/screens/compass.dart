// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:sensors_plus/sensors_plus.dart';

// class CompassPage extends StatefulWidget {
//   const CompassPage({super.key});

//   @override
//   State<CompassPage> createState() => _CompassPageState();
// }

// class _CompassPageState extends State<CompassPage> {
//   MagnetometerEvent _magnetometerEvent = MagnetometerEvent(0, 0, 0);
//   StreamSubscription? subscription;

//   //Initiation of the compass

//   @override
//   void initState() {
//     super.initState();
//     subscription = magnetometerEvents.listen((event) {
//       setState(() {
//         _magnetometerEvent = event;
//       });
//     });
//   }

//   @override
//   void dispose() {
//     subscription?.cancel();
//     super.dispose();
//   }

//   //Calculation of the direction.

//   double calculateDegrees(double x, double y) {
//     double heading = atan2(x, y);
//     heading = heading * 180 / pi;

//     if (heading > 0) {
//       heading -= 360;
//     }
//     return heading * -1;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final degrees = calculateDegrees(_magnetometerEvent.x, _magnetometerEvent.y);
//     final angle = -1 * pi / 180 * degrees;

//     //The compass (diplay of the direction)

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Compass'),
//       ),
//       body:  Container(
//         color: Colors.white,
//         child: Padding(
//           padding: EdgeInsets.all(20),
//           child: Column(
//             children: [
//               Text('Rotated at ${degrees.toStringAsFixed(0)} degree(s)'),
//               Expanded(
//                   child: Center(
//                 child: Transform.rotate(
//                   angle: angle,
//                   child: Image.asset('images/compass2.png',height: MediaQuery.of(context).size.height * 0.8,),
                  
//                 ),
//               ))
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class CompassPage extends StatefulWidget {
  const CompassPage({super.key});

  @override
  State<CompassPage> createState() => _CompassPageState();
}

class _CompassPageState extends State<CompassPage> {
  MagnetometerEvent _magnetometerEvent = MagnetometerEvent(0, 0, 0);
  StreamSubscription? subscription;

  // Initiation of the compass
  @override
  void initState() {
    super.initState();
    subscription = magnetometerEvents.listen((event) {
      setState(() {
        _magnetometerEvent = event;
      });
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  // Calculation of the direction
  double calculateDegrees(double x, double y) {
    double heading = atan2(x, y);
    heading = heading * 180 / pi;

    if (heading < 0) {
      heading += 360;
    }

    return heading;
  }

  String getCompassDirection(double degrees) {
    if (degrees >= 337.5 || degrees < 22.5) {
      return 'North';
    } else if (degrees >= 22.5 && degrees < 67.5) {
      return 'North East';
    } else if (degrees >= 67.5 && degrees < 112.5) {
      return 'East';
    } else if (degrees >= 112.5 && degrees < 157.5) {
      return 'South East';
    } else if (degrees >= 157.5 && degrees < 202.5) {
      return 'South';
    } else if (degrees >= 202.5 && degrees < 247.5) {
      return 'South West';
    } else if (degrees >= 247.5 && degrees < 292.5) {
      return 'West';
    } else if (degrees >= 292.5 && degrees < 337.5) {
      return 'Norht West';
    } else {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final degrees = calculateDegrees(_magnetometerEvent.x, _magnetometerEvent.y);
    final angle = -1 * pi / 180 * degrees;
    final direction = getCompassDirection(degrees);

    // The compass (display of the direction)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compass'),
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Rotated at ${degrees.toStringAsFixed(0)} degree(s) ($direction)',
                style: const TextStyle(fontSize: 20,fontWeight: FontWeight.normal),
              ),
              SizedBox(height: 10,),
              
              Text(
                'You are in $direction Direction',
                style: const TextStyle(fontSize: 20,fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Center(
                  child: Transform.rotate(
                    angle: angle,
                    child: Image.asset(
                      'images/compass2.png',
                      height: MediaQuery.of(context).size.height * 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
