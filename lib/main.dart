import 'package:flutter/material.dart';
import 'package:myapp/core/router.dart';
import 'package:myapp/core/theme.dart';
import 'package:myapp/core/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('fr', null);

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    // Option 1: Afficher une erreur fatale
    throw Exception("Les clés Supabase sont manquantes dans le fichier .env !");
  }
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    debug: true,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          title: 'Expense Tracker',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: router,

          // Utiliser 'const' pour la liste des délégués (car ils sont tous const)
          localizationsDelegates: const [ 
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          
          // Retirer 'const' de la liste des locales et des objets Locale
          // car la liste des locales supportées n'est pas traitée comme une constante de compile.
          supportedLocales: [ 
            Locale('en', ''), 
            Locale('fr', 'FR'),
          ],
          
          // Retirer 'const' de l'objet Locale pour être cohérent avec supportedLocales
          locale: const Locale('fr', 'FR'),
        );
      },
    );
  }
}