import 'package:flutter/material.dart';
import '../widgets/voice_button.dart';
import '../widgets/response_display.dart';
import '../state/voice_assistant_state.dart';
import 'package:provider/provider.dart';
import '../../core/services/history_service.dart';
import '../widgets/bill_display.dart';
import '../widgets/transaction_confirmation_dialog.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/voice_command.dart';
import '../../domain/usecases/listen_for_voice_input.dart';
import '../../domain/usecases/process_voice_command.dart';
import '../../domain/usecases/speak_response.dart';
import '../../core/services/history_service.dart';
import '../../core/injection/injection_container.dart';
import '../../data/datasources/ai_data_source.dart';
import '../../data/datasources/speech_data_source.dart';
import '../../data/models/voice_command_model.dart';

enum CommandMode { transaction, appQuery, listGeneration }

class VoiceAssistantState extends ChangeNotifier {
  final ListenForVoiceInput _listenForVoiceInput;
  final ProcessVoiceCommand _processVoiceCommand;
  final SpeakResponse _speakResponse;
  final HistoryService _historyService;
  final AIDataSource _aiDataSource;

  bool _isListening = false;
  String _recognizedText = '';
  String _originalText = '';
  String _translatedText = '';
  String _partialText = '';
  String _speechLanguage = '';
  VoiceCommand? _command;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isProcessing = false;
  String _responseMessage = '';
  String _selectedLanguage = 'ta-IN'; // Default to Tamil
  CommandMode _commandMode = CommandMode.transaction;
  List<String> _generatedItems = [];
  bool _isAccuracyMode = true;
  bool _isBillGenerationMode = false;
  Map<String, dynamic> _generatedBill = {};
  VoiceCommand? _pendingTransaction;
  bool _showConfirmation = false;
  bool _hasLanguageBeenSet = true; // Set to true since we're defaulting to Tamil

  VoiceAssistantState({
    required ListenForVoiceInput listenForVoiceInput,
    required ProcessVoiceCommand processVoiceCommand,
    required SpeakResponse speakResponse,
  })
      : _listenForVoiceInput = listenForVoiceInput,
        _processVoiceCommand = processVoiceCommand,
        _speakResponse = speakResponse,
        _historyService = serviceLocator.get<HistoryService>(),
        _aiDataSource = serviceLocator.get<AIDataSource>();

  bool get isListening => _isListening;

  String get recognizedText => _recognizedText;

  String get originalText => _originalText;

  String get translatedText => _translatedText;

  String get partialText => _partialText;

  String get speechLanguage => _speechLanguage;

  VoiceCommand? get command => _command;

  bool get isLoading => _isLoading;

  String get errorMessage => _errorMessage;

  bool get isProcessing => _isProcessing;

  String get responseMessage => _responseMessage;

  String get selectedLanguage => _selectedLanguage;

  CommandMode get commandMode => _commandMode;

  List<String> get generatedItems => _generatedItems;

  bool get isAccuracyMode => _isAccuracyMode;

  bool get isBillGenerationMode => _isBillGenerationMode;

  Map<String, dynamic> get generatedBill => _generatedBill;

  List<HistoryItem> get history => _historyService.history;

  List<HistoryItem> get translationHistory =>
      _historyService.getTranslationHistory();

  List<HistoryItem> get listHistory => _historyService.getListHistory();

  bool get hasLanguageBeenSet => _hasLanguageBeenSet;

  VoiceCommand? get pendingTransaction => _pendingTransaction;

  bool get showConfirmation => _showConfirmation;

  String get currentPlaceholder {
    return 'Speak now...';
  }

  void setLanguage(String languageCode) {
    _selectedLanguage = languageCode;
    _hasLanguageBeenSet = true;
    debugPrint('Language set to: $languageCode');
    notifyListeners();
  }

  void toggleCommandMode() {
    if (_commandMode == CommandMode.transaction) {
      _commandMode = CommandMode.appQuery;
    } else if (_commandMode == CommandMode.appQuery) {
      _commandMode = CommandMode.listGeneration;
    } else {
      _commandMode = CommandMode.transaction;
    }
    notifyListeners();
  }

  void setCommandMode(CommandMode mode) {
    _commandMode = mode;
    notifyListeners();
  }

