import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proximity_app/models/profile.dart';
import 'package:proximity_app/state/chats.dart';
import 'package:proximity_app/state/dio.dart';
import 'package:proximity_app/state/ffi_bridge.dart';
import 'package:proximity_app/state/location.dart';
import 'package:proximity_app/state/peer.dart';
import 'package:proximity_app/models/location_ciphertexts.dart';
import 'package:proximity_app/state/server_state.dart';
import 'package:proximity_app/state/conn_data_manager.dart';

class ProfilesManager extends Notifier<List<Profile>> {
  @override
  List<Profile> build() {
    return [];
  }

  getProfiles() async {
    final dio = ref.read(dioProvider);
    final res = await dio.get("/profiles");
    List<Profile> profiles = res.data["profiles"].map<Profile>((p) {
      final profile = Profile(
        publicKey: p["publicKey"],
        peerId: p["peerId"],
        locationCiphertexts: LocationCiphertexts(
          sumOfSquares: p["locationCiphertexts"]["sumOfSquares"],
          twoX: p["locationCiphertexts"]["twoX"],
          twoY: p["locationCiphertexts"]["twoY"]
        )
      );
      return profile;
    }).toList();

    state = profiles;
  }

  processProfiles() async {
    final peerState = ref.read(peerProvider);
    final bridge = ref.read(ffiBridgeProvider);
    final location = await ref.read(locationProvider.future);
    final server = await ref.read(serverStateProvider.future);
    final chats = ref.read(chatsProvider.notifier);
    if (!peerState.connected) throw Exception("Peer not connected!");

    for (final profile in state) {
      if (chats.get(profile.peerId) != null) continue;

      final conn = peerState.peer.connect(profile.peerId);

      conn.on("open").listen((event) async {
        final dr = bridge.getDistanceResult(
            profile.publicKey,
            server.publicKey,
            location.latitude!,
            location.longitude!,
            server.range*server.range,
            profile.locationCiphertexts
        );

        print("Sending distance result to ${conn.peer}");

        conn.send({
          "type": "distanceResult",
          "d2PlusK": dr.d2PlusK,
          "k": dr.k
        });

        final connManager = ref.read(connManagerProvider);
        connManager(conn);
      });
    }
  }

  Profile? getByPeerId(String peerId) {
    final filtered = state.where((p) => p.peerId == peerId).toList();
    if (filtered.isNotEmpty) {
      return filtered[0];
    }
    else {
      return null;
    }
  }
}

final profilesProvider = NotifierProvider<ProfilesManager, List<Profile>>(
  ProfilesManager.new
);