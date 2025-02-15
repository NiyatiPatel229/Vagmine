import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Network',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SocialFeedPage extends StatefulWidget {
  const SocialFeedPage({super.key});

  @override
  _SocialFeedPageState createState() => _SocialFeedPageState();
}

class _SocialFeedPageState extends State<SocialFeedPage> {
  final List<Post> _posts = [];
  final ImagePicker _picker = ImagePicker();
  int _selectedIndex = 0;
  String _username = 'User';
  String? _profileImagePath;
  Uint8List? _profileImageBytes;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'User';
      _profileImagePath = prefs.getString('profileImage');
      if (kIsWeb) {
        _profileImageBytes = prefs.get('profileImageBytes') as Uint8List?;
      }
    });
  }

  Future<Post> _copyImageToAppDir(XFile image) async {
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      return Post(
        username: _username,
        profileImageBytes: _profileImageBytes,
        imageBytes: bytes,
        timestamp: DateTime.now(),
      );
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(image.path);
      final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
      return Post(
        username: _username,
        profileImagePath: _profileImagePath,
        imageFile: savedImage,
        timestamp: DateTime.now(),
      );
    }
  }

  Future<void> _addNewPost() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      try {
        final newPost = await _copyImageToAppDir(image);
        setState(() {
          _posts.insert(0, newPost);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: ${e.toString()}')),
        );
      }
    }
  }

  void _deletePost(Post post) {
    setState(() {
      _posts.remove(post);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
        color: Colors.black,  // Custom color if needed
      ),
      title: const Text('Social Feed'),
      backgroundColor: Colors.white,  // Match your design
      elevation: 1,  // Subtle shadow
    ),
    body: IndexedStack(
      index: _selectedIndex,
      children: [
        _buildFeed(),
        const ChatListScreen(),
        _buildProfile(),
      ],
    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPost,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildFeed() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _posts.length,
      itemBuilder: (context, index) => _buildPostCard(_posts[index]),
    );
  }

  Widget _buildPostCard(Post post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: _getProfileImageProvider(post),
            ),
            title: Text(post.username),
            subtitle: Text(DateFormat('MMM d, y • h:mm a').format(post.timestamp)),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deletePost(post),
            ),
          ),
          _buildPostImage(post),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
                IconButton(icon: const Icon(Icons.comment), onPressed: () {}),
                IconButton(icon: const Icon(Icons.share), onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _getProfileImageProvider(Post post) {
    if (kIsWeb) {
      return post.profileImageBytes != null 
          ? MemoryImage(post.profileImageBytes!)
          : const AssetImage('assets/default_avatar.png');
    }
    return post.profileImagePath != null
        ? FileImage(File(post.profileImagePath!))
        : const AssetImage('assets/default_avatar.png');
  }

  Widget _buildPostImage(Post post) {
    if (kIsWeb) {
      return Image.memory(post.imageBytes!, height: 200, width: double.infinity, fit: BoxFit.cover);
    }
    return Image.file(post.imageFile!, height: 200, width: double.infinity, fit: BoxFit.cover);
  }

  Widget _buildProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: _getCurrentProfileImage(),
          ),
          const SizedBox(height: 16),
          Text(_username, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
              _loadProfile();
            },
            child: const Text('Edit Profile'),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: _posts.length,
            itemBuilder: (context, index) => kIsWeb
                ? Image.memory(_posts[index].imageBytes!, fit: BoxFit.cover)
                : Image.file(_posts[index].imageFile!, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }

  ImageProvider _getCurrentProfileImage() {
    if (kIsWeb) {
      return _profileImageBytes != null
          ? MemoryImage(_profileImageBytes!)
          : const AssetImage('assets/default_avatar.png');
    }
    return _profileImagePath != null
        ? FileImage(File(_profileImagePath!))
        : const AssetImage('assets/default_avatar.png');
  }
}

class Post {
  final String username;
  final String? profileImagePath;
  final Uint8List? profileImageBytes;
  final File? imageFile;
  final Uint8List? imageBytes;
  final DateTime timestamp;

