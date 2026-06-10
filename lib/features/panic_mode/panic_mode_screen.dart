import 'package:flutter/material.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/supabase_service.dart';
import '../../presentation/widgets/custom_button.dart';
import '../../presentation/widgets/loading_widget.dart';
import 'panic_report_view.dart';

class PanicModeScreen extends StatefulWidget {
  const PanicModeScreen({super.key});

  @override
  State<PanicModeScreen> createState() => _PanicModeScreenState();
}

class _PanicModeScreenState extends State<PanicModeScreen> {
  String _selectedScamType = 'Financial Fraud';
  String _selectedCountry = 'Algeria';
  final TextEditingController _detailsController = TextEditingController();
  bool _isGenerating = false;
  List<Map<String, dynamic>> _pastComplaints = [];

  final List<String> _scamTypes = ['Financial Fraud', 'Account Hijacking', 'Cyber Extortion', 'Identity Theft'];
  final List<String> _countries = ['Algeria', 'Saudi Arabia', 'Egypt', 'United Arab Emirates', 'International'];

  @override
  void initState() {
    super.initState();
    _loadPastComplaints();
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
      final prompt = "Generate an official, structured legal complaint report form ready to file. "
          "Victim Details: Authenticated Active App User. "
          "Scam Category Type: $_selectedScamType. "
          "Jurisdiction Country: $_selectedCountry. "
          "Incident Context Facts: ${_detailsController.text}. "
          "Provide exact actionable emergency law enforcement hotline numbers and immediate steps to secure assets.";

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
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Panic System')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.gpp_bad, color: Colors.red),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'If you have transferred funds or exposed critical banking keys, remain calm. Complete parameters below to forge institutional law enforcement filings.',
                      style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedScamType,
              items: _scamTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _selectedScamType = v!),
              decoration: const InputDecoration(labelText: 'Vector Classification', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCountry,
              items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCountry = v!),
              decoration: const InputDecoration(labelText: 'Legal Jurisdiction', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _detailsController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Incident Timeline Details',
                hintText: 'Specify dates, transaction reference nodes, fake accounts or profiles names, links utilized, balances compromised...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              onPressed: _isGenerating ? null : _processPanicReport,
              text: 'GENERATE EMERGENCY ESCALATION FORM',
            ),
            if (_pastComplaints.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text(
                'Generated Emergency Reports',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pastComplaints.length,
                itemBuilder: (context, index) {
                  final complaint = _pastComplaints[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.assignment_late, color: Colors.red),
                      title: Text(complaint['scam_type']?.toString() ?? 'Scam Report'),
                      subtitle: Text('Jurisdiction: ${complaint['country']} • Status: ${complaint['status']}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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