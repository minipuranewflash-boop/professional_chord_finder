import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_processor_service.dart';
import '../models/chord.dart';
import 'chord_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isProcessing = false;

  Future<void> _pickAndAnalyzeFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'flac', 'ogg', 'm4a'],
      );

      if (result != null) {
        String filePath = result.files.single.path!;
        String fileName = result.files.single.name;
        
        setState(() => _isProcessing = true);

        // Analyze audio
        try {
          ChordProgression progression = await AudioProcessorService.analyzeAudioFile(filePath);
          
          if (!mounted) return;
          setState(() => _isProcessing = false);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChordViewerScreen(
                filePath: filePath,
                fileName: fileName,
                progression: progression,
              ),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Analysis failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0F1A),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Title
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Color(0xFF00D4FF), Color(0xFFBB86FC), Color(0xFF00FFA3)],
                    ).createShader(bounds),
                    child: Text(
                      'Professional\nChord Finder',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  Text(
                    'AI-Powered Chord Detection',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  
                  SizedBox(height: 60),
                  
                  // Glassmorphism card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.audio_file_rounded,
                              size: 80,
                              color: Color(0xFF00D4FF),
                            ),
                            
                            SizedBox(height: 24),
                            
                            Text(
                              'Upload Your Song',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            
                            SizedBox(height: 12),
                            
                            Text(
                              'Supports MP3, WAV, FLAC, OGG',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white60,
                              ),
                            ),
                            
                            SizedBox(height: 32),
                            
                            _isProcessing
                                ? Column(
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor: AlwaysStoppedAnimation(Color(0xFF00D4FF)),
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Analyzing audio...',
                                        style: GoogleFonts.inter(color: Colors.white70),
                                      ),
                                    ],
                                  )
                                : ElevatedButton.icon(
                                    onPressed: _pickAndAnalyzeFile,
                                    icon: Icon(Icons.upload_file, size: 24),
                                    label: Text('Select Audio File'),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 60),
                  
                  // Features
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeature(Icons.speed, 'Fast\nAnalysis'),
                      _buildFeature(Icons.verified, 'Accurate\nResults'),
                      _buildFeature(Icons.music_note, '60+ Chord\nTypes'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Icon(icon, color: Color(0xFF00D4FF), size: 32),
        ),
        SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white70,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
