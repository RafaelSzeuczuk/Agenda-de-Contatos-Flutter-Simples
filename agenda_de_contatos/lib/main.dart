import 'package:flutter/material.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'view/HomePage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final pickerImplementation = ImagePickerPlatform.instance;
  if (pickerImplementation is ImagePickerAndroid) {
    pickerImplementation.useAndroidPhotoPicker = true;
  }
  runApp(const ContactsApp());
}

class ContactsApp extends StatelessWidget {
  const ContactsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda de Contatos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const Homepage(),
    );
  }
}
