import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:mobile_final/components/consts.dart';
import 'package:mobile_final/main.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Location _locationController = Location();
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  LatLng _kigaliCenter =
      LatLng(-1.9441, 30.0619); // Coordinates for Kigali center
  LatLng _homeLocation = LatLng(-1.9441, 30.0619); // Initial Home location
  LatLng _workLocation = LatLng(-1.9441, 30.0619); // Initial Work location
  LatLng _schoolLocation = LatLng(-1.9441, 30.0619); // Initial School location
  LatLng? _currentP;
  Map<PolylineId, Polyline> polylines = {};
  Map<PolygonId, Polygon> _polygons = {};
  StreamSubscription<LocationData>? _locationSubscription;
  bool _notificationSentHome = false;
  bool _notificationSentWork = false;
  bool _notificationSentSchool = false;
  bool _notificationSentOutSide = false;

  @override
  void initState() {
    super.initState();
    getLocationUpdates().then(
      (_) => {
        getPolylinePoints().then((coordinates) => {
              generatePolyLineFromPoints(coordinates),
            }),
      },
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel(); // Cancel location updates subscription
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.hintColor,
        title: Text(
          'Your Location',
          style: TextStyle(color: theme.primaryColor),
        ),
        iconTheme: IconThemeData(
          color: theme.primaryColor,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () => _editLocation('Home'),
          ),
          IconButton(
            icon: Icon(Icons.work),
            onPressed: () => _editLocation('Work'),
          ),
          IconButton(
            icon: Icon(Icons.school),
            onPressed: () => _editLocation('School'),
          ),
        ],
      ),
      body: _currentP == null
          ? const Center(
              child: Text("Loading..."),
            )
          : GoogleMap(
              onMapCreated: ((GoogleMapController controller) =>
                  _mapController.complete(controller)),
              initialCameraPosition: CameraPosition(
                target: _kigaliCenter,
                zoom: 13,
              ),
              markers: {
                Marker(
                  markerId: MarkerId("_currentLocation"),
                  icon: BitmapDescriptor.defaultMarker,
                  position: _currentP!,
                ),
                Marker(
                  markerId: MarkerId("_homeLocation"),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen),
                  position: _homeLocation,
                ),
                Marker(
                  markerId: MarkerId("_workLocation"),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueBlue),
                  position: _workLocation,
                ),
                Marker(
                  markerId: MarkerId("_schoolLocation"),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueOrange),
                  position: _schoolLocation,
                ),
              },
              polylines: Set<Polyline>.of(polylines.values),
            ),
    );
  }

  Future<void> _editLocation(String locationType) async {
    final GoogleMapController controller = await _mapController.future;
    LatLng? newLocation = await showDialog<LatLng>(
      context: context,
      builder: (context) {
        LatLng tempLocation = _currentP!;
        return AlertDialog(
          title: Text('Set $locationType Location'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentP!,
                zoom: 14,
              ),
              markers: {
                Marker(
                  markerId: MarkerId("_editLocation"),
                  draggable: true,
                  position: tempLocation,
                  onDragEnd: (newPos) {
                    tempLocation = newPos;
                  },
                ),
              },
              onTap: (latLng) {
                tempLocation = latLng;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, tempLocation),
              child: Text('Set'),
            ),
          ],
        );
      },
    );

    if (newLocation != null) {
      setState(() {
        if (locationType == 'Home') {
          _homeLocation = newLocation;
        } else if (locationType == 'Work') {
          _workLocation = newLocation;
        } else if (locationType == 'School') {
          _schoolLocation = newLocation;
        }
      });
    }
  }

  void _triggerNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'Map_channel', // Change this to match your channel ID
      'Map Notifications', // Replace with your own channel name
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  void _startLocationUpdates() async {
    _locationSubscription = _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        LatLng newLocation =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);

        // Update the marker to the new location
        updateMarkerAndCircle(newLocation);

        // Optionally, keep track of the path by adding to your polyline
        addLocationToPolyline(newLocation);

        _cameraToPosition(newLocation);

        // Check if the device's location is inside or outside the defined geofences
        _checkGeofences(newLocation);
      }
    });
  }

  void _checkGeofences(LatLng newLocation) {
    bool isHome = _isLocationInsideGeofence(newLocation, _homeLocation);
    bool isWork = _isLocationInsideGeofence(newLocation, _workLocation);
    bool isSchool = _isLocationInsideGeofence(newLocation, _schoolLocation);

    if (isHome && !_notificationSentHome) {
      _triggerNotification('Home', 'You are at Home');
      _notificationSentHome = true;
      _notificationSentWork = false;
      _notificationSentSchool = false;
      _notificationSentOutSide = false;
    } else if (isWork && !_notificationSentWork) {
      _triggerNotification('Work', 'You are at Work');
      _notificationSentHome = false;
      _notificationSentWork = true;
      _notificationSentSchool = false;
      _notificationSentOutSide = false;
    } else if (isSchool && !_notificationSentSchool) {
      _triggerNotification('School', 'You are at School');
      _notificationSentHome = false;
      _notificationSentWork = false;
      _notificationSentSchool = true;
      _notificationSentOutSide = false;
    } else if (!isHome && !isWork && !isSchool && !_notificationSentOutSide) {
      _triggerNotification('Outside', 'You are outside of defined locations');
      _notificationSentHome = false;
      _notificationSentWork = false;
      _notificationSentSchool = false;
      _notificationSentOutSide = true;
    }
  }

  bool _isLocationInsideGeofence(LatLng currentLocation, LatLng geofenceCenter,
      {double radius = 100}) {
    double distance = _calculateDistance(currentLocation, geofenceCenter);
    return distance <= radius;
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371000; // Radius of the Earth in meters
    double dLat = _degreesToRadians(end.latitude - start.latitude);
    double dLng = _degreesToRadians(end.longitude - start.longitude);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(start.latitude)) *
            cos(_degreesToRadians(end.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition _newCameraPosition = CameraPosition(
      target: pos,
      zoom: 13,
    );
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(_newCameraPosition),
    );
  }

  Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationSubscription = _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        LatLng newLocation =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);

        // Update the marker to the new location
        updateMarkerAndCircle(newLocation);

        // Optionally, keep track of the path by adding to your polyline
        addLocationToPolyline(newLocation);

        _cameraToPosition(newLocation);

        // Check if the device's location is inside or outside the defined geofences
        _checkGeofences(newLocation);
      }
    });
  }

  void updateMarkerAndCircle(LatLng newLocation) {
    setState(() {
      _currentP = newLocation;
    });
  }

  void addLocationToPolyline(LatLng newLocation) {
    setState(() {
      if (polylines.containsKey(PolylineId("path"))) {
        final polyline = polylines[PolylineId("path")]!;
        final updatedPoints = List<LatLng>.from(polyline.points)
          ..add(newLocation);
        polylines[PolylineId("path")] =
            polyline.copyWith(pointsParam: updatedPoints);
      } else {
        polylines[PolylineId("path")] = Polyline(
          polylineId: PolylineId("path"),
          color: Colors.blue,
          points: [newLocation],
          width: 5,
        );
      }
    });
  }

  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      GOOGLE_MAPS_API_KEY,
      PointLatLng(_kigaliCenter.latitude, _kigaliCenter.longitude),
      PointLatLng(_schoolLocation.latitude, _schoolLocation.longitude),
      travelMode: TravelMode.driving,
    );
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print(result.errorMessage);
    }
    return polylineCoordinates;
  }

  void generatePolyLineFromPoints(List<LatLng> polylineCoordinates) async {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.black,
      points: polylineCoordinates,
      width: 8,
    );
    setState(() {
      polylines[id] = polyline;
    });
  }
}
