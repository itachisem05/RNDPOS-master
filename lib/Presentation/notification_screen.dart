import 'package:flutter/material.dart';
import 'package:usa/API/api_service.dart';
import '../screens/menu_screen.dart';
import '../widgets/app_bar.dart' as custom_app_bar;

class NotificationScreen extends StatefulWidget {
  final int selectedTabIndex;
  final int id;
  final DateTime fromDate;
  final DateTime toDate;

  const NotificationScreen({
    super.key,
    this.selectedTabIndex = 0,
    required this.id,
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _selectedTabIndex = 0;
  int _selectedId = 1;
  List<String> sentencesList = [];
  bool isLoading = true;
  bool hasMoreData = false;
  int _currentPage = 1;
  late final ApiService _apiService;

  final List<int> _tabIds = [1, 5, 6]; // IDs for Delete, Void, No Sale

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.selectedTabIndex;
    _selectedId = widget.id;
    _apiService = ApiService();
    _getAllReasonDetail();
  }

  void _getAllReasonDetail({int page = 1}) async {
    setState(() => isLoading = true);
    try {
      var data = await _apiService.getAllReasonDetail(
        reasonID: _selectedId,
        fromDate: _formatDate(widget.fromDate),
        endDate: _formatDate(widget.toDate),
        pageNumber: page,
      );

      // Only update sentencesList and pagination info
      if (page == 1) {
        sentencesList = List<String>.from(data['sentences']);
      } else {
        sentencesList.addAll(List<String>.from(data['sentences']));
      }

      _currentPage = data['currentPage'];
      hasMoreData = _currentPage < data['totalPages'];

      // Update the loading state
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('An error occurred: $e');
      setState(() {
        isLoading = false;
        hasMoreData = false;
      });
    }
  }

  void _loadMoreNotifications() {
    if (hasMoreData) {
      _getAllReasonDetail(page: _currentPage + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: MenuScreen(),
      appBar: const custom_app_bar.CustomAppBar(
        title: 'Notification',
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 15),
        child: Column(
          children: [
            _buildTabs(),
            Expanded(child: _buildContent()),
            if (hasMoreData) _buildLoadMoreButton(), // Load More button
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(3, (index) {
              return GestureDetector(
                onTap: () => _onTabSelected(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == index ? const Color(0xFF00255D) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    index == 0 ? 'Delete' : index == 1 ? 'Void' : 'No Sale',
                    style: TextStyle(
                      color: _selectedTabIndex == index ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            }),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 1,
            color: const Color(0xFF00255D),
          ),
        ],
      ),
    );
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
      _selectedId = _tabIds[index];
      _currentPage = 1; // Reset to the first page
    });
    _getAllReasonDetail(); // Fetch data for the selected tab
  }

  Widget _buildContent() {
    return ListView.builder(
      itemCount: sentencesList.length,
      itemBuilder: (context, index) {
        String sentence = sentencesList[index];
        return Container(
          color: const Color(0xFFF0F8FF),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sentence,
                style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
              ),
              // SizedBox(height: 8),
              // Text(
              //   'Today, 10:23 AM',
              //   style: TextStyle(fontSize: 14, color: Color(0xFF7E7E7E)),
              // ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _loadMoreNotifications,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF00355E),
            side: const BorderSide(color: Color(0xFFA4D5FF)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: isLoading
              ? const CircularProgressIndicator() // Show loading indicator
              : const Text('Load More'),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const String separator = '/';
    return '${date.month.toString().padLeft(2, '0')}$separator${date.day.toString().padLeft(2, '0')}$separator${date.year}';
  }
}
