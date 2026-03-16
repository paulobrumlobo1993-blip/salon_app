import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _isRegister = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);

    try {
      if (_isRegister) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Erro ao entrar.';
      if (e.code == 'user-not-found') msg = 'Usuário não encontrado.';
      if (e.code == 'wrong-password') msg = 'Senha incorreta.';
      if (e.code == 'email-already-in-use') msg = 'E-mail já cadastrado.';
      if (e.code == 'weak-password') msg = 'Senha muito fraca.';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
        child: SizedBox(
          width: 360,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.content_cut, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _isRegister ? 'Criar conta' : 'Entrar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Senha'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: Text(
                        _loading
                            ? 'Carregando...'
                            : (_isRegister ? 'Cadastrar' : 'Entrar'),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _isRegister = !_isRegister);
                    },
                    child: Text(
                      _isRegister ? 'Já tenho conta' : 'Quero criar uma conta',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
