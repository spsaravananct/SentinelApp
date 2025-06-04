import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

class OTPVerificationScreen extends StatefulWidget {
  final String? verificationId; // Make this optional and nullable

  const OTPVerificationScreen({Key? key, this.verificationId}) : super(key: key);

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountryCode = '+1';
  bool _isLoading = false;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // List of common country codes
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

  // Generate a 6-digit OTP
  String _generateOTP() {
    Random random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Create verification ID using phone number and timestamp
  String _createVerificationId(String phoneNumber) {
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String data = '$phoneNumber$timestamp';
    var bytes = utf8.encode(data);
    var digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  // Store OTP data in Firestore
  Future<void> _storeOTPInFirestore({
    required String phoneNumber,
    required String otp,
    required String verificationId,
  }) async {
    try {
      await _firestore.collection('otp_verifications').doc(verificationId).set({
        'phoneNumber': phoneNumber,
        'otp': otp,
        'verificationId': verificationId,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 5)), // OTP expires in 5 minutes
        ),
        'isVerified': false,
        'attempts': 0,
      });
    } catch (e) {
      throw Exception('Failed to store OTP data: $e');
    }
  }

  // Check if phone number already exists and handle accordingly
  Future<void> _handleExistingUser(String phoneNumber) async {
    try {
      QuerySnapshot existingUser = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        // Update last login attempt
        await _firestore
            .collection('users')
            .doc(existingUser.docs.first.id)
            .update({
          'lastOtpRequest': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new user document
        await _firestore.collection('users').add({
          'phoneNumber': phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
          'lastOtpRequest': FieldValue.serverTimestamp(),
          'isPhoneVerified': false,
        });
      }
    } catch (e) {
      throw Exception('Failed to handle user data: $e');
    }
  }

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
      final fullPhoneNumber = '$_selectedCountryCode$phoneNumber';

      // Generate OTP and verification ID
      final otp = _generateOTP();
      final verificationId = _createVerificationId(fullPhoneNumber);

      // Handle user data in Firestore
      await _handleExistingUser(fullPhoneNumber);

      // Store OTP data in Firestore
      await _storeOTPInFirestore(
        phoneNumber: fullPhoneNumber,
        otp: otp,
        verificationId: verificationId,
      );

      // Simulate SMS sending delay
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        _showSnackBar('OTP sent successfully!', Colors.green);

        // Debug: Print the verification ID and OTP for testing
        debugPrint('Generated Verification ID: $verificationId');
        debugPrint('Generated OTP: $otp');

        // Navigate to OTP input screen with phone number and verification ID
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
        debugPrint('Error sending OTP: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Method to resend OTP with existing verification ID
  Future<String> resendOTP(String phoneNumber, {String? existingVerificationId}) async {
    try {
      final otp = _generateOTP();
      String verificationId;

      if (existingVerificationId != null) {
        // Use existing verification ID for resend
        verificationId = existingVerificationId;
      } else {
        // Create new verification ID if none provided
        verificationId = _createVerificationId(phoneNumber);
      }

      await _storeOTPInFirestore(
        phoneNumber: phoneNumber,
        otp: otp,
        verificationId: verificationId,
      );

      _showSnackBar('OTP resent successfully!', Colors.green);

      // Debug: Print the verification ID and OTP for testing
      debugPrint('Resent Verification ID: $verificationId');
      debugPrint('Resent OTP: $otp');

      return verificationId;
    } catch (e) {
      _showSnackBar('Failed to resend OTP. Please try again.', Colors.red);
      debugPrint('Error resending OTP: $e');
      rethrow;
    }
  }

  // Method to verify OTP (to be used in OTP input screen)
  static Future<Map<String, dynamic>> verifyOTP({
    required String verificationId,
    required String enteredOTP,
    required FirebaseFirestore firestore,
  }) async {
    try {
      debugPrint('Verifying OTP with ID: $verificationId');
      debugPrint('Entered OTP: $enteredOTP');

      DocumentSnapshot otpDoc = await firestore
          .collection('otp_verifications')
          .doc(verificationId)
          .get();

      if (!otpDoc.exists) {
        debugPrint('OTP document does not exist');
        return {'success': false, 'message': 'Invalid verification code'};
      }

      Map<String, dynamic> data = otpDoc.data() as Map<String, dynamic>;
      debugPrint('OTP document data: $data');

      // Check if OTP is expired
      Timestamp expiresAt = data['expiresAt'];
      if (DateTime.now().isAfter(expiresAt.toDate())) {
        debugPrint('OTP has expired');
        return {'success': false, 'message': 'OTP has expired'};
      }

      // Check if already verified
      if (data['isVerified'] == true) {
        debugPrint('OTP already verified');
        return {'success': false, 'message': 'OTP already used'};
      }

      // Check attempts
      int attempts = data['attempts'] ?? 0;
      if (attempts >= 3) {
        debugPrint('Too many attempts');
        return {'success': false, 'message': 'Too many failed attempts'};
      }

      // Increment attempts
      await firestore
          .collection('otp_verifications')
          .doc(verificationId)
          .update({'attempts': attempts + 1});

      // Verify OTP
      String storedOTP = data['otp'];
      debugPrint('Stored OTP: $storedOTP');

      if (storedOTP == enteredOTP) {
        // Mark as verified
        await firestore
            .collection('otp_verifications')
            .doc(verificationId)
            .update({
          'isVerified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
        });

        // Update user verification status
        String phoneNumber = data['phoneNumber'];
        QuerySnapshot userQuery = await firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: phoneNumber)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          await firestore
              .collection('users')
              .doc(userQuery.docs.first.id)
              .update({
            'isPhoneVerified': true,
            'verifiedAt': FieldValue.serverTimestamp(),
          });
        }

        debugPrint('OTP verification successful');
        return {'success': true, 'message': 'Phone number verified successfully'};
      }

      debugPrint('OTP verification failed - incorrect OTP');
      return {'success': false, 'message': 'Incorrect OTP'};
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return {'success': false, 'message': 'Verification failed. Please try again.'};
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),

              // Title
              const Text(
                'Enter your phone number',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Subtitle
              const Text(
                'We Will send an OTP to verify your\nnumber',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 80),

              // Phone number input container
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Country code dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCountryCode,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey,
                            size: 20,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                          dropdownColor: Colors.white,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCountryCode = newValue;
                              });
                            }
                          },
                          items: _countryCodes.map<DropdownMenuItem<String>>(
                                (Map<String, String> country) {
                              return DropdownMenuItem<String>(
                                value: country['code'],
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      country['flag']!,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(country['code']!),
                                  ],
                                ),
                              );
                            },
                          ).toList(),
                        ),
                      ),
                    ),

                    // Divider
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey.withOpacity(0.3),
                    ),

                    // Phone icon
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(
                        Icons.phone_outlined,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),

                    // Phone number input
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Phone Number',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 16,
                          ),
                        ),
                        onSubmitted: (_) => _sendOTP(),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Send OTP Button
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: const Color(0xFF4285F4).withOpacity(0.6),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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