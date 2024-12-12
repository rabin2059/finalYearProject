import 'package:flutter/material.dart';
import '../models/bus.dart';

class BusDetailsCard extends StatelessWidget {
  final Bus bus;
  final VoidCallback onViewDetails;

  const BusDetailsCard({
    Key? key,
    required this.bus,
    required this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bus ${bus.busNumber}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bus.status == 'On Time' ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    bus.status,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text('Driver: ${bus.driverName}'),
            Text('Route: ${bus.routeName}'),
            Text('Next Stop: ${bus.nextStop}'),
            Text('ETA: ${bus.estimatedArrival}'),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onViewDetails,
                child: Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 