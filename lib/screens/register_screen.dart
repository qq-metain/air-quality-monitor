import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/auth_utils.dart';
import '../utils/app_theme.dart';
import '../utils/l10n.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    locale.addListener(_onLocaleChange);
  }

  @override
  void dispose() {
    locale.removeListener(_onLocaleChange);
    super.dispose();
  }

  void _onLocaleChange() => setState(() {});

  Future<void> _register() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (username.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _error = locale.t('Please fill in all fields', '请填写所有字段'));
      return;
    }
    if (username.length < 3) {
      setState(() => _error = locale.t('Username must be at least 3 characters', '用户名至少3个字符'));
      return;
    }
    if (password.length < 6) {
      setState(() => _error = locale.t('Password must be at least 6 characters', '密码至少6个字符'));
      return;
    }
    if (password != confirm) {
      setState(() => _error = locale.t('Passwords do not match', '两次密码不一致'));
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final exists = await DatabaseService.usernameExists(username);
    if (exists) {
      setState(() {
        _loading = false;
        _error = locale.t('Username already exists', '用户名已存在');
      });
      return;
    }

    final hash = AuthUtils.hashPassword(password);
    final user = await DatabaseService.createUser(username, hash);
    setState(() => _loading = false);

    if (user == null) {
      setState(() => _error = locale.t('Registration failed, please try again', '注册失败，请重试'));
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(locale.t('Registration successful, please login', '注册成功，请登录')), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(locale.t('Create Account', '创建账户'))),
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.person_add, size: 64, color: AppTheme.primary),
            const SizedBox(height: 32),
            TextField(
              controller: _usernameCtrl,
              decoration: InputDecoration(
                labelText: locale.t('Username (at least 3 chars)', '用户名（至少3位）'),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: locale.t('Password (at least 6 chars)', '密码（至少6位）'),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: locale.t('Confirm Password', '确认密码'),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(locale.t('Register', '注册'), style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
