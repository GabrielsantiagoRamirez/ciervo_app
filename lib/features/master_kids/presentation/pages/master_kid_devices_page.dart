import 'package:flutter/material.dart';

import '../../data/repositories/master_kids_repository.dart';
import '../../domain/models/master_kids_models.dart';

class MasterKidDevicesPage extends StatefulWidget {
  const MasterKidDevicesPage({
    required this.repository,
    required this.kidId,
    super.key,
  });
  final MasterKidsRepository repository;
  final int kidId;

  @override
  State<MasterKidDevicesPage> createState() => _MasterKidDevicesPageState();
}

class _MasterKidDevicesPageState extends State<MasterKidDevicesPage> {
  List<KidDeviceRegistration>? _devices;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.repository.devices(widget.kidId);
    if (!mounted) return;
    result.when(
      success: (value) => setState(() {
        _devices = value;
        _busy = false;
      }),
      failure: (error) => setState(() {
        _error = error.toString();
        _busy = false;
      }),
    );
  }

  Future<void> _action(KidDeviceRegistration device, bool approve) async {
    setState(() => _busy = true);
    final result = approve
        ? await widget.repository.approveDevice(widget.kidId, device.id)
        : await widget.repository.revokeDevice(widget.kidId, device.id);
    if (!mounted) return;
    await result.when(
      success: (_) => _load(),
      failure: (error) async => setState(() {
        _error = error.toString();
        _busy = false;
      }),
    );
  }

  Future<void> _register() async {
    final firebaseUid = TextEditingController();
    final deviceId = TextEditingController();
    final platform = TextEditingController(text: 'android');
    final appVersion = TextEditingController();
    final command = await showDialog<RegisterKidDeviceCommand>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Registrar dispositivo Kids'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firebaseUid,
                decoration: const InputDecoration(labelText: 'Firebase UID'),
              ),
              TextField(
                controller: deviceId,
                decoration: const InputDecoration(
                  labelText: 'ID de instalación',
                ),
              ),
              TextField(
                controller: platform,
                decoration: const InputDecoration(labelText: 'Plataforma'),
              ),
              TextField(
                controller: appVersion,
                decoration: const InputDecoration(labelText: 'Versión app'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (firebaseUid.text.trim().isEmpty ||
                  deviceId.text.trim().isEmpty ||
                  appVersion.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(
                dialogContext,
                RegisterKidDeviceCommand(
                  firebaseUid: firebaseUid.text.trim(),
                  deviceId: deviceId.text.trim(),
                  platform: platform.text.trim(),
                  appVersion: appVersion.text.trim(),
                ),
              );
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
    firebaseUid.dispose();
    deviceId.dispose();
    platform.dispose();
    appVersion.dispose();
    if (command == null || !mounted) return;
    setState(() => _busy = true);
    final result = await widget.repository.registerDevice(
      widget.kidId,
      command,
    );
    if (!mounted) return;
    result.when(
      success: (_) => _load(),
      failure: (error) => setState(() {
        _busy = false;
        _error = error.toString();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispositivos Kids'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Registrar dispositivo',
            onPressed: _busy ? null : _register,
            icon: const Icon(Icons.add_to_home_screen_outlined),
          ),
        ],
      ),
      body: _busy && _devices == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _devices == null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!),
                    ),
                  if (_devices?.isEmpty ?? true)
                    const ListTile(title: Text('No hay dispositivos')),
                  for (final device in _devices ?? const [])
                    ListTile(
                      leading: Icon(
                        device.revoked
                            ? Icons.phonelink_erase
                            : device.approved
                            ? Icons.verified_user
                            : Icons.pending,
                      ),
                      title: Text(device.deviceId),
                      subtitle: Text(
                        '${device.platform ?? 'plataforma desconocida'} · '
                        '${device.revoked
                            ? 'revocado'
                            : device.approved
                            ? 'aprobado'
                            : 'pendiente'}',
                      ),
                      trailing: device.revoked
                          ? null
                          : device.approved
                          ? IconButton(
                              tooltip: 'Revocar',
                              onPressed: _busy
                                  ? null
                                  : () => _action(device, false),
                              icon: const Icon(Icons.block),
                            )
                          : IconButton(
                              tooltip: 'Aprobar',
                              onPressed: _busy
                                  ? null
                                  : () => _action(device, true),
                              icon: const Icon(Icons.check),
                            ),
                    ),
                ],
              ),
            ),
    );
  }
}
