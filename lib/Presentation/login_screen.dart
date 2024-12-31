import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:usa/Presentation/home_screen.dart';
import 'package:usa/API/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  String? _errorMessage;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _buttonScaleAnimation;

  final double _initialWidth = 300.0;
  final double _finalWidth = 80.0;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initializeUserCredentials();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _buttonScaleAnimation = Tween<double>(begin: _initialWidth, end: _finalWidth).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _initializeUserCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');
    String? password = prefs.getString('password');

    if (username != null && password != null) {
      _usernameController.text = username;
      _passwordController.text = password;

      // Automatically attempt login
      _handleLogin();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final String username = _usernameController.text;
    final String password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    _animationController.forward();

    // Check internet connectivity
    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No internet connection. Please check your settings.';
        });
      }

      // Reset button state after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isLoading = false; // Reset loading state
            _animationController.reverse(); // Reverse animation
            _errorMessage = null; // Clear error message
          });
        }
      });
      return; // Exit early if no connection
    }

    try {
      final Map<String, dynamic> result = await _apiService.login(username, password);

      if (mounted) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>  HomeScreen(),
          ),
        );
      }
    } catch (e) {
      print('Login error: $e');

      if (mounted) {
        setState(() {
          _errorMessage = 'Incorrect Username or Password.'; // A general error message
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _errorMessage = null; // Clear error message after a delay
            });
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Reset loading state after processing
          _animationController.reverse(); // Reverse animation
        });
      }
    }
  }


// Connectivity check function using the http package
  Future<bool> _checkInternetConnection() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  constraints: const BoxConstraints(
                    maxWidth: 150,
                    maxHeight: 150,
                  ),
                  child: SvgPicture.asset(
                    'assets/images/logo.svg',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: const Color(0x13360383)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _usernameController,
                        onTap: () => _usernameController.selection = TextSelection(baseOffset: 0, extentOffset: _usernameController.value.text.length),
                        decoration: InputDecoration(
                          prefixIcon: Transform.scale(
                            scale: 0.5,
                            child: SvgPicture.asset(
                              'assets/images/person.svg',
                              width: 24.0,
                              height: 24.0,
                            ),
                          ),
                          hintText: 'Username',
                          border: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        onTap: () => _passwordController.selection = TextSelection(baseOffset: 0, extentOffset: _passwordController.value.text.length),
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          prefixIcon: Transform.scale(
                            scale: 0.5,
                            child: SvgPicture.asset(
                              'assets/images/lock.svg',
                              width: 24.0,
                              height: 24.0,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: _togglePasswordVisibility,
                          ),
                          hintText: 'Password',
                          border: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: AnimatedBuilder(
                          animation: _buttonScaleAnimation,
                          builder: (context, child) {
                            return Container(
                              width: _isLoading ? _finalWidth : _initialWidth,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF03255D),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                child: _isLoading
                                    ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF00255D),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                                    : const Center(
                                  child: Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: AnimatedOpacity(
                            opacity: _errorMessage == null ? 0 : 1,
                            duration: const Duration(milliseconds: 0),
                            child: _errorMessage != null
                                ? Center(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                                : const SizedBox.shrink(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
