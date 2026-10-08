import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../database/helper/contact_helper.dart';
import '../database/model/contact_model.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key, this.contact});

  final Contact? contact;

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final ContactHelper _helper = ContactHelper();
  final ImagePicker _picker = ImagePicker();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cepController = TextEditingController();
  final _addressController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _cepMask = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _emailFormatter = TextInputFormatter.withFunction((oldValue, newValue) {
    final oldOffset = newValue.selection.baseOffset
        .clamp(0, newValue.text.length)
        .toInt();
    final normalized = newValue.text.toLowerCase().replaceAll(
      RegExp(r'\s'),
      '',
    );
    final normalizedOffset = newValue.text
        .substring(0, oldOffset)
        .toLowerCase()
        .replaceAll(RegExp(r'\s'), '')
        .length;
    return TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalizedOffset),
    );
  });

  String? _imagePath;
  bool _lookingUpCep = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final contact = widget.contact;
    if (contact != null) {
      _nameController.text = contact.name;
      _emailController.text = contact.email;
      _phoneController.text = contact.phone;
      _cepController.text = contact.cep ?? '';
      _addressController.text = contact.address ?? '';
      _numberController.text = contact.number ?? '';
      _complementController.text = contact.complement ?? '';
      _neighborhoodController.text = contact.neighborhood ?? '';
      _cityController.text = contact.city ?? '';
      _stateController.text = contact.state ?? '';
      _imagePath = contact.img;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cepController.dispose();
    _addressController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Usar a câmera'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final photo = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1400,
      );
      if (photo != null && mounted) {
        setState(() => _imagePath = photo.path);
      }
    } on PlatformException {
      if (mounted) {
        _showMessage('Não foi possível abrir a câmera ou a galeria.');
      }
    } catch (_) {
      if (mounted) _showMessage('Não foi possível carregar a imagem.');
    }
  }

  Future<void> _lookupCep() async {
    final cep = _cepController.text.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) {
      _showMessage('Digite um CEP válido com 8 números.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _lookingUpCep = true);
    try {
      final response = await http
          .get(Uri.https('viacep.com.br', '/ws/$cep/json/'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw const FormatException('Falha na consulta do CEP.');
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (data['erro'] == true) {
        _showMessage('CEP não encontrado. Confira os números digitados.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _addressController.text = data['logradouro'] as String? ?? '';
        _neighborhoodController.text = data['bairro'] as String? ?? '';
        _cityController.text = data['localidade'] as String? ?? '';
        _stateController.text = data['uf'] as String? ?? '';
      });
      _showMessage('Endereço preenchido pelo CEP.');
    } on FormatException {
      if (mounted) {
        _showMessage('Não foi possível interpretar a resposta do CEP.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Falha ao consultar o CEP. Verifique sua conexão e tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _lookingUpCep = false);
    }
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final original = widget.contact;
      final contact = Contact(
        id: original?.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        img: _imagePath,
        cep: _cepController.text.trim(),
        address: _addressController.text.trim(),
        number: _numberController.text.trim(),
        complement: _complementController.text.trim(),
        neighborhood: _neighborhoodController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
      );
      if (contact.id == null) {
        await _helper.saveContact(contact);
      } else {
        await _helper.updateContact(contact);
      }
      if (mounted) Navigator.of(context).pop(contact);
    } catch (_) {
      if (mounted) {
        _showMessage('Não foi possível salvar o contato. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _decoration(
    String label, {
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    String? hint,
    Widget? suffixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      textCapitalization: textCapitalization,
      decoration: _decoration(label, hint: hint, suffixIcon: suffixIcon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact?.name ?? 'Novo contato'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(10),
            children: [
              Center(
                child: Column(
                  children: [
                    InkWell(
                      onTap: _selectImage,
                      customBorder: const CircleBorder(),
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.grey.shade200,
                        foregroundImage:
                            _imagePath == null || _imagePath!.isEmpty
                            ? null
                            : FileImage(File(_imagePath!)),
                        onForegroundImageError:
                            _imagePath == null || _imagePath!.isEmpty
                            ? null
                            : (_, _) {},
                        child: const Icon(
                          Icons.person,
                          size: 56,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _textField(
                controller: _nameController,
                label: 'Nome *',
                textCapitalization: TextCapitalization.words,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o nome do contato.'
                    : null,
              ),
              const SizedBox(height: 14),
              _textField(
                controller: _emailController,
                label: 'E-mail',
                hint: 'nome@exemplo.com',
                keyboardType: TextInputType.emailAddress,
                inputFormatters: [_emailFormatter],
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return null;
                  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
                      ? null
                      : 'Informe um e-mail válido.';
                },
              ),
              const SizedBox(height: 14),
              _textField(
                controller: _phoneController,
                label: 'Telefone',
                keyboardType: TextInputType.phone,
                inputFormatters: [_phoneMask],
              ),
              const SizedBox(height: 24),
              Text('Endereço', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _textField(
                controller: _cepController,
                label: 'CEP',
                hint: '00000-000',
                keyboardType: TextInputType.number,
                inputFormatters: [_cepMask],
                suffixIcon: IconButton(
                  tooltip: 'Buscar CEP',
                  onPressed: _lookingUpCep ? null : _lookupCep,
                  icon: _lookingUpCep
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
                validator: (value) {
                  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digits.isNotEmpty && digits.length != 8) {
                    return 'CEP deve ter 8 números.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _lookingUpCep ? null : _lookupCep,
                  icon: const Icon(Icons.location_searching),
                  label: const Text('Preencher endereço pelo CEP'),
                ),
              ),
              const SizedBox(height: 8),
              _textField(
                controller: _addressController,
                label: 'Logradouro',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),
              _textField(
                controller: _numberController,
                label: 'Número',
                hint: 'Número do endereço',
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 14),
              _textField(
                controller: _complementController,
                label: 'Complemento',
                hint: 'Apto, bloco, casa etc.',
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 14),
              _textField(
                controller: _neighborhoodController,
                label: 'Bairro',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),
              _textField(
                controller: _cityController,
                label: 'Cidade',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),
              _textField(
                controller: _stateController,
                label: 'Estado (UF)',
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saving ? null : _saveContact,
        backgroundColor: Colors.blue,
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
      ),
    );
  }
}
