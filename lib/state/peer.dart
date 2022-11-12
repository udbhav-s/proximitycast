import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peerdart/peerdart.dart';
import 'package:proximity_app/models/peer_state.dart';
import 'package:proximity_app/state/conn_data_manager.dart';

class PeerManager extends Notifier<PeerState> {
  @override
  PeerState build() {
    final peer = Peer();
    peer.on("open").listen((id) {
      final newState = PeerState(peer: peer);
      newState.peerId = id;
      newState.connected = true;
      state = newState;
    });

    peer.on<DataConnection>("connection").listen((conn) {
      print("Conn opened with ${conn.peer}");
      final connManager = ref.read(connManagerProvider);
      connManager(conn);
    });

    return PeerState(peer: peer);
  }
}

final peerProvider = NotifierProvider<PeerManager, PeerState>(
  PeerManager.new
);