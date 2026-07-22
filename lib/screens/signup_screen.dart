import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/voltron_theme.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _firstNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_firstNameController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Prénom, nom, e-mail et mot de passe (6 caractères min.) requis',
          ),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final error = await ref
        .read(authNotifierProvider)
        .signUp(
          name: _nameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          address: _addressController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Compte créé ! Vérifie ta boîte mail pour confirmer, puis connecte-toi.',
        ),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('CRÉER UN COMPTE'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/voltron_logo.png',
                  width: 140,
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _firstNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Prénom',
                  hintStyle: TextStyle(color: VoltronColors.greyText),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: VoltronColors.greyText,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Nom',
                  hintStyle: TextStyle(color: VoltronColors.greyText),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: VoltronColors.greyText,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Adresse e-mail',
                  hintStyle: TextStyle(color: VoltronColors.greyText),
                  prefixIcon: Icon(
                    Icons.mail_outline,
                    color: VoltronColors.greyText,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Mot de passe (6 caractères min.)',
                  hintStyle: TextStyle(color: VoltronColors.greyText),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: VoltronColors.greyText,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _addressController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Adresse (optionnel)',
                  hintStyle: TextStyle(color: VoltronColors.greyText),
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: VoltronColors.greyText,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: VoltronColors.deepBlack,
                        ),
                      )
                    : const Text('CRÉER MON COMPTE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
