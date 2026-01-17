import 'package:firebase_core/firebase_core.dart'; // ⬅️ هذا السطر الناقص

class FirebaseConfig {
  // ⚠️ هذا للتطوير فقط - لا تستخدمه للإنتاج
  static const Map<String, dynamic> devConfig = {
    'apiKey': "AIzaSyABiN16MklWtX00PC6UHLSDKJCrPd9EwZs",
    'authDomain': "loverchat190.firebaseapp.com",
    'projectId': "loverchat190",
    'storageBucket': "loverchat190.firebasestorage.app",
    'messagingSenderId': "971632978916",
    'appId': "1:971632978916:web:355f73309996d4a6d935f1",
  };

  static FirebaseOptions get options {
    return FirebaseOptions(
      apiKey: devConfig['apiKey']!,
      appId: devConfig['appId']!,
      messagingSenderId: devConfig['messagingSenderId']!,
      projectId: devConfig['projectId']!,
      storageBucket: devConfig['storageBucket']!,
      authDomain: devConfig['authDomain']!,
    );
  }
}
