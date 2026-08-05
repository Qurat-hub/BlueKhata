import 'package:flutter/material.dart';

class QRScreen extends StatefulWidget {
  const QRScreen({super.key});

  @override
  State<QRScreen> createState() => _QRScreenState();
}

class _QRScreenState extends State<QRScreen> {

  final TextEditingController amountController = TextEditingController();

  final TextEditingController noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("QR Payments"),
      ),

      body: ListView(

        padding: const EdgeInsets.all(18),

        children: [

          Card(

            child: Padding(

              padding: const EdgeInsets.all(20),

              child: Column(

                children: [

                  const Icon(
                    Icons.qr_code_2_rounded,
                    size: 140,
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "Business Payment QR",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Customers can scan this QR to make payments.",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Amount",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 18),

          TextField(
            controller: noteController,
            decoration: const InputDecoration(
              labelText: "Payment Note",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 25),

          FilledButton.icon(

            onPressed: () {

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("QR Generated Successfully"),
                ),
              );

            },

            icon: const Icon(Icons.qr_code),

            label: const Text("Generate QR"),
          ),

          const SizedBox(height: 12),

          FilledButton.icon(

            onPressed: () {

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Scanner coming soon"),
                ),
              );

            },

            icon: const Icon(Icons.qr_code_scanner),

            label: const Text("Scan QR"),
          ),

          const SizedBox(height: 12),

          FilledButton.icon(

            onPressed: () {

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Share feature coming soon"),
                ),
              );

            },

            icon: const Icon(Icons.share),

            label: const Text("Share QR"),
          ),

          const SizedBox(height: 30),

          const Text(
            "Recent Payments",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.check,color: Colors.green),
              ),
              title: const Text("Rs. 5,000"),
              subtitle: const Text("Ali Traders"),
              trailing: const Text("Today"),
            ),
          ),

          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.check,color: Colors.green),
              ),
              title: const Text("Rs. 2,300"),
              subtitle: const Text("Ahmed Store"),
              trailing: const Text("Yesterday"),
            ),
          ),

        ],
      ),
    );
  }
}