import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WaitingScreen extends StatelessWidget {
  const WaitingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFE11D48)),
            const SizedBox(height: 30),
            const Text(
              "تم إرسال الطلب بنجاح! 💌",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "بانتظار موافقة الطرف الآخر...",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 50),
            TextButton.icon(
              onPressed: () async {
                // إلغاء الطلب
                final uid = FirebaseAuth.instance.currentUser!.uid;
                // ملاحظة: في التطبيق الحقيقي يجب حذف الطلب من عند الطرف الآخر أيضاً
                // هنا نقوم بإرجاع حالتي فقط للتبسيط
                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'status': 'single',
                  'targetEmail': FieldValue.delete(),
                });
              },
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              label: const Text("إلغاء الطلب", style: TextStyle(color: Colors.red)),
            )
          ],
        ),
      ),
    );
  }
}

