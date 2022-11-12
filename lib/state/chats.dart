import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peerdart/peerdart.dart';
import 'package:proximity_app/models/chat.dart';

class ChatsManager extends Notifier<List<Chat>> {
  @override
  List<Chat> build() {
    return [];
  }

  Chat? get(String peerId) {
    final filtered = state.where((chat) => chat.conn.peer == peerId).toList();
    if (filtered.isNotEmpty) {
      return filtered[0];
    }
    else {
      return null;
    }
  }

  Chat getOrCreate(DataConnection conn, String nickname, String title) {
    Chat? chat = get(conn.peer);
    if (chat == null) {
      chat = Chat(conn: conn, nickname: nickname, title: title);
      state = [...state, chat];
    }
    return chat;
  }

  addMessage(String peerId, ChatMessage msg) {
    final chat = get(peerId);
    if (chat == null) return;
    final filtered = state.where((c) => c.conn.peer != peerId);
    chat.messages.add(msg);
    state = [...filtered, chat];
  }

  send(String peerId, String msg) {
    Chat? chat = get(peerId);
    if (chat != null) {
      chat.conn.send({
        "type": "chat",
        "message": msg
      });

      addMessage(peerId, ChatMessage(text: msg, fromSelf: true));
    }
  }

  void disconnect(String peerId) {
    final chat = get(peerId);
    if (chat != null) {
      chat.disconnected = true;
    }
  }
}

final chatsProvider = NotifierProvider<ChatsManager, List<Chat>>(
  ChatsManager.new
);