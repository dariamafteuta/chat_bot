import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatBot',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  Future<String> sendMessage(String message) async {
    const String apiKey = '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';
    const String apiUrl =
        'https://api.openai.com/v1/engines/gpt-3.5-turbo-instruct/completions';

    _messages.add({'role': 'user', 'text': message});

    String dialog = _messages
        .map((m) => '${m['role'] == 'user' ? 'Человек: ' : ''}${m['text']}')
        .join('\n');

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'prompt': dialog,
        'max_tokens': 150,
      }),
    );

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(responseBody);
      String botResponse = data['choices'][0]['text'].trim();
      int colonIndex = botResponse.indexOf(':');

      if (colonIndex != -1) {
        botResponse = botResponse.substring(colonIndex + 1).trim();
      }

      setState(() {
        _messages.add({'role': 'bot', 'text': botResponse});
        _scrollToBottom();
      });

      return botResponse;
    } else {
      throw Exception('Failed to load response');
    }
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await sendMessage(_controller.text);
    } catch (error) {
      debugPrint('Error sending message: $error');
    }

    setState(() {
      _isLoading = false;
      _controller.clear();
      _scrollToBottom();
    });
  }

  void clearHistory() => setState(() => _messages.clear());

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final bottomOffset = _scrollController.position.maxScrollExtent;
        _scrollController.animateTo(
          bottomOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Bot'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.black87),
            tooltip: 'Clear History',
            onPressed: clearHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                String messageText = _messages[index]['text'] ?? "";
                bool isUserMessage = _messages[index]['role'] == 'user';
                return ListTile(
                  key: ValueKey(index),
                  title: Align(
                    alignment: isUserMessage
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: isUserMessage
                            ? Colors.deepPurple[200]
                            : Colors.deepPurple[50],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        messageText,
                        style: TextStyle(
                            color:
                                isUserMessage ? Colors.black : Colors.black87),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration:
                        const InputDecoration(hintText: 'Message ChatGPT...'),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.deepPurple),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.black87),
                  onPressed: _isLoading ? null : () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
