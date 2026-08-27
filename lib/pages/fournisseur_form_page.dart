import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/firestore_service.dart';

class FournisseurFormPage extends StatefulWidget {
  final String? fournisseurId;
  final Map<String, dynamic>? fournisseur;

  const FournisseurFormPage({super.key, this.fournisseurId, this.fournisseur});

  @override
  State<FournisseurFormPage> createState() => _FournisseurFormPageState();
}

class _FournisseurFormPageState extends State<FournisseurFormPage> {
  // COULEUR PRINCIPALE
  static const Color couleurPrincipale = Color(0xFF15576B);

  // FIRESTORE
  final FirestoreService firestoreService = FirestoreService();
  // FORMULAIRE

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late TextEditingController nomController;
  late TextEditingController telephoneController;
  late TextEditingController produitController;
  late TextEditingController adresseController;

  bool chargement = false;

  // AJOUT OU MODIFICATION

  bool get modification {
    return widget.fournisseurId != null && widget.fournisseur != null;
  }

  // INITIALISATION

  @override
  void initState() {
    super.initState();

    nomController = TextEditingController(
      text: widget.fournisseur?['nom']?.toString() ?? '',
    );

    telephoneController = TextEditingController(
      text: widget.fournisseur?['telephone']?.toString() ?? '',
    );

    // Compatibilité avec d'anciennes données éventuelles.
    produitController = TextEditingController(
      text:
          widget.fournisseur?['produitFourni']?.toString() ??
          widget.fournisseur?['produit']?.toString() ??
          '',
    );

    adresseController = TextEditingController(
      text: widget.fournisseur?['adresse']?.toString() ?? '',
    );
  }

  // LIBÉRER LES CONTROLLERS
  @override
  void dispose() {
    nomController.dispose();
    telephoneController.dispose();
    produitController.dispose();
    adresseController.dispose();

    super.dispose();
  }

  // ENREGISTRER
  Future<void> enregistrerFournisseur() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (chargement) {
      return;
    }

    setState(() {
      chargement = true;
    });

    final nom = nomController.text.trim();
    final telephone = telephoneController.text.trim();
    final produitFourni = produitController.text.trim();
    final adresse = adresseController.text.trim();

    try {
      // MODIFICATION

      if (modification) {
        final fournisseurReference = firestoreService.fournisseurs.doc(
          widget.fournisseurId,
        );

        final activiteReference = firestoreService.activites.doc();

        final batch = FirebaseFirestore.instance.batch();
        batch.update(fournisseurReference, {
          'nom': nom,
          'telephone': telephone,
          'produitFourni': produitFourni,
          'adresse': adresse,
          'dateModification': FieldValue.serverTimestamp(),
        });
        batch.set(activiteReference, {
          'titre': 'Fournisseur modifié',
          'description': '$nom a été modifié.',
          'type': 'fournisseur',
          'fournisseurId': widget.fournisseurId,
          'date': FieldValue.serverTimestamp(),
        });
        await batch.commit();
      }
      // AJOUT
      else {
        final fournisseurReference = firestoreService.fournisseurs.doc();

        final activiteReference = firestoreService.activites.doc();

        final batch = FirebaseFirestore.instance.batch();

        batch.set(fournisseurReference, {
          'nom': nom,
          'telephone': telephone,
          'produitFourni': produitFourni,
          'adresse': adresse,
          'dateCreation': FieldValue.serverTimestamp(),
        });

        batch.set(activiteReference, {
          'titre': 'Nouveau fournisseur ajouté',
          'description': '$nom fournit : $produitFourni.',
          'type': 'fournisseur',
          'fournisseurId': fournisseurReference.id,
          'date': FieldValue.serverTimestamp(),
        });

        await batch.commit();
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Impossible d’enregistrer le fournisseur.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une erreur est survenue pendant l’enregistrement.'),
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

  // INTERFACE

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),

      appBar: AppBar(
        title: Text(
          modification ? 'Modifier le fournisseur' : 'Ajouter un fournisseur',
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Form(
            key: formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Informations du fournisseur',
                  style: TextStyle(
                    color: couleurPrincipale,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Tous les champs sont obligatoires.',
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 25),

                // NOM
                TextFormField(
                  controller: nomController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,

                  decoration: const InputDecoration(
                    labelText: 'Nom du fournisseur',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: couleurPrincipale,
                    ),
                  ),

                  validator: (value) {
                    final nom = value?.trim() ?? '';

                    if (nom.isEmpty) {
                      return 'Le nom est obligatoire';
                    }

                    if (nom.length < 3) {
                      return 'Le nom doit contenir au moins 3 caractères';
                    }

                    if (nom.length > 40) {
                      return 'Le nom ne doit pas dépasser 20 caractères';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // TÉLÉPHONE
                TextFormField(
                  controller: telephoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,

                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],

                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    hintText: '8 chiffres',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: couleurPrincipale,
                    ),
                  ),

                  validator: (value) {
                    final telephone = value?.trim() ?? '';

                    if (telephone.isEmpty) {
                      return 'Le numéro de téléphone est obligatoire';
                    }

                    if (telephone.length != 8) {
                      return 'Le téléphone doit contenir exactement 8 chiffres';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // PRODUIT FOURNI
                TextFormField(
                  controller: produitController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,

                  decoration: const InputDecoration(
                    labelText: 'Produit fourni',
                    prefixIcon: Icon(
                      Icons.inventory_2_outlined,
                      color: couleurPrincipale,
                    ),
                  ),

                  validator: (value) {
                    final produit = value?.trim() ?? '';

                    if (produit.isEmpty) {
                      return 'Le produit fourni est obligatoire';
                    }

                    if (produit.length < 2) {
                      return 'Le nom du produit est trop court';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ADRESSE
                TextFormField(
                  controller: adresseController,
                  keyboardType: TextInputType.streetAddress,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  minLines: 3,
                  maxLines: 4,

                  decoration: const InputDecoration(
                    labelText: 'Adresse',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                      color: couleurPrincipale,
                    ),
                  ),

                  validator: (value) {
                    final adresse = value?.trim() ?? '';

                    if (adresse.isEmpty) {
                      return 'L’adresse est obligatoire';
                    }

                    if (adresse.length < 3) {
                      return 'L’adresse doit contenir au moins 3 caractères';
                    }

                    return null;
                  },

                  onFieldSubmitted: (_) {
                    enregistrerFournisseur();
                  },
                ),

                const SizedBox(height: 30),

                // ENREGISTRER
                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton.icon(
                    onPressed: chargement ? null : enregistrerFournisseur,

                    icon: chargement
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            modification
                                ? Icons.save_outlined
                                : Icons.person_add_alt_1_outlined,
                          ),

                    label: Text(
                      chargement
                          ? 'Enregistrement...'
                          : modification
                          ? 'Enregistrer les modifications'
                          : 'Ajouter le fournisseur',
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
