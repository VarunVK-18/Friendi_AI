import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';
import 'chat_screen.dart';
import 'package:friendi_ai/Services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Failed to sign in';
      if (e.code == 'user-not-found') msg = 'No user found';
      if (e.code == 'wrong-password') msg = 'Incorrect password';
      if (e.code == 'invalid-email') msg = 'Invalid email';
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
      if (mounted) Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in failed')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email for reset')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send reset email')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildTextField(_emailController, 'Email', false),
                        const SizedBox(height: 20),
                        _buildTextField(_passwordController, 'Password', true),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _resetPassword,
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(color: Color(0xFF534AB7)),
                            ),
                          ),
                        ),
                        _buildRememberMe(),
                        const SizedBox(height: 24),
                        _buildSignInButton(),
                        const SizedBox(height: 24),
                        _buildDivider(),
                        const SizedBox(height: 24),
                        _buildGoogleButton(), // Fixed overflow here
                        const SizedBox(height: 24),
                        _buildSignUpLink(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() =>
      Column(
        children: const [
          Text('Welcome Back',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('Sign in to continue', style: TextStyle(color: Colors.grey)),
        ],
      );

  Widget _buildTextField(TextEditingController controller, String label,
      bool isPassword) =>
      TextFormField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF534AB7), width: 2),
          ),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          )
              : null,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Enter $label';
          if (!isPassword && !value.contains('@')) return 'Enter a valid email';
          if (isPassword && value.length < 6) return 'Min 6 characters';
          return null;
        },
      );

  Widget _buildRememberMe() =>
      Row(
        children: [
          Checkbox(
            value: _rememberMe,
            onChanged: (val) => setState(() => _rememberMe = val ?? false),
            activeColor: const Color(0xFF534AB7),
          ),
          const SizedBox(width: 8),
          const Expanded(
              child: Text('Remember me', style: TextStyle(color: Colors.grey))),
        ],
      );

  Widget _buildSignInButton() =>
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _signIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF534AB7),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Sign In',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,color: Colors.white)),
        ),
      );

  Widget _buildDivider() =>
      Row(
        children: const [
          Expanded(child: Divider(color: Colors.grey)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
                'Or continue with', style: TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Divider(color: Colors.grey)),
        ],
      );

  Widget _buildGoogleButton() =>
      SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton(
          onPressed: _isLoading ? null : _signInWithGoogle,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.grey),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/google_icon.png', width: 20, height: 20),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  'Sign in with Google',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildSignUpLink() =>
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
              'Don\'t have an account?', style: TextStyle(color: Colors.grey)),
          TextButton(
            onPressed: () =>
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SignupScreen())),
            child: const Text('Sign Up', style: TextStyle(
                color: Color(0xFF534AB7), fontWeight: FontWeight.w500,)),
          ),
        ],
      );
}