import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importa Firebase Auth
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Asegúrate de importar las opciones de Firebase generadas
import 'services/auth_service.dart'; // Asegúrate de que esta clase esté definida
import 'services/notification_service.dart'; // Servicio para manejar notificaciones
import 'theme/app_theme.dart';
import 'screens/home_page.dart'; // Asegúrate de que esta ruta es correcta
import 'screens/sign_in_page.dart'; // Asegúrate de que esta ruta es correcta
import 'package:firebase_analytics/firebase_analytics.dart'; // Importa Firebase Analytics

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService().initializeNotificaction();

  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  await FirebaseAuth.instance.signOut();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      title: 'BUMERA Demo',
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(), 
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>( 
      stream: AuthService().authStateChanges, 
      builder: (context, snapshot) {
        
        if (!snapshot.hasData) {
          return const SignInPage(); 
        }

        return HomePage(email: snapshot.data!.email!); 
      },
    );
  }
}
