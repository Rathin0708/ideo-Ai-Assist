import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/voice_assistant_state.dart';
import '../../core/services/history_service.dart';
import '../../domain/entities/voice_command.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<VoiceAssistantState>(context);
    final history = state.history.where(_isTransactionCommand).toList();

    // Sort transactions by date/time (newest first)
    history.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Log history for debugging
    debugPrint('Transaction history count: ${history.length}');
    for (var i = 0; i < history.length; i++) {
      debugPrint(
          'Transaction $i: ${history[i].command.action}, amount: ${history[i]
              .command.amount}, category: ${history[i].command.category}');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        actions: [
          // Add a refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Force a rebuild to refresh the history
              setState(() {});
            },
          ),
        ],
      ),
      body: history.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Your transactions will appear here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          // No need for reverse order now since we sorted the list
          final item = history[index];
          return _buildTransactionCard(context, item);
        },
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, HistoryItem item) {
    final command = item.command;
    final isExpense = command.action == 'add_transaction';

    final amount = _formatAmount(command.amount ?? 0);
    final category = command.category ?? 'Uncategorized';
    final date = _formatDate(command.date);
    final formattedTime = DateFormat('hh:mm a').format(item.timestamp);
    final formattedDate = DateFormat('dd MMM yyyy').format(item.timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isExpense ? Colors.red.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isExpense ? Colors.red.withOpacity(0.2) : Colors
                        .green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isExpense ? Icons.shopping_cart : Icons
                        .account_balance_wallet,
                    color: isExpense ? Colors.red : Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getCategoryDisplayName(category),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        isExpense ? 'பணம் செலவு' : 'வருமானம்',
                        style: TextStyle(
                          color: isExpense ? Colors.red : Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹$amount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isExpense ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                        Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      formattedTime,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            if (command.originalText != null &&
                command.originalText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '"${command.originalText}"',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##,###');
    return formatter.format(amount);
  }

  String _getCategoryDisplayName(String category) {
    final displayNames = {
      'electronics': 'Electronics / மின்னணு',
      'food': 'Food & Dining / உணவு',
      'grocery': 'Groceries / மளிகை',
      'transport': 'Transportation / போக்குவரத்து',
      'shopping': 'Shopping / கடைகள்',
      'bills': 'Bills & Utilities / கட்டணங்கள்',
      'health': 'Healthcare / மருத்துவம்',
      'entertainment': 'Entertainment / பொழுதுபோக்கு',
    };

    return displayNames[category.toLowerCase()] ??
        category.substring(0, 1).toUpperCase() + category.substring(1);
  }

  bool _isTransactionCommand(HistoryItem item) {
    return item.command.action == 'add_transaction' ||
        item.command.action == 'add_income';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return DateFormat('dd MMM yyyy').format(DateTime.now());
    }

    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}