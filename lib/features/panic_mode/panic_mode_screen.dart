import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/supabase_service.dart';
import '../../presentation/widgets/custom_button.dart';
import '../../presentation/widgets/loading_widget.dart';
import 'panic_report_view.dart';
import '../../core/constants/colors.dart';

class PanicModeScreen extends StatefulWidget {
  const PanicModeScreen({super.key});

  @override
  State<PanicModeScreen> createState() => _PanicModeScreenState();
}

class _PanicModeScreenState extends State<PanicModeScreen> {
  String _selectedScamType = 'Financial Fraud';
  String _selectedCountry = 'Algeria';
  final TextEditingController _detailsController = TextEditingController();
  bool _isLocatingCountry = false;

  final Map<String, String> _countryMapping = {
    'Algeria': 'Algeria',
    'Saudi Arabia': 'Saudi Arabia',
    'Egypt': 'Egypt',
    'United Arab Emirates': 'United Arab Emirates',
  };

  Future<void> _detectUserCountry() async {
    if (!mounted) return;
    setState(() => _isLocatingCountry = true);
    try {
      final dio = Dio();
      final response = await dio.get('http://ip-api.com/json/');
      if (response.statusCode == 200 && response.data != null) {
        final countryName = response.data['country']?.toString();
        if (countryName != null && _countries.contains(countryName)) {
          setState(() {
            _selectedCountry = countryName;
          });
        }
      }
    } catch (e) {
      print("Country detection fallback to default: $e");
    } finally {
      if (mounted) {
        setState(() => _isLocatingCountry = false);
      }
    }
  }

  bool _isGenerating = false;
  List<Map<String, dynamic>> _pastComplaints = [];

  final List<String> _scamTypes = [
    'Financial Fraud',
    'Account Hijacking',
    'Cyber Extortion',
    'Identity Theft'
  ];
  final List<String> _countries = [
    'Algeria',
    'Saudi Arabia',
    'Egypt',
    'United Arab Emirates',
    'International'
  ];

  @override
  void initState() {
    super.initState();
    _loadPastComplaints();
    _detectUserCountry();
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _loadPastComplaints() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    try {
      final data = await SupabaseService.client
          .from('panic_complaints')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      setState(() {
        _pastComplaints = List<Map<String, dynamic>>.from(data);
      });
    } catch (_) {}
  }

  Future<void> _processPanicReport() async {
    if (_detailsController.text.trim().isEmpty) return;
    setState(() => _isGenerating = true);

    try {
      final user = SupabaseService.currentUser;
      final prompt = "You are an official expert legal advisor for cybercrime prosecution. "
          "Generate a formal, structured, and legally binding Cybercrime Complaint Statement ready to be filed immediately to judicial and police authorities. "
          "The response must be highly professional and entirely suitable for direct legal presentation. "
          "Do not hallucinate or manufacture fake codes. Provide absolute realistic legal frameworks. "
          "CRITICAL TEXT FORMATTING RULE: The entire text response MUST be completely free from any emojis, special stylistic symbols, stars, hashtags, or decorative characters. "
          "The ONLY permitted characters in the text formatting are normal letters, numbers, hyphens, underscores, dots, commas, parentheses, colons, double quotation marks, and standard clean newlines for organization. "
          "Do not use any mathematical operations or formulas. "
          "Jurisdiction: $_selectedCountry Law Enforcement Systems.\n"
          "Crime Category: $_selectedScamType.\n"
          "Victim Profile: Authenticated Client of TrustGuard Protection Suite.\n"
          "Incident Facts & Timeline: ${_detailsController.text}.\n\n"
          "Requirements:\n"
          "1. Formal heading addressing the General Directorate of National Security / Cybercrime Combat Unit of $_selectedCountry.\n"
          "2. Detailed statement of facts organized chronologically with legal terminology.\n"
          "3. Immediate actionable steps tailored for $_selectedCountry to freeze compromised bank accounts or credit cards.\n"
          "4. Exact official local emergency hotline numbers for cybercrime or financial fraud investigation in $_selectedCountry (e.g., 17 or 1548 for Algeria, 911 for Saudi Arabia, 108 for Egypt, 999 for UAE). Provide real active numbers only.";
      final responseText = await AIService.chat(prompt);

      if (user != null) {
        await SupabaseService.client.from('panic_complaints').insert({
          'user_id': user.id,
          'scam_type': _selectedScamType,
          'country': _selectedCountry,
          'generated_report': responseText,
          'status': 'generated'
        });
        await _loadPastComplaints();
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PanicReportView(reportText: responseText, country: _selectedCountry),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generation failure: $e')));
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Emergency Panic System',
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
      body: _isGenerating
          ? const Center(
              child: LoadingWidget(
                isFullScreen: false,
                text: 'Forging institutional law enforcement filings...                       Generating using  legal AI engines...',
              ),
            )
          : SingleChildScrollView(
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
                        color: AppColors.danger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.danger.withOpacity(0.15), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.gpp_bad_rounded, color: AppColors.danger, size: 26),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'If you have transferred funds or exposed critical banking keys, remain calm. Complete parameters below to forge institutional law enforcement filings.',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: _selectedScamType,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                    items: _scamTypes
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(
                                t,
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedScamType = v!),
                    decoration: InputDecoration(
                      labelText: 'Vector Classification',
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      floatingLabelStyle: const TextStyle(color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.surface,
                      prefixIcon: const Icon(Icons.category_rounded, color: AppColors.textSecondary),
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
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: _selectedCountry,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                    items: _countries
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                c,
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCountry = v!),
                    decoration: InputDecoration(
                      labelText: 'Legal Jurisdiction',
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      floatingLabelStyle: const TextStyle(color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.surface,
                      prefixIcon: const Icon(Icons.gavel_rounded, color: AppColors.textSecondary),
                      suffixIcon: _isLocatingCountry
                          ? Container(
                              padding: const EdgeInsets.all(12),
                              width: 20,
                              height: 20,
                              child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            )
                          : null,
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
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _detailsController,
                    maxLines: 5,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'Incident Timeline Details',
                      hintText: 'Specify dates, transaction reference nodes, fake accounts or profiles names, links utilized, balances compromised...',
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      floatingLabelStyle: const TextStyle(color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.surface,
                      alignLabelWithHint: true,
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
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    onPressed: _isLocatingCountry ? null : _processPanicReport,
                    text: 'GENERATE EMERGENCY ESCALATION FORM',
                  ),
                  if (_pastComplaints.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    const Text(
                      'Generated Emergency Reports',
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
                      itemCount: _pastComplaints.length,
                      itemBuilder: (context, index) {
                        final complaint = _pastComplaints[index];
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
                                color: AppColors.danger.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.assignment_late_rounded, color: AppColors.danger, size: 22),
                            ),
                            title: Text(
                              complaint['scam_type']?.toString() ?? 'Scam Report',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              'Jurisdiction: ${complaint['country']} • Status: ${complaint['status']}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PanicReportView(
                                    reportText: complaint['generated_report']?.toString() ?? '',
                                    country: complaint['country']?.toString() ?? 'International',
                                  ),
                                ),
                              );
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
}