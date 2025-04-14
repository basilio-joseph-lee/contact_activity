import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Editcontact.dart';

class Contact extends StatefulWidget {
  final Map<String, dynamic> contactData;
  final Function(Map<String, dynamic>) onContactUpdated;

  const Contact({
    super.key,
    required this.contactData,
    required this.onContactUpdated,
  });

  @override
  State<Contact> createState() => _ContactState();
}

class _ContactState extends State<Contact> {
  late String _name;
  late List<String> _phone;
  late List<String> _url;
  late List<String> _email;
  late String _photo;
  final String _defaultPhoto = "https://cdn.ebaumsworld.com/mediaFiles/picture/1151541/84693449.png";

  @override
  void initState() {
    super.initState();
    _name = widget.contactData['name'] ?? '';
    _phone = (widget.contactData['phone'] is String)
        ? [widget.contactData['phone'] ?? '']
        : (widget.contactData['phone'] is List ? List<String>.from(widget.contactData['phone']) : []);
    _url = (widget.contactData['url'] is String)
        ? [widget.contactData['url'] ?? '']
        : (widget.contactData['url'] is List ? List<String>.from(widget.contactData['url']) : []);
    _email = (widget.contactData['email'] is String)
        ? [widget.contactData['email'] ?? '']
        : (widget.contactData['email'] is List ? List<String>.from(widget.contactData['email']) : []);
    _photo = widget.contactData['photo'] ?? _defaultPhoto;
  }

  ImageProvider getImageProvider(String path) {
    if (path.startsWith('http')) {
      return NetworkImage(path);
    } else {
      final file = File(path);
      if (file.existsSync()) {
        return FileImage(file);
      } else {
        return NetworkImage(_defaultPhoto);
      }
    }
  }

