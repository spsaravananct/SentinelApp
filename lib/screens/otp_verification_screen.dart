import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, PhoneAuthCredential, PhoneAuthProvider, UserCredential;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String verificationId;

  const OTPVerificationScreen({super.key, required this.verificationId});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountryCode = '+1';
  bool _isLoading = false;

  final List<Map<String, String>> _countryCodes = [
    {'code': '+1', 'country': 'US', 'flag': '🇺🇸'},
    {'code': '+91', 'country': 'IN', 'flag': '🇮🇳'},
    {'code': '+44', 'country': 'UK', 'flag': '🇬🇧'},
    {'code': '+86', 'country': 'CN', 'flag': '🇨🇳'},
    {'code': '+81', 'country': 'JP', 'flag': '🇯🇵'},
    {'code': '+49', 'country': 'DE', 'flag': '🇩🇪'},
    {'code': '+33', 'country': 'FR', 'flag': '🇫🇷'},
    {'code': '+7', 'country': 'RU', 'flag': '🇷🇺'},
    {'code': '+55', 'country': 'BR', 'flag': '🇧🇷'},
    {'code': '+61', 'country': 'AU', 'flag': '🇦🇺'},
  ];

  Future<void> _sendOTP() async {
    final phoneNumber = _phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      _showSnackBar('Please enter your phone number', Colors.red);
      return;
    }

    if (phoneNumber.length < 6) {
      _showSnackBar('Please enter a valid phone number', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));

      final verificationId = 'mock_verification_id_${DateTime.now().millisecondsSinceEpoch}';
      final fullPhoneNumber = '$_selectedCountryCode$phoneNumber';

      if (mounted) {
        _showSnackBar('OTP sent successfully!', Colors.green);

        Navigator.pushNamed(
          context,
          '/otp-input',
          arguments: {
            'phoneNumber': fullPhoneNumber,
            'verificationId': verificationId,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to send OTP. Please try again.', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Enter your phone number',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'We will send an OTP to verify your number',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withAlpha((0.2 * 255).toInt()),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCountryCode,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
                          style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500),
                          dropdownColor: Colors.white,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCountryCode = newValue;
                              });
                            }
                          },
                          items: _countryCodes.map<DropdownMenuItem<String>>((Map<String, String> country) {
                            return DropdownMenuItem<String>(
                              value: country['code'],
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(country['flag']!, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Text(country['code']!),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey.withAlpha((0.3 * 255).toInt()),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(Icons.phone_outlined, color: Colors.grey, size: 20),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                        style: const TextStyle(fontSize: 16, color: Colors.black),
                        decoration: const InputDecoration(
                          hintText: 'Phone Number',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                        ),
                        onSubmitted: (_) => _sendOTP(),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 0,
                    disabledBackgroundColor: const Color(0xFF4285F4).withAlpha((0.6 * 255).toInt()),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'Send OTP',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}

void verifyOTP(String smsCode, String verificationId, BuildContext context) async {
  try {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

    if (userCredential.user != null) {
      // Success: Navigate to Home or Dashboard
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP verification failed: ${e.toString()}')),
      );
    }
  }
}
