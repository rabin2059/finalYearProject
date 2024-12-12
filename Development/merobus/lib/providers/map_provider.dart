import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/bus.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

class MapProvider extends ChangeNotifier {
  List<Bus> _buses = [];
  List<Bus> get buses => _buses;
  List<LatLng> _routePoints = [];
  Map<String, double> _busProgressOnRoute = {};
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;

  // Mock bus data generator
  Bus _generateMockBus(LatLng location, int index, double progress) {
    final List<String> driverNames = [
      'Ram Sharma', 'Hari Krishna', 'Sita Poudel', 
      'Binod Thapa', 'Sunil KC', 'Prakash Gurung'
    ];
    
    final List<String> routeNames = [
      'Kalanki - Koteshwor', 'Balaju - Ratnapark',
      'Thankot - Gaushala', 'Budhanilkantha - Lagankhel',
      'Maharajgunj - Satdobato', 'Gongabu - Sinamangal'
    ];

    final List<String> nextStops = [
      'Ratnapark', 'New Road', 'Koteshwor', 
      'Tinkune', 'Balaju', 'Kalanki'
    ];

    final List<String> statuses = ['On Time', 'Delayed', 'On Route'];
    final String busId = 'BUS_${index + 1}';
    _busProgressOnRoute[busId] = progress;

    return Bus(
      id: busId,
      driverName: driverNames[index % driverNames.length],
      busNumber: 'BA ${1234 + index} KH',
      routeName: routeNames[index % routeNames.length],
      latitude: location.latitude,
      longitude: location.longitude,
      status: statuses[index % statuses.length],
      nextStop: nextStops[index % nextStops.length],
      estimatedArrival: '${(index % 30) + 5} minutes',
    );
  }

  // Initialize buses with route points
  Future<void> initializeBusesOnRoute(List<LatLng> routePoints) async {
    _routePoints = routePoints;
    if (_routePoints.isEmpty) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Simulate network delay
      await Future.delayed(Duration(seconds: 1));

      // Create 5 buses at different positions along the route
      _buses = List.generate(5, (index) {
        double initialProgress = index * 0.2; // Spread buses along the route
        LatLng position = _getPositionAlongRoute(initialProgress);
        return _generateMockBus(position, index, initialProgress);
      });

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get position along the route based on progress (0.0 to 1.0)
  LatLng _getPositionAlongRoute(double progress) {
    if (_routePoints.isEmpty) return LatLng(0, 0);

    // Ensure progress is between 0 and 1
    progress = progress % 1.0;
    
    // Calculate the point index based on progress
    int maxIndex = _routePoints.length - 1;
    double exactIndex = progress * maxIndex;
    int currentIndex = exactIndex.floor();
    int nextIndex = (currentIndex + 1).clamp(0, maxIndex);
    
    // Calculate interpolation factor between points
    double factor = exactIndex - currentIndex;
    
    // Interpolate between current and next point
    return LatLng(
      _routePoints[currentIndex].latitude + 
          (_routePoints[nextIndex].latitude - _routePoints[currentIndex].latitude) * factor,
      _routePoints[currentIndex].longitude + 
          (_routePoints[nextIndex].longitude - _routePoints[currentIndex].longitude) * factor,
    );
  }

  // Simulate smooth bus movement along the route
  void simulateBusMovement() {
    if (_buses.isEmpty || _routePoints.isEmpty) return;

    List<Bus> updatedBuses = [];
    
    for (var bus in _buses) {
      // Update progress for this bus
      double currentProgress = _busProgressOnRoute[bus.id] ?? 0.0;
      double newProgress = currentProgress + 0.005; // Speed of movement
      _busProgressOnRoute[bus.id] = newProgress;

      // Get new position along the route
      LatLng newPosition = _getPositionAlongRoute(newProgress);

      // Create updated bus with new position
      updatedBuses.add(Bus(
        id: bus.id,
        driverName: bus.driverName,
        busNumber: bus.busNumber,
        routeName: bus.routeName,
        latitude: newPosition.latitude,
        longitude: newPosition.longitude,
        status: bus.status,
        nextStop: bus.nextStop,
        estimatedArrival: bus.estimatedArrival,
      ));
    }

    _buses = updatedBuses;
    notifyListeners();
  }

  // Update route and reinitialize buses
  void updateRoute(List<LatLng> newRoutePoints) {
    _routePoints = newRoutePoints;
    initializeBusesOnRoute(newRoutePoints);
  }
} 