import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkController extends GetxController {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool isOffline = false;

  @override
  void onInit() {
    super.onInit();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> connectivityResults) {
    bool hasNoConnection = connectivityResults.every((result) => result == ConnectivityResult.none);
    
    if (hasNoConnection) {
      if (!isOffline) {
        isOffline = true;
        _showOfflineBanner();
      }
    } else {
      if (isOffline) {
        isOffline = false;
        if (Get.isSnackbarOpen) {
          Get.closeCurrentSnackbar();
        }
        _showOnlineBanner();
      }
    }
  }

  void _showOfflineBanner() {
    Get.rawSnackbar(
      messageText: const Text(
        'Anda sedang offline. Silakan periksa koneksi internet Anda.',
        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      isDismissible: true,
      duration: const Duration(days: 1), // Practically infinite until dismissed or online
      backgroundColor: Colors.red[600]!,
      icon: const Icon(Icons.wifi_off, color: Colors.white, size: 20),
      margin: EdgeInsets.zero,
      snackStyle: SnackStyle.GROUNDED,
      snackPosition: SnackPosition.TOP,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  void _showOnlineBanner() {
    Get.rawSnackbar(
      messageText: const Text(
        'Koneksi kembali pulih.',
        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      isDismissible: true,
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.green[600]!,
      icon: const Icon(Icons.wifi, color: Colors.white, size: 20),
      margin: EdgeInsets.zero,
      snackStyle: SnackStyle.GROUNDED,
      snackPosition: SnackPosition.TOP,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  void onClose() {
    _connectivitySubscription.cancel();
    super.onClose();
  }
}
