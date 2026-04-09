import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/content_service.dart';
import 'state/session_controller.dart';

void main() {
  final apiClient = ApiClient();
  runApp(BlockmateApp(apiClient: apiClient));
}

class BlockmateApp extends StatelessWidget {
  const BlockmateApp({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthService>(create: (_) => AuthService(apiClient)),
        Provider<ContentService>(create: (_) => ContentService(apiClient)),
        ChangeNotifierProvider<SessionController>(
          create: (_) => SessionController(apiClient)..init(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0EA5E9)),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        home: const _AppGate(),
      ),
    );
  }
}

class _AppGate extends StatelessWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();

    if (!session.initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!session.isAuthenticated) {
      return const LoginScreen();
    }

    return const HomeScreen();
  }
}
