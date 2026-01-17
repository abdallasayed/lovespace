import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'عشاق';
  static const String appVersion = '1.0.0';
  
  // Firestore collections
  static const String usersCollection = 'users';
  static const String couplesCollection = 'couples';
  static const String messagesCollection = 'messages';
  static const String imagesCollection = 'images';
  static const String musicCollection = 'music';
  static const String notificationsCollection = 'notifications';
  
  // User status
  static const String statusSingle = 'single';
  static const String statusSentRequest = 'sent_request';
  static const String statusReceivedRequest = 'received_request';
  static const String statusLinked = 'linked';
  
  // Colors
  static const Color primaryColor = Color(0xFFE11D48);
  static const Color secondaryColor = Color(0xFF9333EA);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color textColor = Color(0xFF333333);
  static const Color greyColor = Color(0xFF9CA3AF);
}
