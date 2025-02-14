import 'package:flutter/material.dart';

class SelectSeatsScreen extends StatefulWidget {
  final String vehicleType;
  final Set<String> selectedSeats;

  const SelectSeatsScreen(
      {super.key, required this.vehicleType, required this.selectedSeats});

  @override
  _SelectSeatsScreenState createState() => _SelectSeatsScreenState();
}

class _SelectSeatsScreenState extends State<SelectSeatsScreen> {
  Set<String> _selectedSeats = {};

  @override
  void initState() {
    super.initState();
    _selectedSeats =
        Set.from(widget.selectedSeats); // Initialize with previous selection
  }

  /// **Determines Seat Layout Based on Vehicle Type**
  List<List<String>> getSeatLayout() {
    if (widget.vehicleType == 'Bus') {
      return [
        ['1', '2', '', '3', '4'],
        ['5', '6', '', '7', '8'],
        ['9', '10', '', '11', '12'],
        ['13', '14', '', '15', '16'],
        ['17', '18', '', '19', '20'],
        ['21', '22', '', '23', '24'],
        ['25', '26', '', '27', '28'],
        ['29', '30', '', '31', '32'],
        ['33', '34', '', '35', '36'],
        ['37', '38', '39', '40', '41'],
      ];
    } else {
      return [
        ['1', '2'],
        ['3', '4'],
        ['5', '6']
      ];
    }
  }

  /// **Handles Seat Selection/Deselection**
  void _toggleSeatSelection(String seat) {
    setState(() {
      if (_selectedSeats.contains(seat)) {
        _selectedSeats.remove(seat);
      } else {
        _selectedSeats.add(seat);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Seats")),
      body: Column(
        children: [
          SizedBox(height: 10),
          Text("Tap on a seat to select or deselect",
              style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          _buildSeatLayout(),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, _selectedSeats); // Return selected seats
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  /// **Builds the Seat Layout**
  Widget _buildSeatLayout() {
    return Column(
      children: getSeatLayout().map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((seat) {
            return seat.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: GestureDetector(
                      onTap: () => _toggleSeatSelection(seat),
                      child: Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _selectedSeats.contains(seat)
                              ? Colors.blue
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          seat,
                          style: TextStyle(
                            color: _selectedSeats.contains(seat)
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                : SizedBox(width: 40); // Empty space for aisle
          }).toList(),
        );
      }).toList(),
    );
  }
}
