import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Firestore import add kiya
import 'package:babyshophub/User/homescreen.dart';
import 'package:babyshophub/User/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:babyshophub/Admin/admin_console.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool obscurePass = true;

  Future loginUser() async {
    try {
      setState(() => loading = true);

      // 1. Firebase Auth se user ko sign in karein
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      String uid = userCredential.user!.uid;
      String email = userCredential.user!.email!.trim();

      // 2. Agar admin account hai, toh direct redirect karein
      if (email == "admin@gmail.com") {
        setState(() => loading = false);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminConsole()),
          (route) => false,
        );
        return; // Code yahan rok dein
      }

      // 3. Regular user ke liye Firestore se 'isBlocked' status check karein
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>? ?? {};
        bool isBlocked = data['isBlocked'] ?? false;

        // Agar user blocked hai, toh auth se nikal dein aur login cancel karein
        if (isBlocked) {
          await FirebaseAuth.instance.signOut(); // Force sign out
          setState(() => loading = false);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Your account has been suspended by the administrator.",
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }
      }

      // 4. Agar user blocked nahi hai, toh homescreen par bhejien
      setState(() => loading = false);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => homescreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  InputDecoration fieldStyle(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF8B6B4A)),
      filled: true,
      fillColor: const Color(0xFFFFFBF5),
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFBF5), Color(0xFFF3E5D0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF5),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// BANNER
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          "images/banner.jpeg",
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: const Color(0xFFF3E5D0),
                              child: const Center(
                                child: Icon(
                                  Icons.baby_changing_station,
                                  size: 50,
                                  color: Color(0xFF8B6B4A),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// TITLE
                      const Text(
                        "Welcome Back",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D4037),
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        "Login to BabyShopHub",
                        style: TextStyle(
                          color: Color(0xFF8D6E63),
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 25),

                      /// EMAIL
                      TextField(
                        controller: emailController,
                        decoration: fieldStyle(
                          "Email Address",
                          Icons.email_outlined,
                        ),
                      ),

                      const SizedBox(height: 14),

                      /// PASSWORD
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePass,
                        decoration: fieldStyle("Password", Icons.lock_outline)
                            .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePass
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: const Color(0xFF8B6B4A),
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscurePass = !obscurePass;
                                  });
                                },
                              ),
                            ),
                      ),

                      const SizedBox(height: 25),

                      /// LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: loading ? null : loginUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B6B4A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// REGISTER LINK
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Don't have an account? Register",
                          style: TextStyle(
                            color: Color(0xFF8B6B4A),
                            fontWeight: FontWeight.w600,
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
