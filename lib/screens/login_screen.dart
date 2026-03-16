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
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Preencha e-mail e senha.');
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isRegister) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Erro ao entrar.';

      if (e.code == 'user-not-found') msg = 'Usuário não encontrado.';
      if (e.code == 'wrong-password') msg = 'Senha incorreta.';
      if (e.code == 'email-already-in-use') msg = 'E-mail já cadastrado.';
      if (e.code == 'weak-password') msg = 'Senha muito fraca.';
      if (e.code == 'invalid-email') msg = 'E-mail inválido.';
      if (e.code == 'invalid-credential') {
        msg = 'E-mail ou senha inválidos.';
      }

      _showMessage(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      _showMessage('Digite seu e-mail para recuperar a senha.');
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showMessage('Enviamos um link de recuperação para o seu e-mail.');
    } on FirebaseAuthException catch (e) {
      String msg = 'Não foi possível enviar o e-mail.';

      if (e.code == 'invalid-email') msg = 'E-mail inválido.';
      if (e.code == 'user-not-found') msg = 'Usuário não encontrado.';

      _showMessage(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 380,
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
                    const SizedBox(height: 8),
                    Text(
                      _isRegister
                          ? 'Cadastre seu acesso para começar a usar o sistema.'
                          : 'Entre com seu e-mail e senha.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textMedium),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!_isRegister)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading ? null : _resetPassword,
                          child: const Text('Esqueci minha senha'),
                        ),
                      ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              setState(() => _isRegister = !_isRegister);
                            },
                      child: Text(
                        _isRegister
                            ? 'Já tenho conta'
                            : 'Quero criar uma conta',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
