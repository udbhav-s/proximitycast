#include "coords.h"
#include "UTM/UTM.h"

std::tuple<double, double> getUTM(double lat, double lon) {
  double x, y;
  LatLonToUTMXY(lat, lon, 16, x, y);
  return std::make_tuple(x, y);
}