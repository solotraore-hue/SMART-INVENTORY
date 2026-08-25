import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class ApprovisionnementPage extends StatefulWidget {
  const ApprovisionnementPage({super.key});

  @override
  State<ApprovisionnementPage> createState() =>
      _ApprovisionnementPageState();
}

class _ApprovisionnementPageState
    extends State<ApprovisionnementPage> {
  final firestoreService = FirestoreService();

  Future<void> nouvelApprovisionnement() async {
    final formKey = GlobalKey<FormState>();

    String? produitId;
    String? nomProduit;

    final quantiteController = TextEditingController();

    try {
      final produitsSnapshot =
          await firestoreService.produits.get();

      if (!mounted) return;

      if (produitsSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ajoutez d’abord un produit avant de faire un approvisionnement.',
            ),
          ),
        );
        return;
      }

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (bottomSheetContext) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
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

                          const Text(
                            'Nouvel approvisionnement',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15576B),
                            ),
                          ),

                          const SizedBox(height: 25),

                          DropdownButtonFormField<String>(
                            value: produitId,
                            decoration: const InputDecoration(
                              labelText: 'Produit',
                              prefixIcon: Icon(
                                Icons.inventory_2_outlined,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            items: produitsSnapshot.docs.map((doc) {
                              final produit = doc.data();

                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(
                                  produit['nom']?.toString() ??
                                      'Produit sans nom',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              final produit =
                                  produitsSnapshot.docs.firstWhere(
                                (doc) => doc.id == value,
                              );

                              setModalState(() {
                                produitId = value;
                                nomProduit =
                                    produit.data()['nom']?.toString();
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Veuillez sélectionner un produit';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          TextFormField(
                            controller: quantiteController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantité reçue',
                              prefixIcon: Icon(
                                Icons.add_box_outlined,
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
                                  quantite <= 0) {
                                return 'Veuillez saisir une quantité valide';
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

                                final quantiteRecue = int.parse(
                                  quantiteController.text.trim(),
                                );

                                try {
                                  final produitReference =
                                      firestoreService.produits
                                          .doc(produitId);

                                  final approvisionnementReference =
                                      firestoreService
                                          .approvisionnements
                                          .doc();

                                  final activiteReference =
                                      firestoreService.activites.doc();

                                  await FirebaseFirestore.instance
                                      .runTransaction(
                                    (transaction) async {
                                      final produitSnapshot =
                                          await transaction.get(
                                        produitReference,
                                      );

                                      if (!produitSnapshot.exists) {
                                        throw Exception(
                                          'Produit introuvable',
                                        );
                                      }

                                      final produit =
                                          produitSnapshot.data()!;

                                      final stockActuel =
                                          (produit['quantite'] ?? 0)
                                              as int;

                                      final nouveauStock =
                                          stockActuel + quantiteRecue;

                                      transaction.update(
                                        produitReference,
                                        {
                                          'quantite': nouveauStock,
                                        },
                                      );

                                      transaction.set(
                                        approvisionnementReference,
                                        {
                                          'produitId': produitId,
                                          'nomProduit': nomProduit,
                                          'quantite': quantiteRecue,
                                          'date': FieldValue
                                              .serverTimestamp(),
                                        },
                                      );

                                      transaction.set(
                                        activiteReference,
                                        {
                                          'titre':
                                              'Approvisionnement enregistré',
                                          'description':
                                              '$quantiteRecue unité(s) de $nomProduit',
                                          'type':
                                              'approvisionnement',
                                          'produitId': produitId,
                                          'approvisionnementId':
                                              approvisionnementReference.id,
                                          'date': FieldValue
                                              .serverTimestamp(),
                                        },
                                      );
                                    },
                                  );

                                  if (!bottomSheetContext.mounted) {
                                    return;
                                  }

                                  Navigator.pop(
                                    bottomSheetContext,
                                  );

                                  if (!mounted) return;

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Approvisionnement enregistré avec succès.',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Impossible d’enregistrer cet approvisionnement.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.save_outlined,
                              ),
                              label: const Text(
                                'Enregistrer',
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
        },
      );
    } finally {
      quantiteController.dispose();
    }
  }

  Future<void> supprimerApprovisionnement(
    String approvisionnementId,
    Map<String, dynamic> approvisionnement,
  ) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Supprimer l’approvisionnement',
          ),
          content: const Text(
            'Voulez-vous vraiment supprimer cet approvisionnement ? '
            'La quantité correspondante sera retirée du stock.',
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
      final produitId =
          approvisionnement['produitId']?.toString();

      final quantite =
          (approvisionnement['quantite'] ?? 0) as int;

      final approvisionnementReference =
          firestoreService.approvisionnements
              .doc(approvisionnementId);

      final activitesSnapshot =
          await firestoreService.activites
              .where(
                'approvisionnementId',
                isEqualTo: approvisionnementId,
              )
              .get();

      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          if (produitId != null && produitId.isNotEmpty) {
            final produitReference =
                firestoreService.produits.doc(produitId);

            final produitSnapshot =
                await transaction.get(produitReference);

            if (produitSnapshot.exists) {
              final produit = produitSnapshot.data()!;

              final stockActuel =
                  (produit['quantite'] ?? 0) as int;

              final nouveauStock = stockActuel - quantite;

              transaction.update(
                produitReference,
                {
                  'quantite':
                      nouveauStock < 0 ? 0 : nouveauStock,
                },
              );
            }
          }

          transaction.delete(approvisionnementReference);

          for (final activite in activitesSnapshot.docs) {
            transaction.delete(activite.reference);
          }
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Approvisionnement supprimé et stock mis à jour.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de supprimer cet approvisionnement.',
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
          'Approvisionnement',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF15576B),
        foregroundColor: Colors.white,
        onPressed: nouvelApprovisionnement,
        icon: const Icon(Icons.add),
        label: const Text(
          'Ajouter',
        ),
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: firestoreService.approvisionnements
            .orderBy(
              'date',
              descending: true,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Impossible de charger les approvisionnements.',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final approvisionnements =
              snapshot.data!.docs;

          if (approvisionnements.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 80,
                    color: Color(0xFF15576B),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Aucun approvisionnement',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Vos approvisionnements apparaîtront ici.',
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
            itemCount: approvisionnements.length,
            itemBuilder: (context, index) {
              final document =
                  approvisionnements[index];

              final approvisionnement =
                  document.data();

              final nomProduit =
                  approvisionnement['nomProduit']
                          ?.toString() ??
                      'Produit';

              final quantite =
                  approvisionnement['quantite'] ?? 0;

              return Container(
                margin: const EdgeInsets.only(
                  bottom: 12,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2EE),
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.local_shipping_outlined,
                        color: Color(0xFF15576B),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            nomProduit,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            'Quantité reçue : $quantite',
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Color(0xFF15576B),
                      ),
                      onSelected: (value) {
                        if (value == 'supprimer') {
                          supprimerApprovisionnement(
                            document.id,
                            approvisionnement,
                          );
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'supprimer',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              SizedBox(width: 8),
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