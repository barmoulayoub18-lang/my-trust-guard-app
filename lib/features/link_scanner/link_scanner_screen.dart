import 'package:flutter/material.dart';
import 'link_scanner_provider.dart';
import '../../core/constants/colors.dart';
import '../../presentation/widgets/custom_button.dart';
import '../../presentation/widgets/custom_card.dart';
import '../../presentation/widgets/loading_widget.dart';
import '../../data/models/link_scan_model.dart';

class LinkScannerScreen extends StatefulWidget {
  const LinkScannerScreen({super.key});

  @override
  State<LinkScannerScreen> createState() => _LinkScannerScreenState();
}

class _LinkScannerScreenState extends State<LinkScannerScreen> {
  final TextEditingController _urlController = TextEditingController();
  final LinkScannerProvider _provider = LinkScannerProvider();

  @override
  void initState() {
    super.initState();
    _provider.fetchUserHistory();
    _provider.addListener(_updateState);
  }

  @override
  void dispose() {
    _provider.removeListener(_updateState);
    _urlController.dispose();
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phishing Link Scanner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Paste suspicious links from SMS or WhatsApp to trace hidden payloads or phishing destinations safely.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Suspicious URL',
                hintText: 'example.com/login',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            CustomButton(
              onPressed: _provider.isLoading
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      print("Triggering threat scan sequence via UI button push");
                      _provider.scanTargetUrl(_urlController.text);
                    },
              text: 'Execute Threat Scan',
            ),
            if (_provider.isLoading) ...[
              const SizedBox(height: 20),
              const Center(
                child: LoadingWidget(
                  isFullScreen: false,
                  text: 'Analyzing target parameters...',
                ),
              ),
            ],
            if (_provider.errorMessage != null) ...[
              const SizedBox(height: 20),
              CustomCard(
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _provider.errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_provider.currentResult != null) ...[
              const SizedBox(height: 24),
              _buildResultsCard(_provider.currentResult!),
            ],
            if (_provider.scanHistory.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text(
                'Recent Scan History',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _provider.scanHistory.length,
                itemBuilder: (context, index) {
                  final historicItem = _provider.scanHistory[index];
                  final historicColor = historicItem.riskScore >= 75
                      ? AppColors.trustLow
                      : (historicItem.riskScore >= 45 ? AppColors.trustMedium : AppColors.trustHigh);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Icon(Icons.security, color: historicColor),
                      title: Text(
                        historicItem.originalUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('Score: ${historicItem.riskScore}/100'),
                      trailing: Icon(
                        historicItem.isPhishing ? Icons.gpp_bad : Icons.verified_user,
                        color: historicColor,
                      ),
                      onTap: () {
                        _urlController.text = historicItem.originalUrl;
                        _provider.scanTargetUrl(historicItem.originalUrl);
                      },
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard(LinkScanModel result) {
    final score = result.riskScore;
    final color = score >= 75 
        ? AppColors.trustLow 
        : (score >= 45 ? AppColors.trustMedium : AppColors.trustHigh);

    final siteSummary = result.siteSummary;
    final verifiableReason = result.verifiableReason;
    final flags = result.detectedFlags;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Threat Analysis Verdict', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  result.isPhishing ? 'MALICIOUS' : 'CLEAN',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text('Risk Index: $score/100', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 12),
          Text('Trace Destination: ${result.finalUrl}', style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 16),
          
          const Text('فكرة عامة عن الموقع ومحتواه (قبل الدخول):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color.fromARGB(255, 0, 170, 255))),
          const SizedBox(height: 4),
          Text(siteSummary, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
          const SizedBox(height: 16),
          
          const Text('التحليل الفعلي والسبب التفصيلي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color.fromARGB(255, 8, 173, 255))),
          const SizedBox(height: 4),
          Text(verifiableReason, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
          const SizedBox(height: 16),
          
          if (flags.isNotEmpty) ...[
            const Text('Security Evaluation Vectors:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            ...flags.map((flag) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      const Icon(Icons.radio_button_checked, size: 14, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(child: Text(flag, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}