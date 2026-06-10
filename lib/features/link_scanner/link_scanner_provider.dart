import 'package:flutter/material.dart';
import '../../data/services/link_scanner_service.dart';
import '../../data/services/supabase_service.dart';
import '../../data/models/link_scan_model.dart';

class LinkScannerProvider extends ChangeNotifier {
  bool _isLoading = false;
  LinkScanModel? _currentResult;
  String? _errorMessage;
  List<LinkScanModel> _scanHistory = [];

  bool get isLoading => _isLoading;
  LinkScanModel? get currentResult => _currentResult;
  String? get errorMessage => _errorMessage;
  List<LinkScanModel> get scanHistory => _scanHistory;

  Future<void> scanTargetUrl(String url) async {
    if (url.trim().isEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    _currentResult = null;
    notifyListeners();

    try {
      print("Provider invoking LinkScannerService.scanUrl for: $url");
      final data = await LinkScannerService.scanUrl(url);
      
      print("Parsing operational data structure into LinkScanModel...");
      final model = LinkScanModel.fromJson(data);
      _currentResult = model;
      print("Parsing complete. Risk score assigned: ${model.riskScore}");

      final user = SupabaseService.currentUser;
      if (user != null) {
        try {
          await SupabaseService.client.from('link_scans').insert({
            'user_id': user.id,
            'original_url': model.originalUrl,
            'final_url': model.finalUrl,
            'risk_score': model.riskScore,
            'is_phishing': model.isPhishing,
            'scan_details': Map<String, dynamic>.from(model.scanDetails)
          });
          await fetchUserHistory();
        } catch (_) {}
      }
    } catch (e) {
      print("Detailed error tracking context within Provider: $e");
      String cleanMessage = e.toString().replaceAll("Exception: ", "");
      if (cleanMessage.contains("<!DOCTYPE html>") || cleanMessage.contains("Cannot POST")) {
        cleanMessage = "Server endpoint misconfiguration or incorrect backend URL connection.";
      }
      _errorMessage = cleanMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserHistory() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    try {
      final data = await SupabaseService.client
          .from('link_scans')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      _scanHistory = List<Map<String, dynamic>>.from(data)
          .map((item) => LinkScanModel.fromJson(item))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  void resetState() {
    _currentResult = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}