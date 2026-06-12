import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Request all permissions the app needs
  static Future<void> requestAppPermissions() async {
    try {
      if (Platform.isIOS) {
        // On iOS, only request location (phone permission doesn't exist)
        await Permission.location.request();
      } else {
        await [Permission.phone, Permission.location].request();
      }
    } catch (e) {
      // Silently handle — permissions will be requested when needed
    }
  }

  // Check if phone permission is granted
  static Future<bool> hasPhonePermission() async {
    return await Permission.phone.isGranted;
  }

  // Check if location permission is granted
  static Future<bool> hasLocationPermission() async {
    return await Permission.location.isGranted;
  }

  // Open app settings if user denied permanently
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
