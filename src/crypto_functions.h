#include <assert.h>
#include <cstdlib>
#include <string>
#include <vector>
#include <gmp.h>
#include <iostream>
#include <gmpxx.h>
#include <math.h>
#include <random>
#include <climits>
#include <sstream>
#include <iomanip>
extern "C" {
  #include <paillier.h>
}
#include "coords.h"

#define PI 3.14159265359

// Declarations for FFI
extern "C" {
  struct KeyPair {
    char* publicKey;
    char* privateKey;
  };

  struct LocationCiphertexts {
    char* sumOfSquares;
    char* twoX;
    char* twoY;
  };

  struct DistanceResult {
    char* d2PlusK;
    char* k;
  };

  KeyPair createKeys();
  LocationCiphertexts appGetLocationCiphertexts(char* pubKeyString, double lat, double lon);
  DistanceResult appGetDistanceResult(
    char* pubKeyString,
    char* verifierPubKeyString,
    double lat,
    double lon,
    int rangeSquared,
    char* sos,
    char* tx,
    char* ty
  );
  long appDecryptDistanceCiphertext(char* pubKeyString, char* secKeyString, char* ct);
}