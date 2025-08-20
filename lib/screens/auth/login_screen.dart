import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../api/apis.dart';
import '../../helper/dialogs.dart';
import '../../main.dart';
import '../home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isAnimate = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '', // Leave empty for mobile apps, required for web
    scopes: <String>['email', 'profile'],
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() => _isAnimate = true);
    });
  }

  void _handleGoogleBtnClick() {
    Dialogs.showLoading(context);
    _signInWithGoogle().then((user) async {
      Navigator.pop(context);
      if (user != null) {
        log('\nUser: ${user.user}');
        log('\nUserAdditionalInfo: ${user.additionalUserInfo}');

        if (await APIs.userExists() && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          await APIs.createUser().then((value) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          });
        }
      }
    });
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      // Check internet
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        if (mounted) {
          Dialogs.showSnackbar(context, 'No Internet Connection!');
        }
        return null;
      }

      // Trigger Google sign-in (NEW API for v7.1.1)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) {
          Dialogs.showSnackbar(context, 'Login cancelled by user');
        }
        return null;
      }

      // Get auth details (NEW API for v7.1.1)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      ) as OAuthCredential;

      // Sign in to Firebase with Google credentials
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on SocketException {
      if (mounted) {
        Dialogs.showSnackbar(context, 'No Internet Connection!');
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        switch (e.code) {
          case 'account-exists-with-different-credential':
            Dialogs.showSnackbar(
              context,
              'Account already exists with a different sign-in method.',
            );
            break;
          case 'invalid-credential':
            Dialogs.showSnackbar(
              context,
              'Invalid credentials. Please try again.',
            );
            break;
          case 'user-disabled':
            Dialogs.showSnackbar(
              context,
              'This user account has been disabled.',
            );
            break;
          case 'operation-not-allowed':
            Dialogs.showSnackbar(
              context,
              'Google sign-in is not enabled. Please contact support.',
            );
            break;
          default:
            Dialogs.showSnackbar(
              context,
              'Auth error: ${e.message ?? "Unknown error"}',
            );
        }
      }
      return null;
    } catch (e) {
      log('\n_signInWithGoogle: $e');
      if (mounted) {
        Dialogs.showSnackbar(context, 'Unexpected error, please try again.');
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.sizeOf(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Welcome to Chit Chat'),
      ),
      body: Stack(
        children: [
          // App logo
          AnimatedPositioned(
            top: mq.height * .15,
            right: _isAnimate ? mq.width * .25 : -mq.width * .5,
            width: mq.width * .5,
            duration: const Duration(seconds: 1),
            child: Image.asset('assets/images/icon.png'),
          ),

          // Google login button
          Positioned(
            bottom: mq.height * .15,
            left: mq.width * .05,
            width: mq.width * .9,
            height: mq.height * .06,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 223, 255, 187),
                shape: const StadiumBorder(),
                elevation: 1,
              ),
              onPressed: _handleGoogleBtnClick,
              icon: Image.asset(
                'assets/images/google.png',
                height: mq.height * .03,
              ),
              label: RichText(
                text: const TextSpan(
                  style: TextStyle(color: Colors.black, fontSize: 16),
                  children: [
                    TextSpan(text: 'Login with '),
                    TextSpan(
                      text: 'Google',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}