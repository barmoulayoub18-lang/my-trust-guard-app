import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/helpers.dart';
import '../../data/services/supabase_service.dart';
import '../../presentation/widgets/custom_card.dart';
import '../../presentation/widgets/custom_button.dart';
import '../../presentation/widgets/loading_widget.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  final storeController = TextEditingController();
  final reasonController = TextEditingController();

  bool isLoading = false;
  bool isDisposed = false;

  List<Map<String, dynamic>> complaints = [];

  @override
  void initState() {
    super.initState();
    loadComplaints();
  }

  @override
  void dispose() {
    isDisposed = true;
    storeController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  void safeSetState(VoidCallback fn) {
    if (!mounted || isDisposed) return;
    setState(fn);
  }

  Future<void> loadComplaints() async {
    try {
      final data = await SupabaseService.client
          .from('complaints')
          .select()
          .order('created_at', ascending: false);

      safeSetState(() {
        complaints = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (!mounted) return;

      Helpers.showSnackBar(
        context,
        "Failed to load complaints",
        isError: true,
      );
    }
  }

  Future<void> submitComplaint() async {
    if (isLoading) return;

    final storeInput = storeController.text.trim();
    final reason = reasonController.text.trim();

    if (storeInput.isEmpty || reason.isEmpty) {
      Helpers.showSnackBar(
        context,
        "Please fill all fields",
        isError: true,
      );
      return;
    }

    try {
      safeSetState(() => isLoading = true);

      final user = SupabaseService.currentUser;

      await SupabaseService.client.from('complaints').insert({
        "user_id": user?.id,
        "reason": "STORE: $storeInput\n\nCOMPLAINT: $reason",
        "status": "pending",
      });

      storeController.clear();
      reasonController.clear();

      if (mounted) {
        FocusScope.of(context).unfocus();
      }

      Helpers.showSnackBar(
        context,
        "Complaint submitted",
      );

      await loadComplaints();
    } catch (e) {
      if (!mounted) return;

      Helpers.showSnackBar(
        context,
        "Submission failed",
        isError: true,
      );
    } finally {
      safeSetState(() => isLoading = false);
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "resolved":
        return const Color(0xFF10B981);

      case "rejected":
        return const Color(0xFFEF4444);

      default:
        return const Color(0xFFF59E0B);
    }
  }

  String getComplaintStore(dynamic reason) {
    if (reason == null) return "";

    final text = reason.toString();

    if (text.contains("STORE:")) {
      final parts = text.split("\n");

      if (parts.isNotEmpty) {
        return parts.first.replaceAll("STORE:", "").trim();
      }
    }

    return text;
  }

  String getComplaintReason(dynamic reason) {
    if (reason == null) return "";

    final text = reason.toString();

    if (text.contains("COMPLAINT:")) {
      return text.split("COMPLAINT:").last.trim();
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Report Store",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        shape: const Border(
          bottom: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: loadComplaints,
            color: const Color(0xFF2563EB),
            backgroundColor: Colors.white,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                CustomCard(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: Color(0xFF2563EB),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Report suspicious stores to protect other users",
                            style: TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomCard(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      children: [
                        TextField(
                          controller: storeController,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
                          decoration: InputDecoration(
                            labelText: "Store URL or Name",
                            labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                            floatingLabelStyle: const TextStyle(color: Color(0xFF2563EB)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            prefixIcon: const Icon(Icons.storefront_outlined, color: Color(0xFF64748B), size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: reasonController,
                          maxLines: 3,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
                          decoration: InputDecoration(
                            labelText: "Complaint Reason",
                            labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                            floatingLabelStyle: const TextStyle(color: Color(0xFF2563EB)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 40),
                              child: Icon(Icons.edit_note_outlined, color: Color(0xFF64748B), size: 22),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        CustomButton(
                          text: "Submit Complaint",
                          icon: Icons.send_rounded,
                          isLoading: isLoading,
                          onPressed: submitComplaint,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Recent Complaints",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (complaints.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_turned_in_outlined, size: 48, color: const Color(0xFF0F172A).withOpacity(0.2)),
                          const SizedBox(height: 12),
                          const Text(
                            "No complaints yet",
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...complaints.map((item) {
                    final status = item['status']?.toString() ?? "pending";
                    final rawDate = item['created_at'] != null ? item['created_at'].toString() : "";
                    final dateStr = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;

                    return TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      tween: Tween<double>(begin: 0.95, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: CustomCard(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.storefront, size: 18, color: Color(0xFF475569)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        getComplaintStore(item['reason']),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(left: 26),
                                  child: Text(
                                    getComplaintReason(item['reason']),
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Divider(color: Color(0xFFF1F5F9), height: 1),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: getStatusColor(status).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: getStatusColor(status).withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: getStatusColor(status),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                                        const SizedBox(width: 4),
                                        Text(
                                          dateStr,
                                          style: const TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                const SizedBox(height: 30),
              ],
            ),
          ),
          if (isLoading)
            const LoadingWidget(
              isFullScreen: true,
              text: "Submitting complaint...",
            ),
        ],
      ),
    );
  }
}