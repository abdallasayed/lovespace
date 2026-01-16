import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart' as intl;
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';

// --- إعدادات فايربيز ---
const firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyABiN16MklWtX00PC6UHLSDKJCrPd9EwZs",
  appId: "1:971632978916:web:355f73309996d4a6d935f1",
  messagingSenderId: "971632978916",
  projectId: "loverchat190",
  storageBucket: "loverchat190.firebasestorage.app",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  timeago.setLocaleMessages('ar', timeago.ArMessages());
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const LoveSpaceApp());
}

class LoveSpaceApp extends StatelessWidget {
  const LoveSpaceApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'عشاق',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE11D48)),
      ),
      locale: const Locale('ar', 'AE'),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: const AuthGate(),
    );
  }
}

// --- البوابات ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) return const LinkGate();
        return const LoginScreen();
      },
    );
  }
}

class LinkGate extends StatelessWidget {
  const LinkGate({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        
        if (data != null && data['status'] == 'linked') {
          return MainScreen(coupleId: data['partnerId'], myDate: (data['linkedAt'] as Timestamp?)?.toDate() ?? DateTime.now());
        }
        if (data != null && data['status'] == 'sent_request') return const WaitingScreen();
        if (data != null && data['status'] == 'received_request') return IncomingRequestScreen(senderData: data['incomingRequest']);
        return const SendRequestScreen();
      },
    );
  }
}

// --- شاشات الدخول والربط ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _password.text.trim());
      } else {
        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _password.text.trim());
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'email': _email.text.trim(), 'uid': cred.user!.uid, 'status': 'single', 'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFbe123c)])),
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_isLogin ? "مرحباً بعودتك" : "إنشاء حساب", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFE11D48))),
                  const SizedBox(height: 20),
                  TextField(controller: _email, decoration: const InputDecoration(labelText: "البريد الإلكتروني", prefixIcon: Icon(Icons.email))),
                  const SizedBox(height: 10),
                  TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: "كلمة المرور", prefixIcon: Icon(Icons.lock))),
                  const SizedBox(height: 20),
                  _loading ? const CircularProgressIndicator() : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                    child: Text(_isLogin ? "دخول" : "تسجيل جديد"),
                  ),
                  TextButton(onPressed: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? "ليس لديك حساب؟" : "لديك حساب بالفعل؟"))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SendRequestScreen extends StatefulWidget {
  const SendRequestScreen({super.key});
  @override
  State<SendRequestScreen> createState() => _SendRequestScreenState();
}

class _SendRequestScreenState extends State<SendRequestScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;

  Future<void> _sendRequest() async {
    final myUser = FirebaseAuth.instance.currentUser!;
    final targetEmail = _emailController.text.trim();
    if (targetEmail == myUser.email) return;
    setState(() => _loading = true);
    try {
      final query = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: targetEmail).get();
      if (query.docs.isEmpty) throw "لم يتم العثور على المستخدم";
      final targetUser = query.docs.first;
      if (targetUser['status'] != 'single') throw "المستخدم مشغول حالياً";
      
      final batch = FirebaseFirestore.instance.batch();
      batch.update(FirebaseFirestore.instance.collection('users').doc(myUser.uid), {'status': 'sent_request', 'targetEmail': targetEmail});
      batch.update(FirebaseFirestore.instance.collection('users').doc(targetUser.id), {
        'status': 'received_request',
        'incomingRequest': {'fromUid': myUser.uid, 'fromEmail': myUser.email, 'timestamp': FieldValue.serverTimestamp()}
      });
      await batch.commit();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("البحث عن شريك")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 80, color: Colors.pink),
            const SizedBox(height: 20),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "إيميل المحبوب/ة", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            _loading ? const CircularProgressIndicator() : ElevatedButton.icon(
              onPressed: _sendRequest,
              icon: const Icon(Icons.send),
              label: const Text("إرسال طلب ارتباط"),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
            )
          ],
        ),
      ),
    );
  }
}

class WaitingScreen extends StatelessWidget {
  const WaitingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.pink),
            const SizedBox(height: 20),
            const Text("بانتظار الموافقة ❤️", style: TextStyle(fontSize: 18)),
            TextButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser!;
                await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'status': 'single'});
              },
              child: const Text("إلغاء الطلب", style: TextStyle(color: Colors.red)),
            )
          ],
        ),
      ),
    );
  }
}

class IncomingRequestScreen extends StatelessWidget {
  final Map<String, dynamic> senderData;
  const IncomingRequestScreen({super.key, required this.senderData});

