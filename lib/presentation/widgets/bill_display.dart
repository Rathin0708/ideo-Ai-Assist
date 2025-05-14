import 'package:flutter/material.dart';
import '../state/voice_assistant_state.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class BillDisplay extends StatelessWidget {
  const BillDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<VoiceAssistantState>(context);
    final billData = state.generatedBill;

    if (billData.isEmpty) {
      return const SizedBox.shrink();
    }

    final billTitle = billData['billTitle'] ?? 'Purchase Receipt';
    final date = billData['date'] != null
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(billData['date']))
        : DateFormat('MMM dd, yyyy').format(DateTime.now());
    final store = billData['store'] ?? 'Store';
    final currency = billData['currency'] ?? '₹';
    final items = billData['items'] as List<dynamic>? ?? [];
    final subtotal = billData['subtotal']?.toString() ?? '0';
    final tax = billData['tax']?.toString();
    final discount = billData['discount']?.toString();
    final total = billData['total']?.toString() ?? '0';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Receipt header
            Center(
              child: Column(
                children: [
                  Text(
                    billTitle.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store,
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Divider(thickness: 1.5),
                ],
              ),
            ),

            // Items
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'ITEM',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'QTY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'PRICE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const Divider(),

            // Item list
            ...items.map((item) {
              final name = item['name'] ?? 'Unknown item';
              final quantity = item['quantity']?.toString() ?? '1';
              final unit = item['unit'] ?? '';
              final price = item['price']?.toString() ?? '0';
              final subtotal = item['subtotal']?.toString() ?? price;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '$quantity ${unit.isNotEmpty ? unit : ''}',
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '$currency $subtotal',
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const Divider(),

            // Totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  '$currency $subtotal',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            if (tax != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tax',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '$currency $tax',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
            if (discount != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Discount',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '- $currency $discount',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$currency $total',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Thank you message
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Thank you for your purchase!',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}