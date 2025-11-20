import 'dart:convert';

class NlpIntent {
  final String type;
  final Map<String, dynamic> data;
  NlpIntent(this.type, {this.data = const {}});
}

class NlpService {
  final bool moderation = const bool.fromEnvironment('AI_MODERATION', defaultValue: false);
  final List<int> _calls = [];
  Future<void> init() async {}

  Future<NlpIntent> predict(String text) async {
    if (moderation) {
      final now = DateTime.now().millisecondsSinceEpoch;
      _calls.removeWhere((t) => now - t > 2000);
      _calls.add(now);
      if (_calls.length > 12) return NlpIntent('unknown');
    }
    final t = text.toLowerCase();
    if (t.contains('añadir') || t.contains('agregar')) return NlpIntent('add_to_cart');
    if (t.contains('buscar') || t.contains('encuentra')) return NlpIntent('search');
    if (t.contains('pagar') || t.contains('checkout')) return NlpIntent('checkout');
    return NlpIntent('unknown');
  }

  List<int> _tokenize(String t) {
    final words = t.split(RegExp(r"\s+"));
    return words.map((w) => (utf8.encode(w).fold<int>(0, (a, b) => a + b)) % 1000).toList();
  }

  int _argMax(List<double> v) {
    var m = v[0];
    var mi = 0;
    for (var i = 1; i < v.length; i++) {
      if (v[i] > m) { m = v[i]; mi = i; }
    }
    return mi;
  }
}
