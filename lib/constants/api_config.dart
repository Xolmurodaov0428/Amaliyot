class ApiConfig {
  static const String baseUrl = 'https://shaxa.mycoder.uz/api/student';

  static Uri uri(String path, [Map<String, String>? params]) {
    final clean = path.startsWith('/') ? path.substring(1) : path;
    final u = Uri.parse('$baseUrl/$clean');
    return params != null ? u.replace(queryParameters: params) : u;
  }
}
