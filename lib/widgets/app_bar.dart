
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import for SvgPicture
import '../Presentation/info_screen.dart';
import '../Presentation/notification_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;

  const CustomAppBar({
    Key? key,
    this.title,
    this.elevation = 0.0,
    this.scrolledUnderElevation = 0.0,
  }) : super(key: key);

  final double elevation;
  final double scrolledUnderElevation;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      forceMaterialTransparency: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: SvgPicture.asset(
            'assets/images/hamburger_icon.svg', // Ensure this path is correct
            width: 15.00,
            height: 15.00,
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: title != null && title!.isNotEmpty
          ? Text(
        title!,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          color: Color(0xFF00255D),
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
      )
          : SvgPicture.asset(
        'assets/images/appbar_icon.svg',
        width: 30.0, // Adjust width if needed
        height: 30.0, // Adjust height if needed
      ),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 0.0), // Padding around the container
          child: Row(
            mainAxisSize: MainAxisSize.min, // Minimize the size of the row
            children: [
              IconButton(
                icon: SvgPicture.asset(
                  'assets/images/info_icon.svg',
                  width: 20.0, // Adjust the width as needed
                  height: 20.0, // Adjust the height as needed
                ),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const InfoScreen()));
                },
              ),
              // const SizedBox(width: 20), // Space between the icons
              IconButton(
                icon: SvgPicture.asset(
                  'assets/images/bell_icon.svg',
                  width: 20.0, // Adjust the width as needed
                  height: 20.0, // Adjust the height as needed
                ),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NotificationScreen(id: 1, fromDate: DateTime.now() /*DateTime(09,28,2020)*/, toDate: DateTime.now(),)));
                },
              ),
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.0),
        child: Container(
          color: const Color(0xFF00255D),
          height: 1.0,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
