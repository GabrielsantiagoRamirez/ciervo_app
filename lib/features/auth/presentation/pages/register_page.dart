import 'package:flutter/material.dart';

import 'unified_auth_page.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnifiedAuthPage(startEmailRegistration: true);
  }
}
