import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proximity_app/components/drawer.dart';
import 'package:proximity_app/state/key_manager.dart';
import 'package:proximity_app/state/location.dart';
import 'package:proximity_app/state/location_ciphertexts.dart';
import 'package:proximity_app/state/peer.dart';
import 'package:proximity_app/state/profiles.dart';
import 'package:proximity_app/state/server_state.dart';

class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DebugScreen> createState() => _DebugState();
}

class _DebugState extends ConsumerState<DebugScreen> {
  @override
  Widget build(BuildContext context) {
    var kp = ref.watch(keyManagerProvider);
    var server = ref.watch(serverStateProvider);
    var ld = ref.watch(locationProvider);
    var peer = ref.watch(peerProvider);
    var lca = ref.watch(locationCiphertextsProvider);

    const header = TextStyle(fontSize: 20, color: Colors.blue);

    return Scaffold(
        appBar: AppBar(title: const Text("Debug Information")),
        drawer: const AppDrawer(),
        body: Container(
            padding: const EdgeInsets.all(16),
            child: ListView(
                children: [
                  const Text("Public Key", style: header),
                  Text(kp.publicKey),
                  ElevatedButton(
                      onPressed: () {
                        ref.read(keyManagerProvider.notifier).generateNewKeys();
                      },
                      child: const Text("Generate New Keys")
                  ),
                  const Text("Server Public Key", style: header),
                  server.when(
                    loading: () => const Text("Loading server public key.."),
                    data: (data) => Text(data.publicKey),
                    error: (e, st) => Text(server.toString().substring(0, 100) + "..."),
                  ),
                  ElevatedButton(
                      onPressed: () {
                        ref.read(serverStateProvider.notifier).retry();
                      },
                      child: const Text("Reconnect To Server")
                  ),
                  const Text("Location", style: header),
                  ld.when(
                    loading: () => const Text("Loading location"),
                    data: (data) => Text("${data.latitude} ${data.longitude}"),
                    error: (e, st) => Text(e.toString()),
                  ),
                  const Text("Peer ID", style: header),
                  Text(peer.connected ? peer.peerId! : "Connecting peer..."),
                  const Text("Location ciphertext [0]: ", style: header),
                  lca.when(
                    loading: () => const Text("Loading location ciphertexts"),
                    data: (data) => Text(data.sumOfSquares),
                    error: (e, st) => Text(e.toString()),
                  )
                ]
            )
        ));
  }
}