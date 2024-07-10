import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math';
import 'package:vibration/vibration.dart';

class MapTracker extends StatefulWidget {
  final double backAzimuth;

  MapTracker(this.backAzimuth);

  @override
  _MapTrackerState createState() => _MapTrackerState();
}

class _MapTrackerState extends State<MapTracker> {
  Position? _currentPosition;
  Position? _initialPosition;
  String _currentAddress = 'Getting location...';
  StreamSubscription<Position>? positionStream;
  double boxSize = 300.0;
  double iconSize = 25.0;
  double pathOffset =
      15.0; // Adjust the path offset to make the pink zone visible
  List<Position> positionHistory = []; // List to store position history

  Offset _blueIconOffset = Offset(0, 0); // Offset for blue icon position
  List<Offset> _blueIconTrail = []; // List to store the trail of the blue icon
  bool _isDialogOpen = false; // Variable to track if the dialog is open
  Timer? _dialogTimer; // Timer to delay the check after dialog is dismissed

  @override
  void initState() {
    super.initState();
    _checkPermissionAndGetLocation();
  }

  Future<void> _checkPermissionAndGetLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _currentAddress = 'Location services are disabled.';
      });
      return;
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _currentAddress = 'Location permissions are denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _currentAddress =
            'Location permissions are permanently denied, we cannot request permissions.';
      });
      return;
    }

    // When permissions are granted, start listening to location changes
    _startListeningToLocationChanges();
  }

  void _startListeningToLocationChanges() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );

    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        setState(() {
          _currentPosition = position;
          _currentAddress =
              'Lat: ${position.latitude}, Lon: ${position.longitude}';

          // Store initial position
          if (_initialPosition == null) {
            _initialPosition = position;
          }

          // Add current position to history
          positionHistory.add(position);

          // Add the new position to the trail
          _blueIconTrail.add(_calculateBlueIconPosition() +
              Offset(iconSize / 2, iconSize / 2));

          // Check if blue icon is outside the pink path
          if (!_isIconOnPath(_calculateBlueIconPosition()) && !_isDialogOpen) {
            _handleAlert();
          }
        });
      },
      onError: (error) {
        print('Error: $error');
      },
    );
  }

  Future<void> _handleAlert() async {
    _isDialogOpen = true;
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate();
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Warning'),
          content: Text('Anda keluar jalur'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isDialogOpen = false;
                });
                _startDialogTimer();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _startDialogTimer() {
    if (_dialogTimer != null) {
      _dialogTimer!.cancel();
    }
    _dialogTimer = Timer(Duration(seconds: 3), () {
      if (!_isIconOnPath(_calculateBlueIconPosition())) {
        _handleAlert();
      }
    });
  }

  @override
  void dispose() {
    positionStream?.cancel();
    _dialogTimer?.cancel();
    super.dispose();
  }

  Offset _calculateGreenIconPosition() {
    if (_currentPosition == null) return Offset(0, 0);

    double angleRad = (widget.backAzimuth - 90) * pi / 180;
    double radius = boxSize / 2 - iconSize - pathOffset;

    double dx = radius * cos(angleRad);
    double dy = radius * sin(angleRad);

    return Offset(
        boxSize / 2 + dx - iconSize / 2, boxSize / 2 + dy - iconSize / 2);
  }

  Offset _calculateBlueIconPosition() {
    if (_currentPosition == null || _initialPosition == null)
      return Offset(boxSize / 2 - iconSize / 2, boxSize / 2 - iconSize / 2);

    double factor =
        100000; // Factor for converting latitude/longitude to pixel coordinates

    // Convert latitude and longitude to pixel coordinates in the UI
    double latDiff =
        (_currentPosition!.latitude - _initialPosition!.latitude) * factor;
    double lonDiff =
        (_currentPosition!.longitude - _initialPosition!.longitude) * factor;

    double newDx = lonDiff + _blueIconOffset.dx;
    double newDy = latDiff + _blueIconOffset.dy;

    return Offset(
        boxSize / 2 + newDx - iconSize / 2, boxSize / 2 + newDy - iconSize / 2);
  }

  bool _isIconOnPath(Offset iconPosition) {
    double iconCenterX = iconPosition.dx + iconSize / 2;
    double iconCenterY = iconPosition.dy + iconSize / 2;

    Offset start = Offset(boxSize / 2, boxSize / 2);
    Offset end =
        _calculateGreenIconPosition() + Offset(iconSize / 2, iconSize / 2);

    // Tambahkan margin tambahan di luar garis merah jambu
    double margin = 0; // Sesuaikan margin ini sesuai kebutuhan

    // Hitung bounding box dari jalur merah jambu dengan margin tambahan
    double minX = min(start.dx, end.dx) - iconSize / 2 - margin;
    double maxX = max(start.dx, end.dx) + iconSize / 2 + margin;
    double minY = min(start.dy, end.dy) - iconSize / 2 - margin;
    double maxY = max(start.dy, end.dy) + iconSize / 2 + margin;

    // Cek apakah ikon berada di luar bounding box dari jalur merah jambu dengan margin tambahan
    if (iconCenterX < minX ||
        iconCenterX > maxX ||
        iconCenterY < minY ||
        iconCenterY > maxY) {
      return false;
    }

    // Hitung jarak dari pusat ikon ke garis
    double distance = _distanceToLine(
        iconCenterX, iconCenterY, start.dx, start.dy, end.dx, end.dy);

    return distance <= pathOffset + margin;
  }

  double _distanceToLine(
      double px, double py, double x1, double y1, double x2, double y2) {
    double A = px - x1;
    double B = py - y1;
    double C = x2 - x1;
    double D = y2 - y1;

    double dot = A * C + B * D;
    double len_sq = C * C + D * D;
    double param = (len_sq != 0) ? dot / len_sq : -1;

    double xx, yy;

    if (param < 0) {
      xx = x1;
      yy = y1;
    } else if (param > 1) {
      xx = x2;
      yy = y2;
    } else {
      xx = x1 + param * C;
      yy = y1 + param * D;
    }

    double dx = px - xx;
    double dy = py - yy;
    return sqrt(dx * dx + dy * dy);
  }

  @override
  Widget build(BuildContext context) {
    Offset greenIconPosition = _calculateGreenIconPosition();
    Offset blueIconPosition = _calculateBlueIconPosition();

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Map Tracker',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Back Azimuth: ${widget.backAzimuth.toStringAsFixed(2)}°',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              _currentAddress,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onPanUpdate: (details) {
                if (!_isDialogOpen) {
                  setState(() {
                    _blueIconOffset += details.delta;

                    // Add the new position to the trail
                    _blueIconTrail.add(_calculateBlueIconPosition() +
                        Offset(iconSize / 2, iconSize / 2));
                  });
                }
              },
              onPanEnd: (details) {
                if (!_isDialogOpen) {
                  _startDialogTimer();
                }
              },
              child: Container(
                width: boxSize,
                height: boxSize,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Stack(
                  children: [
                    // Grid background
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GridPainter(),
                      ),
                    ),
                    // Purple trail
                    Positioned.fill(
                      child: CustomPaint(
                        painter: TrailPainter(trail: _blueIconTrail),
                      ),
                    ),
                    // Pink path zone
                    Positioned.fill(
                      child: CustomPaint(
                        painter: PathPainter(
                          startPoint: Offset(boxSize / 2, boxSize / 2),
                          endPoint: greenIconPosition +
                              Offset(iconSize / 2, iconSize / 2),
                          pathOffset: pathOffset,
                        ),
                      ),
                    ),
                    // Blue icon (drag target)
                    Positioned(
                      left: blueIconPosition.dx,
                      top: blueIconPosition.dy,
                      child: Icon(Icons.location_on,
                          color: Colors.blue, size: iconSize),
                    ),
                    // Green icon (fixed point)
                    Positioned(
                      left: greenIconPosition.dx,
                      top: greenIconPosition.dy,
                      child: Icon(Icons.location_on,
                          color: Colors.green, size: iconSize),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Navigate back to home screen
              },
              child: Text('Stop'),
            ),
          ],
        ),
      ),
    );
  }
}

class PathPainter extends CustomPainter {
  final Offset startPoint;
  final Offset endPoint;
  final double pathOffset;

  PathPainter(
      {required this.startPoint,
      required this.endPoint,
      required this.pathOffset});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.pink.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = pathOffset * 2;

    Path path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);
    path.lineTo(endPoint.dx, endPoint.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class TrailPainter extends CustomPainter {
  final List<Offset> trail;

  TrailPainter({required this.trail});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (trail.isNotEmpty) {
      Path path = Path()..moveTo(trail.first.dx, trail.first.dy);
      for (Offset point in trail) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    double stepSize = 20.0; // The size of each grid square

    for (double x = 0; x <= size.width; x += stepSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += stepSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
