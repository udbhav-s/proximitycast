import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:proximity_app/components/broadcast.dart';
import 'package:proximity_app/components/chat.dart';
import 'package:proximity_app/components/debug.dart';
import 'package:proximity_app/components/drawer.dart';
import 'package:proximity_app/models/chat_screen_arguments.dart';
import 'package:proximity_app/state/chats.dart';
import 'package:proximity_app/state/key_manager.dart';
import 'package:proximity_app/state/location.dart';
import 'package:proximity_app/state/location_ciphertexts.dart';
import 'package:proximity_app/state/peer.dart';
import 'package:proximity_app/state/profiles.dart';
import 'package:proximity_app/state/server_state.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox("myBox");

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Test App",
      initialRoute: "/",
      routes: {
        "/": (context) => const MainScreen(),
        "/broadcast": (context) => const BroadcastScreen(),
        "/debug": (context) => const DebugScreen(),
        "/chat": (context) => const ChatScreen(),
      }
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainScreen> createState() => _MainState();
}

class _MainState extends ConsumerState<MainScreen> {
  @override
  Widget build(BuildContext context) {
    final chats = ref.watch(chatsProvider);
    ref.read(keyManagerProvider);
    ref.read(serverStateProvider);
    ref.read(locationProvider);
    ref.read(peerProvider);
    ref.read(locationCiphertextsProvider);

    final List<Widget> chatList = [];

    chatList.addAll([
      const Center(
        child: Text("Found Nearby", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
      ),
      const Divider(),
      ElevatedButton(
          child: const Text("Check for events"),
          onPressed: () async {
            final profileManager = ref.read(profilesProvider.notifier);
            await profileManager.getProfiles();
            await profileManager.processProfiles();
          }
      ),
      const Divider(),
    ]);

    for (final chat in chats) {
      chatList.add(ListTile(
          title: Text(chat.title),
          subtitle: Text(chat.nickname),
          onTap: () {
            Navigator.pushNamed(
                context, "/chat",
                arguments: ChatScreenArguments(
                    peerId: chat.conn.peer
                )
            );
          }
      ));
      chatList.add(const Divider());
    }

    return Scaffold(
        appBar: AppBar(title: const Text("Events")),
        drawer: const AppDrawer(),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: chatList,
        )
    );
  }
}
