import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PanicReportView extends StatelessWidget {
  final String reportText;
  final String country;

  const PanicReportView({
    super.key,
    required this.reportText,
    required this.country,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generated Legal Filing Blueprint')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_turned_in, color: Colors.green),
                const SizedBox(width: 8),
                Text('Jurisdiction Framework: $country', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    reportText,
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 13, height: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: reportText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filing report text successfully exported to system clipboard')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('COPY COMPLAINT STATEMENT'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Share.share(reportText);
              },
              icon: const Icon(Icons.share),
              label: const Text('SHARE OFFICIAL REPORT'),
            ),
          ],
        ),
      ),
    );
  }
}

class Share {
  static void share(String text) {}
}