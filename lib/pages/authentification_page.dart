import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'navigation_page.dart';

class AuthentificationPage extends StatefulWidget {
  const AuthentificationPage({super.key});

  @override
  State<AuthentificationPage> createState() =>
      _AuthentificationPageState();
}

class _AuthentificationPageState
    extends State<AuthentificationPage> {
  bool estConnexion = true;
  bool accepterConditions = false;
  bool chargement = false;

  final formKey = GlobalKey<FormState>();

  final nomController = TextEditingController();
  final emailController = TextEditingController();
  final motDePasseController = TextEditingController();
  final confirmationController = TextEditingController();

  String salutation() {
    final heure = DateTime.now().hour;

    if (heure < 18) {
      return 'Bonjour';
    }

    return 'Bonsoir';
  }

  @override
  void dispose() {
    nomController.dispose();
    emailController.dispose();
    motDePasseController.dispose();
    confirmationController.dispose();
    super.dispose();
  }

  Future<void> authentifier() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (!estConnexion && !accepterConditions) {
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
      if (estConnexion) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: motDePasseController.text.trim(),
        );
      } else {
        final credential =
            await FirebaseAuth.instance
                .createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: motDePasseController.text.trim(),
        );

        final user = credential.user;

        if (user != null) {
          await user.updateDisplayName(
            nomController.text.trim(),
          );

          await FirebaseFirestore.instance
              .collection('utilisateurs')
              .doc(user.uid)
              .set({
            'nom': nomController.text.trim(),
            'email': emailController.text.trim(),
            'dateCreation': FieldValue.serverTimestamp(),
          });
        }
      }

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const NavigationPage(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'Une erreur est survenue.';

      if (e.code == 'user-not-found') {
        message = 'Aucun utilisateur trouvé avec cet email.';
      } else if (e.code == 'wrong-password') {
        message = 'Mot de passe incorrect.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Cet email est déjà utilisé.';
      } else if (e.code == 'invalid-email') {
        message = 'Adresse email invalide.';
      } else if (e.code == 'weak-password') {
        message =
            'Le mot de passe doit contenir au moins 6 caractères.';
      } else if (e.code == 'invalid-credential') {
        message = 'Email ou mot de passe incorrect.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Une erreur inattendue est survenue.',
          ),
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

  void changerMode() {
    setState(() {
      estConnexion = !estConnexion;
      accepterConditions = false;

      formKey.currentState?.reset();
    });
  }

  InputDecoration decoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF15576B),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF15576B),
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 450,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    /// LOGO
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 100,
                        errorBuilder:
                            (context, error, stackTrace) {
                          return const Icon(
                            Icons.inventory_2_rounded,
                            size: 85,
                            color: Color(0xFF15576B),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 25),

                    Text(
                      estConnexion
                          ? '${salutation()} !'
                          : 'Créer un compte',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15576B),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      estConnexion
                          ? 'Connectez-vous à SmartInventory'
                          : 'Inscrivez-vous pour utiliser SmartInventory',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 35),

                    /// NOM
                    if (!estConnexion) ...[
                      TextFormField(
                        controller: nomController,
                        textCapitalization:
                            TextCapitalization.words,
                        decoration: decoration(
                          label: 'Nom complet',
                          icon: Icons.person_outline,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Le nom est obligatoire';
                          }

                          if (value.trim().length < 3) {
                            return 'Le nom doit contenir au moins 3 caractères';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),
                    ],

                    /// EMAIL
                    TextFormField(
                      controller: emailController,
                      keyboardType:
                          TextInputType.emailAddress,
                      decoration: decoration(
                        label: 'Adresse email',
                        icon: Icons.email_outlined,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'L’adresse email est obligatoire';
                        }

                        if (!value.contains('@')) {
                          return 'Veuillez saisir une adresse email valide';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    /// MOT DE PASSE
                    TextFormField(
                      controller: motDePasseController,
                      obscureText: true,
                      decoration: decoration(
                        label: 'Mot de passe',
                        icon: Icons.lock_outline,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Le mot de passe est obligatoire';
                        }

                        if (value.length < 6) {
                          return 'Minimum 6 caractères';
                        }

                        return null;
                      },
                    ),

                    /// CONFIRMATION
                    if (!estConnexion) ...[
                      const SizedBox(height: 18),

                      TextFormField(
                        controller: confirmationController,
                        obscureText: true,
                        decoration: decoration(
                          label: 'Confirmer le mot de passe',
                          icon: Icons.lock_reset_outlined,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return 'Veuillez confirmer votre mot de passe';
                          }

                          if (value !=
                              motDePasseController.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      /// CONDITIONS
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: accepterConditions,
                            activeColor:
                                const Color(0xFF15576B),
                            onChanged: (value) {
                              setState(() {
                                accepterConditions =
                                    value ?? false;
                              });
                            },
                          ),

                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  accepterConditions =
                                      !accepterConditions;
                                });
                              },
                              child: const Text(
                                'J’accepte les conditions d’utilisation.',
                                style: TextStyle(
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 25),

                    /// BOUTON
                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF15576B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        onPressed:
                            chargement ? null : authentifier,
                        child: chargement
                            ? const SizedBox(
                                width: 25,
                                height: 25,
                                child:
                                    CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                estConnexion
                                    ? 'Se connecter'
                                    : 'Créer mon compte',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    /// CHANGER CONNEXION / INSCRIPTION
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(
                          estConnexion
                              ? 'Vous n’avez pas de compte ? '
                              : 'Vous avez déjà un compte ? ',
                        ),
                        TextButton(
                          onPressed:
                              chargement ? null : changerMode,
                          child: Text(
                            estConnexion
                                ? 'S’inscrire'
                                : 'Se connecter',
                            style: const TextStyle(
                              color: Color(0xFF15576B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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