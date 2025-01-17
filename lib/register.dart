import 'package:flutter/material.dart';

import 'auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final authService = AuthService();

  // text controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passcheckController = TextEditingController();

  void signUp() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final passcheck = _passcheckController.text;
    //
    if (password != passcheck) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Password do not match')));
      return;
    }

    //attempt sign up
    try {
      await authService.signUpWithEmailPassword(email, password);
      //Pop this register
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error:$e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 50),
        children: [
          //email
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: "Email"),
          ),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: "Password"),
            obscureText: true,
          ),
          TextField(
            controller: _passcheckController,
            decoration:
            const InputDecoration(labelText: "Enter Password Again"),
            obscureText: true,
          ),

          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: signUp,
            child: const Text('Sign Up'),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