  Post({
    required this.username,
    this.profileImagePath,
    this.profileImageBytes,
    this.imageFile,
    this.imageBytes,
    required this.timestamp,
  }) : assert((imageFile != null) ^ (imageBytes != null));
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  String? _selectedImagePath;
  Uint8List? _selectedImageBytes;

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() => _selectedImageBytes = bytes);
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = path.basename(image.path);
        final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
        setState(() => _selectedImagePath = savedImage.path);
      }
    }
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _usernameController.text);
    
    if (kIsWeb) {
      if (_selectedImageBytes != null) {
        await prefs.setString('profileImage', 'web_image');
        await prefs.setString('profileImageBytes', _selectedImageBytes!.toString());
      }
    } else {
      if (_selectedImagePath != null) {
        await prefs.setString('profileImage', _selectedImagePath!);
      }
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _getSelectedImage(),
              ),
            ),
            TextButton(
              onPressed: _pickImage,
              child: const Text('Change Photo'),
            ),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _getSelectedImage() {
    if (kIsWeb) {
      return _selectedImageBytes != null
          ? MemoryImage(_selectedImageBytes!)
          : const AssetImage('assets/default_avatar.png');
    }
    return _selectedImagePath != null
        ? FileImage(File(_selectedImagePath!))
        : const AssetImage('assets/default_avatar.png');
  }
}

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ChatUser> _allFriends = [];
  List<ChatUser> _filteredFriends = [];

  @override
  void initState() {
    super.initState();
    _allFriends = [
      ChatUser(name: 'John Doe', lastMessage: 'Hey there!'),
      ChatUser(name: 'Jane Smith', lastMessage: 'See you tomorrow'),
    ];
    _filteredFriends = _allFriends;
  }

  void _searchFriends(String query) {
    setState(() {
      _filteredFriends = _allFriends.where((user) {
        return user.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchFriends,
              decoration: InputDecoration(
                hintText: 'Search friends...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: _filteredFriends.length,
        itemBuilder: (context, index) => ListTile(
          leading: const CircleAvatar(
            backgroundImage: AssetImage('assets/default_avatar.png'),
          ),
          title: Text(_filteredFriends[index].name),
          subtitle: Text(_filteredFriends[index].lastMessage),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatScreen()),
          ),
        ),
      ),
    );
  }
}

class ChatUser {
  final String name;
  final String lastMessage;

  ChatUser({required this.name, required this.lastMessage});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: message.isMe ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                setState(() {
                  _messages.insert(0, Message(
                    text: _controller.text,
                    isMe: true,
                    timestamp: DateTime.now(),
                  ));
                  _controller.clear();
                });
              }
            },
          ),
        ],
      ),
    );
  }
}

class Message {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}


// Add to your existing code
class SignLanguagePage extends StatefulWidget {
  const SignLanguagePage({super.key});

  @override
  _SignLanguagePageState createState() => _SignLanguagePageState();
}

class _SignLanguagePageState extends State<SignLanguagePage> {
  final List<Map<String, String>> signGifs = [
    {'name': 'Hello', 'gif': 'assets/hello.gif'},
    {'name': 'Thank You', 'gif': 'assets/thank_you.gif'},
    {'name': 'Food', 'gif': 'assets/food.gif'},
    {'name': 'I am Lost', 'gif': 'assets/lost.gif'},
    {'name': "I dont't know", 'gif': 'assets/i_dont_know.gif'},
    {'name': 'Next Week', 'gif': 'assets/next_week.gif'},
    {'name': 'Sorry', 'gif': 'assets/sorry.gif'},
    {'name': 'Awesome', 'gif': 'assets/awesome.gif'},
    {'name': 'Which', 'gif': 'assets/which.gif'},
    {'name': 'Where', 'gif': 'assets/where.gif'},
    {'name': 'Weekend', 'gif': 'assets/weekand.gif'},
    {'name': 'Soup', 'gif': 'assets/soup.gif'},
    {'name': 'Stop', 'gif': 'assets/stop.gif'},
    {'name': 'Mother-in-law', 'gif': 'assets/mother_in_law.gif'},
    {'name': 'Love', 'gif': 'assets/love.gif'},
    {'name': 'Fire', 'gif': 'assets/fire.gif'},
    {'name': 'Dinner', 'gif': 'assets/dinner.gif'},
    {'name': 'Cool', 'gif': 'assets/cool.gif'},
    {'name': 'Cloudy', 'gif': 'assets/cloudy.gif'},
    // Add 10-20 entries
  ];

