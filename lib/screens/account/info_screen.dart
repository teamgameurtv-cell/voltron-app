import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/account_provider.dart';
import '../../theme/voltron_theme.dart';

class InfoScreen extends ConsumerStatefulWidget {
  const InfoScreen({super.key});

  @override
  ConsumerState<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends ConsumerState<InfoScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _firstNameController = TextEditingController(text: profile.firstName);
    _nameController = TextEditingController(text: profile.name);
    _emailController = TextEditingController(text: profile.email);
    _phoneController = TextEditingController(text: profile.phone);
    _addressController = TextEditingController(text: profile.address);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
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
        title: const Text('MES INFORMATIONS'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _firstNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Prénom',
                  hintStyle: TextStyle(color: VoltronColors.greyText),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Nom',
                  hintStyle: TextStyle(color: VoltronColors.greyText),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Email',
                  hintStyle: TextStyle(color: VoltronColors.greyText),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _phoneController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Téléphone',
                  hintStyle: TextStyle(color: VoltronColors.greyText),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _addressController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Adresse',
                  hintStyle: TextStyle(color: VoltronColors.greyText),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(profileProvider.notifier)
                      .update(
                        name: _nameController.text.trim(),
                        firstName: _firstNameController.text.trim(),
                        email: _emailController.text.trim(),
                        phone: _phoneController.text.trim(),
                        address: _addressController.text.trim(),
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informations mises à jour')),
                  );
                },
                child: const Text('ENREGISTRER'),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.push('/account/payment-methods'),
                icon: const Icon(Icons.credit_card_outlined, size: 18),
                label: const Text('MOYENS DE PAIEMENT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
