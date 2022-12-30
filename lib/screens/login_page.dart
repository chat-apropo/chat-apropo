import 'package:chat_apropo/screens/register_page.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _nickname;
  String? _password;
  String? _passwordConfirmation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Container(
        color: const Color(0xfff0f0f0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    width: 172,
                    height: 172,
                  ),
                  const Text(
                    "Welcome to GasconChat!",
                    style: TextStyle(
                      color: Color(0xff0659fd),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 48.0),
                  const Text(
                    'Login into your existing account',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    decoration: buildInputDecoration('Nickname'),
                    validator: validateNickname,
                    onSaved: (value) => _nickname = value,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    decoration: buildInputDecoration('Password'),
                    obscureText: true,
                    validator: validatePassword,
                    onSaved: (value) => _password = value,
                  ),
                  const SizedBox(height: 32.0),
                  Container(
                    width: double.infinity,
                    height: 48.0,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 20),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(32.0)),
                        ),
                      ),
                      onPressed: () {
                        _formKey.currentState?.save();
                        if (_formKey.currentState?.validate() ?? false) {
                          print(
                              '$_nickname, $_password, $_passwordConfirmation');
                        }
                      },
                      child: const Text("Login"),
                    ),
                  ),
                  LoginSwitchRow(
                    builder: (context) => SignUpScreen(),
                    question: 'Don\'t have an account?',
                    buttonText: 'Sign up',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