  final List<Level> quizLevels = [
    Level(
      levelNumber: 1,
      questions: [
  QuizQuestion(
    question: "What is the sign for 'friend'?",
    options: [
      "🤝 Hands clasping together",
      "✌️ Two fingers crossing over each other",
      "🖐️ Open hands moving toward each other"
    ],
    correctIndex: 1,
    feedback: "The sign for 'friend' is crossing two fingers over each other.",
  ),

  QuizQuestion(
    question: "How do you sign 'family'?",
    options: [
      "👪 Both hands forming a circle starting from the chest",
      "👐 Hands moving outward in a sweeping motion",
      "🤲 Hands touching fingertips together"
    ],
    correctIndex: 0,
    feedback: "The sign for 'family' involves making a circular motion starting from the chest.",
  ),

  QuizQuestion(
    question: "Which sign represents 'eat'?",
    options: [
      "🍽️ Fingers touching lips and moving away",
      "🤏 Thumb and fingers bringing food to mouth",
      "✋ Open hand moving toward mouth"
    ],
    correctIndex: 1,
    feedback: "The sign for 'eat' mimics bringing food to your mouth with thumb and fingers.",
  ),

  QuizQuestion(
    question: "What is the sign for 'drink'?",
    options: [
      "🥤 Hand forming a cup shape and moving toward mouth",
      "👐 Hands moving up and down",
      "✊ Fist tapping chest twice"
    ],
    correctIndex: 0,
    feedback: "A hand forming a cup and moving toward the mouth represents 'drink'.",
  ),

  QuizQuestion(
    question: "How do you sign 'love' ?",
    options: [
      "❤️ Hands forming a heart shape",
      "🤟 Thumb, index, and pinky extended",
      "✊ Fists crossing over chest"
    ],
    correctIndex: 2,
    feedback: "The sign for 'love' is crossing fists over the chest.",
  ),

  QuizQuestion(
    question: "Which sign means 'stop'?",
    options: [
      "🖐️ Open palm facing forward",
      "✋ One hand chopping into the other palm",
      "✊ Fist moving downward"
    ],
    correctIndex: 1,
    feedback: "The sign for 'stop' is making a chopping motion into the other palm.",
  ),

  QuizQuestion(
    question: "What is the sign for 'go'?",
    options: [
      "👉 Index fingers pointing and moving forward",
      "👊 Fist moving side to side",
      "✋ Open hands moving up"
    ],
    correctIndex: 0,
    feedback: "The   sign for 'go' involves pointing with index fingers and moving them forward.",
  ),

  QuizQuestion(
    question: "How do you sign 'come' in  ?",
    options: [
      "👉 Index fingers curling toward the body",
      "👐 Hands sweeping outward",
      "✊ Fist tapping chin twice"
    ],
    correctIndex: 0,
    feedback: "The sign for 'come' is curling index fingers toward the body.",
  ),

  QuizQuestion(
    question: "Which sign represents 'good'?",
    options: [
      "👍 Thumb up",
      "👌 Hand making an 'OK' sign",
      "👋 Hand moving forward"
    ],
    correctIndex: 0,
    feedback: "The sign for 'good' is a thumbs-up gesture.",
  ),

  QuizQuestion(
    question: "What is the sign for 'bad'?",
    options: [
      "👎 Thumb down",
      "✋ Open hand waving",
      "🤚 Hand touching forehead"
    ],
    correctIndex: 0,
    feedback: "A thumbs-down represents 'bad' in  .",
  ),
],

      isUnlocked: true,
    ),
    Level(
      levelNumber: 2,
      questions: [
  QuizQuestion(
    question: "What is the sign for 'hello'?",
    options: [
      "👋 Open palm moving side to side",
      "🤚 Hand near forehead in a salute-like motion",
      "✊ Fist tapping chin twice"
    ],
    correctIndex: 1,
    feedback: "A salute-like motion is the correct sign for 'hello'!",
  ),

  QuizQuestion(
    question: "How do you sign 'thank you'?",
    options: [
      "🖐️ Flat hand touching chin and moving outward",
      "👊 Fist touching chest twice",
      "✋ Waving hand left to right"
    ],
    correctIndex: 0,
    feedback: "The sign for 'thank you' is touching your chin and moving outward.",
  ),

  QuizQuestion(
    question: "Which sign represents 'please'?",
    options: [
      "🖐️ Open hand rubbing chest in a circle",
      "🤞 Index and middle finger tapping thumb",
      "✊ Fist tapping forehead"
    ],
    correctIndex: 0,
    feedback: "The correct sign for 'please' is an open hand rubbing the chest in a circle.",
  ),

  QuizQuestion(
    question: "What is the sign for 'yes'?",
    options: [
      "👍 Thumbs-up",
      "✊ Fist nodding up and down",
      "👐 Hands waving side to side"
    ],
    correctIndex: 1,
    feedback: "A fist nodding up and down represents 'yes'!",
  ),

  QuizQuestion(
    question: "How do you sign 'no'?",
    options: [
      "🤏 Index and middle finger tapping thumb",
      "✋ Hand moving side to side",
      "🤚 Palm facing outward and shaking"
    ],
    correctIndex: 0,
    feedback: "The sign for 'no' involves tapping index and middle finger to the thumb.",
  ),

  QuizQuestion(
    question: "Which sign means 'sorry'?",
    options: [
      "✊ Fist rubbing chest in a circular motion",
      "🖐️ Open hand waving",
      "☝️ One finger pointing up"
    ],
    correctIndex: 0,
    feedback: "The sign for 'sorry' is rubbing a fist in a circular motion over the chest.",
  ),

  QuizQuestion(
    question: "How do you sign 'where'?",
    options: [
      "☝️ Index finger pointing and moving side to side",
      "✋ Palm facing up, moving in a circle",
      "🤞 Two fingers making a walking motion"
    ],
    correctIndex: 0,
    feedback: "Pointing with the index finger and moving side to side is the sign for 'where'.",
  ),

  QuizQuestion(
    question: "What is the sign for 'who'?",
    options: [
      "🤚 Open palm twisting near chin",
      "☝️ Index finger pointing to lips",
      "🤏 Thumb and index finger forming a circle"
    ],
    correctIndex: 1,
    feedback: "Pointing to the lips with the index finger is the sign for 'who'.",
  ),

  QuizQuestion(
    question: "Which sign represents 'what'?",
    options: [
      "🤲 Open hands moving side to side, palms up",
      "🖐️ Open hand shaking",
      "✊ Fist tapping palm"
    ],
    correctIndex: 0,
    feedback: "The correct sign for 'what' is open hands moving side to side, palms up.",
  ),

  QuizQuestion(
    question: "What is the sign for 'help'?",
    options: [
      "👍 Thumb up placed on an open palm",
      "👊 Fist hitting palm",
      "✋ Open palm facing forward"
    ],
    correctIndex: 0,
    feedback: "The sign for 'help' is placing a thumbs-up on an open palm.",
  ),
],

      isUnlocked: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sign Language'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.video_library), text: "Tutorials"),
              Tab(icon: Icon(Icons.quiz), text: "Quiz"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTutorialsGrid(),
            _buildQuizLevels(),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: signGifs.length,
      itemBuilder: (context, index) => Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Expanded(
              child: Image.asset(
                signGifs[index]['gif']!,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                signGifs[index]['name']!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizLevels() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quizLevels.length,
      itemBuilder: (context, index) => _buildQuizLevelCard(quizLevels[index]),
    );
  }

  Widget _buildQuizLevelCard(Level level) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: level.isUnlocked ? Colors.blue : Colors.grey,
          child: Text(
            'L${level.levelNumber}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          'Level ${level.levelNumber}',
          style: TextStyle(
            color: level.isUnlocked ? Colors.black : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Icon(
          level.isUnlocked ? Icons.lock_open : Icons.lock,
          color: level.isUnlocked ? Colors.green : Colors.grey,
        ),
        onTap: level.isUnlocked ? () => _startQuiz(context, level) : null,
      ),
    );
  }

  void _startQuiz(BuildContext context, Level level) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignLanguageQuizScreen(
          level: level,
          onLevelCompleted: (success) {
            if (success) {
              setState(() {
                if (level.levelNumber == 1) {
                  quizLevels[1].isUnlocked = true;
                }
              });
            }
          },
        ),
      ),
    );
  }
}

