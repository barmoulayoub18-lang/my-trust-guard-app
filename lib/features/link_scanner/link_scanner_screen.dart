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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Phishing Link Scanner',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1.0 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Paste suspicious links from SMS or WhatsApp to trace hidden payloads or phishing destinations safely.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryDark.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _urlController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Suspicious URL',
                hintText: 'example.com/login',
                labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                floatingLabelStyle: const TextStyle(color: AppColors.primary),
                prefixIcon: const Icon(Icons.link_rounded, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 20),
            CustomButton(
              onPressed: _provider.isLoading
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      _provider.scanTargetUrl(_urlController.text);
                    },
              text: 'Execute Threat Scan',
            ),
            if (_provider.isLoading) ...[
              const SizedBox(height: 24),
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
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _provider.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
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
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300 + (index * 50)),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: historicColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.shield_outlined, color: historicColor, size: 22),
                      ),
                      title: Text(
                        historicItem.originalUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        'Score: ${historicItem.riskScore}/100',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Icon(
                        historicItem.isPhishing ? Icons.gpp_bad_rounded : Icons.verified_user_rounded,
                        color: historicColor,
                        size: 24,
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

    String siteSummary = result.siteSummary;
    if (siteSummary == 'analysis of the website content is in progress and no detailed data was retrieved.') {
      siteSummary = 'Website content analysis is currently unavailable.';
    }

    String verifiableReason = result.verifiableReason;
    if (verifiableReason == 'analysis of the domain structure is in progress and no detailed data was retrieved.') {
      verifiableReason = 'Structural analysis of the domain is in progress and no detailed data was retrieved.';
    }

    final flags = result.detectedFlags;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween<double>(begin: 0.9, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Threat Analysis Verdict',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.2), width: 1),
                    ),
                    child: Text(
                      result.isPhishing ? 'MALICIOUS' : 'CLEAN',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: AppColors.divider, thickness: 1),
              Row(
                children: [
                  const Text(
                    'Risk Index: ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '$score/100',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Text(
                  'Trace Destination: ${result.finalUrl}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'General idea about the site before you visit it:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.primary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                siteSummary, 
                style: const TextStyle(
                  fontSize: 15, 
                  height: 1.5, 
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Verifiable Reason:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.primary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                verifiableReason, 
                style: const TextStyle(
                  fontSize: 15, 
                  height: 1.5, 
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (flags.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Security Evaluation Vectors:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                ...flags.map((flag) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 3.0),
                            child: Icon(Icons.report_problem_rounded, size: 16, color: AppColors.warning),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              flag, 
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}