import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/auth_utils.dart';
import '../utils/app_theme.dart';
import '../utils/l10n.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
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

  Future<void> _login() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = locale.t('Please enter username and password', '请输入用户名和密码'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final hash = AuthUtils.hashPassword(password);
    final user = await DatabaseService.getUser(username, hash);
    setState(() => _loading = false);
    if (user == null) {
      setState(() => _error = locale.t('Incorrect username or password', '用户名或密码错误'));
      return;
    }
    await AuthUtils.saveSession(user.id!, user.username);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(userId: user.id!, username: user.username)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.air, size: 56, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                locale.t('Air Quality Monitor', '空气质量监测'),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(locale.t('Sign in to your account', '登录您的账户'), style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () { locale.toggle(); },
                  child: Text(locale.isChinese ? 'Switch to English' : '切换中文', style: const TextStyle(color: AppTheme.primary)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameCtrl,
                decoration: InputDecoration(
                  labelText: locale.t('Username', '用户名'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: locale.t('Password', '密码'),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(locale.t('Login', '登录'), style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: Text(
                  locale.t("Don't have an account? Register now", '还没有账户？立即注册'),
                  style: const TextStyle(color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