class SignLanguageQuizScreen extends StatefulWidget {
  final Level level;
  final Function(bool) onLevelCompleted;

  const SignLanguageQuizScreen({
    super.key,
    required this.level,
    required this.onLevelCompleted,
  });

  @override
  _SignLanguageQuizScreenState createState() => _SignLanguageQuizScreenState();
}

class _SignLanguageQuizScreenState extends State<SignLanguageQuizScreen> {
  int currentQuestionIndex = 0;
  bool showFeedback = false;
  bool isCorrect = false;

  @override
  Widget build(BuildContext context) {
    QuizQuestion currentQuestion = widget.level.questions[currentQuestionIndex];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[100]!, Colors.purple[100]!],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (currentQuestionIndex + 1) /
                      widget.level.questions.length,
                  backgroundColor: Colors.white30,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            currentQuestion.question,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          const SizedBox(height: 20),
                          ...currentQuestion.options
                              .asMap()
                              .entries
                              .map((entry) => _buildOptionButton(
                                    entry.value,
                                    entry.key ==
                                        currentQuestion.correctIndex,
                                  ))
                              .toList(),
                        ],
                      ),
                    ),
                  ),
                ),
                if (showFeedback) _buildFeedback(currentQuestion),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(String option, bool isCorrectAnswer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: showFeedback ? null : () => _checkAnswer(isCorrectAnswer),
        style: ElevatedButton.styleFrom(
          backgroundColor: showFeedback
              ? (isCorrectAnswer ? Colors.green : Colors.red)
              : Colors.white,
          foregroundColor: showFeedback ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            option,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedback(QuizQuestion question) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          if (isCorrect)
            Image.asset(
              'assets/celebration.gif',
              height: 100,
            ),
          Text(
            question.feedback,
            style: TextStyle(
              fontSize: 16,
              color: isCorrect ? Colors.green[900] : Colors.red[900],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _nextQuestion,
            child: Text(
              currentQuestionIndex < widget.level.questions.length - 1
                  ? 'Next Question'
                  : 'Finish Quiz',
            ),
          ),
        ],
      ),
    );
  }

  void _checkAnswer(bool isCorrectAnswer) {
    setState(() {
      isCorrect = isCorrectAnswer;
      showFeedback = true;
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < widget.level.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        showFeedback = false;
      });
    } else {
      widget.onLevelCompleted(true);
      Navigator.pop(context);
    }
  }
}


