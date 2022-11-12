import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:proximity_app/models/distance_result.dart';
import 'models/key_pair.dart';
import 'models/location_ciphertexts.dart';

class KeyPairNative extends Struct {
  external Pointer<Utf8> publicKey;
  external Pointer<Utf8> privateKey;
}

class LocationCiphertextsNative extends Struct {
  external Pointer<Utf8> sumOfSquares;
  external Pointer<Utf8> twoX;
  external Pointer<Utf8> twoY;
}

class DistanceResultNative extends Struct {
  external Pointer<Utf8> d2PlusK;
  external Pointer<Utf8> k;
}

typedef CreateKeysFunction = KeyPairNative Function();

typedef GetLocationCiphertextsFunctionNative =
  LocationCiphertextsNative Function(Pointer<Utf8> pubKeyString, Double lat, Double lon);
typedef GetLocationCiphertextsFunction =
  LocationCiphertextsNative Function(Pointer<Utf8> pubKeyString, double lat, double lon);

typedef GetDistanceResultFunctionNative =
    DistanceResultNative Function(
        Pointer<Utf8> pubKeyString,
        Pointer<Utf8> verifierPubKeyString,
        Double lat,
        Double lon,
        Int rangeSquared,
        Pointer<Utf8> sos,
        Pointer<Utf8> tx,
        Pointer<Utf8> ty
        );
typedef GetDistanceResultFunction =
    DistanceResultNative Function(
        Pointer<Utf8> pubKeyString,
        Pointer<Utf8> verifierPubKeyString,
        double lat,
        double lon,
        int rangeSquared,
        Pointer<Utf8> sos,
        Pointer<Utf8> tx,
        Pointer<Utf8> ty
        );

typedef DecryptDistanceFunctionNative = Long Function(
    Pointer<Utf8> pubKeyString,
    Pointer<Utf8> prvKeyString,
    Pointer<Utf8> ct
    );
typedef DecryptDistanceFunction = int Function(
    Pointer<Utf8> pubKeyString,
    Pointer<Utf8> prvKeyString,
    Pointer<Utf8> ct
    );

class FfiBridge {
  static final _dylib = DynamicLibrary.open("libmymain.so");
  late final CreateKeysFunction _createKeysNative;
  late final GetLocationCiphertextsFunction _getLocationCiphertextsNative;
  late final GetDistanceResultFunction _getDistanceResult;
  late final DecryptDistanceFunction _decryptDistance;

  FfiBridge() {
    _createKeysNative = _dylib
        .lookupFunction<CreateKeysFunction, CreateKeysFunction>("createKeys");
    _getLocationCiphertextsNative = _dylib
        .lookupFunction<
          GetLocationCiphertextsFunctionNative,
          GetLocationCiphertextsFunction
        >("appGetLocationCiphertexts");
    _getDistanceResult = _dylib
      .lookupFunction<
        GetDistanceResultFunctionNative,
        GetDistanceResultFunction
      >("appGetDistanceResult");
    _decryptDistance = _dylib
      .lookupFunction<
        DecryptDistanceFunctionNative,
        DecryptDistanceFunction
      >("appDecryptDistanceCiphertext");
  }

  KeyPair createKeys() {
    var result = _createKeysNative();
    var kp = KeyPair(
        result.publicKey.toDartString(), result.privateKey.toDartString());

    malloc.free(result.publicKey);
    malloc.free(result.privateKey);

    return kp;
  }

  LocationCiphertexts getLocationCiphertexts(String pubKey, double lat, double lon) {
    final pubKeyUtf8 = pubKey.toNativeUtf8();
    final locationNative = _getLocationCiphertextsNative(
      pubKeyUtf8,
      lat,
      lon
    );

    final location = LocationCiphertexts(
        sumOfSquares: locationNative.sumOfSquares.toDartString(),
        twoX: locationNative.twoX.toDartString(),
        twoY: locationNative.twoY.toDartString()
    );

    malloc.free(locationNative.sumOfSquares);
    malloc.free(locationNative.twoX);
    malloc.free(locationNative.twoY);
    malloc.free(pubKeyUtf8);

    return location;
  }

  DistanceResult getDistanceResult(
      String pubKey,
      String verifierPubKey,
      double lat,
      double lon,
      int rangeSquared,
      LocationCiphertexts lc) {
    final pubKeyUtf8 = pubKey.toNativeUtf8();
    final verifierPubKeyUtf8 = verifierPubKey.toNativeUtf8();
    final sos = lc.sumOfSquares.toNativeUtf8();
    final tx = lc.twoX.toNativeUtf8();
    final ty = lc.twoY.toNativeUtf8();

    final drNative = _getDistanceResult(
      pubKeyUtf8,
      verifierPubKeyUtf8,
      lat,
      lon,
      rangeSquared,
      sos,
      tx,
      ty
    );

    final dr = DistanceResult(
      d2PlusK: drNative.d2PlusK.toDartString(),
      k: drNative.k.toDartString(),
    );

    print("Distance result:");
    print(dr.d2PlusK);
    print(dr.k);

    malloc.free(pubKeyUtf8);
    malloc.free(verifierPubKeyUtf8);
    malloc.free(sos);
    malloc.free(tx);
    malloc.free(ty);
    malloc.free(drNative.d2PlusK);
    malloc.free(drNative.k);

    return dr;
  }

  int decryptDistance(
      String publicKey,
      String privateKey,
      String ciphertext
      ) {
    final pubKeyString = publicKey.toNativeUtf8();
    final prvKeyString = privateKey.toNativeUtf8();
    final ct = ciphertext.toNativeUtf8();

    int result = _decryptDistance(
      pubKeyString,
      prvKeyString,
      ct
    );

    print("Decrypted number ffi: ${result}");

    malloc.free(pubKeyString);
    malloc.free(prvKeyString);
    malloc.free(ct);

    return result;
  }
}
