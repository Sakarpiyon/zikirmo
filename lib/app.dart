// Dosya: lib/app.dart
// Yol: C:\src\zikirmo_new\lib\app.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/theme_config.dart';
import 'core/providers/theme_provider.dart';
import 'routes.dart';

class ZikirMatikApp extends ConsumerWidget {
  const ZikirMatikApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tema modunu provider'dan al
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp(
      // EasyLocalization delegates
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      
      title: 'Zikir Matik',
      theme: ThemeConfig.lightTheme,
      darkTheme: ThemeConfig.darkTheme,
      themeMode: themeMode, // Provider'dan gelen tema modu
      
      // Navigation
      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouteGenerator.generateRoute,
      
      // Debug banner
      debugShowCheckedModeBanner: false,
      
      // Global error handling
      builder: (context, widget) {
        // Error handling için wrap
        return widget ?? const SizedBox();
      },
    );
  }
}