  void toggleAccuracyMode() {
    _isAccuracyMode = !_isAccuracyMode;
    notifyListeners();
  }

  void toggleBillGenerationMode() {
    _isBillGenerationMode = !_isBillGenerationMode;
    notifyListeners();
  }

  void confirmTransaction() {
    if (_pendingTransaction != null) {
      _historyService.addToHistory(_pendingTransaction!);
      debugPrint(
          'Transaction confirmed and added to history: ${_pendingTransaction!
              .action}, amount: ${_pendingTransaction!.amount}');

      final wasExpense = _pendingTransaction!.action == 'add_transaction';
      final amount = _pendingTransaction!.amount;
      final category = _pendingTransaction!.category;

      _pendingTransaction = null;
      _showConfirmation = false;

      if (wasExpense) {
        _responseMessage =
        "Expense of ₹$amount for $category added successfully";
      } else {
        _responseMessage =
        "Income of ₹$amount from $category added successfully";
      }

      _speakResponseAfterConfirmation();

      notifyListeners();
    }
  }

  void cancelTransaction() {
    _pendingTransaction = null;
    _showConfirmation = false;
    _responseMessage = "Transaction canceled";
    debugPrint('Transaction was canceled by user');
    _isProcessing = false;
    notifyListeners();
    _speakCancellationFeedback();
  }

  void hideConfirmationDialog() {
    _showConfirmation = false;
    debugPrint('Confirmation dialog hidden');
    // Reset any pending transaction
    if (_pendingTransaction != null) {
      debugPrint(
          'Found a pending transaction when hiding dialog - cancelling it');
      _pendingTransaction = null;
      _isProcessing = false;
    }
    notifyListeners();
  }

