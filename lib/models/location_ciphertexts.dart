class LocationCiphertexts {
  final String sumOfSquares;
  final String twoX;
  final String twoY;

  LocationCiphertexts({
    required this.sumOfSquares,
    required this.twoX,
    required this.twoY,
  });

  factory LocationCiphertexts.fromJson(Map<String, dynamic> json) {
    return LocationCiphertexts(
        sumOfSquares: json["sumOfSquares"],
        twoX: json["twoX"],
        twoY: json["twoY"]
    );
  }
}
