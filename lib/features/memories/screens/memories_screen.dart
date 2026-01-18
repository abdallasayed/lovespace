import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // المكتبة الأساسية

class MemoriesScreen extends StatefulWidget {
  final String coupleId;
  const MemoriesScreen({super.key, required this.coupleId});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  // دالة الرفع المباشرة والسريعة
  Future<String?> _uploadToUploadcare(File file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('https://upload.uploadcare.com/base/'));
      request.fields['UPLOADCARE_PUB_KEY'] = '8e2cb6a00c4b7dd45f95';
      request.fields['UPLOADCARE_STORE'] = '1'; // تخزين دائم
      
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);
        return json['file']; // يرجع كود الملف (UUID)
      }
    } catch (e) {
      debugPrint("Error uploading: $e");
    }
    return null;
  }

  Future<void> _uploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("جاري الرفع...")));
      
      try {
        final file = File(image.path);
        
        // 1. استخدام دالة الرفع الجديدة
        final String? fileId = await _uploadToUploadcare(file);

        if (fileId != null) {
          final String url = "https://ucarecdn.com/$fileId/";

          // 2. الحفظ في فايربيز
          await FirebaseFirestore.instance
              .collection('couples')
              .doc(widget.coupleId)
              .collection('images')
              .add({
            'url': url,
            'senderId': FirebaseAuth.instance.currentUser!.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });

          FirebaseFirestore.instance
              .collection('couples')
              .doc(widget.coupleId)
              .collection('notifications')
              .add({
            'text': "صورة جديدة 📸",
            'senderId': FirebaseAuth.instance.currentUser!.uid,
            'timestamp': FieldValue.serverTimestamp(),
          });
        } else {
          throw "فشل الاتصال بالخادم";
        }

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ألبوم الذكريات"),
        actions: [IconButton(onPressed: _uploadImage, icon: const Icon(Icons.add_a_photo))],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('couples')
            .doc(widget.coupleId)
            .collection('images')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("أضف أول صورة لذكراكم!"));

          return GridView.builder(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final url = (docs[index].data() as Map<String, dynamic>)['url'];
              return ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(url, fit: BoxFit.cover),
              );
            },
          );
        },
      ),
    );
  }
}

