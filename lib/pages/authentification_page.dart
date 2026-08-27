import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthentificationPage extends StatefulWidget {
  const AuthentificationPage({super.key});

  @override
  State<AuthentificationPage> createState() => _AuthentificationPageState();
}

class _AuthentificationPageState extends State<AuthentificationPage> {
  // COULEUR PRINCIPALE

  static const Color couleurPrincipale = Color(0xFF15576B);

  // FORMULAIRE

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController nomController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController motDePasseController = TextEditingController();

  final TextEditingController confirmationController = TextEditingController();

  // VARIABLES SIMPLES

  bool connexion = true;

  bool accepterConditions = false;

  bool chargement = false;

  bool masquerMotDePasse = true;

  bool masquerConfirmation = true;

  // BONJOUR / BONSOIR

  String salutation() {
    final heure = DateTime.now().hour;

    if (heure >= 18 || heure < 5) {
      return 'Bonsoir';
    }

    return 'Bonjour';
  }

  // LIBÉRATION DES CONTROLLERS

  @override
  void dispose() {
    nomController.dispose();
    emailController.dispose();
    motDePasseController.dispose();
    confirmationController.dispose();

    super.dispose();
  }

  // CHANGER CONNEXION / INSCRIPTION

  void changerMode() {
    if (chargement) return;

    setState(() {
      connexion = !connexion;

      accepterConditions = false;

      motDePasseController.clear();
      confirmationController.clear();

      formKey.currentState?.reset();
    });
  }

  // MESSAGE D'ERREUR FIREBASE

  String messageErreurFirebase(FirebaseAuthException erreur) {
    switch (erreur.code) {
      case 'invalid-email':
        return 'L’adresse email est invalide.';

      case 'user-not-found':
        return 'Aucun compte trouvé avec cette adresse email.';

      case 'wrong-password':
        return 'Le mot de passe est incorrect.';

      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';

      case 'email-already-in-use':
        return 'Cette adresse email est déjà utilisée.';

      case 'weak-password':
        return 'Le mot de passe est trop faible.';

      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard.';

      case 'network-request-failed':
        return 'Vérifiez votre connexion Internet.';

      default:
        return 'Une erreur est survenue : ${erreur.message ?? erreur.code}';
    }
  }

  // CONNEXION

