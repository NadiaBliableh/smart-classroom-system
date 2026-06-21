import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  static const Color bgColor = Color(0xFF0E1325);
  static const Color cardColor = Color(0xFF1E244A);
  static const Color primaryBlue = Color(0xFF4DA3FF);
  

  Future<void> _handleLogin() async {
    final id = _idController.text.trim();
    final password = _passwordController.text.trim();

    if (id.isEmpty || password.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final docSnapshot =
          await _dbRef.child('doctors').child(id).get();

      if (docSnapshot.exists) {
        final data =
            Map<String, dynamic>.from(docSnapshot.value as Map);
        if (data['passward'].toString() == password) {
          _navigateToHome(data['name'], "Doctor");
          return;
        }
      }

      final adminSnapshot =
          await _dbRef.child('admins').child(id).get();

      if (adminSnapshot.exists) {
        final data =
            Map<String, dynamic>.from(adminSnapshot.value as Map);
        if (data['passward'].toString() == password) {
          _navigateToHome(data['name'], "Admin");
          return;
        }
      }

      _showError("Invalid ID or Password");
    } catch (e) {
      _showError("Connection error");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToHome(String name, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userName', name);
    await prefs.setString('userRole', role);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(userName: name, userRole: role),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: primaryBlue,
                  size: 55,
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                "University Login",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Doctors & Administrators Portal",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 50),
              _buildTextField(
                controller: _idController,
                hint: "Employee ID (D001 / A001)",
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _passwordController,
                hint: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 12,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: bgColor,
                        )
                      : const Text(
                          "LOGIN",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: bgColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 22),
              TextButton(
                onPressed: () {},
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: Icon(icon, color: primaryBlue),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.white30,
                  ),
                  onPressed: () => setState(
                    () => _isPasswordVisible = !_isPasswordVisible,
                  ),
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}