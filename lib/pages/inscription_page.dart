import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'navigation_page.dart';

class InscriptionPage extends StatefulWidget {
  const InscriptionPage({super.key});

  @override
  State<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  final formKey = GlobalKey<FormState>();

  final nomController = TextEditingController();
  final emailController = TextEditingController();
  final motDePasseController = TextEditingController();
  final confirmationController = TextEditingController();

  bool masquerMotDePasse = true;
  bool masquerConfirmation = true;
  bool conditionsAcceptees = false;
  bool chargement = false;

  @override
  void dispose() {
    nomController.dispose();
    emailController.dispose();
    motDePasseController.dispose();
    confirmationController.dispose();
    super.dispose();
  }

  Future<void> inscription() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (!conditionsAcceptees) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vous devez accepter les conditions d’utilisation.',
          ),
        ),
      );
      return;
    }

    setState(() {
      chargement = true;
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: motDePasseController.text.trim(),
      );

      await credential.user?.updateDisplayName(
        nomController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'nom': nomController.text.trim(),
        'email': emailController.text.trim(),
        'dateCreation': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const NavigationPage(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Une erreur est survenue.';

      if (e.code == 'email-already-in-use') {
        message = 'Cette adresse e-mail est déjà utilisée.';
      } else if (e.code == 'invalid-email') {
        message = 'Adresse e-mail invalide.';
      } else if (e.code == 'weak-password') {
        message = 'Le mot de passe doit contenir au moins 6 caractères.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          chargement = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F8),
        title: const Text('Créer un compte'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                const SizedBox(height: 15),

                Image.asset(
                  'assets/images/logo.png',
                  height: 90,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 25),

                const Text(
                  'Créer votre compte',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15576B),
                  ),
                ),

                const SizedBox(height: 30),

                TextFormField(
                  controller: nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir votre nom';
                    }

                    if (value.trim().length < 3) {
                      return 'Le nom doit contenir au moins 3 caractères';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Adresse e-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir votre adresse e-mail';
                    }

                    if (!value.contains('@')) {
                      return 'Adresse e-mail invalide';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: motDePasseController,
                  obscureText: masquerMotDePasse,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          masquerMotDePasse =
                              !masquerMotDePasse;
                        });
                      },
                      icon: Icon(
                        masquerMotDePasse
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez saisir un mot de passe';
                    }

                    if (value.length < 6) {
                      return 'Minimum 6 caractères';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: confirmationController,
                  obscureText: masquerConfirmation,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          masquerConfirmation =
                              !masquerConfirmation;
                        });
                      },
                      icon: Icon(
                        masquerConfirmation
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez confirmer votre mot de passe';
                    }

                    if (value != motDePasseController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 15),

                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: conditionsAcceptees,
                  activeColor: const Color(0xFF15576B),
                  title: const Text(
                    'J’accepte les conditions d’utilisation de SmartInventory.',
                  ),
                  onChanged: (value) {
                    setState(() {
                      conditionsAcceptees = value ?? false;
                    });
                  },
                  controlAffinity:
                      ListTileControlAffinity.leading,
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15576B),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: chargement ? null : inscription,
                    child: chargement
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'Créer mon compte',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}