import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../family_chat/presentation/pages/family_conversation_page.dart';
import '../../../kid_me/data/kid_me_repository.dart';

class KidFamilyPage extends StatefulWidget {
  const KidFamilyPage({super.key});

  @override
  State<KidFamilyPage> createState() => _KidFamilyPageState();
}

class _KidFamilyPageState extends State<KidFamilyPage> {
  final _repository = getIt<KidMeRepository>();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _openChat();
  }

  Future<void> _openChat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.familyChat();
    if (!mounted) return;
    result.when(
      success: (conversation) {
        setState(() => _loading = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => FamilyConversationPage(conversation: conversation),
          ),
        );
      },
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      }),
    );
  }

  Future<void> _shareLocation() async {
    try {
      final location = await getIt<LocationService>().currentLocation();
      final result = await _repository.shareLocation(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      if (!mounted) return;
      result.when(
        success: (_) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ubicación compartida con tu familia.')),
        ),
        failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos obtener tu ubicación.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi familia')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.md),
                    CiervoButton(
                      label: 'Reintentar',
                      onPressed: _openChat,
                    ),
                  ] else ...[
                    CiervoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Abriendo chat familiar...'),
                          const SizedBox(height: AppSpacing.md),
                          CiervoButton(
                            label: 'Compartir ubicación',
                            icon: Icons.location_on_outlined,
                            onPressed: _shareLocation,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
