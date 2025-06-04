import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isPasswordVisible = false;
  bool _acceptTerms = false;
  bool _isLoading = false;

  Future<void> register() async {
    if (!_acceptTerms) {
      showErrorDialog("Please accept the Privacy Policy and Terms of Use");
      return;
    }

    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty) {
      showErrorDialog("Please enter your first and last name");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = userCredential.user;
      await user?.updateDisplayName('${_firstNameController.text.trim()} ${_lastNameController.text.trim()}');

      String? fcmToken = await FirebaseMessaging.instance.getToken();

      await FirebaseFirestore.instance.collection('Users').doc(user?.uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': '',
        'fcmToken': fcmToken,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_registered', true);

      Navigator.pushReplacementNamed(
        context,
        '/otp-verification',
        arguments: user?.uid,
      );
    } catch (e) {
      showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const Text('Hey there,', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 8),
              const Text('Create an Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              buildTextField(_firstNameController, 'First Name', Icons.person_outline),
              buildTextField(_lastNameController, 'Last Name', Icons.person_outline),
              buildTextField(_emailController, 'Email', Icons.email_outlined),
              buildPasswordField(),
              buildTermsCheckbox(),
              const SizedBox(height: 20),
              buildRegisterButton(),
              buildSocialLoginButtons(),
              buildLoginLink(),
            ],
          ),
        ),
      ),
    );
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Registration Failed"),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(icon, color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget buildPasswordField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[500]),
          suffixIcon: IconButton(
            icon: Icon(_isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey[500]),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            setState(() {
              _acceptTerms = value ?? false;
            });
          },
          activeColor: const Color(0xFF4285F4),
        ),
        Expanded(
          child: Text(
            'By continuing you accept our Privacy Policy and Terms of Use.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : register,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4285F4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
          'Register',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget buildSocialLoginButtons() {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Text('or continue with', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.google, color: Color(0xFFDB4437)),
              onPressed: () {
                // TODO: Add Google sign-in
              },
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.facebook, color: Color(0xFF3b5998)),
              onPressed: () {
                // TODO: Add Facebook sign-in
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account?"),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
          child: const Text("Login"),
        ),
      ],
    );
  }
}