class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String feedback;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.feedback,
  });
}

class Level {
  final int levelNumber;
  final List<QuizQuestion> questions;
  bool isUnlocked;

  Level({
    required this.levelNumber,
    required this.questions,
    this.isUnlocked = false,
  });
}

class AutismQuiz extends StatefulWidget {
  @override
  _AutismQuizState createState() => _AutismQuizState();
}

class _AutismQuizState extends State<AutismQuiz> {
  late List<Level> levels;
  final Set<int> completedLevels = {};

  @override
  void initState() {
    super.initState();
    _initializeLevels();
    _loadProgress();
  }

  void _initializeLevels() {
    levels = [
      Level(
      levelNumber: 1,
      questions: [
        QuizQuestion(
          question: "How do you greet a friend in the morning?",
          options: ["Wave and smile", "Look at the ground silently"],
          correctIndex: 0,
          feedback: "A friendly wave helps start the day positively!",
        ),
        QuizQuestion(
      question: "Someone says they like your drawing. How to respond?",
      options: ["Say 'Thank you!'", "Rip the drawing"],
      correctIndex: 0,
      feedback: "Accepting compliments makes others feel heard!",
    ),

    QuizQuestion(
      question: "You want to use the red crayon first. What do you say?",
      options: ["Grab it from someone's hand", "Ask 'May I use that next?'"],
      correctIndex: 1,
      feedback: "Using polite words helps share resources!",
    ),

    QuizQuestion(
      question: "You spilled juice accidentally. What next?",
      options: ["Hide under the table", "Get a paper towel"],
      correctIndex: 1,
      feedback: "Cleaning up shows responsibility!",
    ),

    QuizQuestion(
      question: "Your friend looks sad. How can you help?",
      options: ["Ask 'Are you okay?'", "Laugh loudly"],
      correctIndex: 0,
      feedback: "Checking on friends builds strong relationships!",
    ),


      ],
      isUnlocked: true,
    ),
Level(
      levelNumber: 2,
      questions: [// Level 2
QuizQuestion(
  question: "The swing you want is occupied. What to do?",
  options: ["Push the child off", "Wait your turn"],
  correctIndex: 1,
  feedback: "Patience keeps playgrounds fun and safe!",
),

QuizQuestion(
  question: "You're feeling overwhelmed. Best response?",
  options: ["Hit the table", "Ask for a break"],
  correctIndex: 1,
  feedback: "Using words helps manage big feelings!",
),

QuizQuestion(
  question: "Someone asks you to stop tapping. What do you do?",
  options: ["Tap louder", "Say 'Okay' and stop"],
  correctIndex: 1,
  feedback: "Respecting requests shows kindness!",
),

QuizQuestion(
  question: "How to join a conversation already happening?",
  options: ["Interrupt loudly", "Wait for a pause"],
  correctIndex: 1,
  feedback: "Waiting shows respect for others' talk time!",
),

QuizQuestion(
  question: "You see someone struggling with a zipper. How help?",
  options: ["Point and laugh", "Offer to help zip"],
  correctIndex: 1,
  feedback: "Helping others makes the community stronger!",
),

],
      isUnlocked: false,
    ),
Level(
    levelNumber: 3,
      questions: [
        QuizQuestion(
  question: "Arrange steps for making your bed",
  options: ["Smoothing sheets", "Placing pillows", "Pulling up blanket"],
  correctIndex: 0,
  feedback: "Start with smoothing sheets for a well-made bed!",
),

QuizQuestion(
  question: "What comes first when setting the table?",
  options: ["Putting napkins", "Placing forks/spoons", "Arranging plates"],
  correctIndex: 2,
  feedback: "Always start with plates when setting the table!",
),
    QuizQuestion(
      question: "Order these laundry steps",
      options: ["Sorting colors", "Adding detergent","Pressing 'start'"],
      correctIndex: 0,
      feedback: "Always start with sorting colors!",
    ),

    QuizQuestion(
      question: "First step to take a safe bath?",
      options: ["Check water temperature", "Get a towel", "Turn on faucet"],
      correctIndex: 1,
      feedback: "Getting a towel is the first step!",
    ),

    QuizQuestion(
      question: "Arrange phone call steps",
      options: [" Say 'Goodbye'", "Dial number","Say 'Hello'"],
      correctIndex: 0,
      feedback: "Without Diaing a number you can't call",
    ),

      ],
      isUnlocked: false,
    ),
    Level(
      levelNumber: 4,
      questions: [
QuizQuestion(
  question: " Your sibling shares their favorite snack with you. How do you feel?",
  options: ["😊 Happy ", "😠 Angry"],
  correctIndex: 0,
  feedback: "Sharing often makes people feel happy!",
),

QuizQuestion(
  question: "You lost your favorite toy at the park. How might you feel?",
  options: ["😢 Sad", "😊 Happy"],
  correctIndex: 0,
  feedback: "Losing something special can make you sad!",
),

QuizQuestion(
  question: "Your surprise birthday party is revealed. How do you feel?",
  options: ["😃 Surprisedr", "😢 Sad"],
  correctIndex: 0,
  feedback: "Surprises usually bring happy feelings!",
),

QuizQuestion(
  question: "You hear fire alarms suddenly. How might you feel?",
  options: ["😨 Scared ", "😠 Angry"],
  correctIndex: 0,
  feedback: "Loud alarms can feel scary!",
),

QuizQuestion(
  question: "Your friend remembers your favorite color. How do they feel?",
  options: ["😊 Caring ", "😢 Sad"],
  correctIndex: 0,
  feedback: "Remembering details shows they care!",
),

],
      isUnlocked: false,
    ),
    Level(
      levelNumber: 5,
      questions: [
QuizQuestion(
  question: " You see someone trip and fall. How might they feel?",
  options: ["😳 Embarrassed", "😊 Happy"],
  correctIndex: 0,
  feedback: "Falling can make people feel embarrassed!",
),

QuizQuestion(
  question: "Your parent comes home from work early. How do you feel?",
  options: ["😠 Angry", "😃 Excited"],
  correctIndex: 0,
  feedback: "Unexpected visits often bring joy!",
),

QuizQuestion(
  question: "Your ice cream melts before you eat it. How do you feel?",
  options: ["😊 Happy", "😢 Disappointed"],
  correctIndex: 1,
  feedback: "Melting treats can cause disappointment!",
),

QuizQuestion(
  question: "Someone takes your seat without asking. How might you feel?",
  options: ["😠 Frustrated ", "😢 Sad"],
  correctIndex: 0,
  feedback: "Boundary-crossing often causes frustration!",
),

QuizQuestion(
  question: "You get to choose the movie tonight. How do you feel?",
  options: ["😊 Proud ", "😨 Scared"],
  correctIndex: 0,
  feedback: "Making choices helps build confidence!",
),

],
      isUnlocked: false,
    ),
  ];


      // Initialize other levels with isUnlocked: false

  }

