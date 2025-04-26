import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../../components/AppColors.dart';
import '../../../../components/CustomButton.dart';
import '../../../../core/constants.dart';
import '../../../../core/shared_prefs_utils.dart';
import '../../../../routes/app_router.dart';
import '../providers/bus_details_provider.dart';

class BusDetailScreen extends ConsumerStatefulWidget {
  const BusDetailScreen({super.key, required this.busId});

  final int busId;

  @override
  ConsumerState<BusDetailScreen> createState() => _BusDetailScreenState();
}

class _BusDetailScreenState extends ConsumerState<BusDetailScreen> {
  int? groupId;
  String? groupName;
  double _selectedRating = 0.0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  double _averageRating = 0.0;
  int _totalRatings = 0;

  // Ratings fetched on init
  List<dynamic> _fetchedRatings = [];
  bool _ratingsLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(busDetailsProvider.notifier).fetchBusDetail(widget.busId);
      getChatGroup();
      fetchRatings();
      fetchRatingsList(); // Fetch all ratings initially
    });
  }

  void getChatGroup() async {
    try {
      final url = Uri.parse("$apiBaseUrl/vehicles/${widget.busId}/chatGroup");
      final tokenData = await SharedPrefsUtil.getToken();
      final token = tokenData is Map ? tokenData["token"] : tokenData;
      final header = {
        'Authorization': 'Bearer $token',
      };
      final data = await http.get(url, headers: header);
      if (data.statusCode == 200 || data.statusCode == 201) {
        final response = json.decode(data.body);
        final groupData = response['message'];
        groupId = groupData['id'];
        groupName = groupData['name'];
      }
    } catch (e) {
      print(e);
    }
  }

  void fetchRatings() async {
    final driverId = ref.read(busDetailsProvider).vehicle?.owner?.id;
    if (driverId == null) return;

    final response =
        await http.get(Uri.parse('$apiBaseUrl/getRating/$driverId'));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List ratings = json['result'];
      if (ratings.isEmpty) {
        setState(() {
          _averageRating = 0.0;
          _totalRatings = 0;
        });
        return;
      }
      if (ratings.isNotEmpty) {
        double sum =
            ratings.fold(0.0, (acc, val) => acc + (val['rating'] ?? 0));
        setState(() {
          _averageRating =
              double.parse((sum / ratings.length).toStringAsFixed(1));
          _totalRatings = ratings.length;
        });
      }
    }
  }

  Future<void> fetchRatingsList() async {
    final driverId = ref.read(busDetailsProvider).vehicle?.owner?.id;
    if (driverId == null) {
      setState(() {
        _fetchedRatings = [];
        _ratingsLoading = false;
      });
      return;
    }
    final response =
        await http.get(Uri.parse('$apiBaseUrl/getRating/$driverId'));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      setState(() {
        _fetchedRatings = json['result'] ?? [];
        _ratingsLoading = false;
      });
    } else {
      setState(() {
        _fetchedRatings = [];
        _ratingsLoading = false;
      });
    }
  }

  void _showAllRatings() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('All Reviews'),
          content: SizedBox(
            width: double.maxFinite,
            child: _ratingsLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _fetchedRatings.isEmpty
                    ? Text('No reviews available.')
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _fetchedRatings.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: AppColors.background),
                        itemBuilder: (context, index) {
                          final rating = _fetchedRatings[index];
                          final user = rating['user'];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.2),
                              child: Text(
                                user?['username'] != null
                                    ? user['username'][0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(user?['username'] ?? 'Unknown User'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rating['review'] ?? 'No comment'),
                                SizedBox(height: 4),
                                Row(
                                  children: List.generate(
                                    5,
                                    (starIndex) => Icon(
                                      starIndex < (rating['rating'] ?? 0)
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 16,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  void _submitReview() async {
    if (_reviewController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    final tokenData = await SharedPrefsUtil.getToken();
    final token = tokenData is Map ? tokenData["token"] : tokenData;
    final driverId = ref.read(busDetailsProvider).vehicle?.owner?.id;

    if (driverId == null) {
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    final response = await http.post(
      Uri.parse("$apiBaseUrl/rating"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "driverId": driverId,
        "rating": _selectedRating,
        "review": _reviewController.text.trim(),
      }),
    );

    setState(() {
      _isSubmitting = false;
    });

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Review submitted successfully"),
          backgroundColor: AppColors.primary,
        ),
      );
      _reviewController.clear();
      setState(() {
        _selectedRating = 0.0;
      });

      // Refresh ratings
      fetchRatings();
      fetchRatingsList();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to submit review"),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busDetailState = ref.watch(busDetailsProvider);
    final vehicle = busDetailState.vehicle;

    int bookedSeatsCount = vehicle?.booking?.where((b) {
          final bookingDate = DateTime.parse(b.bookingDate ?? '');
          final tomorrow = DateTime.now().add(const Duration(days: 1));
          return bookingDate.year == tomorrow.year &&
              bookingDate.month == tomorrow.month &&
              bookingDate.day == tomorrow.day;
        }).fold(
            0, (sum, booking) => sum! + (booking.bookingSeats?.length ?? 0)) ??
        0;

    final seatCount = (vehicle?.vehicleSeat?.length ?? 0) - bookedSeatsCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Bus Information",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ref.watch(busDetailsProvider).isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : Stack(
              children: [
                // Top curved background
                Container(
                  height: 80.h,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30.r),
                      bottomRight: Radius.circular(30.r),
                    ),
                  ),
                ),

                // Main content
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 80.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bus info card
                      _buildBusInfoCard(),

                      // Ratings section
                      Padding(
                        padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: AppColors.accent,
                              size: 16.r,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              "$_totalRatings Reviews",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14.sp,
                              ),
                            ),
                            Spacer(),
                            InkWell(
                              onTap: _showAllRatings,
                              borderRadius: BorderRadius.circular(20.r),
                              child: Padding(
                                padding: EdgeInsets.all(4.r),
                                child: Row(
                                  children: [
                                    Text(
                                      "Show All",
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 12.r,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Driver details
                      _buildDriverDetails(),

                      SizedBox(height: 20.h),

                      // Review input section
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.rate_review,
                                  color: AppColors.primary,
                                  size: 20.r,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  "Leave a Review",
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                color: AppColors.background,
                              ),
                              child: TextFormField(
                                controller: _reviewController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(
                                      color: AppColors.primary.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(
                                      color: AppColors.primary,
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(
                                      color: AppColors.primary.withOpacity(0.3),
                                    ),
                                  ),
                                  hintText: 'Write your review here...',
                                  hintStyle: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14.sp,
                                  ),
                                  contentPadding: EdgeInsets.all(16.r),
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Row(
                              children: [
                                Text(
                                  "Your Rating:",
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                RatingBar.builder(
                                  initialRating: _selectedRating,
                                  minRating: 1,
                                  direction: Axis.horizontal,
                                  allowHalfRating: false,
                                  itemCount: 5,
                                  itemSize: 24.r,
                                  itemBuilder: (context, _) => Icon(
                                    Icons.star,
                                    color: AppColors.accent,
                                  ),
                                  onRatingUpdate: (rating) {
                                    setState(() {
                                      _selectedRating = rating;
                                    });
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSubmitting || _selectedRating == 0
                                    ? null
                                    : _submitReview,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  elevation: 0,
                                  disabledBackgroundColor:
                                      AppColors.primary.withOpacity(0.3),
                                ),
                                child: _isSubmitting
                                    ? SizedBox(
                                        height: 20.r,
                                        width: 20.r,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.w,
                                        ),
                                      )
                                    : Text(
                                        "Submit Review",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16.sp,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: ref.watch(busDetailsProvider).isLoading
          ? null
          : Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Chat button
                  Expanded(
                    flex: 1,
                    child: InkWell(
                      onTap: () {
                        if (groupId != null && groupName != null) {
                          context.pushNamed(
                            'chat',
                            extra: ChatArgs(groupId!, groupName!),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Chat group not yet loaded. Please wait.'),
                              backgroundColor: AppColors.accent,
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_outlined,
                              color: AppColors.primary,
                              size: 20.r,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "Chat",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // Book seat button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => context.pushNamed(
                        '/book',
                        pathParameters: {'id': widget.busId.toString()},
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Book Seat",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBusInfoCard() {
    final vehicle = ref.watch(busDetailsProvider).vehicle;

    final bookedSeatsCount = vehicle?.booking?.where((b) {
          final bookingDate = DateTime.parse(b.bookingDate ?? "");
          final tomorrow = DateTime.now().add(const Duration(days: 1));
          return bookingDate.year == tomorrow.year &&
              bookingDate.month == tomorrow.month &&
              bookingDate.day == tomorrow.day;
        }).fold(
            0, (sum, booking) => sum + (booking.bookingSeats?.length ?? 0)) ??
        0;

    final availableSeats =
        (vehicle?.vehicleSeat?.length ?? 0) - bookedSeatsCount;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.iconColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_bus,
                  color: AppColors.primary,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bus No ${vehicle?.vehicleNo ?? 'N/A'}",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    vehicle?.model ?? 'Standard Bus',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  "Rs.${vehicle?.route?[0].fare ?? 'N/A'}",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Route and timing section
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                // Route name if available
                if (vehicle?.route?.isNotEmpty == true &&
                    vehicle?.route?[0].name != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.route,
                          color: AppColors.textSecondary,
                          size: 18.r,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          vehicle!.route![0].name!,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Time section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Departure",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          vehicle?.departure != null
                              ? DateFormat.jm()
                                  .format(DateTime.parse(vehicle!.departure!))
                              : 'N/A',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),

                    // Route line
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 2.h,
                              color: AppColors.textSecondary.withOpacity(0.3),
                            ),
                            Icon(
                              Icons.arrow_forward,
                              color: AppColors.textSecondary,
                              size: 18.r,
                            ),
                          ],
                        ),
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Arrival",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          vehicle?.arrivalTime != null
                              ? DateFormat.jm()
                                  .format(DateTime.parse(vehicle!.arrivalTime!))
                              : 'N/A',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Info tags
          Row(
            children: [
              _buildInfoTag(
                icon: Icons.event_seat,
                text: "$availableSeats Available",
                backgroundColor: AppColors.primary.withOpacity(0.1),
                iconColor: AppColors.primary,
              ),
              SizedBox(width: 10.w),
              _buildInfoTag(
                icon: Icons.access_time,
                text: "${_calculateTravelTime(vehicle)} Journey",
                backgroundColor: AppColors.iconColor.withOpacity(0.3),
                iconColor: AppColors.primary,
              ),
              const Spacer(),
              _buildRatingTag(
                  _averageRating > 0 ? _averageRating.toString() : "0"),
            ],
          ),
        ],
      ),
    );
  }

  String _calculateTravelTime(vehicle) {
    if (vehicle?.departure == null || vehicle?.arrivalTime == null) {
      return "N/A";
    }

    try {
      final departure = DateTime.parse(vehicle.departure);
      final arrival = DateTime.parse(vehicle.arrivalTime);
      print(departure);
      print(arrival);

      final duration = arrival.difference(departure);

      if (duration.inHours > 0) {
        return "${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
      } else {
        return "${duration.inMinutes}m";
      }
    } catch (e) {
      return "N/A";
    }
  }

  Widget _buildDriverDetails() {
    final owner = ref.watch(busDetailsProvider).vehicle?.owner;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 2.w,
              ),
            ),
            child: CircleAvatar(
              radius: 30.r,
              backgroundColor: AppColors.iconColor.withOpacity(0.3),
              backgroundImage: owner?.images != null
                  ? NetworkImage(imageUrl + owner!.images!)
                  : null,
              child: owner?.images == null
                  ? Icon(
                      Icons.person,
                      size: 30.r,
                      color: AppColors.primary,
                    )
                  : null,
            ),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  owner?.username ?? 'N/A',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  owner?.phone ?? 'N/A',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    "Driver",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => launchUrl(Uri(scheme: 'tel', path: owner?.phone)),
            borderRadius: BorderRadius.circular(30.r),
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.call,
                color: AppColors.primary,
                size: 22.r,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTag({
    required IconData icon,
    required String text,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 16.r,
          ),
          SizedBox(width: 6.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingTag(String rating) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: AppColors.accent,
            size: 16.r,
          ),
          SizedBox(width: 4.w),
          Text(
            rating,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
