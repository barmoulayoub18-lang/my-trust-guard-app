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
        "Complaint submitted ✅",
      );

      await loadComplaints();
    } catch (e) {
      if (!mounted) return;

      Helpers.showSnackBar(
        context,
        "Submission failed ❌",
        isError: true,
      );
    } finally {
      safeSetState(() => isLoading = false);
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "resolved":
        return AppColors.success;

      case "rejected":
        return AppColors.danger;

      default:
        return AppColors.warning;
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
      appBar: AppBar(
        title: const Text("Report Store"),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: loadComplaints,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CustomCard(
                  gradient: AppColors.primaryGradient,
                  child: const Row(
                    children: [
                      Icon(
                        Icons.report,
                        color: Colors.white,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Report suspicious stores to protect other users",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                CustomCard(
                  child: Column(
                    children: [
                      TextField(
                        controller: storeController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: "Store URL or Name",
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: reasonController,
                        maxLines: 3,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: "Complaint Reason",
                        ),
                      ),
                      const SizedBox(height: 15),
                      CustomButton(
                        text: "Submit Complaint",
                        icon: Icons.send,
                        isLoading: isLoading,
                        onPressed: submitComplaint,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Recent Complaints",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (complaints.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        "No complaints yet",
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  ...complaints.map((item) {
                    final status = item['status']?.toString() ?? "pending";

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: CustomCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getComplaintStore(item['reason']),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              getComplaintReason(item['reason']),
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: getStatusColor(status)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: getStatusColor(status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Text(
                                  item['created_at'] != null
                                      ? item['created_at']
                                          .toString()
                                          .substring(0, 10)
                                      : "",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
