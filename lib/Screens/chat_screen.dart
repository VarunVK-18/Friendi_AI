import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Services/auth_service.dart';
import '../Services/gemini_service.dart';
import 'login_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final AuthService _authService = AuthService();
  final GeminiService _geminiService = GeminiService();

  final TextEditingController controller =
  TextEditingController();

  final ScrollController scrollController =
  ScrollController();

  List<ChatMessage> messages = [];

  bool isTyping = false;
  bool isSending = false;

  bool isDarkMode = false;

  late String username;
  late String userInitial;

  /// LOAD CHAT HISTORY
  Future<void> loadChat() async {

    final prefs =
    await SharedPreferences.getInstance();

    final savedData =
    prefs.getString("chat_history");

    if (savedData != null) {

      final decoded =
      jsonDecode(savedData) as List;

      messages =
          decoded.map((msg) {

            return ChatMessage(
                text: msg["text"],
                isUser: msg["isUser"]);

          }).toList();

    }

  }

  /// SAVE CHAT HISTORY
  Future<void> saveChat() async {

    final prefs =
    await SharedPreferences.getInstance();

    final encoded =
    jsonEncode(messages.map((msg) {

      return {
        "text": msg.text,
        "isUser": msg.isUser
      };

    }).toList());

    await prefs.setString(
        "chat_history",
        encoded);

  }

  /// LOAD DARK MODE
  Future<void> loadThemeMode() async {

    final prefs =
    await SharedPreferences.getInstance();

    isDarkMode =
        prefs.getBool("dark_mode") ?? false;

  }

  /// SAVE DARK MODE
  Future<void> saveThemeMode() async {

    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setBool(
        "dark_mode",
        isDarkMode);

  }

  @override
  void initState() {

    super.initState();

    final user =
        FirebaseAuth.instance.currentUser;

    username =
        user?.displayName ??
            user?.email ??
            "User";

    userInitial =
        username[0].toUpperCase();

    loadThemeMode();

    loadChat().then((_) {

      if (messages.isEmpty) {

        setState(() {

          messages.add(ChatMessage(
            text:
            "Hello **$username** 👋\n\nI'm **Friendi AI**. Ask me anything!",
            isUser: false,
          ));

        });

      } else {

        setState(() {});

      }

    });

  }

  void scrollDown() {

    Future.delayed(
        const Duration(milliseconds: 200),
            () {

          if (scrollController.hasClients) {

            scrollController.animateTo(
              scrollController.position
                  .maxScrollExtent,
              duration:
              const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );

          }

        });

  }

  Future<void> sendMessage() async {

    if (isSending) return;

    final text =
    controller.text.trim();

    if (text.isEmpty) return;

    setState(() {

      messages.add(ChatMessage(
          text: text,
          isUser: true));

      isTyping = true;
      isSending = true;

    });

    controller.clear();

    await saveChat();

    scrollDown();

    String reply = "";

    try {

      reply =
      await _geminiService
          .sendMessage(text);

      int retryCount = 0;

      while (reply.contains(
          "Too many requests") &&
          retryCount < 3) {

        await Future.delayed(
            const Duration(seconds: 2));

        reply =
        await _geminiService
            .sendMessage(text);

        retryCount++;

      }

    } catch (e) {

      reply =
      "⚠️ Failed to get a response. Try again later.";

    }

    setState(() {

      isTyping = false;
      isSending = false;

      messages.add(ChatMessage(
          text: reply,
          isUser: false));

    });

    await saveChat();

    scrollDown();

  }

  Future<void> clearChat() async {

    final prefs =
    await SharedPreferences.getInstance();

    await prefs.remove("chat_history");

    setState(() {

      messages.clear();

    });

  }

  Future<void> logout() async {

    await _authService.signOut();

    if (!mounted) return;

    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) =>
            const LoginScreen()));

  }

  void showProfileMenu() {

    showModalBottomSheet(
      context: context,
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
            top: Radius.circular(20)),
      ),
      builder: (_) {

        return SizedBox(
          height: 180,
          child: Column(
            children: [

              const SizedBox(height: 20),

              CircleAvatar(
                radius: 25,
                backgroundColor:
                const Color(0xff5F2EEA),
                child: Text(
                  userInitial,
                  style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                username,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w600),
              ),

              const SizedBox(height: 10),

              ListTile(
                leading: const Icon(
                    Icons.logout,
                    color: Colors.red),
                title: const Text("Logout"),
                onTap: logout,
              ),

            ],
          ),
        );

      },
    );

  }

  void showOptionsMenu() {

    showModalBottomSheet(
      context: context,
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
            top: Radius.circular(20)),
      ),
      builder: (_) {

        return SizedBox(
          height: 120,
          child: Column(
            children: [

              ListTile(
                leading: const Icon(
                    Icons.delete_forever,
                    color: Colors.red),
                title:
                const Text("Clear Chat"),
                onTap: () async {

                  await clearChat();

                  Navigator.pop(context);

                },
              ),

              ListTile(
                leading: Icon(
                  isDarkMode
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                title: Text(
                    isDarkMode
                        ? "Light Mode"
                        : "Dark Mode"),
                onTap: () {

                  setState(() {

                    isDarkMode =
                    !isDarkMode;

                  });

                  saveThemeMode();

                  Navigator.pop(context);

                },
              ),

            ],
          ),
        );

      },
    );

  }

  @override
  Widget build(BuildContext context) {

    final bgColor =
    isDarkMode
        ? const Color(0xff0F1115)
        : const Color(0xffF6F7FB);

    final appBarColor =
    isDarkMode
        ? const Color(0xff1E222B)
        : const Color(0xff5F2EEA);

    final iconColor =
        Colors.white;

    return Scaffold(

      backgroundColor: bgColor,

      appBar: AppBar(

        backgroundColor: appBarColor,

        elevation: 0,

        shape:
        const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(
              bottom:
              Radius.circular(20)),
        ),

        title: Text(
          "Friendi AI",
          style: TextStyle(
              fontWeight:
              FontWeight.w600,
              color: iconColor),
        ),

        actions: [

          IconButton(
            icon: Icon(
                isDarkMode
                    ? Icons.light_mode
                    : Icons.dark_mode,
                color: iconColor),
            onPressed: () {

              setState(() {

                isDarkMode =
                !isDarkMode;

              });

              saveThemeMode();

            },
          ),

          Padding(
            padding:
            const EdgeInsets.only(
                right: 10),
            child: GestureDetector(
              onTap:
              showProfileMenu,
              child: CircleAvatar(
                backgroundColor:
                Colors.white,
                child: Text(
                  userInitial,
                  style: TextStyle(
                      color:
                      appBarColor,
                      fontWeight:
                      FontWeight.bold),
                ),
              ),
            ),
          ),

          IconButton(
            icon: Icon(
                Icons.more_vert,
                color: iconColor),
            onPressed:
            showOptionsMenu,
          ),

        ],
      ),

      body: Column(
        children: [

          Expanded(
            child: ListView.builder(
              controller:
              scrollController,
              padding:
              const EdgeInsets.all(
                  16),
              itemCount:
              messages.length +
                  (isTyping
                      ? 1
                      : 0),
              itemBuilder:
                  (context, index) {

                if (isTyping &&
                    index ==
                        messages
                            .length) {

                  return TypingBubble(
                      dark:
                      isDarkMode);

                }

                return MessageBubble(
                  message:
                  messages[index],
                  dark:
                  isDarkMode,
                  userInitial:
                  userInitial,
                );

              },
            ),
          ),

          inputBar(),

        ],
      ),

    );

  }

  Widget inputBar() {

    return Container(
      margin:
      const EdgeInsets.all(12),
      padding:
      const EdgeInsets.symmetric(
          horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(
            0xff1E222B)
            : Colors.white,
        borderRadius:
        BorderRadius.circular(
            30),
        boxShadow: const [
          BoxShadow(
              blurRadius: 10,
              color:
              Colors.black12),
        ],
      ),

      child: Row(
        children: [

          Expanded(
            child: TextField(
              controller:
              controller,
              style: TextStyle(
                  color:
                  isDarkMode
                      ? Colors.white
                      : Colors.black),
              decoration:
              const InputDecoration(
                hintText:
                "Ask Friendi AI...",
                border:
                InputBorder.none,
              ),
            ),
          ),

          GestureDetector(
            onTap:
            isSending
                ? null
                : sendMessage,
            child: Container(
              padding:
              const EdgeInsets.all(
                  10),
              decoration:
              BoxDecoration(
                gradient:
                const LinearGradient(
                  colors: [
                    Color(
                        0xff6C63FF),
                    Color(
                        0xff5F2EEA)
                  ],
                ),
                shape:
                BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      blurRadius: 8,
                      color: Colors
                          .purple
                          .withOpacity(
                          0.4))
                ],
              ),
              child: const Icon(
                  Icons.send,
                  color:
                  Colors.white),
            ),
          ),

        ],
      ),
    );

  }

}

