import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart'; // مكتبة الصلاحيات

class MemoriesScreen extends StatefulWidget {
  final String coupleId;
  const MemoriesScreen({super.key, required this.coupleId});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  bool _isUploading = false;

  Future<String?> _uploadToUploadcare(File file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('https://upload.uploadcare.com/base/'));
      request.fields['UPLOADCARE_PUB_KEY'] = '8e2cb6a00c4b7dd45f95';
      request.fields['UPLOADCARE_STORE'] = '1';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);
        return json['file'];
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    return null;
  }

  Future<void> _uploadImage() async {
    // 1. طلب الصلاحية أولاً (حل مشكلة التعليق)
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage, 
      Permission.photos,
    ].request();

    // 2. اختيار الصورة
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isUploading = true); // إظهار التحميل
      
      try {
        final String? fileId = await _uploadToUploadcare(File(image.path));

        if (fileId != null) {
          final String url = "https://ucarecdn.com/$fileId/";
          await FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('images').add({
            'url': url,
            'senderId': FirebaseAuth.instance.currentUser!.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل: $e")));
      } finally {
        setState(() => _isUploading = false); // إخفاء التحميل
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        title: const Text("ألبوم ذكرياتنا", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploadImage,
        backgroundColor: const Color(0xFFE11D48),
        icon: _isUploading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
            : const Icon(Icons.add_a_photo, color: Colors.white),
        label: Text(_isUploading ? "جارِ الرفع..." : "إضافة ذكرى"),
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
          
          return GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.8, // صور طولية (بورتيريه)
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final url = (snapshot.data!.docs[index].data() as Map<String, dynamic>)['url'];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

