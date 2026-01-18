import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class MusicScreen extends StatefulWidget {
  final String coupleId;
  const MusicScreen({super.key, required this.coupleId});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final AudioPlayer _player = AudioPlayer();
  String? _playingUrl;
  bool _isPlaying = false;
  bool _isUploading = false;

  Future<String?> _uploadToUploadcare(File file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('https://upload.uploadcare.com/base/'));
      request.fields['UPLOADCARE_PUB_KEY'] = '8e2cb6a00c4b7dd45f95';
      request.fields['UPLOADCARE_STORE'] = '1';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        var json = jsonDecode(await response.stream.bytesToString());
        return json['file'];
      }
    } catch (e) { debugPrint("Error: $e"); }
    return null;
  }

  Future<void> _uploadMusic() async {
    // 1. طلب الصلاحيات
    await [Permission.storage, Permission.audio].request();

    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      setState(() => _isUploading = true);
      try {
        final String? fileId = await _uploadToUploadcare(File(result.files.single.path!));
        if (fileId != null) {
          final String url = "https://ucarecdn.com/$fileId/";
          await FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('music').add({
            'url': url,
            'name': result.files.single.name,
            'senderId': FirebaseAuth.instance.currentUser!.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل: $e")));
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        title: const Text("نغماتنا", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadMusic,
        backgroundColor: const Color(0xFFE11D48),
        child: _isUploading ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('music').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final isPlayingThis = _playingUrl == data['url'] && _isPlaying;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isPlayingThis ? const Color(0xFFE11D48) : Colors.pink[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(isPlayingThis ? Icons.pause : Icons.play_arrow, color: isPlayingThis ? Colors.white : const Color(0xFFE11D48)),
                  ),
                  title: Text(data['name'] ?? "مقطع صوتي", style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () async {
                    if (isPlayingThis) {
                      await _player.pause();
                      setState(() => _isPlaying = false);
                    } else {
                      await _player.play(UrlSource(data['url']));
                      setState(() { _playingUrl = data['url']; _isPlaying = true; });
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

