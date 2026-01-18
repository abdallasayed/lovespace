import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:uuid/uuid.dart';

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

  Future<void> _uploadMusic() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("جاري الرفع...")));
      try {
        File file = File(result.files.single.path!);
        String fileName = "${const Uuid().v4()}.mp3";
        final ref = FirebaseStorage.instance.ref().child('couples/${widget.coupleId}/music/$fileName');
        
        await ref.putFile(file);
        String url = await ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('couples')
            .doc(widget.coupleId)
            .collection('music')
            .add({
          'url': url,
          'name': result.files.single.name,
          'senderId': FirebaseAuth.instance.currentUser!.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل الرفع: $e")));
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("قائمتنا الموسيقية"),
        actions: [IconButton(onPressed: _uploadMusic, icon: const Icon(Icons.add))],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('couples')
            .doc(widget.coupleId)
            .collection('music')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final isPlayingThis = _playingUrl == data['url'] && _isPlaying;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isPlayingThis ? Colors.green : Colors.pink[100],
                  child: Icon(isPlayingThis ? Icons.pause : Icons.play_arrow, color: Colors.white),
                ),
                title: Text(data['name'] ?? "مقطع صوتي", maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () async {
                  if (isPlayingThis) {
                    await _player.pause();
                    setState(() => _isPlaying = false);
                  } else {
                    await _player.play(UrlSource(data['url']));
                    setState(() {
                      _playingUrl = data['url'];
                      _isPlaying = true;
                    });
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