  void _loadProgress() {
    // Implement persistent storage logic here if needed
  }

  void _updateLevelUnlockStatus() {
    for (int i = 0; i < levels.length; i++) {
      if (i == 0) continue;
      levels[i].isUnlocked = completedLevels.contains(levels[i-1].levelNumber);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[200]!, Colors.green[200]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 50,
              flexibleSpace: const FlexibleSpaceBar(
                title: Text('Autism Quiz'),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildLevelTile(levels[index]),
                childCount: levels.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelTile(Level level) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: level.isUnlocked ? Colors.white : Colors.grey[300],
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: level.isUnlocked ? Colors.blue : Colors.grey,
          child: Text(
            'L${level.levelNumber}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          'Level ${level.levelNumber}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: level.isUnlocked ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Text(
          '${level.questions.length} Questions',
          style: TextStyle(color: level.isUnlocked ? Colors.grey : Colors.grey[400]),
        ),
        trailing: Icon(
          level.isUnlocked ? Icons.lock_open : Icons.lock_outline,
          color: level.isUnlocked ? Colors.green : Colors.grey,
        ),
        onTap: level.isUnlocked ? () => _startLevel(context, level) : null,
      ),
    );
  }

  void _startLevel(BuildContext context, Level level) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          level: level,
          onLevelCompleted: (success) {
            if (success) {
              completedLevels.add(level.levelNumber);
              _updateLevelUnlockStatus();
            }
          },
        ),
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  final Level level;
  final Function(bool) onLevelCompleted;

