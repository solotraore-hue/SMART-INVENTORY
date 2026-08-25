import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class FournisseursPage extends StatefulWidget {
  const FournisseursPage({super.key});

  @override
  State<FournisseursPage> createState() => _FournisseursPageState();
}

class _FournisseursPageState extends State<FournisseursPage> {
  final FirestoreService firestoreService = FirestoreService();

  static const Color couleurPrincipale = Color(0xFF15576B);

  // ============================================================
  // AJOUTER OU MODIFIER UN FOURNISSEUR
  // ============================================================

  Future<void> afficherFormulaire({
    String? fournisseurId,
    Map<String, dynamic>? fournisseur,
  }) async {
    final formKey = GlobalKey<FormState>();

    final nomController = TextEditingController(
      text: fournisseur?['nom']?.toString() ?? '',
    );

    final telephoneController = TextEditingController(
      text: fournisseur?['telephone']?.toString() ?? '',
    );

    final produitController = TextEditingController(
      text: fournisseur?['produit']?.toString() ?? '',
    );

    final adresseController = TextEditingController(
      text: fournisseur?['adresse']?.toString() ?? '',
    );

    final bool modification = fournisseurId != null;

    try {
      final resultat = await showModalBottomSheet<bool>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Barre du BottomSheet
                        Container(
                          width: 45,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          modification
                              ? 'Modifier le fournisseur'
                              : 'Nouveau fournisseur',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: couleurPrincipale,
                          ),
                        ),

                        const SizedBox(height: 25),

                        // ==================================================
                        // NOM
                        // ==================================================
                        TextFormField(
                          controller: nomController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Nom du fournisseur',
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: couleurPrincipale,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final nom = value?.trim() ?? '';

                            if (nom.isEmpty) {
                              return 'Le nom est obligatoire';
                            }

                            if (nom.length < 3 || nom.length > 20) {
                              return 'Le nom doit contenir entre 3 et 20 caractères';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // TELEPHONE
                        // ==================================================
                        TextFormField(
                          controller: telephoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 8,
                          decoration: InputDecoration(
                            labelText: 'Téléphone',
                            counterText: '',
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              color: couleurPrincipale,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final telephone = value?.trim() ?? '';

                            if (telephone.isEmpty) {
                              return 'Le téléphone est obligatoire';
                            }

                            if (!RegExp(r'^\d{8}$').hasMatch(telephone)) {
                              return 'Le téléphone doit contenir exactement 8 chiffres';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // PRODUIT FOURNI
                        // ==================================================
                        TextFormField(
                          controller: produitController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Produit fourni',
                            prefixIcon: const Icon(
                              Icons.inventory_2_outlined,
                              color: couleurPrincipale,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Le produit est obligatoire';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // ADRESSE
                        // ==================================================
                        TextFormField(
                          controller: adresseController,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: 'Adresse',
                            alignLabelWithHint: true,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 45),
                              child: Icon(
                                Icons.location_on_outlined,
                                color: couleurPrincipale,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
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
                        ),

                        const SizedBox(height: 25),

                        // ==================================================
                        // BOUTON AJOUTER / MODIFIER
                        // ==================================================
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: couleurPrincipale,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) {
                                return;
                              }

                              final donnees = <String, dynamic>{
                                'nom': nomController.text.trim(),
                                'telephone': telephoneController.text.trim(),
                                'produit': produitController.text.trim(),
                                'adresse': adresseController.text.trim(),
                              };

                              try {
                                // ==========================================
                                // MODIFICATION
                                // ==========================================

                                if (modification) {
                                  await firestoreService.fournisseurs
                                      .doc(fournisseurId)
                                      .update({
                                        ...donnees,
                                        'dateModification':
                                            FieldValue.serverTimestamp(),
                                      });

                                  // Mettre à jour les activités liées
                                  final activitesSnapshot =
                                      await firestoreService.activites
                                          .where(
                                            'fournisseurId',
                                            isEqualTo: fournisseurId,
                                          )
                                          .get();

                                  final batch = FirebaseFirestore.instance
                                      .batch();

                                  for (final activite
                                      in activitesSnapshot.docs) {
                                    batch.update(activite.reference, {
                                      'description':
                                          '${donnees['nom']} fournit ${donnees['produit']}',
                                    });
                                  }

                                  if (activitesSnapshot.docs.isNotEmpty) {
                                    await batch.commit();
                                  }
                                }
                                // ==========================================
                                // AJOUT
                                // ==========================================
                                else {
                                  final fournisseurReference = firestoreService
                                      .fournisseurs
                                      .doc();

                                  final activiteReference = firestoreService
                                      .activites
                                      .doc();

                                  final batch = FirebaseFirestore.instance
                                      .batch();

                                  // Enregistrer le fournisseur
                                  batch.set(fournisseurReference, {
                                    ...donnees,
                                    'dateCreation':
                                        FieldValue.serverTimestamp(),
                                  });

                                  // Enregistrer l'activité
                                  batch.set(activiteReference, {
                                    'titre': 'Nouveau fournisseur ajouté',
                                    'description':
                                        '${donnees['nom']} fournit ${donnees['produit']}',
                                    'type': 'fournisseur',
                                    'fournisseurId': fournisseurReference.id,
                                    'date': FieldValue.serverTimestamp(),
                                  });

                                  await batch.commit();
                                }

                                // Vérification importante
                                if (!sheetContext.mounted) return;

                                // Le BottomSheet retourne uniquement true.
                                // Aucun SnackBar n'est affiché ici.
                                Navigator.of(
                                  sheetContext,
                                  rootNavigator: true,
                                ).pop(true);
                              } catch (e) {
                                if (!sheetContext.mounted) return;

                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Une erreur est survenue. Veuillez réessayer.',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: Icon(
                              modification ? Icons.edit_outlined : Icons.add,
                            ),
                            label: Text(
                              modification
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
            ),
          );
        },
      );

      // On revient ici uniquement après la fermeture du BottomSheet.
      if (!mounted) return;

      if (resultat == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              modification
                  ? 'Fournisseur modifié avec succès.'
                  : 'Fournisseur ajouté avec succès.',
            ),
          ),
        );
      }
    } finally {
      // Libération propre des controllers
      nomController.dispose();
      telephoneController.dispose();
      produitController.dispose();
      adresseController.dispose();
    }
  }

  // ============================================================
  // SUPPRIMER UN FOURNISSEUR
  // ============================================================

  Future<void> supprimerFournisseur(String fournisseurId) async {
    final confirmation = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Supprimer le fournisseur'),
          content: const Text(
            'Voulez-vous vraiment supprimer ce fournisseur ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext, rootNavigator: true).pop(false);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext, rootNavigator: true).pop(true);
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirmation != true) return;

    try {
      // Chercher les activités associées au fournisseur
      final activitesSnapshot = await firestoreService.activites
          .where('fournisseurId', isEqualTo: fournisseurId)
          .get();

      if (!mounted) return;

      final batch = FirebaseFirestore.instance.batch();

      // Supprimer le fournisseur
      batch.delete(firestoreService.fournisseurs.doc(fournisseurId));

      // Supprimer automatiquement les activités associées
      for (final activite in activitesSnapshot.docs) {
        batch.delete(activite.reference);
      }

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fournisseur supprimé avec succès.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de supprimer ce fournisseur.'),
        ),
      );
    }
  }

  // ============================================================
  // INTERFACE PRINCIPALE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),

      appBar: AppBar(
        backgroundColor: couleurPrincipale,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Fournisseurs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ==========================================================
      // BOUTON AJOUTER
      // ==========================================================
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: couleurPrincipale,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
        onPressed: () {
          afficherFormulaire();
        },
      ),

      // ==========================================================
      // LISTE DES FOURNISSEURS
      // ==========================================================
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestoreService.fournisseurs
            .orderBy('dateCreation', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Chargement
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Erreur
          if (snapshot.hasError) {
            return const Center(
              child: Text('Impossible de charger les fournisseurs.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final fournisseurs = snapshot.data!.docs;

          // ======================================================
          // AUCUN FOURNISSEUR
          // ======================================================

          if (fournisseurs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: couleurPrincipale,
                  ),

                  SizedBox(height: 15),

                  Text(
                    'Aucun fournisseur',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 5),

                  Text('Ajoutez vos fournisseurs ici.'),
                ],
              ),
            );
          }

          // ======================================================
          // LISTE
          // ======================================================

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: fournisseurs.length,
            itemBuilder: (context, index) {
              final document = fournisseurs[index];

              final fournisseur = document.data();

              final nom = fournisseur['nom']?.toString() ?? 'Sans nom';

              final telephone = fournisseur['telephone']?.toString() ?? '';

              final produit = fournisseur['produit']?.toString() ?? '';

              final adresse = fournisseur['adresse']?.toString() ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // ICONE
                    // ==================================================
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2EE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: couleurPrincipale,
                      ),
                    ),

                    const SizedBox(width: 14),

                    // ==================================================
                    // INFORMATIONS
                    // ==================================================
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nom,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Row(
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  telephone,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 5),

                          Row(
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  produit,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 5),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  adresse,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ==================================================
                    // MENU TROIS POINTS
                    // ==================================================
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: couleurPrincipale,
                      ),

                      // IMPORTANT :
                      // On attend que le menu soit totalement fermé
                      // avant d'ouvrir un Dialog ou un BottomSheet.
                      onSelected: (value) {
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          // Petite attente supplémentaire pour Android
                          await Future.delayed(
                            const Duration(milliseconds: 150),
                          );

                          if (!mounted) return;

                          if (value == 'modifier') {
                            await afficherFormulaire(
                              fournisseurId: document.id,
                              fournisseur: fournisseur,
                            );
                          } else if (value == 'supprimer') {
                            await supprimerFournisseur(document.id);
                          }
                        });
                      },

                      itemBuilder: (menuContext) => const [
                        PopupMenuItem<String>(
                          value: 'modifier',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                color: couleurPrincipale,
                              ),
                              SizedBox(width: 10),
                              Text('Modifier'),
                            ],
                          ),
                        ),

                        PopupMenuItem<String>(
                          value: 'supprimer',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 10),
                              Text(
                                'Supprimer',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
uuuuuuuuu