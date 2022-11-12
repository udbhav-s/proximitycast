import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proximity_app/models/chat.dart';
import 'package:proximity_app/models/chat_screen_arguments.dart';
import 'package:proximity_app/state/chats.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final messageController = TextEditingController();

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as ChatScreenArguments;
    ref.watch(chatsProvider);
    final chatManager = ref.read(chatsProvider.notifier);
    final chat = chatManager.get(args.peerId);

    late Widget comp;
    if (chat == null) {
      comp = const Center(
        child: Text("Chat not found")
      );
    } else {

      List<Widget> chatList = [
        Center(
          child: Padding(
            child: Text("Messages with ${chat.nickname}", style: const TextStyle(color: Colors.black54)),
            padding: EdgeInsets.all(16),
          )
        )
      ];

      for (final c in chat.messages) {
        chatList.add(Row(
          children: [
            Text(c.fromSelf ? "You: " : "${chat.nickname}: ",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)
            ),
            Text(c.text)
          ]
        ));
      }

      if (chat.disconnected) {
        chatList.add(
            const Center(
                child: Padding(
                    child: Text("Chat disconnected",
                    style: TextStyle(color: Colors.black54)),
                  padding: EdgeInsets.all(16),
                )
            )
        );
      }

      comp = Column(
          children: [
            Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: chatList,
                )
            ),
            TextField(
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
                hintText: 'Enter message',
                fillColor: Colors.blueGrey,
                filled: true,
                hintStyle: TextStyle(
                  color: Colors.black26,
                ),
              ),
              onSubmitted: (String input) {
                chatManager.send(args.peerId, input);
                messageController.clear();
              },
              controller: messageController
            ),
          ]
      );
    }

    return Scaffold(
        appBar: AppBar(title: const Text("Events")),
        body: comp
    );
  }
}