  Future<void> seConnecter() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: motDePasseController.text,
      );

      // Aucun Navigator ici.

      // AuthGate dans main.dart détecte automatiquement
      // l'utilisateur connecté.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(messageErreurFirebase(e))));

      rethrow;
    }
  }

  // INSCRIPTION

  Future<void> sinscrire() async {
    final nom = nomController.text.trim();

    final email = emailController.text.trim();

    try {
      // Création du compte Firebase
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: motDePasseController.text,
          );

      final utilisateur = credential.user;

      if (utilisateur == null) {
        throw Exception('Impossible de créer le compte.');
      }

      // ENREGISTRER LE NOM DANS FIREBASE AUTH

      await utilisateur.updateDisplayName(nom);

      // Recharge l'utilisateur pour récupérer le nouveau nom.
      await utilisateur.reload();

      // CRÉER LE DOCUMENT DE L'UTILISATEUR DANS FIRESTORE

      await FirebaseFirestore.instance
          .collection('users')
          .doc(utilisateur.uid)
          .set({
            'nom': nom,
            'email': email,
            'conditionsAcceptees': true,
            'dateCreation': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Aucun Navigator ici.
      // AuthGate prendra automatiquement le relais.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(messageErreurFirebase(e))));

      rethrow;
    }
  }

  // AUTHENTIFICATION

  Future<void> authentifier() async {
    // Vérifier tous les champs.
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Conditions obligatoires uniquement lors de l'inscription.
    if (!connexion && !accepterConditions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez accepter les conditions d’utilisation.'),
        ),
      );

      return;
    }

    if (chargement) return;

    // Démarrer le chargement.
    setState(() {
      chargement = true;
    });

    try {
      if (connexion) {
        await seConnecter();
      } else {
        await sinscrire();
      }
    } catch (_) {
      // Les messages sont déjà affichés
      // dans seConnecter() ou sinscrire().
    } finally {
      if (!mounted) return;

      setState(() {
        chargement = false;
      });
    }
  }

  // DÉCORATION DES CHAMPS

  InputDecoration decorationChamp({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: couleurPrincipale),
      suffixIcon: suffixIcon,
    );
  }

  // INTERFACE

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),

              child: Form(
                key: formKey,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [
                    // LOGO
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 105,

                        // Si le logo rencontre un problème,
                        // l'application ne plante pas.
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.inventory_2_rounded,
                            size: 90,
                            color: couleurPrincipale,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 25),

                    // SALUTATION
                    Text(
                      connexion ? '${salutation()} !' : 'Créer un compte',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: couleurPrincipale,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      connexion
                          ? 'Bienvenue dans SmartInventory'
                          : 'Inscrivez-vous pour commencer à gérer votre stock',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, color: Colors.grey),
                    ),

                    const SizedBox(height: 35),

                    // NOM COMPLET
                    // Visible seulement à l'inscription
                    if (!connexion) ...[
                      TextFormField(
                        controller: nomController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: decorationChamp(
                          label: 'Nom complet',
                          icon: Icons.person_outline,
                        ),
                        validator: (value) {
                          final nom = value?.trim() ?? '';

                          if (nom.isEmpty) {
                            return 'Le nom est obligatoire';
                          }

                          if (nom.length < 3) {
                            return 'Le nom doit contenir au moins 3 caractères';
                          }

                          if (nom.length > 50) {
                            return 'Le nom est trop long';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),
                    ],

                    // EMAIL
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: decorationChamp(
                        label: 'Adresse email',
                        icon: Icons.email_outlined,
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';

                        if (email.isEmpty) {
                          return 'L’adresse email est obligatoire';
                        }

                        final emailRegExp = RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        );

                        if (!emailRegExp.hasMatch(email)) {
                          return 'Veuillez saisir une adresse email valide';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    // MOT DE PASSE
                    TextFormField(
                      controller: motDePasseController,
                      obscureText: masquerMotDePasse,
                      textInputAction: connexion
                          ? TextInputAction.done
                          : TextInputAction.next,
                      autofillHints: [
                        connexion
                            ? AutofillHints.password
                            : AutofillHints.newPassword,
                      ],
                      decoration: decorationChamp(
                        label: 'Mot de passe',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              masquerMotDePasse = !masquerMotDePasse;
                            });
                          },
                          icon: Icon(
                            masquerMotDePasse
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le mot de passe est obligatoire';
                        }

                        if (value.length < 6) {
                          return 'Le mot de passe doit contenir au moins 6 caractères';
                        }

                        return null;
                      },
                      onFieldSubmitted: connexion
                          ? (_) {
                              authentifier();
                            }
                          : null,
                    ),

                    // CONFIRMATION MOT DE PASSE
                    if (!connexion) ...[
                      const SizedBox(height: 18),

                      TextFormField(
                        controller: confirmationController,
                        obscureText: masquerConfirmation,
                        textInputAction: TextInputAction.done,
                        decoration: decorationChamp(
                          label: 'Confirmer le mot de passe',
                          icon: Icons.lock_reset_outlined,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                masquerConfirmation = !masquerConfirmation;
                              });
                            },
                            icon: Icon(
                              masquerConfirmation
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez confirmer le mot de passe';
                          }

                          if (value != motDePasseController.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }

                          return null;
                        },
                        onFieldSubmitted: (_) {
                          authentifier();
                        },
                      ),

                      const SizedBox(height: 10),

                      // CONDITIONS D'UTILISATION
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: accepterConditions,
                            activeColor: couleurPrincipale,
                            onChanged: chargement
                                ? null
                                : (value) {
                                    setState(() {
                                      accepterConditions = value ?? false;
                                    });
                                  },
                          ),

                          Expanded(
                            child: GestureDetector(
                              onTap: chargement
                                  ? null
                                  : () {
                                      setState(() {
                                        accepterConditions =
                                            !accepterConditions;
                                      });
                                    },
                              child: const Text(
                                'J’accepte les conditions d’utilisation de SmartInventory.',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 25),

                    // BOUTON
                    SizedBox(
                      height: 55,

                      child: ElevatedButton(
                        onPressed: chargement ? null : authentifier,

                        child: chargement
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                connexion ? 'Se connecter' : 'Créer mon compte',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // CONNEXION / INSCRIPTION
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            connexion
                                ? 'Vous n’avez pas de compte ?'
                                : 'Vous avez déjà un compte ?',
                            textAlign: TextAlign.center,
                          ),
                        ),

                        TextButton(
                          onPressed: chargement ? null : changerMode,
                          child: Text(
                            connexion ? 'S’inscrire' : 'Se connecter',
                            style: const TextStyle(
                              color: couleurPrincipale,
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
