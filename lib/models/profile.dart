import "package:proximity_app/models/location_ciphertexts.dart";
import "package:proximity_app/models/chat.dart";

class Profile {
  final String publicKey;
  String peerId;
  LocationCiphertexts locationCiphertexts;

  String nickname = "User";
  String title = "No title provided";

  Profile({
    required this.publicKey,
    required this.peerId,
    required this.locationCiphertexts,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    final profile = Profile(
      publicKey: json["publicKey"],
      peerId: json["peerId"],
      locationCiphertexts: LocationCiphertexts.fromJson(json["location"])
    );
    profile.nickname = json["nickname"] ?? "User";
    profile.title = json["title"] ?? "No title provided";
    return profile;
  }

  bool isEqual(Profile p) {
    return (
        peerId == p.peerId &&
        publicKey == p.publicKey &&
        locationCiphertexts.sumOfSquares == p.locationCiphertexts.sumOfSquares &&
        locationCiphertexts.twoX == p.locationCiphertexts.twoX &&
        locationCiphertexts.twoY == p.locationCiphertexts.twoY
    );
  }
}
