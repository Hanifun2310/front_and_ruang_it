import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../../routes/app_routes.dart';
import '../controllers/guidelines_controller.dart';

class GuidelinesView extends GetView<GuidelinesController> {
  const GuidelinesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panduan Penulisan'),
        backgroundColor: context.theme.appBarTheme.backgroundColor,
        foregroundColor: context.theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.loadGuidelines,
                    child: const Text('Muat ulang'),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: HtmlWidget(
            controller.htmlContent.value,
            textStyle: TextStyle(
              color: Get.isDarkMode ? Colors.white70 : Colors.black87,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        );
      }),
    );
  }
}
