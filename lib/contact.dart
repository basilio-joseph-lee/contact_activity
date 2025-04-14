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