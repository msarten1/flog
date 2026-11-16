import 'dart:convert';

import 'package:http/http.dart' as http;

/// Jugador tal como lo devuelve el buscador público de hándicap de la RFEG.
class JugadorRfeg {
  const JugadorRfeg({
    required this.nombre,
    required this.licencia,
    required this.club,
    required this.federacion,
    this.handicap,
    this.actualizado,
    this.profesional = false,
  });

  final String nombre;
  final String licencia;
  final String club;
  final String federacion;
  final double? handicap;
  final String? actualizado; // AAAA-MM-DD si la RFEG lo informa
  final bool profesional;

  factory JugadorRfeg.fromDocument(Map<String, dynamic> d) {
    final hcpRaw = (d['handicap'] ?? '').toString().replaceAll(',', '.');
    final hcp = double.tryParse(hcpRaw);
    final fecha = (d['date_hdc_updated_at'] ?? '').toString();
    return JugadorRfeg(
      nombre: _titulo((d['full_name'] ?? '').toString()),
      licencia: (d['guid_licence'] ?? '').toString(),
      club: _titulo((d['club_title'] ?? '').toString()),
      federacion: _titulo((d['federation_title'] ?? '').toString()),
      handicap: hcp == null || hcp >= 99 ? null : hcp,
      actualizado: fecha.length >= 10 ? fecha.substring(0, 10) : null,
      profesional: d['is_professional'] == 1 || d['is_professional'] == true,
    );
  }

  static String _titulo(String s) {
    const minus = {'de', 'del', 'la', 'las', 'el', 'los', 'y', 'e'};
    return s
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => minus.contains(w) ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

/// Consulta pública de hándicap de la RFEG (https://rfegolf.es/consulta-handicap).
/// La propia RFEG indica que hándicaps y resultados son públicos.
class RfegService {
  RfegService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _endpoint = 'https://rfegolf.es/wp-json/handicap-search/v1/search';

  /// Busca por número de licencia o por nombre (mínimo 5 caracteres, como en la web).
  Future<List<JugadorRfeg>> buscar(String consulta, {int max = 8}) async {
    final q = consulta.trim();
    if (q.length < 5) return const [];
    final uri = Uri.parse('$_endpoint?q=${Uri.encodeQueryComponent(q)}&size=$max');
    final r = await _client.get(uri, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) {
      throw Exception('RFEG respondió ${r.statusCode}');
    }
    final body = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final hits = ((body['data'] as Map<String, dynamic>?)?['hits'] as List?) ?? const [];
    return hits
        .map((h) => JugadorRfeg.fromDocument((h as Map<String, dynamic>)['document'] as Map<String, dynamic>))
        .toList();
  }
}
