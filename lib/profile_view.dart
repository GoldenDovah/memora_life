// ignore_for_file: use_build_context_synchronously
import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter/material.dart';
import 'package:memora_life/firebase_wrapper.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  TextEditingController aboutTextController = TextEditingController();
  String aboutTextPlaceholder = 'Add something interesting about you';

  final String _password = '********';
  bool _isUsernameEditable = false;
  bool _isPasswordEditable = false;
  int _isLoading = -1;
  bool isEditingAbout = false;
  FocusNode _textFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _usernameController.text = FirebaseWrapper.username;
    _passwordController.text = _password;
    _emailController.text = FirebaseWrapper.auth.currentUser!.email!;
    aboutTextController.text = FirebaseWrapper.aboutText;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  void toggleEditPassword() {
    setState(() {
      _isPasswordEditable = !_isPasswordEditable;
    });
  }

  Future<void> toggleEditUsername() async {
    if (_isUsernameEditable) {
      setState(() {
        _isLoading = 0;
      });
      bool usernameUnique =
          await FirebaseWrapper.usernameUnique(_usernameController.text);
      bool AllowUsernameEdit = usernameUnique ||
          _usernameController.text == FirebaseWrapper.username;
      setState(() {
        _isLoading = -1;
      });
      if (AllowUsernameEdit) {
        FirebaseWrapper.updateUsername(_usernameController.text);
        setState(() {
          _isUsernameEditable = !_isUsernameEditable;
        });
      } else {
        ElegantNotification.error(
            width: 100,
            title: const Text(
              "Username Duplicate",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            description: const Text(
              "This username has already been picked. Try another one",
              style: TextStyle(color: Colors.black),
            )).show(context);
      }
    } else {
      setState(() {
        _isUsernameEditable = !_isUsernameEditable;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: FirebaseWrapper.profilePicture.image,
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      Image? placeholderImage =
                          await FirebaseWrapper.uploadPic();
                      if (placeholderImage != null) {
                        setState(() {
                          FirebaseWrapper.profilePicture = placeholderImage;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0, right: 10),
                  child: Container(
                    decoration: isEditingAbout
                        ? BoxDecoration(
                            border: Border.all(
                              color: Colors.grey,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          )
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          flex: 5,
                          child: IntrinsicWidth(
                            child: TextFormField(
                              focusNode: _textFieldFocusNode,
                              maxLines: null,
                              maxLength: 250,
                              minLines: 1,
                              onTap: () {
                                setState(() {
                                  if (isEditingAbout == false) {
                                    isEditingAbout = true;
                                  }
                                });
                                FocusScope.of(context)
                                    .requestFocus(_textFieldFocusNode);
                              },
                              readOnly: !isEditingAbout,
                              controller: aboutTextController,
                              onChanged: (value) {
                                setState(() {
                                  FirebaseWrapper.aboutText = value;
                                });
                              },
                              decoration: const InputDecoration(
                                hintText: 'Add something about yourself',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          child: IconButton(
                            icon: _isLoading == 3
                                ? CircularProgressIndicator()
                                : isEditingAbout
                                    ? const Icon(Icons.check)
                                    : const Icon(Icons.edit),
                            onPressed: () async {
                              setState(() {
                                isEditingAbout = !isEditingAbout;
                              });
                              if (isEditingAbout == false) {
                                setState(() {
                                  _isLoading = 3;
                                });
                                await FirebaseWrapper.saveAboutText(
                                    aboutTextController.text);
                                setState(() {
                                  _isLoading = -1;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextFieldWithLabel(
                    'Username',
                    Icons.person,
                    _usernameController,
                    _isUsernameEditable,
                    toggleEditUsername,
                    0),
                const SizedBox(height: 16),
                _buildTextFieldWithLabel(
                    'Password',
                    Icons.lock,
                    _passwordController,
                    _isPasswordEditable,
                    toggleEditPassword,
                    1),
                const SizedBox(height: 16),
                _buildTextFieldWithLabel(
                    'Email', Icons.email, _emailController, false, null, 2),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextFieldWithLabel(
    String label,
    IconData icon,
    TextEditingController? controller,
    bool isEditable,
    VoidCallback? onToggleEdit,
    int ord,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(icon),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              readOnly: !isEditable,
              decoration: InputDecoration(
                hintText: label,
                border: InputBorder.none,
              ),
            ),
          ),
          if (label != 'Email')
            if (_isLoading == ord)
              const CircularProgressIndicator()
            else if (!isEditable)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onToggleEdit,
              )
            else
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: onToggleEdit,
              )
        ],
      ),
    );
  }
}
