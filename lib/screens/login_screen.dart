import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'home_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isPasswordVisible = false;
  bool _acceptTerms = false;
  bool _isLoading = false;

  Future<void> login() async {
    if (!_acceptTerms) {
      showErrorDialog("Please accept the Privacy Policy and Terms of Use");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception("User authentication failed");
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();

      if (!userDoc.exists) {
        throw Exception("User data not found in Firestore");
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_logged_in', true);
      await prefs.setString('user_email', userDoc['email'] ?? '');
      await prefs.setString('user_firstName', userDoc['firstName'] ?? '');
      await prefs.setString('user_lastName', userDoc['lastName'] ?? '');
      await prefs.setString('user_phoneNumber', userDoc['phoneNumber'] ?? '');

      final bool permissionsGiven = prefs.getBool('permissions_given') ?? false;
      Navigator.pushReplacementNamed(context, permissionsGiven ? '/home' : '/permissions');
    } catch (e) {
      showErrorDialog(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> signInWithGoogle() async {
    showErrorDialog("Google Sign-In not implemented yet");
  }

  Future<void> signInWithFacebook() async {
    showErrorDialog("Facebook Sign-In not implemented yet");
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Login Failed"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
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
              const Text('Login with your email', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              buildTextField(_emailController, 'Email', Icons.email_outlined),
              const SizedBox(height: 16),
              buildPasswordField(),
              buildTermsCheckbox(),
              const SizedBox(height: 40),
              buildLoginButton(),
              const SizedBox(height: 24),
              buildOrDivider(),
              const SizedBox(height: 24),
              buildSocialLoginButtons(),
              const SizedBox(height: 40),
              buildRegisterLink(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
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
      margin: const EdgeInsets.only(top: 16),
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
            icon: Icon(
              _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Colors.grey[500],
            ),
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
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
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
      ),
    );
  }

  Widget buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4285F4),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
            : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget buildOrDivider() {
    return Row(
      children: const [
        Expanded(child: Divider(thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text("or"),
        ),
        Expanded(child: Divider(thickness: 1)),
      ],
    );
  }

  Widget buildSocialLoginButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.google, color: Color(0xFFDB4437)),
          onPressed: signInWithGoogle,
        ),
        const SizedBox(width: 20),
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.facebook, color: Color(0xFF4267B2)),
          onPressed: signInWithFacebook,
        ),
      ],
    );
  }

  Widget buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? "),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          child: const Text(
            "Register",
            style: TextStyle(
              color: Color(0xFF4285F4),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
