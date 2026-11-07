import 'package:flutter/material.dart';
import 'core/database/database_factory.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDatabaseFactory();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'WoL Client',
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(child: Text('WoL Client')),
        ),
      );
}
