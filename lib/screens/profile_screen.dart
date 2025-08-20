import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/apis.dart';
import '../../helper/dialogs.dart';
import '../../main.dart';
import '../../models/chat_user.dart';
import '../widgets/profile_image.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _image;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '', // Leave empty for mobile apps
    scopes: <String>['email', 'profile'],
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile Screen')),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FloatingActionButton.extended(
            backgroundColor: Colors.redAccent,
            onPressed: () async {
              Dialogs.showLoading(context);
              await APIs.updateActiveStatus(false);

              // Sign out from Firebase and Google
              try {
                await APIs.auth.signOut();
                await _googleSignIn.signOut();

                Navigator.pop(context); // Hide loading
                Navigator.pop(context); // Pop profile screen

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              } catch (e) {
                Navigator.pop(context); // Hide loading
                log('Logout error: $e');
                if (mounted) {
                  Dialogs.showSnackbar(context, 'Logout failed. Please try again.');
                }
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(width: mq.width, height: mq.height * .03),

                  // User profile picture
                  Stack(
                    children: [
                      _image != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.all(
                          Radius.circular(mq.height * .1),
                        ),
                        child: Image.file(
                          File(_image!),
                          width: mq.height * .2,
                          height: mq.height * .2,
                          fit: BoxFit.cover,
                        ),
                      )
                          : ProfileImage(
                        size: mq.height * .2,
                        url: widget.user.image,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: MaterialButton(
                          elevation: 1,
                          onPressed: _showBottomSheet,
                          shape: const CircleBorder(),
                          color: Colors.white,
                          child: const Icon(Icons.edit, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: mq.height * .03),
                  Text(
                    widget.user.email,
                    style: const TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                  SizedBox(height: mq.height * .05),

                  // Name input field
                  TextFormField(
                    initialValue: widget.user.name,
                    onSaved: (val) => APIs.me.name = val ?? '',
                    validator: (val) =>
                    val != null && val.isNotEmpty ? null : 'Required Field',
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      hintText: 'eg. Harry Potter',
                      label: Text('Name'),
                    ),
                  ),

                  SizedBox(height: mq.height * .02),

                  // About input field
                  TextFormField(
                    initialValue: widget.user.about,
                    onSaved: (val) => APIs.me.about = val ?? '',
                    validator: (val) =>
                    val != null && val.isNotEmpty ? null : 'Required Field',
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.info_outline, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      hintText: 'eg. Good Job',
                      label: Text('About'),
                    ),
                  ),

                  SizedBox(height: mq.height * .05),

                  // Update profile button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      minimumSize: Size(mq.width * .5, mq.height * .06),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        APIs.updateUserInfo().then((value) {
                          Dialogs.showSnackbar(
                            context,
                            'Profile Updated Successfully!',
                          );
                        });
                      }
                    },
                    icon: const Icon(Icons.edit, size: 28),
                    label: const Text('UPDATE', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(
            top: mq.height * .03,
            bottom: mq.height * .05,
          ),
          children: [
            const Text(
              'Pick Profile Picture',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: mq.height * .02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Pick from gallery
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    fixedSize: Size(mq.width * .3, mq.height * .15),
                  ),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (image != null && mounted) {
                      log('Image Path: ${image.path}');
                      setState(() {
                        _image = image.path;
                      });
                      APIs.updateProfilePicture(File(_image!));
                      Navigator.pop(context);
                    }
                  },
                  child: Image.asset('assets/images/add_image.png'),
                ),

                // Take picture from camera
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    fixedSize: Size(mq.width * .3, mq.height * .15),
                  ),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 80,
                    );
                    if (image != null && mounted) {
                      log('Image Path: ${image.path}');
                      setState(() {
                        _image = image.path;
                      });
                      APIs.updateProfilePicture(File(_image!));
                      Navigator.pop(context);
                    }
                  },
                  child: Image.asset('assets/images/camera.png'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}