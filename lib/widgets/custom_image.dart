import 'package:flutter/material.dart';

class CustomImageView extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final BoxFit fit;
  final Alignment alignment;

  const CustomImageView({
    Key? key,
    required this.imagePath,
    this.width = 100.0,
    this.height = 100.0,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: alignment,
      child: Image.asset(
        imagePath,
        fit: fit,
      ),
    );
  }
}