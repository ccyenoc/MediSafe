import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medisafe/screens/optional_info_page.dart';
import '../colors/color.dart';
import 'email_verification_page.dart';
import 'dart:math';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String generateOTP() {
  final random = Random();
  return (1000 + random.nextInt(9000)).toString();
}

// logic to store the user information data (username , email and password) - not using google
  Future<void> registerUser() async {
  try {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();
    String username = usernameController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    // Check if email already exists
    final methods =
        await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

    if (methods.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email already registered")),
      );
      return;
    }

    // ✅ Create account
    final userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // ✅ Save user data
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({
      'username': username,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ✅ Send verification email
    await userCredential.user!.sendEmailVerification();

    // Navigate to verification waiting screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const EmailVerificationPage(),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              Center(
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage('assets/images/logo.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // App Name
              const Text(
                'MediSafe',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              // Slogan
              const Text(
                'Your medication, made simple',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 40),

              _label('Username'),
              _inputField(
                controller: usernameController,
                hint: 'Enter your username',
                icon: Icons.person,
              ),

              const SizedBox(height: 16),

              _label('Email'),
              _inputField(
                controller: emailController,
                hint: 'Enter your email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              _label('Password'),
              _inputField(
                controller: passwordController,
                hint: 'Enter your password',
                icon: Icons.lock,
                obscureText: true,
              ),

              const SizedBox(height: 16),

              _label('Confirm Password'),
              _inputField(
                controller: confirmPasswordController,
                hint: 'Re-enter your password',
                icon: Icons.lock_outline,
                obscureText: true,
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () async {
                  await registerUser();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade200,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
