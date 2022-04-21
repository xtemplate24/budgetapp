import 'package:budgetapp/authentication/authentication_service.dart';
import 'package:budgetapp/screens/home/home_view.dart';
import 'package:budgetapp/screens/login/login_view.dart';
import 'package:budgetapp/screens/login/signup_view.dart';
import 'package:budgetapp/screens/setCategory/set_category_page.dart';
import 'package:budgetapp/screens/setIncome/set_income_page.dart';
import 'package:budgetapp/screens/setup/setup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MultiProvider(
      providers: [
        Provider<AuthenticationService?>(
            create: (_) => AuthenticationService(FirebaseAuth.instance)),
        StreamProvider(
            create: (context) =>
                context.read<AuthenticationService>().authStateChanges,
            initialData: null)
      ],
      child: Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
              title: "Budget App",
              theme: ThemeData(
                primarySwatch: Colors.teal,
                visualDensity: VisualDensity.adaptivePlatformDensity,
                textTheme: GoogleFonts.cabinTextTheme(),
              ),
              home: AuthenticationWrapper(),
              routes: {
                LoginPage.routeName: (context) => LoginPage(),
                SignUpPage.routeName: (context) => SignUpPage(),
                HomePage.routeName: (context) => HomePage(),
                SetupPage.routeName: (context) => SetupPage(),
                SetIncomePage.routeName: (context) => SetIncomePage(),
                SetCategoryPage.routeName: (context) => SetCategoryPage(),
              });
        },
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final firebaseuser = context.watch<User?>();

    if (firebaseuser != null) {
      print("Email verified");
      return HomePage();
    } else {
      print('hello');
      return LoginPage();
    }
  }
}
