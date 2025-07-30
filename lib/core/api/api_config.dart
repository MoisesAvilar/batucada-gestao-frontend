import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // O IP local do seu computador. Mude aqui se ele mudar.
  static const String _localIp = '192.168.3.6'; 

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000'; // Para web
    }
    // Para mobile (Android/iOS), usa o IP local
    return 'http://$_localIp:8000';
  }
}