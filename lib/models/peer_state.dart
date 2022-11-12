import 'package:peerdart/peerdart.dart';

class PeerState {
  Peer peer;
  String? peerId;
  bool connected = false;

  PeerState({ required this.peer });
}