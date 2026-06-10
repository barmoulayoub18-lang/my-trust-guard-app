import 'package:flutter/material.dart';
import '../../data/services/supabase_service.dart';
import '../home/home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final codeController = TextEditingController();

  bool isLoading = false;
  int secondsRemaining = 60;
  bool canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  // ⏳ Countdown
  void startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return false;

      if (secondsRemaining == 0) {
        setState(() => canResend = true);
        return false;
      }

      setState(() => secondsRemaining--);
      return true;
    });
  }

  // ✅ VERIFY
  Future<void> verifyCode() async {
    final code = codeController.text.trim();

    if (code.length < 6) {
      _showMessage("Enter valid 6-digit code");
      return;
    }

    try {
      setState(() => isLoading = true);

      await SupabaseService.verifyOtp(
        email: widget.email,
        token: code,
      );

      if (!mounted) return;

      _showMessage("Verified successfully ✅");

      // 🔥 الحل الحقيقي هنا
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      _showMessage("Invalid or expired code ❌");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // 🔁 RESEND
  Future<void> resendCode() async {
    try {
      setState(() {
        secondsRemaining = 60;
        canResend = false;
      });

      await SupabaseService.sendOtp(widget.email);

      startTimer();

      _showMessage("Code resent 📩");
    } catch (e) {
      _showMessage("Failed to resend code");
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Verification"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 30),

              const Icon(Icons.verified_user, size: 80),

              const SizedBox(height: 20),

              const Text(
                "Enter Verification Code",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Code sent to\n${widget.email}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 40),

              // 🔢 OTP FIELD
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 10,
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "------",
                  counterText: "",
                ),
              ),

              const SizedBox(height: 25),

              // 🔘 VERIFY BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : verifyCode,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Verify"),
                ),
              ),

              const SizedBox(height: 20),

              // ⏳ RESEND
              canResend
                  ? TextButton(
                      onPressed: resendCode,
                      child: const Text("Resend Code"),
                    )
                  : Text(
                      "Resend in $secondsRemaining s",
                      style: const TextStyle(color: Colors.grey),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
