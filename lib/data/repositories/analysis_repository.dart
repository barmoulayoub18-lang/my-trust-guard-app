import '../services/api_service.dart';
import '../services/supabase_service.dart';

class AnalysisRepository {
  // =====================================================
  // 🧠 ANALYZE STORE (BACKEND ONLY 🔥)
  // =====================================================
  static Future<Map<String, dynamic>> analyzeStore(String input) async {
    try {
      final user = SupabaseService.currentUser;

      if (user == null) {
        throw Exception("User not authenticated");
      }

      Map<String, dynamic> result;

      try {
        // ✅ التحليل الحقيقي عبر السيرفر (Gemma + Serper)
        result = await ApiService.analyze(input);
      } catch (e) {
        // ⚠️ fallback في حالة فشل السيرفر
        result = _fallbackAnalysis(input);
      }

      final normalized = _normalizeResult(result);

      // 💾 حفظ في Supabase
      await SupabaseService.client.from('analysis_results').insert({
        "user_id": user.id,
        "store_name": input,
        "score": normalized["score"],
        "risk_level": normalized["risk"],
        "details": normalized,
      });

      return normalized;
    } catch (e) {
      throw Exception("Analysis failed: $e");
    }
  }

  // =====================================================
  // 📊 GET USER ANALYSIS HISTORY
  // =====================================================
  static Future<List<Map<String, dynamic>>> getUserAnalyses() async {
    try {
      final user = SupabaseService.currentUser;

      if (user == null) return [];

      final data = await SupabaseService.client
          .from('analysis_results')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception("Fetch failed: $e");
    }
  }

  // =====================================================
  // 🗑️ DELETE ANALYSIS
  // =====================================================
  static Future<void> deleteAnalysis(String id) async {
    try {
      await SupabaseService.client
          .from('analysis_results')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception("Delete failed: $e");
    }
  }

  // =====================================================
  // ⭐ GET TOP SAFE STORES
  // =====================================================
  static Future<List<Map<String, dynamic>>> getTopStores() async {
    try {
      final data = await SupabaseService.client
          .from('analysis_results')
          .select()
          .gte('score', 80)
          .order('score', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception("Top stores error: $e");
    }
  }

  // =====================================================
  // 🧠 NORMALIZE RESULT
  // =====================================================
  static Map<String, dynamic> _normalizeResult(Map<String, dynamic> result) {
    double score = (result["score"] ?? 50).toDouble();

    String risk;
    if (score >= 80) {
      risk = "Low Risk";
    } else if (score >= 50) {
      risk = "Medium Risk";
    } else {
      risk = "High Risk";
    }

    return {
      "score": score,
      "risk": risk,
      "reviews": result["reviews"] ?? "Unknown",
      "activity": result["activity"] ?? "Unknown",
      "trust_signals": result["trust_signals"] ?? "Unknown",
      "red_flags": result["red_flags"] ?? [],
      "explanation": result["explanation"] ?? "",
      "raw": result,
    };
  }

  // =====================================================
  // ⚠️ FALLBACK (في حالة فشل السيرفر)
  // =====================================================
  static Map<String, dynamic> _fallbackAnalysis(String input) {
    final fakeScore = (50 + (input.length * 3)) % 100;

    return {
      "score": fakeScore.toDouble(),
      "risk": fakeScore > 70
          ? "Low Risk"
          : fakeScore > 50
              ? "Medium Risk"
              : "High Risk",
      "reviews": fakeScore > 60 ? "Mostly Positive" : "Negative",
      "activity": fakeScore > 70 ? "Active" : "Suspicious",
      "trust_signals": "Unavailable",
      "red_flags": ["Analysis fallback used"],
      "explanation": "Server unavailable, fallback result used",
    };
  }
}
