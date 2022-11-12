import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proximity_app/state/key_manager.dart';
import 'package:proximity_app/state/user_profile.dart';

class BroadcastScreen extends ConsumerStatefulWidget {
  const BroadcastScreen({Key? key}) : super(key: key);

  @override
 BroadcastScreenState createState() => BroadcastScreenState();
}

class BroadcastScreenState extends ConsumerState<BroadcastScreen> {
  final nicknameField = TextEditingController();
  final descriptionField = TextEditingController();

  @override
  void dispose() {
    nicknameField.dispose();
    descriptionField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);

    final broadcastForm = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            children: [
              TextField(controller: nicknameField, decoration: const InputDecoration(
                hintText: "Name"
              )),
              TextField(controller: descriptionField, decoration: const InputDecoration(
                hintText: "Event Title"
              )),
              ElevatedButton(
                child: const Text("Broadcast"),
                onPressed: () async {
                  final nickname = nicknameField.text;
                  final description = descriptionField.text;

                  ref.read(userProfileProvider.notifier).upload(
                    nickname,
                    description
                  );
                },
              ),
            ]
        )
    );

    final broadcasting = Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
            children: [
              const Text("Broadcasting"),
              Text(userProfile?.nickname ?? "No username"),
              Text(userProfile?.title ?? "No description"),
              ElevatedButton(
                  child: const Text("Stop Broadcasting"),
                  onPressed: () async {
                    await ref.read(userProfileProvider.notifier).delete();
                  }
              )
            ]
        )
      )
    );

    return Scaffold(
        appBar: AppBar(title: const Text("Broadcast")),
        body: userProfile != null ? broadcasting : broadcastForm,
    );
  }
}
