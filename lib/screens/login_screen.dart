import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../theme/voltron_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn({String redirect = '/home'}) async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(redirect == '/admin'
              ? 'Connecte-toi avec ton compte administrateur (e-mail + mot de passe) pour accéder au panel'
              : 'Renseigne ton e-mail et ton mot de passe'),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final error = await ref.read(authNotifierProvider).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    if (redirect == '/admin') {
      final supabase = ref.read(supabaseProvider);
      final userId = supabase.auth.currentUser?.id;
      final row = userId == null
          ? null
          : await supabase.from('profiles').select('is_admin').eq('id', userId).maybeSingle();
      final isAdmin = row?['is_admin'] == true;
      if (!isAdmin) {
        await supabase.auth.signOut();
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ce compte n\'est pas administrateur.')),
        );
        return;
      }
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    context.go(redirect);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Image.asset(
                  'assets/images/voltron_logo.png',
                  width: 200,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Content de te revoir.',
                textAlign: TextAlign.center,
                style: TextStyle(color: VoltronColors.greyText, fontSize: 14),
              ),
              const SizedBox(height: 40),
              Container(
                height: 160,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      VoltronColors.electricBlue.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.electric_scooter_rounded,
                  size: 110,
                  color: VoltronColors.electricYellow,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Adresse e-mail',
                  hintStyle: TextStyle(color: VoltronColors.greyText),
                  prefixIcon: Icon(Icons.mail_outline, color: VoltronColors.greyText),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Mot de passe',
                  hintStyle: TextStyle(color: VoltronColors.greyText),
                  prefixIcon: Icon(Icons.lock_outline, color: VoltronColors.greyText),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    if (_emailController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Renseigne ton e-mail d\'abord')),
                      );
                      return;
                    }
                    try {
                      await ref.read(supabaseProvider).auth.resetPasswordForEmail(
                            _emailController.text.trim(),
                            redirectTo: '${Uri.base.origin}${Uri.base.path}#/reset-password',
                          );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('E-mail de réinitialisation envoyé')),
                      );
                    } on AuthException catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  },
                  child: const Text(
                    'Mot de passe oublié ?',
                    style: TextStyle(color: VoltronColors.electricBlueGlow, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: VoltronColors.deepBlack),
                      )
                    : const Text('SE CONNECTER'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/signup'),
                child: const Text('CRÉER UN COMPTE'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Connexion Google bientôt disponible')),
                      ),
                      icon: const Icon(Icons.g_mobiledata, size: 26),
                      label: const Text('Google'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Connexion Apple bientôt disponible')),
                      ),
                      icon: const Icon(Icons.apple),
                      label: const Text('Apple'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : () => _signIn(redirect: '/admin'),
                  child: const Text(
                    'Accès administrateur',
                    style: TextStyle(color: VoltronColors.greyText, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