  const QuizScreen({super.key, required this.level, required this.onLevelCompleted});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  bool showFeedback = false;
  bool isCorrect = false;

  @override
  Widget build(BuildContext context) {
    QuizQuestion currentQuestion = widget.level.questions[currentQuestionIndex];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple[200]!, Colors.blue[200]!],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProgressBar(),
                const SizedBox(height: 24),
                _buildQuestion(currentQuestion),
                const SizedBox(height: 24),
                _buildOptions(currentQuestion),
                if (showFeedback) _buildFeedback(currentQuestion),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: (currentQuestionIndex + 1) / widget.level.questions.length,
      backgroundColor: Colors.white30,
      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
    );
  }

 Widget _buildQuestion(QuizQuestion question) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 16),
    padding: EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          'Question ${currentQuestionIndex + 1}',
          style: TextStyle(
            color: Colors.blue[800],
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 12),
        Text(
          question.question,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

Widget _buildOptionButton(String option, VoidCallback onTap) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: ElevatedButton(
      onPressed: showFeedback ? null : onTap,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              option,
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildOptions(QuizQuestion question) {
    return Column(
      children: List.generate(
        question.options.length,
        (index) => _buildOptionButton(
          question.options[index],
          () => _checkAnswer(index, question),
        ),
      ),
    );
  }

  Widget _buildFeedback(QuizQuestion question) {
    return Column(
      children: [
        if (isCorrect)
  Image.asset(
    'assets/completed.gif',
    height: 200,
  ),


        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCorrect ? Colors.green[100] : Colors.red[100],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            question.feedback,
            style: TextStyle(
              fontSize: 18,
              color: isCorrect ? Colors.green[900] : Colors.red[900],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        ElevatedButton(
          onPressed: _nextQuestion,
          child: Text(
            currentQuestionIndex < widget.level.questions.length - 1
                ? 'Next Question'
                : 'Finish Quiz',
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }

  void _checkAnswer(int selectedIndex, QuizQuestion question) {
    setState(() {
      isCorrect = selectedIndex == question.correctIndex;
      showFeedback = true;
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < widget.level.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        showFeedback = false;
      });
    } else {
      widget.onLevelCompleted(true);
      Navigator.pop(context);
    }
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final List<Map<String, dynamic>> features = const [
    {'title': 'Text to Speech', 'icon': Icons.volume_up},
    {'title': 'Speech to Text', 'icon': Icons.mic},
    {'title': 'Autism-based Quiz', 'icon': Icons.quiz},
    {'title': 'Sign Language Tutorials', 'icon': Icons.sign_language},
    {'title': 'Social Network', 'icon': Icons.people},
  ];

Widget _getPage(String title) {
  switch (title) {
    case 'Text to Speech':
      return const TextToSpeechPage();
    case 'Speech to Text':
      return const SpeechToTextPage();
    case 'Autism-based Quiz':
      return AutismQuiz();
    case 'Sign Language Tutorials':
       return const SignLanguagePage();
    case 'Social Network':
      return const SocialFeedPage();
    default:
      return PlaceholderPage(title: title);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[400]!, Colors.purple[200]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Vagmine',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(2, 2),
                        blurRadius: 3.0,
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: features.length,
                  itemBuilder: (context, index) => _buildFeatureCard(features[index], context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _getPage(feature['title'])),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    feature['icon'],
                    size: 40,
                    color: Colors.blue[900],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  feature['title'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.blue),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class TextToSpeechPage extends StatefulWidget {
  const TextToSpeechPage({super.key});

  @override
  _TextToSpeechPageState createState() => _TextToSpeechPageState();
}

class _TextToSpeechPageState extends State<TextToSpeechPage> {
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _textController = TextEditingController();
  double _pitch = 1.0;
  double _rate = 0.5;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _flutterTts.setStartHandler(() => debugPrint("TTS Started"));
    _flutterTts.setCompletionHandler(() => debugPrint("TTS Completed"));
  }

  Future<void> _speak() async {
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setSpeechRate(_rate);
    await _flutterTts.setVolume(_volume);
    await _flutterTts.speak(_textController.text);
  }

  @override
   Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text to Speech'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Enter Text',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSlider('Pitch', _pitch, 0.5, 2.0, (value) => _pitch = value),
            _buildSlider('Rate', _rate, 0.0, 1.0, (value) => _rate = value),
            _buildSlider('Volume', _volume, 0.0, 1.0, (value) => _volume = value),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.volume_up),
              label: const Text('Speak'),
              onPressed: _speak,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSlider(String label, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(1)}'),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 10,
          onChanged: (value) => setState(() => onChanged(value)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}

class SpeechToTextPage extends StatefulWidget {
  const SpeechToTextPage({super.key});

  @override
  _SpeechToTextPageState createState() => _SpeechToTextPageState();
}

class _SpeechToTextPageState extends State<SpeechToTextPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = 'Press the mic button to start listening';
  double _confidence = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech to Text'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    _text,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(_isListening ? Icons.stop : Icons.mic),
              label: Text(_isListening ? 'Stop Listening' : 'Start Listening'),
              onPressed: _listen,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: _isListening ? Colors.red : Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) => setState(() {
            _text = result.recognizedWords;
            _confidence = result.confidence;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Text(
          '$title Page\n(Under Development)',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
