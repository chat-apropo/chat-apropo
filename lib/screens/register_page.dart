import 'package:chat_apropo/ircClient.dart';
import 'package:chat_apropo/utils.dart';
import 'package:flutter/material.dart';

String? validateNickname(String? value) {
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

/// Check with nickserv if the nickname is already taken
Future<String?> validateNicknameInServer(String? nickname, IrcClient irc) async {
  String? message;
  irc.client.sendMessage('nickserv', 'info $nickname');
  await for (final event in irc.client.onMessage) {
    var response = event.message!.toLowerCase();
    var fromNick = event.from!.name!.toLowerCase();
    if (fromNick == 'nickserv') {
      if (response.contains('isn\'t registered.')) {
        message = null;
        break;
      }
      if (response.contains('${nickname!.toLowerCase()} is ')) {
        message = 'Sorry, this nickname is already taken';
        break;
      }
    }
  }
  return message;
}

String? validatePassword(String? value) {
  if (value?.isEmpty ?? true) {
    return 'Please enter a password';
  }
  if (value!.length < 8) {
    return 'Password must be at least 8 characters';
  }
  return null;
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
            style: const TextStyle(
              color: Color(0xff0659fd),
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

class SignUpScreen extends StatefulWidget {
  final bool login;
  const SignUpScreen({super.key, this.login = false});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _nicknameSignupErr;
  String? _nickname;
  String? _password;
  String? _passwordConfirmation;

  var irc = IrcClient();

  @override
  void initState() {
    super.initState();
    var client = IrcClient();
    client.connect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.login ? 'Login' : 'Sign Up'),
      ),
      body: Container(
        color: const Color(0xfff8f8f8),
        width: double.infinity,
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: _formKey,
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: 500,
                    minWidth: 300,
                    maxHeight: MediaQuery.of(context).size.height,
                    maxWidth: 1200,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      Text(
                        widget.login
                            ? 'Login into your existing account'
                            : 'Create your Account',
                        style: const TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        decoration: buildInputDecoration('Nickname'),
                        validator: (value) {
                          validateNickname(value);
                          if (widget.login) {
                            return null;
                          }
                          return _nicknameSignupErr;
                        },
                        onSaved: (value) => _nickname = value,
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        decoration: buildInputDecoration('Password'),
                        obscureText: true,
                        validator: validatePassword,
                        onSaved: (value) => _password = value,
                      ),
                      ...(widget.login
                          ? []
                          : [
                              const SizedBox(height: 16.0),
                              TextFormField(
                                decoration:
                                    buildInputDecoration('Confirm Password'),
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
                                onSaved: (value) =>
                                    _passwordConfirmation = value,
                              ),
                            ]),
                      const SizedBox(height: 32.0),
                      SizedBox(
                        width: double.infinity,
                        height: 48.0,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(fontSize: 20),
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(32.0)),
                            ),
                          ),
                          onPressed: () async {
                            _formKey.currentState?.save();
                            _nicknameSignupErr = null;
                            if (_formKey.currentState?.validate() ?? false) {
                              if (widget.login) {
                                print(
                                    'Logging in with: $_nickname, $_password');
                              } else {
                                _nicknameSignupErr = await validateNicknameInServer(_nickname, irc);
                                if (_nicknameSignupErr != null) {
                                  _formKey.currentState?.validate();
                                  return;
                                }
                                print(
                                    'singing up with: $_nickname, $_password, $_passwordConfirmation');
                              }
                            }
                          },
                          child: Text(widget.login ? "Login" : "Sign Up"),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      widget.login
                          ? LoginSwitchRow(
                              builder: (context) => const SignUpScreen(),
                              question: 'Don\'t have an account?',
                              buttonText: 'Sign up',
                            )
                          : LoginSwitchRow(
                              builder: (context) => const LoginScreen(),
                              question: 'Already have an account?',
                              buttonText: 'Log In',
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

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SignUpScreen(login: true);
  }
}
