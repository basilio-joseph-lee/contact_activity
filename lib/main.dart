import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'contact.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('database');
  runApp(CupertinoApp(
    theme: CupertinoThemeData(brightness: Brightness.dark),
    debugShowCheckedModeBanner: false,
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var box = Hive.box('database');
  List<Map<String, dynamic>> contacts = [];
  List<Map<String, dynamic>> filteredContacts = [];

  TextEditingController _searchController = TextEditingController();
  TextEditingController _fnameController = TextEditingController();
  TextEditingController _lnameController = TextEditingController();
  List<TextEditingController> _phoneControllers = [];
  List<String?> _phoneLabels = [];
  List<TextEditingController> _emailControllers = [];
  List<String?> _emailLabels = [];
  List<TextEditingController> _urlControllers = [];
  List<String?> _urlLabels = [];
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadContacts();

    // Load saved image path from local storage
    _imagePath = box.get('imagePath', defaultValue: null);

    _searchController.addListener(_filterContacts);
  }


  void _loadContacts() {
    var storedContacts = box.get('contacts');
    if (storedContacts is List) {
      contacts = storedContacts.map((item) {
        if (item is Map) {
          return item.map<String, dynamic>((key, value) {
            return MapEntry(key.toString(), value);
          });
        }
        return <String, dynamic>{};
      }).toList();
      contacts.sort((a, b) => (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase()));
      filteredContacts = List.from(contacts);
    } else {
      contacts = [];
      filteredContacts = [];
    }
  }

  void _filterContacts() {
    setState(() {
      filteredContacts = contacts
          .where((contact) =>
          (contact['name'] as String)
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
      filteredContacts.sort((a, b) => (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase()));
    });
  }

  void _saveContacts() {
    box.put('contacts', contacts);
  }

  bool _isFormValid() {
    final isNameNotEmpty = _fnameController.text.trim().isNotEmpty || _lnameController.text.trim().isNotEmpty;
    final isPhoneNumberNotEmpty = _phoneControllers.any((controller) => controller.text.trim().isNotEmpty);
    return isNameNotEmpty || isPhoneNumberNotEmpty;
  }

  void _updateContact(int index, Map<String, dynamic> updatedContact) {
    setState(() {
      if (index >= 0 && index < contacts.length) {
        contacts[index] = {
          'name': updatedContact['name']?.trim() ?? '',
          'phone': updatedContact['phone'] ?? '',
          'email': updatedContact['email'] ?? '',
          'url': updatedContact['url'] is String
              ? [updatedContact['url']]
              : (updatedContact['url'] is List ? updatedContact['url'] : []),
          'photo': updatedContact['photo'] ?? '',
        };
        contacts.sort((a, b) => (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase()));
        _filterContacts();
        _saveContacts();
      }
    });
  }

  Future<void> _pickImage(BuildContext context, StateSetter setModalState) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setModalState(() {
        _imagePath = pickedFile.path;
      });

      // Save image path to local storage using Hive
      var box = Hive.box('database');
      box.put('imagePath', pickedFile.path); // Save the path

      print("Image path saved to local storage: ${pickedFile.path}");
    }
  }


  void _formatPhoneNumber(TextEditingController controller, String value, StateSetter setModalState) {
    String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length > 12) {
      digitsOnly = digitsOnly.substring(0, 12);
    }
    controller.value = TextEditingValue(
      text: digitsOnly,
      selection: TextSelection.collapsed(offset: digitsOnly.length),
    );
    if (digitsOnly.length >= 4) {
      String formatted = '(${digitsOnly.substring(0, 4)})';
      if (digitsOnly.length > 4) {
        formatted += ' ${digitsOnly.substring(4)}';
      }
      controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setModalState(() {});
  }

  void _addPhoneField(StateSetter setModalState) {
    setModalState(() {
      _phoneControllers.add(TextEditingController());
      _phoneLabels.add('phone');
    });
  }

  void _removePhoneField(StateSetter setModalState, int index) {
    if (_phoneControllers.length > 0) {
      setModalState(() {
        _phoneControllers.removeAt(index);
        _phoneLabels.removeAt(index);
      });
    }
  }

  void _addEmailField(StateSetter setModalState) {
    setModalState(() {
      _emailControllers.add(TextEditingController());
      _emailLabels.add('personal');
    });
  }

  void _removeEmailField(StateSetter setModalState, int index) {
    if (_emailControllers.length > 0) {
      setModalState(() {
        _emailControllers.removeAt(index);
        _emailLabels.removeAt(index);
      });
    }
  }

  void _addUrlField(StateSetter setModalState) {
    setModalState(() {
      _urlControllers.add(TextEditingController());
      _urlLabels.add('homepage');
    });
  }

  void _removeUrlField(StateSetter setModalState, int index) {
    if (_urlControllers.length > 0) {
      setModalState(() {
        _urlControllers.removeAt(index);
        _urlLabels.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        trailing: CupertinoButton(
          child: Icon(CupertinoIcons.add),
          onPressed: () {
            showCupertinoModalPopup(
              context: context,
              builder: (context) {
                return StatefulBuilder(
                  builder: (context, setModalState) {
                    return CupertinoActionSheet(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            child: Text('Cancel'),
                            onPressed: () {
                              Navigator.pop(context);
                              _fnameController.clear();
                              _lnameController.clear();
                              _phoneControllers = [];
                              _phoneLabels = [];
                              _emailControllers = [];
                              _emailLabels = [];
                              _urlControllers = [];
                              _urlLabels = [];
                              _imagePath = null;
                            },
                          ),
                          Text('New Contact', style: TextStyle(fontSize: 20, color: CupertinoColors.white,) ),
                          CupertinoButton(
                            child: Text(
                              'Done',
                              style: TextStyle(
                                color: _isFormValid() ? CupertinoColors.systemBlue : CupertinoColors.inactiveGray,
                              ),
                            ),