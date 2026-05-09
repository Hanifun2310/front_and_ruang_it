import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const LoadingWidget({
    Key? key, 
    this.size = 40.0, 
    this.color,
    this.strokeWidth = 3.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.blueAccent),
            ),
          ),
          Image.asset(
            'assets/images/newlogo.png',
            width: size * 0.5,
            height: size * 0.5,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.rocket_launch_rounded, // Fallback icon
              size: 20,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }
}
