import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proximity_app/models/location_ciphertexts.dart';
import 'package:proximity_app/state/key_manager.dart';
import 'package:proximity_app/state/location.dart';
import 'ffi_bridge.dart';

final locationCiphertextsProvider = FutureProvider<LocationCiphertexts>((ref) async {
  final bridge = ref.read(ffiBridgeProvider);
  final kp = ref.read(keyManagerProvider);
  final location = await ref.read(locationProvider.future);

  if (location.latitude == null || location.longitude == null) {
    throw Exception("No latitude or longitude in location");
  }

  final lc = bridge.getLocationCiphertexts(
      kp.publicKey,
      location.latitude!,
      location.longitude!
  );

  return lc;
});