  Future<void> startListening() async {
    if (_isProcessing) return;

    final speechLocale = _selectedLanguage.isNotEmpty
        ? _selectedLanguage
        : 'ta-IN';
    debugPrint('Starting speech recognition with locale: $speechLocale');

    _isListening = true;
    _recognizedText = '';
    _partialText = '';
    _speechLanguage = '';
    _originalText = '';
    _translatedText = '';
    _command = null;
    _errorMessage = '';
    _responseMessage = '';
    _generatedItems = [];
    notifyListeners();

    try {
      final speechSource = serviceLocator.get<SpeechDataSource>();
      speechSource.textStream.listen((text) {
        if (text.startsWith('partial:')) {
          final parts = text.substring(8).split(':');
          if (parts.length > 1) {
            _speechLanguage = parts[0];
            _partialText = parts[1];
          } else {
            _partialText = text.substring(8);
          }
          notifyListeners();
        } else {
          final parts = text.split(':');
          if (parts.length > 1) {
            _speechLanguage = parts[0];
            _recognizedText = parts[1];
          } else {
            _recognizedText = text;
          }
          _partialText = '';
          notifyListeners();
        }
      });

      await _listenForVoiceInput.execute(languageCode: speechLocale);
      debugPrint('Successfully started listening');
    } catch (e) {
      _errorMessage = 'Failed to start listening: $e';
      _isListening = false;
      notifyListeners();
      debugPrint('Error starting listening: $e');
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    debugPrint('Stopping listening...');
    _isListening = false;
    notifyListeners();

    // Process the last recognized text even if it's partial
    if (_recognizedText.isEmpty && _partialText.isNotEmpty) {
      debugPrint('Using partial text as final: $_partialText');
      _recognizedText = _partialText;
      _originalText = _partialText;
    }

    // Check for Chinese characters appearing incorrectly instead of Tamil
    if (_containsChineseCharacters(_recognizedText)) {
      debugPrint(
          'Chinese characters detected, likely a device speech recognition issue');
      _recognizedText = '';
      _originalText = '';
      _isProcessing = false;
      _responseMessage =
      "Speech recognition isn't working properly for Tamil. Please try using English.";
      notifyListeners();
      await _speakResponse.execute(_responseMessage);
      return;
    }

    try {
      _isProcessing = true;
      _responseMessage = "Processing your request...";
      notifyListeners();

      final recognizedText = await _listenForVoiceInput.execute();
      if (recognizedText.startsWith('partial:')) {
        debugPrint('Using last recognized text: $_recognizedText');
        if (_recognizedText.isEmpty) {
          _isProcessing = false;
          _responseMessage = "I didn't catch that. Please try speaking again.";
          notifyListeners();
          await _speakResponse.execute(_responseMessage);
          return;
        }
      } else if (recognizedText.contains(':')) {
        final parts = recognizedText.split(':');
        if (parts.length > 1) {
          _speechLanguage = parts[0];
          _recognizedText = parts[1];
          _originalText = parts[1];
        } else {
          _recognizedText = recognizedText;
          _originalText = recognizedText;
        }
      } else if (recognizedText.isNotEmpty) {
        _recognizedText = recognizedText;
        _originalText = recognizedText;
      }

      _partialText = '';
      notifyListeners();

      debugPrint('Recognized text after stopping: $_recognizedText');

      if (_recognizedText.isEmpty || _recognizedText
          .trim()
          .isEmpty) {
        _isProcessing = false;
        _responseMessage = "I didn't catch that. Please try speaking again.";
        notifyListeners();
        await _speakResponse.execute(_responseMessage);
        return;
      }

      // Check for Tamil transaction patterns directly before doing heavy AI processing
      if (_detectTamilTransaction(_recognizedText)) {
        debugPrint('Direct Tamil transaction pattern detected');
        final transaction = _localTransactionProcessing(_recognizedText, '');
        if (transaction != null) {
          _command = transaction;
          _pendingTransaction = _command;
          _showConfirmation = true;
          _responseMessage =
          "Please confirm this transaction: ${_generateConfirmationMessage(
              _command!)}";
          await _speakResponse.execute(_responseMessage);
          _isProcessing = false;
          notifyListeners();
          return;
        }
      }

      debugPrint('Final recognized text: $_recognizedText');

      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300));

      if (_isAccuracyMode && _recognizedText.isNotEmpty) {
        _responseMessage = "Improving transcription accuracy...";
        notifyListeners();

        try {
          final improvedText = await _aiDataSource.improveTranscriptionAccuracy(
              _recognizedText);
          if (improvedText.isNotEmpty) {
            _originalText = _recognizedText;
            _recognizedText = improvedText;
            debugPrint('Improved text: $_recognizedText');
          }
        } catch (e) {
          debugPrint('Error improving transcription: $e');
        }

        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      _responseMessage = "Detecting language...";
      notifyListeners();
      final detectedLanguageCode = await _aiDataSource.detectLanguage(
          _recognizedText);
      debugPrint('Detected language: $detectedLanguageCode');

      final languageName = _getLanguageName(detectedLanguageCode);
      _responseMessage = "Analysis Result: $languageName language detected";
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 500));

      if (detectedLanguageCode != 'en') {
        _responseMessage = "Translating from $languageName to English...";
        notifyListeners();
        _translatedText = await _aiDataSource.translateToEnglish(
            _recognizedText, detectedLanguageCode);
        debugPrint('Translated text: $_translatedText');
      } else {
        _translatedText = _recognizedText;
      }

      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 500));

      if (_isBillGenerationMode) {
        _responseMessage = "Generating bill from your input...";
        notifyListeners();

        try {
          _generatedBill =
          await _aiDataSource.generateBillFromText(_translatedText);
          debugPrint('Generated bill: $_generatedBill');

          final billCommand = VoiceCommandModel(
            action: 'generate_bill',
            query: _translatedText,
            originalText: _originalText,
            translatedText: _translatedText,
            language: detectedLanguageCode,
            status: "success",
            timestamp: DateTime.now().toIso8601String(),
          );

          _command = billCommand;
          _historyService.addToHistory(billCommand);

          String billTitle = _generatedBill['billTitle'] ?? 'Purchase Receipt';
          String total = _generatedBill['total']?.toString() ??
              'unknown amount';
          String currency = _generatedBill['currency'] ?? '₹';
          int itemCount = _generatedBill['items']?.length ?? 0;

          _responseMessage =
          "Generated $billTitle. Total: $currency $total for $itemCount item(s)";

          notifyListeners();
          await _speakResponse.execute(_responseMessage);
          return;
        } catch (e) {
          debugPrint('Error generating bill: $e');
          _responseMessage =
          "Sorry, I couldn't generate a bill from your input.";
          await _speakResponse.execute(_responseMessage);
          return;
        }
      }

      try {
        final input = await _processVoiceCommand.execute(
            _translatedText,
            commandMode: _getCommandModeString()
        );

        debugPrint('Input from AI: ${input.action}, amount: ${input
            .amount}, category: ${input.category}');

        if (input.action == 'error' || input.action == 'unknown') {
          debugPrint('AI processing failed, switching to local backup parsing');
          final result = _localTransactionProcessing(
              _originalText, _translatedText);
          if (result != null) {
            debugPrint(
                'Local processing successful: ${result.action}, amount: ${result
                    .amount}, category: ${result.category}');
            _command = result;

            _pendingTransaction = _command;
            _showConfirmation = true;
            _responseMessage =
            "Please confirm this transaction: ${_generateConfirmationMessage(
                _command!)}";
            await _speakResponse.execute(_responseMessage);
            return;
          }
        }

        var enhancedCommand = VoiceCommandModel(
          action: input.action,
          location: input.location,
          date: input.date,
          amount: input.amount,
          category: input.category,
          query: input.query,
          language: detectedLanguageCode,
          listDescription: input.listDescription,
          items: input.items,
          originalText: _originalText,
          translatedText: _translatedText,
        );

        _command = enhancedCommand;

        if (_command!.action == 'generate_list' ||
            _commandMode == CommandMode.listGeneration) {
          _responseMessage = "Generating list items...";
          notifyListeners();
          _generatedItems =
          await _aiDataSource.generateItemList(_translatedText);
          debugPrint('Generated items: $_generatedItems');

          enhancedCommand = VoiceCommandModel(
            action: 'generate_list',
            listDescription: _command!.listDescription ?? 'Generated List',
            items: _generatedItems,
            language: detectedLanguageCode,
            originalText: _originalText,
            translatedText: _translatedText,
            processedText: _recognizedText,
            status: "success",
            timestamp: DateTime.now().toIso8601String(),
          );

          _command = enhancedCommand;
        }

        if (_command != null && _command!.action != 'error' &&
            _command!.action != 'unknown') {
          if (_command!.action == 'add_transaction' ||
              _command!.action == 'add_income') {
            _pendingTransaction = _command;
            _showConfirmation = true;
            _responseMessage =
            "Please confirm this transaction: ${_generateConfirmationMessage(
                _command!)}";
            debugPrint('Showing confirmation for transaction: ${_command!
                .action}, amount: ${_command!.amount}, category: ${_command!
                .category}');
            await _speakResponse.execute(_responseMessage);
          } else {
            _historyService.addToHistory(_command!);
            _responseMessage = _generateConfirmationMessage(_command!);
            await _speakResponse.execute(_responseMessage);
          }
        } else {
          debugPrint(
              'Command not recognized as a valid action: ${_command?.action}');
          debugPrint('Original text: $_originalText');
          debugPrint('Translated text: $_translatedText');
          _responseMessage = "Sorry, I couldn't understand that request.";
          await _speakResponse.execute(_responseMessage);
        }
      } catch (e) {
        _errorMessage = 'Error processing voice command: $e';
        _responseMessage = "Sorry, there was an error processing your request.";
        debugPrint('Error in voice processing: $e');

        try {
          final result = _localTransactionProcessing(
              _originalText, _translatedText);
          if (result != null) {
            _command = result;
            _pendingTransaction = _command;
            _showConfirmation = true;
            _responseMessage =
            "Please confirm this transaction: ${_generateConfirmationMessage(
                _command!)}";
            await _speakResponse.execute(_responseMessage);
            _isProcessing = false;
            notifyListeners();
            return;
          }
        } catch (localError) {
          debugPrint('Local processing also failed: $localError');
        }

        await _speakResponse.execute(_responseMessage);
      } finally {
        _isProcessing = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error processing voice command: $e';
      _responseMessage = "Sorry, there was an error processing your request.";
      debugPrint('Error in voice processing: $e');
      await _speakResponse.execute(_responseMessage);
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void updateRecognizedText(String text) {
    _recognizedText = text;
    notifyListeners();
  }

  String _getCommandModeString() {
    switch (_commandMode) {
      case CommandMode.transaction:
        return 'transaction';
      case CommandMode.appQuery:
        return 'app_query';
      case CommandMode.listGeneration:
        return 'generate_list';
      default:
        return 'default';
    }
  }

  String _generateConfirmationMessage(VoiceCommand command) {
    final StringBuffer message = StringBuffer();

    switch (command.action) {
      case 'add_transaction':
        message.write("Added transaction");
        if (command.amount != null) {
          message.write(" of ₹${command.amount}");
        }
        if (command.category != null && command.category!.isNotEmpty) {
          message.write(" for ${command.category}");
        }
        if (command.date != null && command.date!.isNotEmpty) {
          message.write(" on ${command.date}");
        }
        break;

      case 'add_income':
        message.write("Added income");
        if (command.amount != null) {
          message.write(" of ₹${command.amount}");
        }
        if (command.category != null && command.category!.isNotEmpty) {
          message.write(" from ${command.category}");
        }
        if (command.date != null && command.date!.isNotEmpty) {
          message.write(" on ${command.date}");
        }
        break;

      case 'generate_list':
        message.write("Created list");
        if (command.listDescription != null &&
            command.listDescription!.isNotEmpty) {
          message.write(" for ${command.listDescription}");
        }
        if (command.items != null && command.items!.isNotEmpty) {
          message.write(" with ${command.items!.length} items");
        }
        break;

      case 'app_query':
        if (command.query != null && command.query!.isNotEmpty) {
          message.write("I'll help you with: ${command.query}");
        } else {
          message.write("I'll help you with your question");
        }
        break;

      default:
        message.write("I've processed your request");
    }

    return message.toString();
  }

  String _getLanguageName(String code) {
    final languageNames = {
      'en': 'English',
      'ta': 'Tamil',
      'te': 'Telugu',
      'ml': 'Malayalam',
      'hi': 'Hindi',
      'bn': 'Bengali',
      'kn': 'Kannada',
    };

    return languageNames[code] ?? code.toUpperCase();
  }

  VoiceCommandModel? _localTransactionProcessing(String originalText,
      String translatedText) {
    final text = translatedText.isNotEmpty ? translatedText : originalText;
    final lowerText = text.toLowerCase();

    // Check if this is Tamil text by detecting Tamil script characters
    final isTamilText = _containsTamilCharacters(text);
    debugPrint('Text contains Tamil characters: $isTamilText');

    // Check for Tamil transaction keywords
    final containsTamilTransactionWords =
        lowerText.contains('வாங்க') || // buy
            lowerText.contains('விலை') || // price
            lowerText.contains('ரூபாய்') || // rupees
            lowerText.contains('ரூ') || // Rs
            lowerText.contains('செலவு'); // expense

    // Check for Tamil numbers
    final hasTamilNumbers =
        lowerText.contains('ஒன்று') || // one
            lowerText.contains('இரண்டு') || // two
            lowerText.contains('மூன்று') || // three
            lowerText.contains('நான்கு') || // four
            lowerText.contains('ஐந்து') || // five
            lowerText.contains('ஆறு') || // six
            lowerText.contains('ஏழு') || // seven
            lowerText.contains('எட்டு') || // eight
            lowerText.contains('ஒன்பது') || // nine
            lowerText.contains('பத்து') || // ten
            lowerText.contains('ஐம்பது') || // fifty
            lowerText.contains('நூறு') || // hundred
            lowerText.contains('ஆயிரம்'); // thousand

    bool isTransaction = false;
    bool isIncome = false;

    // Determine if this is a transaction
    if (isTamilText) {
      debugPrint('Detected Tamil text based on character set');
      isTransaction = true;
    }
    else if (containsTamilTransactionWords) {
      debugPrint('Detected Tamil transaction words');
      isTransaction = true;
    }
    else if (
    lowerText.contains('buy') ||
        lowerText.contains('bought') ||
        lowerText.contains('purchase') ||
        lowerText.contains('spent') ||
        lowerText.contains('paid') ||
        lowerText.contains('price') ||
        lowerText.contains('rs') ||
        lowerText.contains('rupees') ||
        lowerText.contains('cost')
    ) {
      debugPrint('Detected English transaction words');
      isTransaction = true;
    }

    // Check if this is income
    if (lowerText.contains('earn') ||
        lowerText.contains('got') ||
        lowerText.contains('received') ||
        lowerText.contains('income') ||
        lowerText.contains('salary')) {
      isTransaction = true;
      isIncome = true;
    }

    if (!isTransaction) {
      return null;
    }

    // Extract amount from text
    double? amount;
    final numericMatches = RegExp(r'\b(\d+)\b').allMatches(text).toList();
    if (numericMatches.isNotEmpty) {
      int largestNum = 0;
      for (var match in numericMatches) {
        final num = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (num > largestNum) largestNum = num;
      }
      amount = largestNum.toDouble();
    } else if (hasTamilNumbers) {
      // If we have Tamil numbers but no digits, use default amount
      amount = 1000.0;
    }

    // Determine category
    String category = 'Misc';
    final categories = {
      'food': [
        'food',
        'lunch',
        'dinner',
        'breakfast',
        'meal',
        'restaurant',
        'eat',
        'உணவு',
        'சாப்பாடு'
      ],
      'grocery': [
        'grocery',
        'groceries',
        'supermarket',
        'market',
        'store',
        'மளிகை'
      ],
      'transport': ['transport', 'travel', 'bus', 'train', 'ticket', 'fare'],
      'shopping': ['shop', 'mall', 'clothes', 'dress', 'shirt', 'shoes'],
      'electronics': [
        'laptop',
        'phone',
        'computer',
        'mobile',
        'tv',
        'television',
        'மடிக்கணினி'
      ],
      'bills': ['bill', 'rent', 'electricity', 'water', 'gas', 'வாடகை'],
      'health': ['medicine', 'doctor', 'hospital', 'medical', 'health'],
      'entertainment': ['movie', 'cinema', 'theater', 'game', 'entertainment']
    };

    // Find matching category
    for (var entry in categories.entries) {
      for (var keyword in entry.value) {
        if (lowerText.contains(keyword)) {
          category = entry.key;
          break;
        }
      }
      if (category != 'Misc') break;
    }

    // Special case for laptop
    if (category == 'Misc') {
      if (lowerText.contains('laptop')) {
        category = 'electronics';
      } else if (lowerText.contains('மடிக்கணினி')) {
        category = 'electronics';
      }
    }

    return VoiceCommandModel(
      action: isIncome ? 'add_income' : 'add_transaction',
      amount: amount,
      category: category,
      originalText: originalText,
      translatedText: translatedText,
      status: 'success',
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  bool _detectTamilTransaction(String text) {
    final lowerText = text.toLowerCase();

    final hasTamilCurrency = lowerText.contains('ரூபாய்') ||
        lowerText.contains('ரூ');
    final hasTamilVerbs = lowerText.contains('வாங்க') ||
        lowerText.contains('விலை') ||
        lowerText.contains('செலவு');

    final hasTamilCategories = lowerText.contains('மளிகை') || // grocery
        lowerText.contains('உணவு') || // food
        lowerText.contains('சாப்பாடு') || // food
        lowerText.contains('மொபைல்') || // mobile
        lowerText.contains('கணினி') || // computer
        lowerText.contains('மடிக்கணினி'); // laptop

    final hasNumberWithCurrency = RegExp(r'\d+\s*ரூபாய்').hasMatch(lowerText) ||
        RegExp(r'\d+\s*ரூ').hasMatch(lowerText);

    // Also check if the text contains Tamil script characters
    final hasTamilScript = _containsTamilCharacters(text);

    return hasTamilScript ||
        hasNumberWithCurrency ||
        lowerText.contains('ரூபாய்') ||
        (hasTamilCurrency && (hasTamilVerbs || hasTamilCategories)) ||
        (lowerText.contains('₹') && (hasTamilVerbs || hasTamilCategories));
  }

  bool _containsTamilCharacters(String text) {
    final tamilRange = RegExp(r'[\u0B80-\u0BFF]');
    return tamilRange.hasMatch(text);
  }

  bool _containsChineseCharacters(String text) {
    // Unicode range for Chinese characters
    final chineseRange = RegExp(r'[\u4E00-\u9FFF]');
    return chineseRange.hasMatch(text);
  }

  void _speakResponseAfterConfirmation() async {
    try {
      await _speakResponse.execute(_responseMessage);
    } catch (e) {
      debugPrint('Error speaking confirmation: $e');
    }
  }

  void _speakCancellationFeedback() async {
    try {
      await _speakResponse.execute(_responseMessage);
    } catch (e) {
      debugPrint('Error speaking cancellation feedback: $e');
    }
  }
}