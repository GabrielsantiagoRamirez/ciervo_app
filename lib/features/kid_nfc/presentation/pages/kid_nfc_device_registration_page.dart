import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/nfc/nfc_tag_reader.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';

class KidNfcDeviceRegistrationPage extends StatefulWidget {
  const KidNfcDeviceRegistrationPage({super.key});

  @override
  State<KidNfcDeviceRegistrationPage> createState() =>
      _KidNfcDeviceRegistrationPageState();
}

class _KidNfcDeviceRegistrationPageState
    extends State<KidNfcDeviceRegistrationPage> {
  final _labelController = TextEditingController(text: 'Mi dispositivo NFC');
  final _uidController = TextEditingController();
  bool _nfcAvailable = false;
  bool _scanning = false;
  String _countryCode = CountryRegistration.defaultCountryCode();

  @override
  void initState() {
    super.initState();
    _checkNfc();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _uidController.dispose();
    super.dispose();
  }

  Future<void> _checkNfc() async {
    final available = await NfcTagReader.isAvailable();
    if (mounted) setState(() => _nfcAvailable = available);
  }

  Future<void> _scanUid() async {
    if (!_nfcAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activa NFC en tu dispositivo.')),
      );
      return;
    }
    setState(() => _scanning = true);
    final uid = await NfcTagReader.readUid();
    if (!mounted) return;
    setState(() => _scanning = false);
    if (uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos leer el UID.')),
      );
      return;
    }
    setState(() => _uidController.text = uid);
  }

  String get _shareMessage {
    final uid = _uidController.text.trim().toUpperCase();
    final label = _labelController.text.trim();
    return 'Registro NFC CIERVO Kids\n'
        'Dispositivo: ${label.isEmpty ? 'Mi NFC' : label}\n'
        'UID: $uid\n'
        'País: ${CountryRegistration.countryLabel(_countryCode)}\n'
        'Por favor vincula esta tarjeta desde tu perfil de tutor en Ciervo Kids.';
  }

  Future<void> _shareWithTutor() async {
    final uid = _uidController.text.trim();
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escanea o ingresa un UID primero.')),
      );
      return;
    }
    await Share.share(_shareMessage, subject: 'Vincular NFC CIERVO');
  }

  Future<void> _sendToContact() async {
    final uid = _uidController.text.trim();
    if (uid.isEmpty) return;
    final granted = await FlutterContacts.requestPermission();
    if (!granted || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitamos acceso a contactos.')),
      );
      return;
    }
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    if (!mounted) return;
    final selected = await showModalBottomSheet<Contact>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return ListTile(
            title: Text(contact.displayName),
            subtitle: Text(contact.phones.firstOrNull?.number ?? ''),
            onTap: () => Navigator.pop(context, contact),
          );
        },
      ),
    );
    if (selected == null) return;
    await Share.share(
      'Hola ${selected.displayName}, necesito que vincules mi tarjeta NFC en CIERVO.\n$_shareMessage',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear NFC Kids')),
      body: ListView(
        padding: pagePaddingOf(context),
        children: [
          CiervoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nfcAvailable ? 'NFC activo' : 'NFC no disponible',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Escanea tu tarjeta y comparte el UID con tu tutor. '
                  'El registro oficial lo hace el tutor desde Ciervo Kids.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _uidController,
            decoration: const InputDecoration(
              labelText: 'UID del dispositivo',
              prefixIcon: Icon(Icons.nfc),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          CiervoButton(
            label: _scanning ? 'Leyendo NFC...' : 'Escanear NFC',
            icon: Icons.sensors,
            state: _scanning
                ? CiervoButtonState.loading
                : CiervoButtonState.normal,
            onPressed: _scanning ? null : _scanUid,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Etiqueta',
              prefixIcon: Icon(Icons.label_outline),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _countryCode,
            decoration: const InputDecoration(
              labelText: 'País',
              prefixIcon: Icon(Icons.public_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'CO', child: Text('Colombia')),
              DropdownMenuItem(value: 'CL', child: Text('Chile')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _countryCode = value);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          CiervoButton(
            label: 'Compartir UID con tutor',
            icon: Icons.share_outlined,
            onPressed: _shareWithTutor,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _sendToContact,
            icon: const Icon(Icons.contacts_outlined),
            label: const Text('Enviar a contacto'),
          ),
        ],
      ),
    );
  }
}
