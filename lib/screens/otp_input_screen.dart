import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OTPInputScreen extends StatefulWidget {
  const OTPInputScreen({super.key});

  @override
  State<OTPInputScreen> createState() => _OTPInputScreenState();
}

class _OTPInputScreenState extends State<OTPInputScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String _phoneNumber = '';
  String _verificationId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
      if (args != null) {
        setState(() {
          _phoneNumber = args['phoneNumber'] ?? '';
          _verificationId = args['verificationId'] ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _verifyOTP() async {
    if (_otpCode.length < 6) {
      _showSnackBar('Please enter the complete OTP', Colors.red);
      return;
    }

    if (_verificationId.isEmpty) {
      _showSnackBar('Verification ID is missing. Please go back and try again.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _verifyOTPWithFirestore(
        verificationId: _verificationId,
        enteredOTP: _otpCode,
        phoneNumber: _phoneNumber,
        firestore: FirebaseFirestore.instance,
      );

      if (result['success']) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('phone_verified', true);
        await prefs.setString('verified_phone', _phoneNumber);

        if (mounted) {
          _showSnackBar(result['message'], Colors.green);
          await Future.delayed(const Duration(milliseconds: 1000));
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/permissions');
          }
        }
      } else {
        _showSnackBar(result['message'], Colors.red);
        _clearOtpFields();
      }
    } catch (e) {
      _showSnackBar('Verification failed. Please try again.', Colors.red);
      _clearOtpFields();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  static Future<Map<String, dynamic>> _verifyOTPWithFirestore({
    required String verificationId,
    required String enteredOTP,
    required String phoneNumber,
    required FirebaseFirestore firestore,
  }) async {
    try {
      DocumentSnapshot otpDoc = await firestore.collection('otp_verifications').doc(verificationId).get();
      if (!otpDoc.exists) return {'success': false, 'message': 'Invalid verification code'};

      Map<String, dynamic> data = otpDoc.data() as Map<String, dynamic>;

      if (DateTime.now().isAfter(data['expiresAt'].toDate())) return {'success': false, 'message': 'OTP expired'};
      if (data['isVerified'] == true) return {'success': false, 'message': 'OTP already used'};
      int attempts = data['attempts'] ?? 0;
      if (attempts >= 3) return {'success': false, 'message': 'Too many attempts'};

      await firestore.collection('otp_verifications').doc(verificationId).update({'attempts': attempts + 1});

      if (data['otp'] == enteredOTP) {
        await firestore.collection('otp_verifications').doc(verificationId).update({
          'isVerified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
        });

        // ✅ **Update phone number in Firestore Users collection**
        QuerySnapshot userQuery = await firestore
            .collection('Users')
            .where('phoneNumber', isEqualTo: '')
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          await firestore.collection('Users').doc(userQuery.docs.first.id).update({
            'phoneNumber': phoneNumber,
            'isPhoneVerified': true,
            'verifiedAt': FieldValue.serverTimestamp(),
          });
        }

        return {'success': true, 'message': 'Phone number verified successfully'};
      }

      return {'success': false, 'message': 'Incorrect OTP'};
    } catch (e) {
      return {'success': false, 'message': 'Verification failed'};
    }
  }

  void _clearOtpFields() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text('Enter verification code', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 16),
              const Text('We have sent a 6-digit code to your phone', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    height: 55,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF7F8F8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4285F4), foregroundColor: Colors.white),
                    child: _isLoading ? const CircularProgressIndicator() : const Text('Verify', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}