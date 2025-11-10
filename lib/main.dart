import 'package:flutter/material.dart';
import 'package:myapp/core/router.dart';
import 'package:myapp/core/theme.dart';
import 'package:myapp/core/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const String SUPABASE_URL_ENV = String.fromEnvironment('SUPABASE_URL');
const String SUPABASE_ANON_KEY_ENV = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
);

final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr', null);

  String? finalSupabaseUrl;
  String? finalSupabaseAnonKey;

  // 1. Priorité aux clés définies lors de la compilation (mode release)
  if (SUPABASE_URL_ENV.isNotEmpty && SUPABASE_ANON_KEY_ENV.isNotEmpty) {
    finalSupabaseUrl = SUPABASE_URL_ENV;
    finalSupabaseAnonKey = SUPABASE_ANON_KEY_ENV;
  } else {
    // 2. Si non définies, charger depuis le fichier .env (mode debug)
    await dotenv.load(fileName: ".env");
    finalSupabaseUrl = dotenv.env['SUPABASE_URL'];
    finalSupabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  }

  // 3. Vérification finale
  if (finalSupabaseUrl == null || finalSupabaseAnonKey == null) {
    throw Exception(
      "Les clés Supabase sont manquantes. Vérifiez .env ou --dart-define !",
    );
  }

  // 4. Initialisation avec les clés valides
  await Supabase.initialize(
    url: finalSupabaseUrl,
    anonKey: finalSupabaseAnonKey,
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
          supportedLocales: [Locale('en', ''), Locale('fr', 'FR')],

          // Retirer 'const' de l'objet Locale pour être cohérent avec supportedLocales
          locale: const Locale('fr', 'FR'),
        );
      },
    );
  }
}
