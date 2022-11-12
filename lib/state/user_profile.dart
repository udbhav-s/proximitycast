import 'package:proximity_app/models/profile.dart';
import 'package:proximity_app/state/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proximity_app/state/key_manager.dart';
import 'package:proximity_app/state/location_ciphertexts.dart';
import 'package:proximity_app/state/peer.dart';

class UserProfileManager extends Notifier<Profile?> {
  @override
  Profile? build() {
    return null;
  }

  upload(String nickname, String title) async {
    final dio = ref.read(dioProvider);
    final kp = ref.read(keyManagerProvider);
    final locationCiphertexts = await ref.read(locationCiphertextsProvider.future);
    final peerState = ref.read(peerProvider);

    if (!peerState.connected) throw Exception("Not connected to Peer server");

    final res = await dio.post("/profile/create", data: {
      "publicKey": kp.publicKey,
      "locationCiphertexts": {
        "sumOfSquares": locationCiphertexts.sumOfSquares,
        "twoX": locationCiphertexts.twoX,
        "twoY": locationCiphertexts.twoY,
      },
      "peerId": peerState.peerId,
    });

    final profile = Profile(
      publicKey: kp.publicKey,
      peerId: peerState.peerId!,
      locationCiphertexts: locationCiphertexts
    );
    profile.nickname = nickname;
    profile.title = title;
    state = profile;

    print("Updated profile state");
  }

  delete() async {
    final dio = ref.read(dioProvider);
    await dio.post("/logout");

    state = null;
  }
}

final userProfileProvider = NotifierProvider<UserProfileManager, Profile?>(
  UserProfileManager.new
);