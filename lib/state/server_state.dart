import "dart:async";
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proximity_app/state/dio.dart';
import '../models/server_state.dart';

class ServerStateManager extends AsyncNotifier<ServerState> {
  @override
  Future<ServerState> build() async {
    return read();
  }

  Future<ServerState> read() async {
    final dio = ref.read(dioProvider);

    var res = await dio.get("/range");
    var range = res.data["range"];

    res = await dio.get("/publicKey");
    String publicKey = res.data["publicKey"];

    return ServerState(publicKey: publicKey, range: range);
  }

  retry() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await read());
  }
}

final serverStateProvider = AsyncNotifierProvider<ServerStateManager, ServerState>(
  ServerStateManager.new
);