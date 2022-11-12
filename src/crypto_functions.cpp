#include "crypto_functions.h"
//#include <android/log.h>

void applog(const std::string &s) {
  // __android_log_print(ANDROID_LOG_DEBUG, "CRYPTO_FUNCTIONS", "%s", s.c_str());
}

unsigned char HexChar (char c)
{
    if ('0' <= c && c <= '9') return (unsigned char)(c - '0');
    if ('A' <= c && c <= 'F') return (unsigned char)(c - 'A' + 10);
    if ('a' <= c && c <= 'f') return (unsigned char)(c - 'a' + 10);
    return 0xFF;
}

int HexToBin (const char* s, unsigned char * buff, int length)
{
    int result;
    if (!s || !buff || length <= 0) return -1;

    for (result = 0; *s; ++result)
    {
        unsigned char msn = HexChar(*s++);
        if (msn == 0xFF) return -1;
        unsigned char lsn = HexChar(*s++);
        if (lsn == 0xFF) return -1;
        unsigned char bin = (msn << 4) + lsn;

        if (length-- <= 0) return -1;
        *buff++ = bin;
    }
    return result;
}

std::string hexStr(const uint8_t *data, int len)
{
  std::stringstream ss;
  ss << std::hex;

  for (int i(0); i < len; ++i)
    ss << std::setw(2) << std::setfill('0') << (int)data[i];

  return ss.str();
}

char* getHexFromBytes(char* buf, int len) {
  auto str = hexStr((uint8_t*)buf, len);
  char* cstr = (char*) malloc(str.length()+1);
  std::strcpy(cstr, str.c_str());
  return cstr;
}

char* getBytesFromHex(char* hex, size_t len) {
  unsigned char* out = (unsigned char*) malloc(len);
  int result = HexToBin(hex, out, len);
  return (char*) out;
}

KeyPair createKeys()
{
  // Security parameter (number of bits of modulus)
  const long n = 1024;

  // Generate public and secret keys
  paillier_pubkey_t *pubKey;
  paillier_prvkey_t *secKey;
  paillier_keygen(n, &pubKey, &secKey, paillier_get_rand_devurandom);

  char *hexSecKey = paillier_prvkey_to_hex(secKey);
  char *hexPubKey = paillier_pubkey_to_hex(pubKey);

  paillier_freepubkey(pubKey);
  paillier_freeprvkey(secKey);

  KeyPair kp;
  kp.publicKey = hexPubKey;
  kp.privateKey = hexSecKey;
  return kp;
}

std::tuple<mpz_class, mpz_class> getEncodedLatLon(paillier_pubkey_t *pubKey, double lat, double lon)
{
  auto utm = getUTM(lat, lon);

  long lat2 = static_cast<long>(std::get<0>(utm));
  long lon2 = static_cast<long>(std::get<1>(utm));

  mpz_class latGmp(lat2);
  mpz_class lonGmp(lon2);

  // mod coordinates with key N to wrap negative values
  mpz_class keyN(pubKey->n);
  latGmp = latGmp % keyN;
  lonGmp = lonGmp % keyN;

  // mpz_t num1;
  // mpz_init(num1);
  // mpz_mod(num1, lonGmp.get_mpz_t(), keyN.get_mpz_t());
  // mpz_class lonGmp2(num1);
  // mpz_t num2;
  // mpz_init(num2);
  // mpz_mod(num2, latGmp.get_mpz_t(), keyN.get_mpz_t());
  // mpz_class latGmp2(num2);

  std::tuple<mpz_class, mpz_class> tup{latGmp, lonGmp};
  return tup;
}

char *getEncryptedNumberBytes(paillier_pubkey_t *pubKey, long n)
{
  mpz_class n1 = n;
  mpz_class keyN(pubKey->n);
  n1 = n1 % keyN;

  paillier_plaintext_t *p1 = (paillier_plaintext_t *)malloc(sizeof(paillier_plaintext_t));
  mpz_init_set(p1->m, n1.get_mpz_t());

  paillier_ciphertext_t *c1;
  c1 = paillier_enc(NULL, pubKey, p1, paillier_get_rand_devurandom);

  char *s1 = (char *)paillier_ciphertext_to_bytes(PAILLIER_BITS_TO_BYTES(pubKey->bits) * 2, c1);

  paillier_freeplaintext(p1);
  paillier_freeciphertext(c1);

  return s1;
}

