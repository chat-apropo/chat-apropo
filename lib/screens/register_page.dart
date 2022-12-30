import 'package:chat_apropo/screens/login_page.dart';
import 'package:flutter/material.dart';

String? validateNickname(value) {
  if (value?.isEmpty ?? true) {
    return 'Please enter a nickname';
  }
  // Validate with regex for a valid nickname
  const irc_nick_re = r"^[a-z][a-z0-9]{2,}$";
  if (!RegExp(irc_nick_re, caseSensitive: false).hasMatch(value!)) {
    return 'Sorry, this nickname is not valid';
  }
  return null;
}

String? validatePassword(value) {
  if (value?.isEmpty ?? true) {
    return 'Please enter a password';
  }
  if (value!.length < 8) {
    return 'Password must be at least 8 characters';
  }
  return null;
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _nickname;
  String? _password;
  String? _passwordConfirmation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
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
                    'Create your Account',
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
                  const SizedBox(height: 16.0),
                  TextFormField(
                    decoration: buildInputDecoration('Confirm Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter a password';
                      }
                      if (value != _password) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    onSaved: (value) => _passwordConfirmation = value,
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
                      child: const Text("Sign Up"),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  LoginSwitchRow(
                    builder: (context) => LoginScreen(),
                    question: 'Already have an account?',
                    buttonText: 'Log In',
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

class LoginSwitchRow extends StatelessWidget {
  final Widget Function(BuildContext) builder;
  final String question;
  final String buttonText;
  const LoginSwitchRow({
    Key? key,
    required this.builder,
    required this.question,
    required this.buttonText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(question),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: builder,
              ),
            );
          },
          child: Text(
            buttonText,
            style: TextStyle(
              color: const Color(0xff0659fd),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

InputDecoration buildInputDecoration(String labelText) {
  return InputDecoration(
    labelText: labelText,
    border: const OutlineInputBorder(),
    filled: true,
    fillColor: Colors.white,
  );
}
