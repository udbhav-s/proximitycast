import "package:proximity_app/ffi_bridge.dart";
import 'package:riverpod_annotation/riverpod_annotation.dart';

final ffiBridgeProvider = Provider<FfiBridge>((ref) {
  return FfiBridge();
});