  Future<void> _respond(bool accept) async {
    final myUser = FirebaseAuth.instance.currentUser!;
    final senderUid = senderData['fromUid'];
    final batch = FirebaseFirestore.instance.batch();

    if (accept) {
      final List<String> ids = [myUser.uid, senderUid]; ids.sort();
      final coupleId = "${ids[0]}_${ids[1]}";
      final updateData = {'status': 'linked', 'partnerId': coupleId, 'linkedAt': FieldValue.serverTimestamp(), 'incomingRequest': FieldValue.delete(), 'targetEmail': FieldValue.delete()};
      batch.update(FirebaseFirestore.instance.collection('users').doc(myUser.uid), updateData);
      batch.update(FirebaseFirestore.instance.collection('users').doc(senderUid), updateData);
      batch.set(FirebaseFirestore.instance.collection('couples').doc(coupleId), {'createdAt': FieldValue.serverTimestamp(), 'users': ids});
    } else {
      batch.update(FirebaseFirestore.instance.collection('users').doc(myUser.uid), {'status': 'single', 'incomingRequest': FieldValue.delete()});
      batch.update(FirebaseFirestore.instance.collection('users').doc(senderUid), {'status': 'single', 'targetEmail': FieldValue.delete()});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread, size: 80, color: Colors.pink),
            const SizedBox(height: 20),
            Text("طلب ارتباط من:\n${senderData['fromEmail']}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            Row(children: [
                Expanded(child: ElevatedButton(onPressed: () => _respond(true), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text("موافقة"))),
                const SizedBox(width: 20),
                Expanded(child: ElevatedButton(onPressed: () => _respond(false), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text("رفض"))),
            ])
          ],
        ),
      ),
    );
  }
}

// --- الشاشة الرئيسية ---
class MainScreen extends StatefulWidget {
  final String coupleId;
  final DateTime myDate;
  const MainScreen({super.key, required this.coupleId, required this.myDate});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  @override
  void initState() {
    super.initState();
    _listenForNotifications();
  }

  void _listenForNotifications() {
    FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('notifications')
        .orderBy('timestamp', descending: true).limit(1).snapshots().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        if (data['senderId'] != FirebaseAuth.instance.currentUser!.uid) {
           final diff = DateTime.now().difference((data['timestamp'] as Timestamp).toDate());
           if (diff.inSeconds < 10) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("إشعار: ${data['text']}"), backgroundColor: Colors.pink));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(coupleId: widget.coupleId, linkedDate: widget.myDate),
      ChatScreen(coupleId: widget.coupleId),
      MusicScreen(coupleId: widget.coupleId),
      MemoriesScreen(coupleId: widget.coupleId),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          screens[_currentIndex],
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: const Offset(0, -5))], borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _navItem(Icons.image_rounded, "ذكريات", 3),
                  _navItem(Icons.music_note_rounded, "موسيقى", 2),
                  GestureDetector(onTap: () => setState(() => _currentIndex = 0), child: Container(padding: const EdgeInsets.all(15), margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE11D48), Color(0xFF9333EA)]), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFFE11D48).withOpacity(0.4), blurRadius: 15)]), child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 30))),
                  _navItem(Icons.chat_bubble_rounded, "محادثة", 1),
                  _navItem(Icons.settings_rounded, "إعدادات", 4),
              ]),
            ),
          ),
        ],
      ),
    );
  }
  Widget _navItem(IconData icon, String label, int index) => GestureDetector(onTap: () => setState(() => _currentIndex = index), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: _currentIndex == index ? const Color(0xFFE11D48) : Colors.grey[400], size: 26), Text(label, style: TextStyle(fontSize: 10, color: _currentIndex == index ? const Color(0xFFE11D48) : Colors.grey))]));
}

class HomeScreen extends StatelessWidget {
  final String coupleId;
  final DateTime linkedDate;
  const HomeScreen({super.key, required this.coupleId, required this.linkedDate});
  @override
  Widget build(BuildContext context) {
    final days = DateTime.now().difference(linkedDate).inDays;
    return SingleChildScrollView(child: Column(children: [
      Container(padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30), decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFbe123c)]), borderRadius: BorderRadius.vertical(bottom: Radius.circular(40))), child: Column(children: [
        const Text("قصة حبنا ❤️", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Column(children: [Text("$days", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), const Text("يوماً معاً", style: TextStyle(color: Colors.white70))]),
          const Icon(Icons.favorite, color: Colors.white, size: 40),
          Column(children: [const Text("∞", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), const Text("إلى الأبد", style: TextStyle(color: Colors.white70))])
        ]))
      ])),
      const SizedBox(height: 50),
      GestureDetector(onTap: () {
         FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('notifications').add({'text': "أنا مشتاق لك! 😍", 'senderId': FirebaseAuth.instance.currentUser!.uid, 'timestamp': FieldValue.serverTimestamp()});
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إرسال شوقك!")));
      }, child: Container(width: 150, height: 150, decoration: BoxDecoration(color: Colors.pink[50], shape: BoxShape.circle), child: const Icon(Icons.touch_app, size: 60, color: Colors.pink))),
      const SizedBox(height: 10), const Text("اضغط لإرسال إشعار 'اشتقت لك'", style: TextStyle(color: Colors.grey)),
    ]));
  }
}