std::vector<paillier_ciphertext_t *>
getLocationCiphertexts(paillier_pubkey_t *pubKey, double lat, double lon)
{
  auto tup = getEncodedLatLon(pubKey, lat, lon);
  auto latGmp = std::get<0>(tup);
  auto lonGmp = std::get<1>(tup);

  mpz_class sumOfSquares = latGmp * latGmp + lonGmp * lonGmp;
  mpz_class twoX = 2 * lonGmp;
  mpz_class twoY = 2 * latGmp;

  // gmp_printf("%Zd\n", twoX.get_mpz_t()); // DEBUG

  paillier_plaintext_t *p1 = (paillier_plaintext_t *)malloc(sizeof(paillier_plaintext_t));
  mpz_init_set(p1->m, sumOfSquares.get_mpz_t());
  paillier_ciphertext_t *encSumOfSquares;
  encSumOfSquares = paillier_enc(NULL, pubKey, p1, paillier_get_rand_devurandom);

  paillier_plaintext_t *p2 = (paillier_plaintext_t *)malloc(sizeof(paillier_plaintext_t));
  mpz_init_set(p2->m, twoX.get_mpz_t());
  paillier_ciphertext_t *encTwoX;
  encTwoX = paillier_enc(NULL, pubKey, p2, paillier_get_rand_devurandom);

  paillier_plaintext_t *p3 = (paillier_plaintext_t *)malloc(sizeof(paillier_plaintext_t));
  mpz_init_set(p3->m, twoY.get_mpz_t());
  paillier_ciphertext_t *encTwoY;
  encTwoY = paillier_enc(NULL, pubKey, p3, paillier_get_rand_devurandom);

  paillier_freeplaintext(p1);
  paillier_freeplaintext(p2);
  paillier_freeplaintext(p3);

  std::vector<paillier_ciphertext_t *> vec{encSumOfSquares, encTwoX, encTwoY};
  return vec;
}

LocationCiphertexts appGetLocationCiphertexts(char *pubKeyString, double lat, double lon)
{
  applog("Encoding latlon with public key: ");
  applog(pubKeyString);
  applog("lat: " + std::to_string(lat) + " lon: " + std::to_string(lon));

  paillier_pubkey_t *pubKey = paillier_pubkey_from_hex(pubKeyString);
  int buflen = PAILLIER_BITS_TO_BYTES(pubKey->bits) * 2;

  auto ctxts = getLocationCiphertexts(pubKey, lat, lon);

  LocationCiphertexts lc;

  auto c1 = ctxts.at(0);
  char *s1 = (char *)paillier_ciphertext_to_bytes(buflen, c1);
  lc.sumOfSquares = getHexFromBytes(s1, buflen);
  free(s1);

  auto c2 = ctxts.at(1);
  char *s2 = (char *)paillier_ciphertext_to_bytes(buflen, c2);
  lc.twoX = getHexFromBytes(s2, buflen);
  free(s2);

  auto c3 = ctxts.at(2);
  char *s3 = (char *)paillier_ciphertext_to_bytes(buflen, c3);
  lc.twoY = getHexFromBytes(s3, buflen);
  free(s3);

  paillier_freepubkey(pubKey);

  applog("Location ciphertexts in function (sos, tx, ty): ");
  applog(lc.sumOfSquares);
  applog(lc.twoX);
  applog(lc.twoY);

  return lc;
}

