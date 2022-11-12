import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:proximity_app/state/ffi_bridge.dart';
import '../models/key_pair.dart';

class KeyManager extends Notifier<KeyPair> {
  @override
  KeyPair build() {
    var box = Hive.box("myBox");
    var bridge = ref.read(ffiBridgeProvider);
    late final KeyPair keyPair;

    var publicKey = box.get("publicKey");
    var privateKey = box.get("privateKey");
    if (publicKey != null && privateKey != null) {
      keyPair = KeyPair(publicKey, privateKey);
    } else {
      keyPair = bridge.createKeys();
      box.put("publicKey", keyPair.publicKey);
      box.put("privateKey", keyPair.privateKey);
    }

    return keyPair;
  }

  void generateNewKeys() {
    var box = Hive.box("myBox");
    var bridge = ref.read(ffiBridgeProvider);
    final keyPair = bridge.createKeys();
    box.put("publicKey", keyPair.publicKey);
    box.put("privateKey", keyPair.privateKey);

    state = keyPair;
  }
}

final keyManagerProvider =
    NotifierProvider<KeyManager, KeyPair>(KeyManager.new);