class ChatScreen extends StatefulWidget {
  final String coupleId;
  const ChatScreen({super.key, required this.coupleId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _user = FirebaseAuth.instance.currentUser!;
  void _send() {
    if (_controller.text.isEmpty) return;
    final text = _controller.text; _controller.clear();
    FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('messages').add({'text': text, 'senderId': _user.uid, 'createdAt': FieldValue.serverTimestamp()});
    FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('notifications').add({'text': "رسالة جديدة: $text", 'senderId': _user.uid, 'timestamp': FieldValue.serverTimestamp()});
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("المحادثة"), centerTitle: true),
      body: Column(children: [
        Expanded(child: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('messages').orderBy('createdAt', descending: true).snapshots(), builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView.builder(reverse: true, itemCount: docs.length, itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>; final isMe = data['senderId'] == _user.uid;
            return Align(alignment: isMe ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isMe ? const Color(0xFFE11D48) : Colors.grey[300], borderRadius: BorderRadius.circular(20)), child: Text(data['text'] ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black))));
          });
        })),
        Padding(padding: const EdgeInsets.fromLTRB(10, 0, 10, 90), child: Row(children: [Expanded(child: TextField(controller: _controller, decoration: InputDecoration(hintText: "رسالة...", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)))), IconButton(onPressed: _send, icon: const Icon(Icons.send, color: Color(0xFFE11D48)))]))
      ])
    );
  }
}

class MusicScreen extends StatefulWidget {
  final String coupleId;
  const MusicScreen({super.key, required this.coupleId});
  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final AudioPlayer _player = AudioPlayer();
  String? _playingUrl; bool _isPlaying = false;
  Future<void> _upload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("جاري الرفع...")));
      try {
        final ref = FirebaseStorage.instance.ref().child('couples/${widget.coupleId}/music/${const Uuid().v4()}.mp3');
        await ref.putFile(File(result.files.single.path!));
        await FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('music').add({'url': await ref.getDownloadURL(), 'name': result.files.single.name, 'createdAt': FieldValue.serverTimestamp()});
      } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل: $e"))); }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الموسيقى"), actions: [IconButton(onPressed: _upload, icon: const Icon(Icons.add))]),
      body: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('music').orderBy('createdAt', descending: true).snapshots(), builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView.builder(itemCount: docs.length, itemBuilder: (context, index) {
          final data = docs[index].data() as Map<String, dynamic>;
          final isPlayingThis = _playingUrl == data['url'] && _isPlaying;
          return ListTile(leading: CircleAvatar(backgroundColor: isPlayingThis ? Colors.green : Colors.pink[100], child: Icon(isPlayingThis ? Icons.pause : Icons.play_arrow, color: Colors.white)), title: Text(data['name'] ?? "صوت"), onTap: () async {
            if (isPlayingThis) { await _player.pause(); setState(() => _isPlaying = false); } else { await _player.play(UrlSource(data['url'])); setState(() { _playingUrl = data['url']; _isPlaying = true; }); }
          });
        });
      }),
    );
  }
}

class MemoriesScreen extends StatefulWidget {
  final String coupleId;
  const MemoriesScreen({super.key, required this.coupleId});
  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  Future<void> _upload() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("جاري الرفع...")));
      try {
        final ref = FirebaseStorage.instance.ref().child('couples/${widget.coupleId}/images/${const Uuid().v4()}.jpg');
        await ref.putFile(File(image.path));
        await FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('images').add({'url': await ref.getDownloadURL(), 'createdAt': FieldValue.serverTimestamp()});
        FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('notifications').add({'text': "صورة جديدة 📸", 'senderId': FirebaseAuth.instance.currentUser!.uid, 'timestamp': FieldValue.serverTimestamp()});
      } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل: $e"))); }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الذكريات"), actions: [IconButton(onPressed: _upload, icon: const Icon(Icons.add_a_photo))]),
      body: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('images').orderBy('createdAt', descending: true).snapshots(), builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return GridView.builder(padding: const EdgeInsets.all(10), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: docs.length, itemBuilder: (context, index) {
          return ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network((docs[index].data() as Map<String, dynamic>)['url'], fit: BoxFit.cover));
        });
      }),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("الإعدادات")), body: ListView(children: [ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("تسجيل الخروج"), onTap: () => FirebaseAuth.instance.signOut())]));
  }
}
