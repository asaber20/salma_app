import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'conversations_screen.dart';

class LoginOtpScreen extends StatefulWidget {
  const LoginOtpScreen({super.key});

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen> {
  int _step = 0; // 0: Employee ID, 1: OTP
  final TextEditingController _employeeIdController = TextEditingController();
  bool _isTestMode = true;

  // 4 OTP digit controllers & focus nodes
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(4, (_) => FocusNode());

  Timer? _timer;
  int _remainingSeconds = 120; // 2 minutes
  bool _isTimerExpired = false;

  final LocalAuthentication _auth = LocalAuthentication();
  bool _hasStoredUser = false;

  @override
  void initState() {
    super.initState();
    _loadLastEmployeeId();
  }

  Future<void> _loadLastEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getString('last_employee_id');
    if (lastId != null && lastId.isNotEmpty && mounted) {
      setState(() {
        _employeeIdController.text = lastId;
        _hasStoredUser = true;
      });
    }
  }

  Future<void> _authenticateWithBiometrics(String employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getString('last_employee_id');

    if (lastId == null || employeeId.trim() != lastId.trim()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Biometric login is only available for the last logged-in Employee ID"),
            backgroundColor: const Color(0xFF303489),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    if (kIsWeb) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationsScreen(employeeId: employeeId),
          ),
        );
      }
      return;
    }

    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      if (!canAuthenticate) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ConversationsScreen(employeeId: employeeId),
            ),
          );
        }
        return;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Authenticate with Face ID, Fingerprint, or device PIN to login',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationsScreen(employeeId: employeeId),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationsScreen(employeeId: employeeId),
          ),
        );
      }
    }
  }

  Future<void> _saveLastEmployeeId(String employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_employee_id', employeeId);
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = 120;
      _isTimerExpired = false;
      for (var c in _otpControllers) {
        c.clear();
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isTimerExpired = true;
          for (var c in _otpControllers) {
            c.clear();
          }
        });
      }
    });
  }

  String get _formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool _isLoading = false;

  Future<void> _submitEmployeeId() async {
    final employeeId = _employeeIdController.text.trim();
    if (employeeId.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter a valid 5-digit Employee ID"),
          backgroundColor: const Color(0xFF303489),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (_isTestMode) {
      await _saveLastEmployeeId(employeeId);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationsScreen(employeeId: employeeId),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String bearerToken =
          'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxNTk2MzIiLCJuYW1lIjoiQWhtZWQgU2FiZXIiLCJhZG1pbiI6dHJ1ZSwiaXNfc2FiZXIiOnRydWUsImlhdCI6MTUxNjIzOTAyMn0.ULGyy3ePlq0QEGjMDRJzT7Jop7TQ4Rjw3Bp6TcFdTkM';

      final response = await http.post(
        Uri.parse('https://n8n.srv1348343.hstgr.cloud/webhook/generate_otp'),
        headers: {
          'user_id': employeeId,
          'authorization': bearerToken,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          setState(() {
            _step = 1;
          });
          _startTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("OTP sent successfully to your email!"),
              backgroundColor: const Color(0xFF303489),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _step = 1;
          });
          _startTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("OTP generated (Status: ${response.statusCode})"),
              backgroundColor: const Color(0xFF8045DD),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = 1;
        });
        _startTimer();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isVerifying = false;

  Future<void> _verifyOtp() async {
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter the 4-digit verification code"),
          backgroundColor: const Color(0xFF8045DD),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final employeeId = _employeeIdController.text.trim();

    setState(() {
      _isVerifying = true;
    });

    try {
      String bearerToken =
          'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxNTk2MzIiLCJuYW1lIjoiQWhtZWQgU2FiZXIiLCJhZG1pbiI6dHJ1ZSwiaXNfc2FiZXIiOnRydWUsImlhdCI6MTUxNjIzOTAyMn0.ULGyy3ePlq0QEGjMDRJzT7Jop7TQ4Rjw3Bp6TcFdTkM';

      final response = await http.post(
        Uri.parse('https://n8n.srv1348343.hstgr.cloud/webhook/verify_otp'),
        headers: {
          'user_id': employeeId,
          'otp': otp,
          'authorization': bearerToken,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        bool isMatched = false;

        if (data is List && data.isNotEmpty) {
          final first = data.first;
          if (first is Map && first.containsKey('matched_otp')) {
            isMatched = first['matched_otp'] != null;
          }
        } else if (data is Map) {
          if (data.containsKey('matched_otp')) {
            isMatched = data['matched_otp'] != null;
          }
        }

        if (isMatched) {
          _timer?.cancel();
          await _saveLastEmployeeId(employeeId);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ConversationsScreen(employeeId: employeeId)),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Incorrect OTP. Please check your email and try again."),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
            for (var c in _otpControllers) {
              c.clear();
            }
            _otpFocusNodes[0].requestFocus();
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Verification error: ${response.statusCode}"),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Network error: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF303489), // Deep Navy
              Color(0xFF8045DD), // Purple
              Color(0xFF2659E4), // Royal Blue
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(28.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF33333D).withValues(alpha: 0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Company Logo
                          Center(
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF8045DD), Color(0xFF2659E4)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8045DD).withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/Salma_Icon.jpeg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _step == 0 ? "Employee Authentication" : "OTP Verification",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF303489),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _step == 0
                                ? "Enter your 5-digit Employee ID to continue"
                                : "Please check your email for the 4-digit OTP sent to Employee ID: ${_employeeIdController.text}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF33333D),
                            ),
                          ),
                          const SizedBox(height: 32),

                          if (_step == 0) ...[
                            // Step 0: Employee ID TextField (Max 5 digits)
                            TextField(
                              controller: _employeeIdController,
                              keyboardType: TextInputType.number,
                              maxLength: 5,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(5),
                              ],
                              style: const TextStyle(
                                  color: Color(0xFF33333D),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2.0),
                              decoration: InputDecoration(
                                labelText: "Employee ID (5 Digits)",
                                labelStyle: const TextStyle(color: Color(0xFF303489)),
                                counterText: "",
                                prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF8045DD)),
                                filled: true,
                                fillColor: const Color(0xFFF9FBFB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF2659E4), width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Next Button
                            _buildLiquidButton(
                              label: "Next",
                              onPressed: _submitEmployeeId,
                              isLoading: _isLoading,
                              gradientColors: const [
                                Color(0xFF303489),
                                Color(0xFF8045DD),
                              ],
                            ),
                            if (_hasStoredUser) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  final employeeId = _employeeIdController.text.trim();
                                  if (employeeId.length == 5) {
                                    _authenticateWithBiometrics(employeeId);
                                  }
                                },
                                icon: const Icon(Icons.fingerprint_rounded, color: Color(0xFF8045DD)),
                                label: const Text(
                                  "Login with Biometric / PIN",
                                  style: TextStyle(color: Color(0xFF303489), fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  side: const BorderSide(color: Color(0xFF8045DD), width: 1.5),
                                ),
                              ),
                            ],
                          ] else ...[
                            // Step 1: 4-Digit OTP inputs
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(4, (index) {
                                return SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: TextField(
                                    controller: _otpControllers[index],
                                    focusNode: _otpFocusNodes[index],
                                    enabled: !_isTimerExpired,
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    maxLength: 1,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF303489),
                                    ),
                                    decoration: InputDecoration(
                                      counterText: "",
                                      filled: true,
                                      fillColor: _isTimerExpired
                                          ? Colors.grey.shade200
                                          : const Color(0xFFF9FBFB),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide:
                                            BorderSide(color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF8045DD), width: 2),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide:
                                            BorderSide(color: Colors.grey.shade300),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      if (value.isNotEmpty && index < 3) {
                                        _otpFocusNodes[index + 1].requestFocus();
                                      } else if (value.isEmpty && index > 0) {
                                        _otpFocusNodes[index - 1].requestFocus();
                                      }
                                      // Auto submit when 4 digits entered
                                      if (index == 3 && value.isNotEmpty) {
                                        _verifyOtp();
                                      }
                                    },
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 24),

                            // Timer Display
                            Center(
                              child: Text(
                                _isTimerExpired
                                    ? "Code expired. Please request a new OTP."
                                    : "Time remaining: $_formattedTime",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _isTimerExpired
                                      ? Colors.redAccent
                                      : const Color(0xFF8045DD),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Submit or Resend Button
                            if (!_isTimerExpired)
                              _buildLiquidButton(
                                label: "Verify & Login",
                                onPressed: _verifyOtp,
                                isLoading: _isVerifying,
                                gradientColors: const [
                                  Color(0xFF2659E4),
                                  Color(0xFF3CCEFF),
                                ],
                              )
                            else
                              _buildLiquidButton(
                                label: "Resend OTP",
                                onPressed: _startTimer,
                                gradientColors: const [
                                  Color(0xFF8045DD),
                                  Color(0xFF303489),
                                ],
                              ),
                            const SizedBox(height: 12),

                            // Back to Employee ID
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _step = 0;
                                  _timer?.cancel();
                                });
                              },
                              child: const Text(
                                "Change Employee ID",
                                style: TextStyle(
                                  color: Color(0xFF33333D),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Test Mode Switch under the login card
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Test Mode (Skip OTP & Email)",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: _isTestMode,
                          activeThumbColor: const Color(0xFF3CCEFF),
                          onChanged: (val) {
                            setState(() {
                              _isTestMode = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Company Logo Under Login Card & Centered
                    Center(
                      child: Image.asset(
                        'assets/images/company_logo.png',
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidButton({
    required String label,
    required VoidCallback onPressed,
    required List<Color> gradientColors,
    bool isLoading = false,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
