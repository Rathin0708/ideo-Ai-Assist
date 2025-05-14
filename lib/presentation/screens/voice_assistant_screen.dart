import 'package:flutter/material.dart';
import '../widgets/voice_button.dart';
import '../widgets/response_display.dart';
import '../state/voice_assistant_state.dart';
import 'package:provider/provider.dart';
import '../../core/services/history_service.dart';
import '../widgets/bill_display.dart';
import '../widgets/transaction_confirmation_dialog.dart';
import 'transaction_history_screen.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<VoiceAssistantState>(context);

    // Show confirmation dialog when needed
    if (state.showConfirmation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => const TransactionConfirmationDialog(),
        ).then((_) {
          // Ensure the state is updated if the dialog is dismissed by back button or tapping outside
          if (state.showConfirmation) {
            state.hideConfirmationDialog();
          }
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Multilingual Voice Assistant'),
        centerTitle: true,
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () {
              _showHistoryDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Transaction History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TransactionHistoryScreen()),
              );
            },
          ),
          _buildLanguageMenu(context),
          _buildBillToggle(context),
          Consumer<VoiceAssistantState>(
            builder: (context, state, _) {
              // If we're in Tamil mode, offer a quick way to switch to English
              if (state.selectedLanguage.contains('ta')) {
                return IconButton(
                  icon: const Icon(Icons.translate),
                  tooltip: 'Switch to English',
                  onPressed: () {
                    state.setLanguage('en-US');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Switched to English for better recognition'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Expanded(
            child: ResponseDisplay(),
          ),
          if (state.isBillGenerationMode && state.generatedBill.isNotEmpty)
            const BillDisplay(),
        ],
      ),
      floatingActionButton: const VoiceButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showHistoryDialog(BuildContext context) {
    final state = Provider.of<VoiceAssistantState>(context, listen: false);
    final history = state.history;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('History'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: history.isEmpty
                ? const Center(child: Text('No history yet'))
                : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[history.length - 1 - index];
                return _buildHistoryItem(context, item);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryItem(BuildContext context, HistoryItem item) {
    final command = item.command;
    IconData icon;
    Color color;
    String typeText;

    if (command.action == 'generate_list') {
      icon = Icons.format_list_bulleted;
      color = Colors.green;
      typeText = 'List';
    } else if (command.action.contains('transaction') ||
        command.action.contains('income')) {
      icon = Icons.payments;
      color = Colors.blue;
      typeText = 'Transaction';
    } else if (command.action == 'app_query') {
      icon = Icons.help_outline;
      color = Colors.purple;
      typeText = 'Query';
    } else {
      icon = Icons.mic;
      color = Colors.grey;
      typeText = 'Voice';
    }

    String displayText = '';
    if (command.originalText != null && command.originalText!.isNotEmpty) {
      displayText = command.originalText!;
      if (displayText.length > 50) {
        displayText = '${displayText.substring(0, 47)}...';
      }
    }

    final formattedDate = '${item.timestamp.hour}:${item.timestamp.minute
        .toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(typeText),
        subtitle: Text(displayText),
        trailing: Text(formattedDate),
      ),
    );
  }

  Widget _buildLanguageMenu(BuildContext context) {
    final state = Provider.of<VoiceAssistantState>(context, listen: false);

    // Set Tamil as the default language when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!state.hasLanguageBeenSet) {
        state.setLanguage('ta-IN');
      }
    });

    return PopupMenuButton<String>(
      icon: const Icon(Icons.language),
      tooltip: 'Select Language',
      onSelected: (String langCode) {
        state.setLanguage(langCode);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Language changed'))
        );
      },
      itemBuilder: (context) =>
      [
        const PopupMenuItem<String>(
          value: 'ta-IN',
          child: Text('Tamil / தமிழ்'),
        ),
        const PopupMenuItem<String>(
          value: 'en-US',
          child: Text('English / ஆங்கிலம்'),
        ),
        const PopupMenuItem<String>(
          value: 'hi-IN',
          child: Text('Hindi / இந்தி'),
        ),
        const PopupMenuItem<String>(
          value: 'te-IN',
          child: Text('Telugu / தெலுங்கு'),
        ),
      ],
    );
  }

  Widget _buildBillToggle(BuildContext context) {
    final state = Provider.of<VoiceAssistantState>(context);
    final isBillMode = state.isBillGenerationMode;

    return IconButton(
      icon: Icon(isBillMode ? Icons.receipt : Icons.receipt_outlined),
      tooltip: isBillMode
          ? 'Disable Bill Generation'
          : 'Enable Bill Generation',
      onPressed: () {
        state.toggleBillGenerationMode();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isBillMode
                ? 'Bill generation disabled'
                : 'Bill generation enabled'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}