  Future<String?> _showActionSheet(BuildContext context, List<String> items, String title) async {
    return await showCupertinoModalPopup<String>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(title),
        actions: <CupertinoActionSheetAction>[
          for (var item in items)
            CupertinoActionSheetAction(
              child: Text(item),
              onPressed: () {
                Navigator.pop(context, item);
              },
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context, null);
          },
        ),
      ),
    );
  }

  Future<void> _launchSMS(BuildContext context) async {
    String? selected = _phone.length == 1
        ? _phone[0]
        : await _showActionSheet(context, _phone, 'Select a number to message');
    if (selected != null) {
      await launchUrl(Uri.parse('sms:$selected'));
    }
  }

  Future<void> _launchCall(BuildContext context) async {
    String? selected = _phone.length == 1
        ? _phone[0]
        : await _showActionSheet(context, _phone, 'Select a number to call');
    if (selected != null) {
      await launchUrl(Uri.parse('tel:$selected'));
    }
  }

  Future<void> _launchMail(BuildContext context) async {
    String? selected = _email.length == 1
        ? _email[0]
        : await _showActionSheet(context, _email, 'Select an email to send to');
    if (selected != null) {
      await launchUrl(Uri.parse('mailto:$selected'));
    }
  }

  // Helper function to apply a subtle shadow effect
  Widget _buildButtonWithShadow({required Widget child, required VoidCallback onPressed}) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      color: CupertinoColors.transparent,
      onPressed: onPressed,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.1), // Subtle shadow
              spreadRadius: 1,
              blurRadius: 2,
              offset: Offset(0, 1), // Offset slightly downwards
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = screenWidth / 4 - 12; // Adjust spacing as needed

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Removed the top Padding widget

              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: getImageProvider(_photo),
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Removed the alignment and padding that might have displayed the name
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _buildButtonWithShadow(
                      onPressed: () => Navigator.pop(context),
                      child: Icon(CupertinoIcons.back, color: CupertinoColors.white),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _buildButtonWithShadow(
                      onPressed: () async {
                        final updatedData = await Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => EditContact(
                              currentName: _name,
                              currentPhone: _phone,
                              currentEmail: _email,
                              currentUrl: _url,
                              currentPhoto: _photo,
                              onSave: (updatedContact) {
                                widget.onContactUpdated(updatedContact);
                                setState(() {
                                  _name = updatedContact['name'] ?? '';
                                  _phone = updatedContact['phone'] is String
                                      ? [updatedContact['phone'] ?? '']
                                      : List<String>.from(updatedContact['phone'] ?? []);
                                  _email = updatedContact['email'] is String
                                      ? [updatedContact['email'] ?? '']
                                      : List<String>.from(updatedContact['email'] ?? []);
                                  _url = updatedContact['url'] is String
                                      ? [updatedContact['url'] ?? '']
                                      : List<String>.from(updatedContact['url'] ?? []);
                                  _photo = updatedContact['photo'] ?? _photo;
                                });
                              },
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                                   Positioned(
                    bottom: 80, // Adjust position above the buttons
                    child: Text(
                      _name,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 2.0,
                            color: CupertinoColors.black.withOpacity(0.3),
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        buildActionButton(
                          icon: CupertinoIcons.bubble_left_bubble_right_fill,
                          label: "message",
                          onTap: () => _launchSMS(context),
                          size: buttonSize,
                          labelTextStyle: TextStyle( // Apply shadow to the label
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: CupertinoColors.systemGrey2,
                            shadows: [
                              Shadow(
                                blurRadius: 1.0,
                                color: CupertinoColors.black.withOpacity(0.3),
                                offset: Offset(0, 0.5),
                              ),
                            ],
                          ),
                        ),
                        buildActionButton(
                          icon: CupertinoIcons.phone_fill,
                          label: "call",
                          onTap: () => _launchCall(context),
                          size: buttonSize,
                          labelTextStyle: TextStyle( // Apply shadow to the label
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: CupertinoColors.systemGrey2,
                            shadows: [
                              Shadow(
                                blurRadius: 1.0,
                                color: CupertinoColors.black.withOpacity(0.3),
                                offset: Offset(0, 0.5),
                              ),
                            ],
                          ),
                        ),
                        buildActionButton(
                          icon: CupertinoIcons.video_camera_solid,
                          label: "video",
                          onTap: () {},
                          size: buttonSize,
                          labelTextStyle: TextStyle( // Apply shadow to the label
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: CupertinoColors.systemGrey2,
                            shadows: [
                              Shadow(
                                blurRadius: 1.0,
                                color: CupertinoColors.black.withOpacity(0.3),
                                offset: Offset(0, 0.5),
                              ),
                            ],
                          ),
                        ),
                        buildActionButton(
                          icon: CupertinoIcons.mail_solid,
                          label: "mail",
                          onTap: () => _launchMail(context),
                          size: buttonSize,
                          labelTextStyle: TextStyle( // Apply shadow to the label
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: CupertinoColors.systemGrey2,
                            shadows: [
                              Shadow(
                                blurRadius: 1.0,
                                color: CupertinoColors.black.withOpacity(0.3),
                                offset: Offset(0, 0.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),

              SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_phone.isNotEmpty)
                      for (var phone in _phone)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: buildContactInfoTile(
                            label: 'mobile',
                            value: phone,
                            onTap: () => launchUrl(Uri.parse('tel:$phone')),
                          ),
                        ),
                    if (_email.isNotEmpty)
                      for (var email in _email)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: buildContactInfoTile(
                            label: 'home',
                            value: email,
                            onTap: () => launchUrl(Uri.parse('mailto:$email')),
                          ),
                        ),
                    if (_url.isNotEmpty)
                      for (var url in _url)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: buildContactInfoTile(
                            label: 'url',
                            value: url,
                            onTap: () async {
                              if (url.startsWith('http') || url.startsWith('https')) {
                                await launchUrl(Uri.parse(url));
                              } else {
                                await launchUrl(Uri.parse('http://$url'));
                              }
                            },
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    double? size,
    TextStyle? labelTextStyle, // Added optional TextStyle for the label
  }) {
    return Container(
      width: size,
      child: Column(
        children: [
          CupertinoButton(
            padding: EdgeInsets.all(10),
            color: CupertinoColors.systemGrey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
            child: Icon(icon, color: CupertinoColors.white),
            onPressed: onTap,
          ),
          SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: labelTextStyle ?? TextStyle( // Use provided style or default
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: CupertinoColors.systemGrey2,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildContactInfoTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(15, 8, 15, 8),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: CupertinoColors.systemGrey.withOpacity(0.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemGrey,
                )),
            SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.systemBlue,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}