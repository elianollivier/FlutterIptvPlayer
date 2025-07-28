import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import '../services/logo_service.dart';
import 'home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SupabaseService.instance
          .signIn(_emailCtrl.text, _passwordCtrl.text);
      await LogoService().syncWithSupabase();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Login failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SupabaseService.instance
          .signUp(_emailCtrl.text, _passwordCtrl.text);
      await LogoService().syncWithSupabase();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Register failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            _loading
                ? const CircularProgressIndicator()
                : Row(
                    children: [
                      ElevatedButton(
                        onPressed: _login,
                        child: const Text('Se connecter'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _register,
                        child: const Text('Créer un compte'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