paillier_ciphertext_t *getDistanceCiphertext(
    paillier_pubkey_t *pubKey,
    double lat,
    double lon,
    int rangeSquared,
    std::vector<paillier_ciphertext_t *> encs,
    long &k)
{
  auto tup = getEncodedLatLon(pubKey, lat, lon);
  auto latGmp = std::get<0>(tup);
  auto lonGmp = std::get<1>(tup);

  mpz_class sumOfSquares = latGmp * latGmp + lonGmp * lonGmp;

  paillier_plaintext_t *px = (paillier_plaintext_t *)malloc(sizeof(paillier_plaintext_t));
  mpz_init_set(px->m, lonGmp.get_mpz_t());

  paillier_plaintext_t *py = (paillier_plaintext_t *)malloc(sizeof(paillier_plaintext_t));
  mpz_init_set(py->m, latGmp.get_mpz_t());

  paillier_plaintext_t *p1 = (paillier_plaintext_t *)malloc(sizeof(paillier_plaintext_t));
  mpz_init_set(p1->m, sumOfSquares.get_mpz_t());

  paillier_ciphertext_t *encSumOfSquares;
  encSumOfSquares = paillier_enc(NULL, pubKey, p1, paillier_get_rand_devurandom);

  paillier_ciphertext_t *sum1 = paillier_create_enc_zero();
  paillier_mul(pubKey, sum1, encSumOfSquares, encs[0]);

  paillier_ciphertext_t *sum2 = paillier_create_enc_zero();
  paillier_exp(pubKey, sum2, encs[1], px);

  paillier_ciphertext_t *sum3 = paillier_create_enc_zero();
  paillier_exp(pubKey, sum3, encs[2], py);

  paillier_ciphertext_t *sum4 = paillier_create_enc_zero();
  paillier_mul(pubKey, sum4, sum2, sum3);

  mpz_class neg(-1);
  mpz_class keyN(pubKey->n);
  neg = neg % keyN;
  paillier_plaintext_t *p2 = (paillier_plaintext_t *)malloc(sizeof(paillier_plaintext_t));
  mpz_init_set(p2->m, neg.get_mpz_t());
  // gmp_printf("Modded version of neg: %Zd\n", neg.get_mpz_t());

  paillier_ciphertext_t *sum5 = paillier_create_enc_zero();
  paillier_exp(pubKey, sum5, sum4, p2);

  paillier_ciphertext_t *sum = paillier_create_enc_zero();
  paillier_mul(pubKey, sum, sum1, sum5);

  paillier_ciphertext_t *sumMinusR2 = paillier_create_enc_zero();
  mpz_class r2 = (-rangeSquared) % keyN;
  paillier_plaintext_t *p_r2 = (paillier_plaintext_t *)malloc(sizeof(paillier_plaintext_t));
  mpz_init_set(p_r2->m, r2.get_mpz_t());
  paillier_ciphertext_t *enc_r2 = paillier_enc(NULL, pubKey, p_r2, paillier_get_rand_devurandom);
  paillier_mul(pubKey, sumMinusR2, sum, enc_r2);

  std::default_random_engine generator;
  std::uniform_int_distribution<long> distribution(LONG_MIN / 2, LONG_MAX / 2);
  long randomNum = distribution(generator);
  mpz_class rn = randomNum;
  paillier_plaintext_t *rnp = (paillier_plaintext_t *)malloc(sizeof(paillier_plaintext_t));
  mpz_init_set(rnp->m, rn.get_mpz_t());
  paillier_ciphertext_t *encRandom;
  encRandom = paillier_enc(NULL, pubKey, rnp, paillier_get_rand_devurandom);

  paillier_ciphertext_t *sumWithRandom = paillier_create_enc_zero();
  paillier_mul(pubKey, sumWithRandom, sumMinusR2, encRandom);

  paillier_freeplaintext(p1);
  paillier_freeplaintext(p2);
  paillier_freeplaintext(px);
  paillier_freeplaintext(py);
  paillier_freeplaintext(p_r2);
  paillier_freeplaintext(rnp);

  paillier_freeciphertext(encSumOfSquares);
  paillier_freeciphertext(sum1);
  paillier_freeciphertext(sum2);
  paillier_freeciphertext(sum3);
  paillier_freeciphertext(sum4);
  paillier_freeciphertext(sum5);
  paillier_freeciphertext(sum);
  paillier_freeciphertext(encRandom);
  paillier_freeciphertext(sumMinusR2);
  paillier_freeciphertext(enc_r2);

  k = randomNum;
  return sumWithRandom;
}

DistanceResult appGetDistanceResult(
    char *pubKeyString,
    char *verifierPubKeyString,
    double lat,
    double lon,
    int rangeSquared,
    char *sos,
    char *tx,
    char *ty
  )
{
  applog("Get distance: ");
  applog("pub key: ");
  applog(pubKeyString);
  applog("Verifier pub key: ");
  applog(verifierPubKeyString);
  applog("getdistance lat: " + std::to_string(lat) + " lon: " + std::to_string(lon));
  applog("range squared: " + std::to_string(rangeSquared));
  applog("location ciphertexts: ");
  applog(sos);
  applog(tx);
  applog(ty);

  paillier_pubkey_t *pubKey = paillier_pubkey_from_hex(pubKeyString);
  paillier_pubkey_t *verifierPubKey = paillier_pubkey_from_hex(verifierPubKeyString);
  int buflen = PAILLIER_BITS_TO_BYTES(pubKey->bits) * 2;

  char *sosBytes = getBytesFromHex(sos, buflen);
  char *txBytes = getBytesFromHex(tx, buflen);
  char *tyBytes = getBytesFromHex(ty, buflen);

  auto c1 = paillier_ciphertext_from_bytes((void *)sosBytes, buflen);
  auto c2 = paillier_ciphertext_from_bytes((void *)txBytes, buflen);
  auto c3 = paillier_ciphertext_from_bytes((void *)tyBytes, buflen);
  std::vector<paillier_ciphertext_t *> vec{c1, c2, c3};

  free(sosBytes);
  free(txBytes);
  free(tyBytes);

  long k;

  auto d = getDistanceCiphertext(pubKey, lat, lon, rangeSquared, vec, k);
  char *dc = (char *)paillier_ciphertext_to_bytes(buflen, d);
  char *dcHex = getHexFromBytes(dc, buflen);
  free(dc);

  applog("Distance ciphertext: ");
  applog(dcHex);

  applog("Random k generated: ");
  applog(std::to_string(k));

  char *encK = getEncryptedNumberBytes(verifierPubKey, k);
  char *encKHex = getHexFromBytes(encK, buflen);

  free(encK);

  DistanceResult dr;
  dr.d2PlusK = dcHex;
  dr.k = encKHex;

  paillier_freepubkey(pubKey);
  paillier_freepubkey(verifierPubKey);

  paillier_freeciphertext(c1);
  paillier_freeciphertext(c2);
  paillier_freeciphertext(c3);
  paillier_freeciphertext(d);

  return dr;
}

