import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/voice_command.dart';
import '../state/voice_assistant_state.dart';
import 'package:intl/intl.dart';

class TransactionConfirmationDialog extends StatelessWidget {
  const TransactionConfirmationDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<VoiceAssistantState>(context);
    final transaction = state.pendingTransaction;

    if (transaction == null || !state.showConfirmation) {
      return const SizedBox.shrink();
    }

    final isExpense = transaction.action == 'add_transaction';
    final String formattedAmount = _formatAmount(transaction.amount ?? 0);
    final String categoryName = _getCategoryDisplayName(
        transaction.category ?? 'Misc');

    return AlertDialog(
      backgroundColor: isExpense ? Colors.red.shade50 : Colors.green.shade50,
      title: Column(
        children: [
          Text(
            isExpense ? 'Confirm Expense' : 'Confirm Income',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            isExpense
                ? 'செலவை உறுதிப்படுத்தவும்'
                : 'வருமானத்தை உறுதிப்படுத்தவும்',
            style: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isExpense ? Colors.red.shade200 : Colors.green.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '₹$formattedAmount',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isExpense ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  categoryName,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            'Amount / தொகை:',
            '₹$formattedAmount',
            Icons.currency_rupee,
            Colors.green,
          ),
          _buildInfoRow(
            context,
            'Category / வகை:',
            categoryName,
            Icons.category,
            Colors.blue,
          ),
          _buildInfoRow(
            context,
            'Date / தேதி:',
            _formatDate(transaction.date),
            Icons.calendar_today,
            Colors.orange,
          ),
          _buildInfoRow(
            context,
            'Type / வகை:',
            isExpense ? 'Expense / செலவு' : 'Income / வருமானம்',
            isExpense ? Icons.shopping_cart : Icons.account_balance_wallet,
            isExpense ? Colors.red : Colors.green,
          ),
          if (transaction.originalText != null &&
              transaction.originalText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                '"${transaction.originalText}"',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            state.cancelTransaction();
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction canceled'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: const Text('Cancel / ரத்து செய்'),
        ),
        ElevatedButton(
          onPressed: () {
            state.confirmTransaction();
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction added to history'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
          ),
          child: const Text(
            'Confirm / உறுதிசெய்',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value,
      IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return DateFormat('yyyy-MM-dd').format(DateTime.now());
    }

    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return dateStr;
    }
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
      'misc': 'Miscellaneous / பல்வகை',
    };

    return displayNames[category.toLowerCase()] ??
        category.substring(0, 1).toUpperCase() + category.substring(1);
  }
}