import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Services/auth_service.dart';
import 'chat_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  final AuthService _authService = AuthService();

  bool _loading = false;
  bool _hidePassword = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// EMAIL SIGNUP
  Future<void> _signUp() async {

    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Please accept Terms & Privacy Policy"),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {

      UserCredential credential =
      await _authService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      /// Save username to Firebase profile
      await credential.user?.updateDisplayName(
        _nameController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ChatScreen(),
        ),
      );

    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );

    } finally {

      if (mounted) {
        setState(() => _loading = false);
      }

    }
  }

  /// GOOGLE SIGNUP
  Future<void> _googleSignup() async {

    setState(() => _loading = true);

    try {

      await _authService.signInWithGoogle();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ChatScreen(),
        ),
      );

    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );

    } finally {

      if (mounted) {
        setState(() => _loading = false);
      }

    }
  }

  Widget _inputField(
      TextEditingController controller,
      String label,
      bool isPassword,
      ) {

    return TextFormField(

      controller: controller,

      obscureText:
      isPassword ? _hidePassword : false,

      decoration: InputDecoration(

        labelText: label,

        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
        ),

        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _hidePassword
                ? Icons.visibility_off
                : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _hidePassword =
              !_hidePassword;
            });
          },
        )
            : null,
      ),

      validator: (value) {

        if (value == null ||
            value.trim().isEmpty) {
          return "Enter $label";
        }

        if (label == "Email" &&
            !value.contains("@")) {
          return "Invalid email";
        }

        if (label == "Password" &&
            value.length < 6) {
          return "Minimum 6 characters";
        }

        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(0xFFF6F7FB),

      body: Center(

        child: SingleChildScrollView(

          padding:
          const EdgeInsets.all(24),

          child: ConstrainedBox(

            constraints:
            const BoxConstraints(
                maxWidth: 420),

            child: Card(

              elevation: 8,

              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(22),
              ),

              child: Padding(

                padding:
                const EdgeInsets.all(28),

                child: Form(

                  key: _formKey,

                  child: Column(

                    children: [

                      const Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                          height: 8),

                      const Text(
                        "Sign up to continue",
                        style: TextStyle(
                          color:
                          Colors.grey,
                        ),
                      ),

                      const SizedBox(
                          height: 30),

                      _inputField(
                        _nameController,
                        "Full Name",
                        false,
                      ),

                      const SizedBox(
                          height: 18),

                      _inputField(
                        _emailController,
                        "Email",
                        false,
                      ),

                      const SizedBox(
                          height: 18),

                      _inputField(
                        _passwordController,
                        "Password",
                        true,
                      ),

                      const SizedBox(
                          height: 10),

                      Row(

                        children: [

                          Checkbox(
                            value:
                            _acceptTerms,
                            onChanged:
                                (value) {
                              setState(() {
                                _acceptTerms =
                                    value ??
                                        false;
                              });
                            },
                          ),

                          const Expanded(
                            child: Text(
                              "Accept Terms & Privacy Policy",
                              style:
                              TextStyle(
                                fontSize:
                                13,
                              ),
                            ),
                          ),

                        ],
                      ),

                      const SizedBox(
                          height: 20),

                      SizedBox(

                        width:
                        double.infinity,

                        height: 50,

                        child:
                        ElevatedButton(

                          onPressed:
                          _loading
                              ? null
                              : _signUp,

                          style:
                          ElevatedButton
                              .styleFrom(
                            backgroundColor:
                            const Color(
                                0xFF534AB7),
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                  12),
                            ),
                          ),

                          child: _loading
                              ? const CircularProgressIndicator(
                              color:
                              Colors
                                  .white)
                              : const Text(
                            "Create Account",
                            style:
                            TextStyle(
                              fontSize:
                              16,
                              color:
                              Colors
                                  .white,
                            ),
                          ),

                        ),

                      ),

                      const SizedBox(
                          height: 20),

                      const Text(
                        "OR",
                        style: TextStyle(
                            color:
                            Colors.grey),
                      ),

                      const SizedBox(
                          height: 20),

                      SizedBox(

                        width:
                        double.infinity,

                        height: 50,

                        child:
                        OutlinedButton(

                          onPressed:
                          _loading
                              ? null
                              : _googleSignup,

                          style:
                          OutlinedButton
                              .styleFrom(
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                  12),
                            ),
                          ),

                          child: Row(

                            mainAxisAlignment:
                            MainAxisAlignment
                                .center,

                            children: [

                              Image.asset(
                                "assets/google_icon.png",
                                height: 22,
                              ),

                              const SizedBox(
                                  width:
                                  12),

                              const Text(
                                "Sign up with Google",
                                style:
                                TextStyle(
                                  fontSize:
                                  16,
                                ),
                              ),

                            ],

                          ),

                        ),

                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}