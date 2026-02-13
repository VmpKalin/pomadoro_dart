import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static Uint8List? _cachedBeep;
  static String? _cachedFilePath;

  /// Generates a pleasant two-tone WAV notification sound in memory.
  static Uint8List _generateBeepWav() {
    if (_cachedBeep != null) return _cachedBeep!;

    const sampleRate = 44100;
    const bitsPerSample = 16;
    const channels = 1;

    // Two tones: 880 Hz (A5) then 1108 Hz (C#6) — major-third interval
    const tone1Freq = 880.0;
    const tone2Freq = 1108.0;
    const toneDuration = 0.18;
    const gapDuration = 0.10;
    const totalDuration = toneDuration + gapDuration + toneDuration;

    final numSamples = (sampleRate * totalDuration).toInt();
    final dataSize = numSamples * channels * (bitsPerSample ~/ 8);

    final buffer = ByteData(44 + dataSize);

    void writeStr(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        buffer.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    // WAV header
    writeStr(0, 'RIFF');
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    writeStr(8, 'WAVE');
    writeStr(12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, channels, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(
        28, sampleRate * channels * (bitsPerSample ~/ 8), Endian.little);
    buffer.setUint16(32, channels * (bitsPerSample ~/ 8), Endian.little);
    buffer.setUint16(34, bitsPerSample, Endian.little);
    writeStr(36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);

    // Audio data
    final tone1Samples = (sampleRate * toneDuration).toInt();
    final gapSamples = (sampleRate * gapDuration).toInt();

    for (int i = 0; i < numSamples; i++) {
      double sample = 0;
      final t = i / sampleRate;

      if (i < tone1Samples) {
        final env = _envelope(i, tone1Samples);
        sample = sin(2 * pi * tone1Freq * t) * env;
      } else if (i >= tone1Samples + gapSamples) {
        final j = i - tone1Samples - gapSamples;
        final tone2Len = numSamples - tone1Samples - gapSamples;
        final env = _envelope(j, tone2Len);
        sample = sin(2 * pi * tone2Freq * t) * env;
      }

      final pcm = (sample * 14000).toInt().clamp(-32768, 32767);
      buffer.setInt16(44 + i * 2, pcm, Endian.little);
    }

    _cachedBeep = buffer.buffer.asUint8List();
    return _cachedBeep!;
  }

  static double _envelope(int i, int total) {
    final fadeIn = (total * 0.08).toInt().clamp(1, total);
    final fadeOut = (total * 0.35).toInt().clamp(1, total);
    if (i < fadeIn) return i / fadeIn;
    if (i > total - fadeOut) return (total - i) / fadeOut;
    return 1.0;
  }

  /// Play the completion sound.
  static Future<void> playCompletion() async {
    try {
      if (_cachedFilePath == null || !File(_cachedFilePath!).existsSync()) {
        final bytes = _generateBeepWav();
        final file =
            File('${Directory.systemTemp.path}/pomodoro_complete.wav');
        await file.writeAsBytes(bytes, flush: true);
        _cachedFilePath = file.path;
      }
      await _player.stop();
      await _player.play(DeviceFileSource(_cachedFilePath!));
    } catch (_) {
      // Silently ignore audio errors
    }
  }
}
