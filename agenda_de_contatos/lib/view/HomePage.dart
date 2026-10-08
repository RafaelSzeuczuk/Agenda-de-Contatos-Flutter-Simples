import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../database/helper/contact_helper.dart';
import '../database/model/contact_model.dart';
import 'contact_page.dart';

enum OrderOptions { orderAZ, orderZA }

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final ContactHelper _helper = ContactHelper();
  List<Contact> contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final list = await _helper.getAllContacts();
    if (!mounted) return;
    setState(() => contacts = list);
  }

  Future<void> _showContactPage({Contact? contact}) async {
    final updatedContact = await Navigator.of(context).push<Contact>(
      MaterialPageRoute<Contact>(builder: (_) => ContactPage(contact: contact)),
    );
    if (updatedContact != null) await _loadContacts();
  }

  Future<void> _showOptions(BuildContext context, int index) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => BottomSheet(
        onClosing: () {},
        builder: (context) => Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () async {
                  final phone = contacts[index].phone.replaceAll(
                    RegExp(r'\D'),
                    '',
                  );
                  Navigator.pop(sheetContext);
                  if (phone.isNotEmpty) {
                    await launchUrl(Uri(scheme: 'tel', path: phone));
                  }
                },
                child: const Text(
                  'Ligar',
                  style: TextStyle(color: Colors.green, fontSize: 20),
                ),
              ),
              TextButton(
                onPressed: () {
                  final contact = contacts[index];
                  Navigator.pop(sheetContext);
                  _showContactPage(contact: contact);
                },
                child: const Text(
                  'Editar',
                  style: TextStyle(color: Colors.blue, fontSize: 20),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final id = contacts[index].id;
                  Navigator.pop(sheetContext);
                  if (id != null) {
                    await _helper.deleteContact(id);
                    await _loadContacts();
                  }
                },
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.red, fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _orderList(OrderOptions option) {
    setState(() {
      contacts.sort((a, b) {
        final result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return option == OrderOptions.orderAZ ? result : -result;
      });
    });
  }

  Widget _contactCard(BuildContext context, int index) {
    final contact = contacts[index];
    final imagePath = contact.img;
    final hasImage = imagePath != null && imagePath.isNotEmpty;

    return GestureDetector(
      onTap: () => _showOptions(context, index),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade200,
                foregroundImage: hasImage ? FileImage(File(imagePath)) : null,
                onForegroundImageError: hasImage ? (_, _) {} : null,
                child: const Icon(Icons.person, size: 38, color: Colors.grey),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (contact.email.isNotEmpty)
                      Text(
                        contact.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18),
                      ),
                    if (contact.phone.isNotEmpty)
                      Text(
                        contact.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda de Contatos'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          PopupMenuButton<OrderOptions>(
            onSelected: _orderList,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: OrderOptions.orderAZ,
                child: Text('Ordenar de A-Z'),
              ),
              PopupMenuItem(
                value: OrderOptions.orderZA,
                child: Text('Ordenar de Z-A'),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: contacts.length,
        itemBuilder: (context, index) => _contactCard(context, index),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContactPage(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
