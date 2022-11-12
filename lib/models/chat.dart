import 'package:peerdart/peerdart.dart';

class ChatMessage {
  final String text;
  final bool fromSelf;

  ChatMessage({
    required this.text,
    required this.fromSelf,
  });
}

class Chat {
  bool disconnected = false;
  List<ChatMessage> messages = [];
  DataConnection conn;
  String nickname;
  String title;

  Chat({ required this.conn, required this.nickname, required this.title });
}