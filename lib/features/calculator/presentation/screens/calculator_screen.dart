import 'package:flutter/material.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController percentController = TextEditingController();

  double result = 0;

  void calculateGST() {
    final amount = double.tryParse(amountController.text) ?? 0;
    final percent = double.tryParse(percentController.text) ?? 0;

    setState(() {
      result = amount + (amount * percent / 100);
    });
  }

  void calculateDiscount() {
    final amount = double.tryParse(amountController.text) ?? 0;
    final percent = double.tryParse(percentController.text) ?? 0;

    setState(() {
      result = amount - (amount * percent / 100);
    });
  }

  void calculateProfit() {
    final cost = double.tryParse(amountController.text) ?? 0;
    final sell = double.tryParse(percentController.text) ?? 0;

    setState(() {
      result = sell - cost;
    });
  }

  void clear() {
    amountController.clear();
    percentController.clear();

    setState(() {
      result = 0;
    });
  }

  Widget actionButton(
      String title,
      Color color,
      VoidCallback onTap,
      ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: color,
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: onTap,
          child: Text(title),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Business Calculator"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),

        child: Column(
          children: [

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount / Cost",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: percentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Percentage / Selling Price",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [

                actionButton(
                  "GST",
                  Colors.blue,
                  calculateGST,
                ),

                actionButton(
                  "Discount",
                  Colors.green,
                  calculateDiscount,
                ),
              ],
            ),

            Row(
              children: [

                actionButton(
                  "Profit",
                  Colors.orange,
                  calculateProfit,
                ),

                actionButton(
                  "Clear",
                  Colors.red,
                  clear,
                ),
              ],
            ),

            const SizedBox(height: 35),

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [

                    const Text(
                      "Result",
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      result.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}