long appDecryptDistanceCiphertext(char *pubKeyString, char *secKeyString, char *ct)
{
  paillier_pubkey_t *pubKey = paillier_pubkey_from_hex(pubKeyString);
  paillier_prvkey_t *secKey = paillier_prvkey_from_hex(secKeyString, pubKey);
  int buflen = PAILLIER_BITS_TO_BYTES(pubKey->bits) * 2;

  char* ctBytes = getBytesFromHex(ct, buflen);
  auto c = paillier_ciphertext_from_bytes((void *)ctBytes, buflen);

  paillier_plaintext_t *dec;
  dec = paillier_dec(NULL, pubKey, secKey, c);

  mpz_class decVal(dec->m);
  mpz_class keyN(pubKey->n);
  mpz_class diff = keyN - decVal;

  paillier_freepubkey(pubKey);
  paillier_freeprvkey(secKey);
  paillier_freeciphertext(c);
  free(ctBytes);

  long n = mpz_get_si(dec->m);

  applog("decrypted number: " + std::to_string(n));

  // handle negative values
  if (diff < decVal) {
    n = -diff.get_si();
  }

  paillier_freeplaintext(dec);

  return n;
}

int test() {
  KeyPair alice = createKeys();
  KeyPair verifier = createKeys();

  double aliceLat = 42.723138;
  double aliceLon = -84.488246;

  double bobLat = 42.724761;
  double bobLon = -84.487344;

  int rangeSquared = 100*100;

  auto aliceLocation = appGetLocationCiphertexts(alice.publicKey, aliceLat, aliceLon);

  auto bobDistanceResult = appGetDistanceResult(
    alice.publicKey,
    verifier.publicKey,
    bobLat,
    bobLon,
    rangeSquared,
    aliceLocation.sumOfSquares,
    aliceLocation.twoX,
    aliceLocation.twoY
  );

  auto d2plusk = appDecryptDistanceCiphertext(alice.publicKey, alice.privateKey, bobDistanceResult.d2PlusK);
  auto k = appDecryptDistanceCiphertext(verifier.publicKey, verifier.privateKey, bobDistanceResult.k);

  std::cout << "Decrypted:\n";
  std::cout << "d2 + k\n" << d2plusk << std::endl;
  std::cout << "k: \n" << k << std::endl;
  std::cout << "d2: " << d2plusk - k << std::endl;

  return 0;
}

// For node server
int cmd(int argc, char *argv[])
{
  if (argc <= 1)
    return 1;
  std::string option(argv[1]);

  if (option == "createKeys")
  {
    KeyPair kp = createKeys();
    std::cout << kp.publicKey << std::endl;
    // a little haiku by me:
    // this is not secure
    // i know but i dont have time
    // must finish project
    std::cout << kp.privateKey << std::endl;
  }
  else if (option == "decryptDistance")
  {
    if (argc < 5)
      return 1;

    long d = appDecryptDistanceCiphertext(
        argv[2],
        argv[3],
        argv[4]);

    std::cout << d << std::endl;
  }
  else if (option == "getLocationCiphertexts")
  {
    if (argc < 5)
      return 1;
    std::string pk(argv[2]);
    double lat = atof(argv[3]);
    double lon = atof(argv[4]);
    auto res = appGetLocationCiphertexts(argv[2], lat, lon);
    std::cout << res.sumOfSquares << std::endl;
    std::cout << res.twoX << std::endl;
    std::cout << res.twoY << std::endl;
  }
  else if (option == "getDistanceResult")
  {
    if (argc < 10)
      return 1;
    double lat = atof(argv[4]);
    double lon = atof(argv[5]);
    int r2 = atoi(argv[6]);
    auto dr = appGetDistanceResult(
        argv[2],
        argv[3],
        lat,
        lon,
        r2,
        argv[7],
        argv[8],
        argv[9]);
    std::cout << dr.d2PlusK << std::endl;
    std::cout << dr.k << std::endl;
    delete[] dr.d2PlusK;
    delete[] dr.k;
  }

  return 0;
}

int main(int argc, char *argv[])
{
  return cmd(argc, argv);
  // return test();
}