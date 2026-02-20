import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../helper/dialogs.dart';
import '../models/message.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _textC = TextEditingController();
  final _scrollC = ScrollController();

  final _list = <AiMessage>[
    AiMessage(msg: 'Hello 👋, How can I help you?', msgType: MessageType.bot)
  ];

  final List<Map<String, String>> _chatHistory = [
    {
      "role": "system",
      "content":
      "You are a helpful AI assistant. Reply short and clean."
    }
  ];

  // ================= ASK =================
  Future<void> _askQuestion() async {
    final text = _textC.text.trim();

    if (text.isEmpty) {
      Dialogs.showSnackbar(context, 'Ask Something!');
      return;
    }

    _list.add(AiMessage(msg: text, msgType: MessageType.user));
    _chatHistory.add({"role": "user", "content": text});

    setState(() {});
    _scrollDown();

    _textC.clear();

    // typing
    _list.add(AiMessage(msg: "Typing...", msgType: MessageType.bot));
    setState(() {});
    _scrollDown();

    final res = await _getAnswer();

    _list.removeLast();

    _list.add(AiMessage(msg: res, msgType: MessageType.bot));
    _chatHistory.add({"role": "assistant", "content": res});

    setState(() {});
    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollC.hasClients) {
        _scrollC.animateTo(
          _scrollC.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ================= API =================
  Future<String> _getAnswer() async {
    try {
      const apiKey = "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";

      final response = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "openai/gpt-4o-mini",
          "messages": _chatHistory,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["choices"][0]["message"]["content"];
      } else {
        return "Error: ${response.statusCode}";
      }
    } catch (e) {
      log("ERROR: $e");
      return "Something went wrong!";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),

      // 🔥 APPBAR (same like your screenshot but improved)
      appBar: AppBar(
        leading: const Icon(Icons.arrow_back),
        centerTitle: true,
        title: const Text("AI Assistant"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.indigo],
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          // 🔥 CHAT AREA
          Expanded(
            child: ListView.builder(
              controller: _scrollC,
              padding: const EdgeInsets.all(12),
              itemCount: _list.length,
              itemBuilder: (context, index) {
                final msg = _list[index];

                return Align(
                  alignment: msg.msgType == MessageType.user
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment:
                    msg.msgType == MessageType.user
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (msg.msgType == MessageType.bot)
                        const CircleAvatar(
                          radius: 16,
                          child: Icon(Icons.smart_toy, size: 18),
                        ),

                      const SizedBox(width: 6),

                      Container(
                        constraints:
                        const BoxConstraints(maxWidth: 260),
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: msg.msgType == MessageType.user
                              ? Colors.blue
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: msg.msgType == MessageType.bot
                              ? Border.all(color: Colors.blue.shade200)
                              : null,
                        ),
                        child: Text(
                          msg.msg,
                          style: TextStyle(
                            color: msg.msgType == MessageType.user
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 🔥 INPUT BAR (FIXED PROBLEM IN YOUR SCREENSHOT)
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 2,
                  color: Colors.black.withOpacity(.05),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textC,
                    decoration: InputDecoration(
                      hintText: "Ask anything...",
                      filled: true,
                      fillColor: const Color(0xFFF1F3F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    onPressed: _askQuestion,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
