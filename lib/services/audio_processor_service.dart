import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chord.dart';

class AudioProcessorService {
  static Future<ChordProgression> analyzeAudioFile(String filePath) async {
    print('[AudioProcessor] Starting ACCURATE analysis of: $filePath');
    
    // Get file info
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final fileSize = await file.length();
    print('[AudioProcessor] File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

    // Upload to ChordMini API for professional chord detection
    print('[AudioProcessor] Uploading to professional chord detection API...');
    
    var uri = Uri.parse('https://chordmini-backend-191567167632.us-central1.run.app/api/recognize-chords');
    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    
    try {
      print('[AudioProcessor] Sending request...');
      var response = await request.send().timeout(Duration(seconds: 120));
      print('[AudioProcessor] API Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final jsonResp = jsonDecode(respStr);
        
        print('[AudioProcessor] Parsing response...');
        List<ChordInfo> chords = [];
        
        if (jsonResp['result'] != null && jsonResp['result'] is List) {
          final results = jsonResp['result'] as List;
          print('[AudioProcessor] Found ${results.length} chord frames');
          
          // Calculate duration from number of frames (each frame is ~0.1 seconds typically)
          double frameDuration = 0.1; // Approximate, API specific
          double totalDuration = results.length * frameDuration;
          
          for (var i = 0; i < results.length; i++) {
            var chordData = results[i];
            String label = chordData['label']?.toString() ?? 'N';
            
            if (label == 'N' || label.isEmpty) continue; // Skip "no chord"
            
            // Parse chord label
            String root = _extractRoot(label);
            String quality = _extractQuality(label);
            
            double timestamp = i * frameDuration;
            
            chords.add(ChordInfo(
              root: root,
              quality: quality,
              timestamp: timestamp,
              duration: frameDuration,
              confidence: 0.95, // ChordMini API is highly accurate
            ));
          }
          
          // Merge consecutive identical chords
          chords = _mergeConsecutiveChords(chords);
          
          print('[AudioProcessor] Detected ${chords.length} unique chords');
          
          return ChordProgression(
            chords: chords,
            totalDuration: totalDuration,
          );
        } else {
          throw Exception('Invalid API response format');
        }
      } else {
        final errorBody = await response.stream.bytesToString();
        print('[AudioProcessor] Error response: $errorBody');
        throw Exception('API returned status ${response.statusCode}');
      }
    } catch (e) {
      print('[AudioProcessor] Error: $e');
      throw Exception('Failed to analyze audio: $e');
    }
  }
  
  static List<ChordInfo> _mergeConsecutiveChords(List<ChordInfo> chords) {
    if (chords.isEmpty) return [];
    
    List<ChordInfo> merged = [];
    ChordInfo current = chords[0];
    
    for (int i = 1; i < chords.length; i++) {
      if (chords[i].root == current.root && chords[i].quality == current.quality) {
        // Same chord, extend duration
        current = ChordInfo(
          root: current.root,
          quality: current.quality,
          timestamp: current.timestamp,
          duration: current.duration + chords[i].duration,
          confidence: (current.confidence + chords[i].confidence) / 2,
        );
      } else {
        // Different chord, save current and start new
        merged.add(current);
        current = chords[i];
      }
    }
    merged.add(current); // Add last chord
    
    return merged;
  }
  
  static String _extractRoot(String label) {
    if (label.isEmpty) return 'C';
    
    String root = label[0].toUpperCase();
    if (label.length >= 2 && (label[1] == '#' || label[1] == 'b')) {
      root += label[1];
    }
    return root;
  }
  
  static String _extractQuality(String label) {
    String lower = label.toLowerCase();
    
    // More comprehensive chord quality detection
    if (lower.contains('maj9')) return 'major9';
    if (lower.contains('maj7')) return 'major7';
    if (lower.contains('maj')) return 'major';
    if (lower.contains('min9')) return 'minor9';
    if (lower.contains('min7') || lower.contains('m7')) return 'minor7';
    if (lower.contains('min') || lower.contains('m')) return 'minor';
    if (lower.contains('dom7') || lower.contains('7')) return 'dominant7';
    if (lower.contains('dim7')) return 'diminished7';
    if (lower.contains('dim')) return 'diminished';
    if (lower.contains('aug')) return 'augmented';
    if (lower.contains('sus4')) return 'sus4';
    if (lower.contains('sus2')) return 'sus2';
    if (lower.contains('add9')) return 'add9';
    if (lower.contains('6')) return 'major6';
    
    return 'major';
  }
}
