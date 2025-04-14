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
                           onPressed: _isFormValid()
                                ? () {
                              final firstName = _fnameController.text.trim();
                              final lastName = _lnameController.text.trim();
                              final phoneNumbers = _phoneControllers
                                  .map((controller) => controller.text.trim())
                                  .where((number) => number.isNotEmpty)
                                  .toList();
                              final emailAddresses = _emailControllers
                                  .map((controller) => controller.text.trim())
                                  .where((email) => email.isNotEmpty)
                                  .toList();
                              final urls = _urlControllers
                                  .map((controller) => controller.text.trim())
                                  .where((url) => url.isNotEmpty)
                                  .toList();

                              if (firstName.isNotEmpty || lastName.isNotEmpty || phoneNumbers.isNotEmpty || emailAddresses.isNotEmpty || urls.isNotEmpty) {
                                setState(() {
                                  contacts.add({
                                    "name": "$firstName $lastName".trim(),
                                    "phone": phoneNumbers,
                                    "email": emailAddresses,
                                    "url": urls,
                                    "photo": _imagePath ?? "assets/default_profile.png",
                                  });

                                  // Sorting contacts by name
                                  contacts.sort((a, b) => (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase()));

                                  _saveContacts();
                                  _filterContacts();
                                });

                                // Clear controllers and reset fields
                                _fnameController.clear();
                                _lnameController.clear();
                                _phoneControllers.clear();
                                _phoneLabels.clear();
                                _emailControllers.clear();
                                _emailLabels.clear();
                                _urlControllers.clear();
                                _urlLabels.clear();
                                _imagePath = null;

                                // Close the modal or form
                                Navigator.pop(context);
                              } else {
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
                            }
                                : null,
                          )

                        ],
                      ),
                      message: Column(
                        children: [
                          GestureDetector(
                            onTap: () => _pickImage(context, setModalState),
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                _imagePath == null
                                    ? Icon(CupertinoIcons.person_circle_fill, size: 200, color: CupertinoColors.systemGrey)
                                    : CircleAvatar(
                                  radius: 100,
                                  backgroundImage: FileImage(File(_imagePath!)),
                                ),
                                if (_imagePath == null)
                                  Positioned(
                                    bottom: -20,
                                    child: CupertinoButton(
                                      child: Text('Add Photo', style: TextStyle(fontSize: 15, color: CupertinoColors.white)),
                                      onPressed: () => _pickImage(context, setModalState),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          CupertinoTextField(
                            controller: _fnameController,
                            placeholder: 'First name',
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey.withOpacity(0.1),
                            ),
                            padding: EdgeInsets.all(12),
                            clearButtonMode: OverlayVisibilityMode.editing,
                            onChanged: (value) => setModalState(() {}),
                          ),
                          CupertinoTextField(
                            controller: _lnameController,
                            placeholder: 'Last name',
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey.withOpacity(0.1),
                            ),
                            padding: EdgeInsets.all(12),
                            clearButtonMode: OverlayVisibilityMode.editing,
                            onChanged: (value) => setModalState(() {}),
                          ),
                          SizedBox(height: 10),
                          if (_phoneControllers.isNotEmpty)
                            Column(
                              children: _phoneControllers.asMap().entries.map((entry) {
                                int index = entry.key;
                                TextEditingController controller = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: Row(
                                    children: [
                                      CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        child: Icon(CupertinoIcons.minus_circle_fill, color: CupertinoColors.systemRed),
                                        onPressed: () => _removePhoneField(setModalState, index),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: CupertinoTextField(
                                          controller: controller,
                                          placeholder: 'Phone number',
                                          decoration: BoxDecoration(
                                            color: CupertinoColors.systemGrey.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: EdgeInsets.all(12),
                                          keyboardType: TextInputType.phone,
                                          onChanged: (value) {
                                            _formatPhoneNumber(controller, value, setModalState);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: CupertinoButton(
                              onPressed: () => _addPhoneField(setModalState),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(width: 5),
                                  Icon(CupertinoIcons.add_circled_solid,
                                      color: CupertinoColors.systemGreen),
                                  SizedBox(width: 8),
                                  Text('add phone', style: TextStyle(color: CupertinoColors.systemGreen)),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          if (_emailControllers.isNotEmpty)
                            Column(
                              children: _emailControllers.asMap().entries.map((entry) {
                                int index = entry.key;
                                TextEditingController controller = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: Row(
                                    children: [
                                      CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        child: Icon(CupertinoIcons.minus_circle_fill, color: CupertinoColors.systemRed),
                                        onPressed: () => _removeEmailField(setModalState, index),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: CupertinoTextField(
                                          controller: controller,
                                          placeholder: 'email',
                                          decoration: BoxDecoration(
                                            color: CupertinoColors.systemGrey.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: EdgeInsets.all(12),
                                          keyboardType: TextInputType.emailAddress,
                                          onChanged: (value) => setModalState(() {}),
                                        ),
                                      ),
                                    ],
                                                                     ),
                                );
                              }).toList(),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: CupertinoButton(
                              onPressed: () => _addEmailField(setModalState),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(width: 5),
                                  Icon(CupertinoIcons.add_circled_solid,
                                      color: CupertinoColors.systemGreen),
                                  SizedBox(width: 8),
                                  Text('add email', style: TextStyle(color: CupertinoColors.systemGreen)),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          if (_urlControllers.isNotEmpty)
                            Column(
                              children: _urlControllers.asMap().entries.map((entry) {
                                int index = entry.key;
                                TextEditingController controller = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: Row(
                                    children: [
                                      CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        child: Icon(CupertinoIcons.minus_circle_fill, color: CupertinoColors.systemRed),
                                        onPressed: () => _removeUrlField(setModalState, index),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: CupertinoTextField(
                                          controller: controller, // ✅ <-- add this
                                          placeholder: 'url',
                                          decoration: BoxDecoration(
                                            color: CupertinoColors.systemGrey.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: EdgeInsets.all(12),
                                          keyboardType: TextInputType.url,
                                          onChanged: (value) => setModalState(() {}),
                                        ),

                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: CupertinoButton(
                              onPressed: () => _addUrlField(setModalState),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(CupertinoIcons.add_circled_solid, color: CupertinoColors.systemGreen),
                                  SizedBox(width: 8),
                                  Text('add url', style: TextStyle(color: CupertinoColors.systemGreen)),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          SizedBox(height: double.maxFinite),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Contacts',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                  ),
                ],
              ),
              SizedBox(height: 15.0),
              CupertinoTextField(
                controller: _searchController,
                placeholder: 'Search',
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                prefix: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(CupertinoIcons.search,
                      color: CupertinoColors.systemGrey, size: 20),
                ),
                suffix: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(CupertinoIcons.mic_fill,
                      color: CupertinoColors.systemGrey, size: 20),
                ),
                onChanged: (value) {
                  _filterContacts();
                },
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(10, 9, 10, 9),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'JB',
                      style: TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Joseph Basilio',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('My Card',
                          style: TextStyle(
                              fontWeight: FontWeight.w400, fontSize: 12)),
                    ],
                  )
                ],
              ),
              SizedBox(height: 10),
              Divider(color: CupertinoColors.systemGrey.withOpacity(0.3)),
              if (_searchController.text.isNotEmpty && filteredContacts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'TOP NAME MATCHES',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = filteredContacts[index];
                    return Dismissible(
                      key: UniqueKey(),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        color: CupertinoColors.systemRed,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(CupertinoIcons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        setState(() {
                          int actualIndex = contacts.indexOf(contact);
                          if (actualIndex != -1) {
                            contacts.removeAt(actualIndex);
                          }
                          filteredContacts.removeAt(index);
                          _saveContacts();
                        });
                      },
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => Contact(
                                contactData: contact,
                                onContactUpdated: (updatedData) {
                                  final contactIndex = contacts.indexOf(contact);
                                  if (contactIndex != -1) {
                                    _updateContact(contactIndex, updatedData);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(0), // Adjust the radius as needed
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5.0),
                                child: Text(
                                  (contact['name'] as String).trim().isEmpty
                                      ? contact['phone'] as String
                                      : contact['name'] as String,
                                  style: TextStyle(fontSize: 15),
                                ),
                              ),
                              Divider(
                                color: CupertinoColors.systemGrey.withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

                            