class MessageBubble extends StatelessWidget {

  final ChatMessage message;
  final bool dark;
  final String userInitial;

  const MessageBubble({

    super.key,

    required this.message,

    required this.dark,

    required this.userInitial,

  });

  @override
  Widget build(BuildContext context) {

    final aiColor =
    dark
        ? const Color(
        0xff232733)
        : Colors.white;

    return Padding(

      padding:
      const EdgeInsets.symmetric(
          vertical: 6),

      child: Row(

        mainAxisAlignment:
        message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,

        children: [

          if (!message.isUser)
            const CircleAvatar(
              radius: 14,
              backgroundColor:
              Color(0xff5F2EEA),
              child: Icon(
                  Icons.smart_toy,
                  size: 16,
                  color:
                  Colors.white),
            ),

          if (!message.isUser)
            const SizedBox(
                width: 8),

          Flexible(

            child: Container(

              padding:
              const EdgeInsets.all(
                  14),

              decoration:
              BoxDecoration(
                color:
                message.isUser
                    ? const Color(
                    0xff5F2EEA)
                    : aiColor,
                borderRadius:
                BorderRadius
                    .circular(18),
              ),

              child:
              MarkdownBody(
                data:
                message.text,
                styleSheet:
                MarkdownStyleSheet(
                  p: TextStyle(
                      color: dark
                          ? Colors.white
                          : Colors.black),
                ),
              ),

            ),

          ),

          if (message.isUser)
            const SizedBox(
                width: 8),

          if (message.isUser)
            CircleAvatar(
              radius: 14,
              backgroundColor:
              Colors.grey,
              child: Text(
                userInitial,
                style:
                const TextStyle(
                    color: Colors.white),
              ),
            ),

        ],

      ),

    );

  }

}

class TypingBubble extends StatelessWidget {

  final bool dark;

  const TypingBubble({
    super.key,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {

    return Row(

      children: [

        const CircleAvatar(
          radius: 14,
          backgroundColor:
          Color(0xff5F2EEA),
          child: Icon(
              Icons.smart_toy,
              size: 16,
              color: Colors.white),
        ),

        const SizedBox(width: 8),

        Text(
          "Friendi AI typing...",
          style: TextStyle(
              color: dark
                  ? Colors.white
                  : Colors.black),
        ),

      ],

    );

  }

}

class ChatMessage {

  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });

}