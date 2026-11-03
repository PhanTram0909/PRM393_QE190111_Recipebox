import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _submitted = false;
  bool _isLoading = false;
  String? _firebaseError;
  String? _successMessage;

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w\.-]+@[\w-]+\.[\w-]{2,}$');
    return emailRegex.hasMatch(email.trim());
  }

  String? get _emailError {
    if (!_submitted) return null;
    final text = _emailController.text;
    if (text.isEmpty) {
      return 'Email is required';
    }
    if (!_isValidEmail(text)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? get _passwordError {
    if (!_submitted) return null;
    final text = _passwordController.text;
    if (text.isEmpty) {
      return 'Password is required';
    }
    if (text.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? get _confirmPasswordError {
    if (!_submitted) return null;
    final text = _confirmPasswordController.text;
    if (text.isEmpty) {
      return 'Confirm password is required';
    }
    if (text != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    setState(() {
      _submitted = true;
      _firebaseError = null;
      _successMessage = null;
    });

    if (_emailError != null ||
        _passwordError != null ||
        _confirmPasswordError != null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.registerWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _successMessage = 'Registration successful';
          _isLoading = false;
        });

        // Delay briefly so the user sees "Registration successful" before transitioning
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _firebaseError = e.message ?? 'Registration failed. Please try again.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _firebaseError = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Register',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sign up to start saving and organizing your recipes',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 28),

              // Email Field
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'name@example.com',
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
                onChanged: (_) {
                  if (_submitted) setState(() {});
                },
              ),
              const SizedBox(height: 18),

              // Password Field
              CustomTextField(
                controller: _passwordController,
                label: 'Password',
                hint: 'At least 6 characters',
                obscureText: true,
                errorText: _passwordError,
                onChanged: (_) {
                  if (_submitted) setState(() {});
                },
              ),
              const SizedBox(height: 18),

              // Confirm Password Field
              CustomTextField(
                controller: _confirmPasswordController,
                label: 'Confirm password',
                hint: 'Re-enter your password',
                obscureText: true,
                errorText: _confirmPasswordError,
                onChanged: (_) {
                  if (_submitted) setState(() {});
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 1,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              // Registration Successful Message
              if (_successMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Text(
                    _successMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              // Firebase Error below submit button
              if (_firebaseError != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _firebaseError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
