import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  final stt.SpeechToText _stt = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _tts.setLanguage('es-ES');
    await _tts.setSpeechRate(0.4);
    await _stt.initialize();
    _initialized = true;
  }

  Future<bool> startListening(Function(String text) onResult) async {
    if (!_initialized) await init();
    return await _stt.listen(onResult: (res) {
      final txt = res.recognizedWords.trim();
      if (txt.isNotEmpty) onResult(txt);
    }, localeId: 'es_ES');
  }

  Future<void> stopListening() async {
    await _stt.stop();
  }

  Future<void> speak(String text) async {
    if (!_initialized) await init();
    await _tts.speak(text);
  }
}
