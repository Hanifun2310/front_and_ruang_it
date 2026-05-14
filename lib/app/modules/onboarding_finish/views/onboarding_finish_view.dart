import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/onboarding_finish_controller.dart';

class OnboardingFinishView extends GetView<OnboardingFinishController> {
  const OnboardingFinishView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Icon or Illustration (Optional but good for premium feel)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.blueAccent,
                  size: 50,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Selamat membaca',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Semoga anda menemukan inovasi yang dapat memotivasi anda',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => controller.goToDashboard(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Mulai Membaca',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
