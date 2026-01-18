import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart' as intl;

class ChatScreen extends StatefulWidget {
  final String coupleId;
  const ChatScreen({super.key, required this.coupleId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ScrollController _scrollController = ScrollController();
  bool _isRecording = false;
  bool _isUploading = false;

  // --- دوال الرفع (مضمونة) ---
  Future<String?> _uploadToUploadcare(File file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('https://upload.uploadcare.com/base/'));
      request.fields['UPLOADCARE_PUB_KEY'] = '8e2cb6a00c4b7dd45f95';
      request.fields['UPLOADCARE_STORE'] = '1';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        var json = jsonDecode(await response.stream.bytesToString());
        return "https://ucarecdn.com/${json['file']}/";
      }
    } catch (e) { debugPrint("Upload Error: $e"); }
    return null;
  }

  // --- إرسال نص ---
  void _sendText() async {
    if (_textController.text.trim().isEmpty) return;
    String text = _textController.text.trim();
    _textController.clear();
    await _sendMessage(type: 'text', content: text);
  }

  // --- إرسال صورة ---
  void _sendImage() async {
    await [Permission.photos, Permission.storage].request();
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _isUploading = true);
      String? url = await _uploadToUploadcare(File(image.path));
      if (url != null) await _sendMessage(type: 'image', content: url);
      setState(() => _isUploading = false);
    }
  }

  // --- تسجيل وإرسال صوت ---
  void _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String filePath = '${appDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: filePath);
      setState(() => _isRecording = true);
    }
  }

  void _stopRecording() async {
    final String? path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    if (path != null) {
      setState(() => _isUploading = true);
      String? url = await _uploadToUploadcare(File(path));
      if (url != null) await _sendMessage(type: 'audio', content: url);
      setState(() => _isUploading = false);
    }
  }

  // --- الدالة العامة للإرسال ---
  Future<void> _sendMessage({required String type, required String content}) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('messages').add({
      'type': type, // text, image, audio
      'content': content,
      'senderId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // إشعار بسيط
    FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('notifications').add({
      'text': type == 'text' ? content : (type == 'image' ? 'أرسل صورة 📷' : 'أرسل مقطع صوتي 🎙️'),
      'senderId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5), // لون خلفية واتساب الهادئ
      appBar: AppBar(
        title: const Text("محادثتنا ❤️", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('couples')
                  .doc(widget.coupleId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return MessageBubble(
                      type: data['type'] ?? 'text',
                      content: data['content'] ?? '',
                      isMe: data['senderId'] == FirebaseAuth.instance.currentUser!.uid,
                      time: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
                    );
                  },
                );
              },
            ),
          ),
          if (_isUploading) const LinearProgressIndicator(color: Color(0xFFE11D48)),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          // زر الصور
          IconButton(icon: const Icon(Icons.image, color: Colors.grey), onPressed: _sendImage),
          
          // حقل النص
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(25)),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(hintText: "اكتب رسالة...", border: InputBorder.none),
              ),
            ),
          ),
          const SizedBox(width: 5),
          
          // زر الإرسال أو التسجيل
          GestureDetector(
            onLongPress: _startRecording,
            onLongPressUp: _stopRecording,
            onTap: _sendText,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: _isRecording ? Colors.red : const Color(0xFFE11D48),
              child: Icon(
                _isRecording ? Icons.mic : (_textController.text.isNotEmpty ? Icons.send : Icons.mic),
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- ويدجت الفقاعة (Bubble) ---
class MessageBubble extends StatefulWidget {
  final String type;
  final String content;
  final bool isMe;
  final DateTime time;

  const MessageBubble({super.key, required this.type, required this.content, required this.isMe, required this.time});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: widget.isMe ? const Color(0xFFE11D48) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(widget.isMe ? 15 : 0),
            bottomRight: Radius.circular(widget.isMe ? 0 : 15),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4), // Padding صغير للحاوية العامة
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildContent(),
              Padding(
                padding: const EdgeInsets.only(right: 5, bottom: 2, left: 5),
                child: Text(
                  intl.DateFormat('hh:mm a').format(widget.time),
                  style: TextStyle(fontSize: 10, color: widget.isMe ? Colors.white70 : Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.type) {
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: widget.content,
            placeholder: (context, url) => const SizedBox(height: 150, width: 150, child: Center(child: CircularProgressIndicator())),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            fit: BoxFit.cover,
          ),
        );
      case 'audio':
        return Container(
          width: 150,
          padding: const EdgeInsets.all(5),
          child: Row(
            children: [
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: widget.isMe ? Colors.white : const Color(0xFFE11D48)),
                onPressed: () async {
                  if (_isPlaying) {
                    await _player.pause();
                    setState(() => _isPlaying = false);
                  } else {
                    await _player.play(UrlSource(widget.content));
                    setState(() => _isPlaying = true);
                    _player.onPlayerComplete.listen((_) => setState(() => _isPlaying = false));
                  }
                },
              ),
              Expanded(
                child: Container(height: 2, color: widget.isMe ? Colors.white54 : Colors.grey[300]),
              ),
            ],
          ),
        );
      default: // text
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            widget.content,
            style: TextStyle(fontSize: 16, color: widget.isMe ? Colors.white : Colors.black87),
          ),
        );
    }
  }
}

