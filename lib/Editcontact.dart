import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditContact extends StatefulWidget {
  final String currentName;
  final List<String> currentPhone;
  final List<String> currentEmail;
  final List<String> currentUrl;
  final String? currentPhoto;
  final Function(Map<String, dynamic>) onSave;

  const EditContact({
    super.key,
    required this.currentName,
    required this.currentPhone,
    required this.currentEmail,
    required this.currentUrl,
    this.currentPhoto,
    required this.onSave,
  });

  @override
  State<EditContact> createState() => _EditContactState();
}

class _EditContactState extends State<EditContact> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  List<TextEditingController> _phoneControllers = [];
  List<TextEditingController> _emailControllers = [];
  List<TextEditingController> _urlControllers = [];

  File? _image;

  @override
  void initState() {
    super.initState();
    final fullNameParts = widget.currentName.split(' ');
    _firstNameController = TextEditingController(
        text: fullNameParts.isNotEmpty ? fullNameParts.first : '');
    _lastNameController = TextEditingController(
        text: fullNameParts.length > 1 ? fullNameParts.sublist(1).join(' ') : '');

    for (var phone in widget.currentPhone) {
      _phoneControllers.add(TextEditingController(text: phone));
    }
    if (_phoneControllers.isEmpty) {
      _phoneControllers.add(TextEditingController());
    }

    for (var email in widget.currentEmail) {
      _emailControllers.add(TextEditingController(text: email));
    }
    if (_emailControllers.isEmpty) {
      _emailControllers.add(TextEditingController());
    }

    for (var url in widget.currentUrl) {
      _urlControllers.add(TextEditingController(text: url));
    }
    if (_urlControllers.isEmpty) {
      _urlControllers.add(TextEditingController());
    }

    if (widget.currentPhoto != null && widget.currentPhoto!.isNotEmpty) {
      _image = File(widget.currentPhoto!);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    for (var controller in _emailControllers) {
      controller.dispose();
    }
    for (var controller in _urlControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  String _formatPhoneNumber(String value) {
    String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length > 11) {
      digitsOnly = digitsOnly.substring(0, 11);
    }
    if (digitsOnly.length >= 4) {
      return '(${digitsOnly.substring(0, 4)}) ${digitsOnly.substring(4)}';
    }
    return digitsOnly;
  }

  Widget _buildAddField(List<TextEditingController> controllers, String label, IconData icon,
      {required int index, required VoidCallback onRemove, TextInputType? keyboardType,
        Function(String)? onChanged}) {
    final controller = controllers[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: label,
              prefix: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(icon, color: CupertinoColors.activeGreen),
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.darkBackgroundGray,
                borderRadius: BorderRadius.circular(10),
              ),
              keyboardType: keyboardType,
              onChanged: onChanged,
            ),
          ),
          if (controllers.length > 1)
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(CupertinoIcons.minus_circle_fill,
                  color: CupertinoColors.systemRed),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onPressed) {
    return CupertinoButton(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(CupertinoIcons.add_circled_solid,
              color: CupertinoColors.activeGreen),
          SizedBox(width: 8),
          Text('add $label', style: TextStyle(color: CupertinoColors.activeBlue)),
        ],
      ),
      onPressed: onPressed,
    );
  }

  void _addPhoneField() {
    setState(() {
      _phoneControllers.add(TextEditingController());
    });
  }

  void _removePhoneField(int index) {
    setState(() {
      if (_phoneControllers.length > 1) {
        _phoneControllers.removeAt(index);
      }
    });
  }

  void _addEmailField() {
    setState(() {
      _emailControllers.add(TextEditingController());
    });
  }

  void _removeEmailField(int index) {
    setState(() {
      if (_emailControllers.length > 1) {
        _emailControllers.removeAt(index);
      }
    });
  }

  void _addUrlField() {
    setState(() {
      _urlControllers.add(TextEditingController());
    });
  }

  void _removeUrlField(int index) {
    setState(() {
      if (_urlControllers.length > 1) {
        _urlControllers.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        middle: Text('Edit Contact',
            style: TextStyle(color: CupertinoColors.white)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text('Cancel',
              style: TextStyle(color: CupertinoColors.activeBlue)),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text('Done',
              style: TextStyle(color: CupertinoColors.activeBlue)),
          onPressed: () {
            final firstName = _firstNameController.text.trim();
            final lastName = _lastNameController.text.trim();
            final phoneNumbers = _phoneControllers
                .map((controller) => _formatPhoneNumber(controller.text.trim()))
                .where((number) => number.isNotEmpty) // Don't add blank numbers
                .toList();
            final emailAddresses = _emailControllers
                .map((controller) => controller.text.trim())
                .where((email) => email.isNotEmpty) // Don't add blank emails
                .toList();
            final urls = _urlControllers
                .map((controller) => controller.text.trim())
                .where((url) => url.isNotEmpty) // Don't add blank URLs
                .toList();

            if (firstName.isNotEmpty || lastName.isNotEmpty || phoneNumbers.isNotEmpty || emailAddresses.isNotEmpty || urls.isNotEmpty) {
              widget.onSave({
                'name': '$firstName $lastName'.trim(),
                'phone': phoneNumbers,
                'email': emailAddresses,
                'url': urls,
                'photo': _image?.path ?? widget.currentPhoto ?? '',
              });
              Navigator.pop(context);
            } else {
              // Optionally show a warning message if no data was entered
              showCupertinoDialog(
                context: context,
                builder: (BuildContext context) => CupertinoAlertDialog(
                  title: const Text('Warning'),
                  content: const Text('Please enter at least one contact detail.'),
                  actions: <CupertinoDialogAction>[
                    CupertinoDialogAction(
                      child: const Text('OK'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    _image == null
                        ? Icon(CupertinoIcons.person_circle_fill,
                        size: 120, color: CupertinoColors.systemGrey)
                        : CircleAvatar(
                      radius: 60,
                      backgroundImage: FileImage(_image!),
                    ),
                    if (_image == null)
                      Positioned(
                        bottom: -10,
                        child: CupertinoButton(
                          child: Text('Add Photo',
                              style: TextStyle(
                                  fontSize: 15,
                                  color: CupertinoColors.activeBlue)),
                          onPressed: _pickImage,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              CupertinoTextField(
                controller: _firstNameController,
                placeholder: 'First Name',
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.darkBackgroundGray,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 12),
              CupertinoTextField(
                controller: _lastNameController,
                placeholder: 'Last Name',
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.darkBackgroundGray,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 16),
              for (var i = 0; i < _phoneControllers.length; i++)
                _buildAddField(
                  _phoneControllers,
                  'phone',
                  CupertinoIcons.phone_fill,
                  index: i,
                  onRemove: () => _removePhoneField(i),
                  keyboardType: TextInputType.phone,
                  onChanged: (value) {
                    _phoneControllers[i].value = TextEditingValue(
                      text: _formatPhoneNumber(value),
                      selection: TextSelection.collapsed(offset: _formatPhoneNumber(value).length),
                    );
                  },
                ),
              _buildAddButton('phone', _addPhoneField),
              SizedBox(height: 12),
              for (var i = 0; i < _emailControllers.length; i++)
                _buildAddField(_emailControllers, 'email',
                    CupertinoIcons.mail_solid, index: i, onRemove: () => _removeEmailField(i),
                    keyboardType: TextInputType.emailAddress),
              _buildAddButton('email', _addEmailField),
              SizedBox(height: 12),
              for (var i = 0; i < _urlControllers.length; i++)
                _buildAddField(_urlControllers, 'url',
                    CupertinoIcons.link, index: i, onRemove: () => _removeUrlField(i),
                    keyboardType: TextInputType.url),
              _buildAddButton('url', _addUrlField),
            ],
          ),
        ),
      ),
    );
  }
}