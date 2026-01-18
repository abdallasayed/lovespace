import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import '../../home/screens/home_screen.dart'; // سننشئه لاحقاً
import '../../couple/screens/waiting_screen.dart'; // سننشئه لاحقاً
import '../../couple/screens/incoming_request_screen.dart'; // سننشئه لاحقاً
import '../../couple/screens/link_partner_screen.dart'; // سننشئه لاحقاً

class LinkGate extends StatelessWidget {
  const LinkGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // 1. إذا لم يكن مسجلاً للدخول -> شاشة الدخول
        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        final user = authSnapshot.data!;
        
        // 2. إذا مسجل دخول -> نفحص حالة الارتباط من قاعدة البيانات
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
            
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final status = data?['status'] ?? 'single';

            // توجيه المستخدم حسب حالته
            if (status == 'linked') {
               // إذا مرتبط -> نذهب للصفحة الرئيسية
               // ملاحظة: سنحتاج لتعديل home_screen ليقبل coupleId
               return HomeScreen(
                 coupleId: data!['partnerId'],
                 linkedDate: (data['linkedAt'] as Timestamp?)?.toDate() ?? DateTime.now()
               );
            }
            
            if (status == 'sent_request') return const WaitingScreen();
            
            if (status == 'received_request') {
              return IncomingRequestScreen(senderData: data!['incomingRequest']);
            }

            // الحالة الافتراضية: البحث عن شريك
            return const LinkPartnerScreen();
          },
        );
      },
    );
  }
}

