class ChordInfo {
  final String root;
  final String quality;
  final double timestamp;
  final double duration;
  final double confidence;
  
  ChordInfo({
    required this.root,
    required this.quality,
    required this.timestamp,
    required this.duration,
    required this.confidence,
  });
  
  String get displayName {
    if (quality == 'major') return root;
    if (quality == 'minor') return 'm';
    if (quality == 'dominant7') return '7';
    if (quality == 'major7') return 'maj7';
    if (quality == 'minor7') return 'm7';
    if (quality == 'diminished') return 'dim';
    if (quality == 'augmented') return 'aug';
    if (quality == 'sus2') return 'sus2';
    if (quality == 'sus4') return 'sus4';
    return '';
  }
  
  @override
  String toString() => ' @s (%)';
}

class ChordProgression {
  final List<ChordInfo> chords;
  final double totalDuration;
  
  ChordProgression({
    required this.chords,
    required this.totalDuration,
  });
  
  String toPlainText() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('Professional Chord Finder - Chord Sheet\n');
    buffer.writeln('Total Duration: s');
    buffer.writeln('Chords Detected: \n');
    buffer.writeln('Time    Chord   Confidence');
    buffer.writeln('─' * 35);
    
    for (var chord in chords) {
      String time = chord.timestamp.toStringAsFixed(1).padRight(7);
      String name = chord.displayName.padRight(7);
      String conf = '%';
      buffer.writeln('  ');
    }
    
    return buffer.toString();
  }
}
