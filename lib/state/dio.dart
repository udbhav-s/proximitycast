import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const apiUrl = "http://10.0.2.2:3000";

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: apiUrl
  ));
  final cookieJar = CookieJar();
  final cookieManager = CookieManager(cookieJar);
  dio.interceptors.add(cookieManager);
  return dio;
});
