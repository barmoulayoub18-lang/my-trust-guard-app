import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../data/services/ai_service.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<Map<String, String>> messages = [
    {
      "role": "ai",
      "text":
          "👋 Hi! I'm your AI assistant.\nAsk me about store safety, scams, or safe shopping tips."
    }
  ];

  bool isLoading = false;

  Future<void> sendMessage() async {
    final text = controller.text.trim();

    print("======== SEND MESSAGE START ========");
    print("User input: $text");
    print("isLoading: $isLoading");

    if (text.isEmpty || isLoading) {
      print("Blocked: empty or loading");
      return;
    }

    setState(() {
      messages.add({"role": "user", "text": text});
      controller.clear();
      isLoading = true;
    });

    print("Message added to UI");
    _scrollToBottom();

    try {
      final prompt =
          "You are a professional e-commerce safety assistant.\n"
          "Answer clearly and shortly.\n\nUser: $text";

      print("Sending to AIService...");
      print("Prompt: $prompt");

      final response = await AIService.chat(prompt);

      print("AI response received:");
      print(response);

      setState(() {
        messages.add({
          "role": "ai",
          "text": response.toString(),
        });
      });

      print("AI message added to UI");
    } catch (e) {
      print("ERROR in sendMessage:");
      print(e.toString());

      setState(() {
        messages.add({
          "role": "ai",
          "text": "⚠️ Failed to get response. Try again."
        });
      });
    } finally {
      setState(() => isLoading = false);
      print("Loading finished");
      print("======== SEND MESSAGE END ========");
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    print("Scrolling to bottom...");
    Future.delayed(const Duration(milliseconds: 200), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        print("Scroll done");
      } else {
        print("ScrollController has no clients");
      }
    });
  }

  Widget buildMessage(Map<String, String> msg) {
    final isUser = msg["role"] == "user";

    print("Building message: ${msg["text"]}");

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.smart_toy, size: 16, color: Colors.white),
            ),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                msg["text"] ?? "",
                style: const TextStyle(
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget buildTyping() {
    print("Showing typing indicator");

    return Row(
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.smart_toy, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Row(
          children: const [
            Dot(),
            Dot(delay: 200),
            Dot(delay: 400),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    print("Building AssistantScreen UI");

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("AI Assistant"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return buildMessage(messages[index]);
              },
            ),
          ),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.all(12),
              child: buildTyping(),
            ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Ask anything...",
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: isLoading ? null : sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Dot extends StatefulWidget {
  final int delay;

  const Dot({super.key, this.delay = 0});

  @override
  State<Dot> createState() => _DotState();
}

class _DotState extends State<Dot>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    print("Dot init with delay ${widget.delay}");

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        controller.repeat();
        print("Dot animation started");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.2, end: 1.0).animate(controller),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: CircleAvatar(
          radius: 3,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  @override
  void dispose() {
    print("Dot disposed");
    controller.dispose();
    super.dispose();
  }
}