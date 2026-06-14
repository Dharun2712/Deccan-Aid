import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecognitionService {
  static final VoiceRecognitionService _instance = VoiceRecognitionService._internal();
  factory VoiceRecognitionService() => _instance;
  VoiceRecognitionService._internal();

  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  bool _isListening = false;

  // Multi-language support
  static const Map<String, String> supportedLanguages = {
    'en': 'en_IN',  // English (India)
    'ta': 'ta_IN',  // Tamil
    'hi': 'hi_IN',  // Hindi
    'kn': 'kn_IN',  // Kannada
    'ml': 'ml_IN',  // Malayalam
    'te': 'te_IN',  // Telugu
  };

  String? _selectedLanguageCode;

  void setLanguage(String? langCode) {
    _selectedLanguageCode = langCode;
  }

  String? get selectedLanguageCode => _selectedLanguageCode;

  String? get _currentLocaleId {
    if (_selectedLanguageCode == null) return null;
    return supportedLanguages[_selectedLanguageCode];
  }
  
  // Emergency keywords - multilingual
  final List<String> _emergencyKeywords = [
    // English
    'emergency', 'help', 'help me', 'ambulance', 'hospital', 'accident',
    'injured', 'hurt', 'save me', 'danger', 'sos',
    'i need help', 'somebody help', 'please help',
    'call ambulance', 'call police', 'send ambulance',
    'medical emergency', 'i\'m hurt', 'i\'m injured',
    'i\'m in danger', 'i fell down', 'i need assistance',
    // Tamil (native)
    'உதவி', 'உதவி செய்யுங்கள்', 'விபத்து', 'ஆம்புலன்ஸ்', 'அவசரம்',
    'காயம்', 'காப்பாத்துங்க', 'காப்பாற்றுங்க', 'காப்பாற்றுங்கள்',
    'என்னை காப்பாத்துங்க', 'என்னை காப்பாற்றுங்கள்',
    'காப்பாத்துங்க ஐயா', 'எனக்கு உதவி வேண்டும்', 'ஆபத்து',
    'ஆம்புலன்ஸ் அழைக்கவும்', 'போலீஸ் அழைக்கவும்',
    'நான் காயம் அடைந்தேன்', 'நான் விழுந்துவிட்டேன்',
    'தயவு செய்து உதவி செய்யுங்கள்',
    // Tamil (phonetic)
    'udhavi', 'udavi', 'udhavi pannunga',
    'kaapathunga', 'kapathunga', 'kaapatrunga',
    'ennaai kaapathunga', 'ambulance azhaikkavum', 'vibathu',
    // Hindi
    'मदद', 'मेरी मदद करो', 'दुर्घटना', 'एम्बुलेंस', 'आपातकाल',
    'घायल', 'बचाओ', 'एम्बुलेंस बुलाओ', 'पुलिस बुलाओ',
    'मुझे चोट लगी है', 'कृपया मदद करें', 'खतरा',
    'मेरी जान बचाओ', 'जल्दी मदद करो',
    // Kannada
    'ಸಹಾಯ', 'ಸಹಾಯ ಮಾಡಿ', 'ಅಪಘಾತ', 'ಆಂಬುಲೆನ್ಸ್', 'ತುರ್ತು',
    'ಗಾಯ', 'ರಕ್ಷಿಸಿ', 'ಅಪಾಯ', 'ತುರ್ತು ಪರಿಸ್ಥಿತಿ',
    'ಆಂಬುಲೆನ್ಸ್ ಕರೆ ಮಾಡಿ', 'ಪೋಲೀಸ್ ಕರೆ ಮಾಡಿ',
    'ನನಗೆ ಗಾಯವಾಗಿದೆ', 'ದಯವಿಟ್ಟು ಸಹಾಯ ಮಾಡಿ',
    // Malayalam
    'സഹായം', 'സഹായിക്കൂ', 'അപകടം', 'ആംബുലൻസ്', 'അടിയന്തരം',
    'പരിക്ക്', 'രക്ഷിക്കൂ', 'ആംബുലൻസ് വിളിക്കൂ', 'പൊലീസ് വിളിക്കൂ',
    'എനിക്ക് പരിക്ക് പറ്റി', 'ദയവായി സഹായിക്കൂ', 'അടിയന്തിരം',
    // Telugu
    'సహాయం', 'సహాయం చేయండి', 'ప్రమాదం', 'ఆంబులెన్స్', 'అత్యవసరం',
    'గాయం', 'రక్షించండి', 'అంబులెన్స్ పిలవండి', 'పోలీస్ పిలవండి',
    'నాకు గాయం అయ్యింది', 'దయచేసి సహాయం చేయండి',
  ];

  Future<bool> initialize() async {
    if (_initialized) return true;

    // Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      print('[Voice] Microphone permission denied');
      return false;
    }

    _initialized = await _speech.initialize(
      onStatus: (status) => print('[Voice] Status: $status'),
      onError: (error) => print('[Voice] Error: $error'),
    );

    return _initialized;
  }

  Future<void> startListening({
    required Function() onEmergencyDetected,
    required Function(String) onResult,
  }) async {
    if (!_initialized) {
      final success = await initialize();
      if (!success) return;
    }

    if (_isListening) return;

    _isListening = true;
    await _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords.toLowerCase();
        print('[Voice] Recognized: $words');
        
        onResult(words);
        
        // Check for emergency keywords
        for (final keyword in _emergencyKeywords) {
          if (words.contains(keyword)) {
            print('[Voice] 🚨 Emergency keyword detected: $keyword');
            stopListening();
            onEmergencyDetected();
            break;
          }
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      cancelOnError: false,
      listenMode: ListenMode.confirmation,
      localeId: _currentLocaleId,
    );
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    await _speech.stop();
    _isListening = false;
  }

  bool get isListening => _isListening;
  bool get isAvailable => _initialized;

  void dispose() {
    stopListening();
  }
}
