import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class ProduitsPage extends StatefulWidget {
  const ProduitsPage({super.key});

  @override
  State<ProduitsPage> createState() => _ProduitsPageState();
}

class _ProduitsPageState extends State<ProduitsPage> {
  final firestoreService = FirestoreService();

  Future<void> afficherFormulaire({
    String? produitId,
    Map<String, dynamic>? produit,
  }) async {
    final formKey = GlobalKey<FormState>();

    final nomController = TextEditingController(
      text: produit?['nom']?.toString() ?? '',
    );

    final quantiteController = TextEditingController(
      text: produit?['quantite']?.toString() ?? '',
    );

    final prixController = TextEditingController(
      text: produit?['prixUnitaire']?.toString() ?? '',
    );

    final seuilController = TextEditingController(
      text: produit?['seuilAlerte']?.toString() ?? '',
    );

    final modification = produitId != null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext)
                .viewInsets
                .bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                          ? 'Modifier le produit'
                          : 'Ajouter un produit',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15576B),
                      ),
                    ),

                    const SizedBox(height: 25),

                    TextFormField(
                      controller: nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du produit',
                        prefixIcon: Icon(
                          Icons.inventory_2_outlined,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Le nom du produit est obligatoire';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: quantiteController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantité',
                        prefixIcon: Icon(
                          Icons.numbers_outlined,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'La quantité est obligatoire';
                        }

                        final quantite =
                            int.tryParse(value.trim());

                        if (quantite == null ||
                            quantite < 0) {
                          return 'Veuillez saisir une quantité valide';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: prixController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Prix unitaire (FCFA)',
                        prefixIcon: Icon(
                          Icons.payments_outlined,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Le prix unitaire est obligatoire';
                        }

                        final prix =
                            num.tryParse(value.trim());

                        if (prix == null || prix < 0) {
                          return 'Veuillez saisir un prix valide';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: seuilController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Seuil d’alerte',
                        prefixIcon: Icon(
                          Icons.warning_amber_outlined,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Le seuil d’alerte est obligatoire';
                        }

                        final seuil =
                            int.tryParse(value.trim());

                        if (seuil == null || seuil < 0) {
                          return 'Veuillez saisir un seuil valide';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF15576B),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!
                              .validate()) {
                            return;
                          }

                          final donnees = {
                            'nom': nomController.text.trim(),
                            'quantite': int.parse(
                              quantiteController.text.trim(),
                            ),
                            'prixUnitaire': num.parse(
                              prixController.text.trim(),
                            ),
                            'seuilAlerte': int.parse(
                              seuilController.text.trim(),
                            ),
                          };

                          try {
                            if (modification) {
                              await firestoreService.produits
                                  .doc(produitId)
                                  .update(donnees);

                              // Supprime les anciennes activités
                              // liées à ce produit.
                              final anciennesActivites =
                                  await firestoreService.activites
                                      .where(
                                        'produitId',
                                        isEqualTo: produitId,
                                      )
                                      .get();

                              final batch =
                                  FirebaseFirestore.instance.batch();

                              for (final activite
                                  in anciennesActivites.docs) {
                                batch.delete(
                                  activite.reference,
                                );
                              }

                              // Nouvelle activité.
                              final activiteReference =
                                  firestoreService.activites.doc();

                              batch.set(
                                activiteReference,
                                {
                                  'titre': 'Produit modifié',
                                  'description':
                                      nomController.text.trim(),
                                  'type': 'produit',
                                  'produitId': produitId,
                                  'date':
                                      FieldValue.serverTimestamp(),
                                },
                              );

                              await batch.commit();
                            } else {
                              final nouveauProduit =
                                  await firestoreService.produits
                                      .add({
                                ...donnees,
                                'dateCreation':
                                    FieldValue.serverTimestamp(),
                              });

                              await firestoreService.activites
                                  .add({
                                'titre': 'Nouveau produit',
                                'description':
                                    nomController.text.trim(),
                                'type': 'produit',
                                'produitId':
                                    nouveauProduit.id,
                                'date':
                                    FieldValue.serverTimestamp(),
                              });
                            }

                            if (!bottomSheetContext.mounted) {
                              return;
                            }

                            Navigator.pop(bottomSheetContext);

                            if (!mounted) return;

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  modification
                                      ? 'Produit modifié avec succès'
                                      : 'Produit ajouté avec succès',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Une erreur est survenue.',
                                ),
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          modification
                              ? Icons.save_outlined
                              : Icons.add,
                        ),
                        label: Text(
                          modification
                              ? 'Enregistrer'
                              : 'Ajouter le produit',
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    nomController.dispose();
    quantiteController.dispose();
    prixController.dispose();
    seuilController.dispose();
  }

  Future<void> supprimerProduit(
    String produitId,
    String nomProduit,
  ) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer le produit'),
          content: Text(
            'Voulez-vous vraiment supprimer "$nomProduit" ?\n\n'
            'Les ventes, approvisionnements et activités '
            'liés à ce produit seront également supprimés.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmation != true) return;

    try {
      // Récupération de toutes les données liées.
      final activites = await firestoreService.activites
          .where(
            'produitId',
            isEqualTo: produitId,
          )
          .get();

      final ventes = await firestoreService.ventes
          .where(
            'produitId',
            isEqualTo: produitId,
          )
          .get();

      final approvisionnements =
          await firestoreService.approvisionnements
              .where(
                'produitId',
                isEqualTo: produitId,
              )
              .get();

      final batch = FirebaseFirestore.instance.batch();

      // Suppression des activités.
      for (final activite in activites.docs) {
        batch.delete(activite.reference);
      }

      // Suppression des ventes.
      for (final vente in ventes.docs) {
        batch.delete(vente.reference);
      }

      // Suppression des approvisionnements.
      for (final approvisionnement
          in approvisionnements.docs) {
        batch.delete(approvisionnement.reference);
      }

      // Suppression du produit.
      batch.delete(
        firestoreService.produits.doc(produitId),
      );

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Produit et toutes ses données associées supprimés.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de supprimer le produit.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF15576B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Produits',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF15576B),
        foregroundColor: Colors.white,
        onPressed: () {
          afficherFormulaire();
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: firestoreService.produits
            .orderBy(
              'dateCreation',
              descending: true,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Impossible de charger les produits.',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final produits = snapshot.data!.docs;

          if (produits.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Color(0xFF15576B),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Aucun produit',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Ajoutez votre premier produit.',
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              100,
            ),
            itemCount: produits.length,
            itemBuilder: (context, index) {
              final document = produits[index];
              final produit = document.data();

              final nom =
                  produit['nom']?.toString() ?? '';

              final quantite =
                  produit['quantite'] ?? 0;

              final prix =
                  produit['prixUnitaire'] ?? 0;

              final seuil =
                  produit['seuilAlerte'] ?? 0;

              final alerte =
                  quantite <= seuil;

              return Container(
                margin: const EdgeInsets.only(
                  bottom: 12,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(18),
                  border: alerte
                      ? Border.all(
                          color: Colors.red.shade300,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: alerte
                            ? Colors.red.shade50
                            : const Color(0xFFE0F2EE),
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: Icon(
                        alerte
                            ? Icons.warning_amber_outlined
                            : Icons.inventory_2_outlined,
                        color: alerte
                            ? Colors.red
                            : const Color(0xFF15576B),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            nom,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            'Qté : $quantite',
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'P.U : $prix FCFA',
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),

                          if (alerte) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Stock faible — seuil : $seuil',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Color(0xFF15576B),
                      ),
                      onSelected: (value) {
                        if (value == 'modifier') {
                          afficherFormulaire(
                            produitId: document.id,
                            produit: produit,
                          );
                        }

                        if (value == 'supprimer') {
                          supprimerProduit(
                            document.id,
                            nom,
                          );
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'modifier',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 10),
                              Text('Modifier'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'supprimer',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Supprimer',
                                style: TextStyle(
                                  color: Colors.red,
                                ),
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