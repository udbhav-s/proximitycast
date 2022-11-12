import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peerdart/peerdart.dart';
import 'package:proximity_app/state/profiles.dart';
import 'package:proximity_app/state/user_profile.dart';

import '../models/chat.dart';
import 'chats.dart';
import 'dio.dart';
import 'ffi_bridge.dart';
import 'key_manager.dart';

final connManagerProvider = Provider((ref) {
  return (DataConnection conn) async {
    conn.on("close").listen((event) {
      ref.read(chatsProvider.notifier).disconnect(conn.peer);
      print("Conn closed with ${conn.peer}");
    });

    conn.on("data").listen((data) async {
      print("data received");

      if (data["type"] == "distanceResult") {
        final bridge = ref.read(ffiBridgeProvider);
        final kp = ref.read(keyManagerProvider);
        final dio = ref.read(dioProvider);
        final selfProfile = ref.read(userProfileProvider);

        if (selfProfile == null) return;

        final encD2PlusK = data["d2PlusK"];
        final encK = data["k"];

        final d2PlusK = bridge.decryptDistance(
            kp.publicKey,
            kp.privateKey,
            encD2PlusK
        );

        final result = await dio.post("/verifyDistance", data: {
          "d2PlusK": d2PlusK,
          "encK": encK
        });

        if (result.data["isNearby"]) {
          print("${conn.peer} found in proximity");
          conn.send({
            "type": "foundNearby",
            "nickname": selfProfile.nickname,
            "title": selfProfile.title,
          });

          ref.read(chatsProvider.notifier).getOrCreate(
              conn,
              "Anonymous User",
              "Anonymous User ${conn.peer}"
          );
        }
      } else if (data["type"] == "chat") {
        ref.read(chatsProvider.notifier).addMessage(conn.peer, ChatMessage(
          text: data["message"],
          fromSelf: false,
        ));
      } else if (data["type"] == "foundNearby") {
        final profile = ref.read(profilesProvider.notifier).getByPeerId(conn.peer);
        if (profile != null) {
          ref.read(chatsProvider.notifier).getOrCreate(
            conn,
            data["nickname"] ?? "Anonymous User",
            data["title"] ?? "No title provided"
          );
        }
      }
    });
  };
});