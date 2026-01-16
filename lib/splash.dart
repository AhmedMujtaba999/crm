import 'package:flutter/material.dart';
import 'providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 900), () async{
      if (!mounted) return;
       await context.read<AuthProvider>().checkAuth();
    Navigator.pushReplacementNamed(context, '/auth');
    });
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: const [
            Icon(Icons.water_drop_outlined, color: Colors.white, size: 56),
            SizedBox(height: 14),
            Text("PoolPro CRM", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
            SizedBox(height: 16),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
            ),
          ]),
        ),
      ),
    );
  }
}