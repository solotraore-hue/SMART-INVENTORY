import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class VentesPage extends StatefulWidget {
  const VentesPage({super.key});

  @override
  State<VentesPage> createState() => _VentesPageState();
}

class _VentesPageState extends State<VentesPage> {
  final firestoreService = FirestoreService();

  Future<void> nouvelleVente() async {
    final formKey = GlobalKey<FormState>();

    String? produitId;
    String? nomProduit;
    int? quantiteDisponible;

    final quantiteController = TextEditingController();

    final produitsSnapshot =
        await firestoreService.produits.get();

    if (!mounted) return;

    if (produitsSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ajoutez d’abord un produit avant de faire une vente.',
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
                          'Nouvelle vente',
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
                                '${produit['nom']} (${produit['quantite']} disponible)',
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

                              quantiteDisponible =
                                  produit.data()['quantite'] as int?;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Veuillez sélectionner un produit';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        if (quantiteDisponible != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Quantité disponible : $quantiteDisponible',
                              style: const TextStyle(
                                color: Color(0xFF15576B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: quantiteController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantité vendue',
                            prefixIcon: Icon(
                              Icons.shopping_cart_outlined,
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

                            if (quantiteDisponible != null &&
                                quantite >
                                    quantiteDisponible!) {
                              return 'La quantité vendue dépasse le stock disponible';
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

                              final quantiteVendue = int.parse(
                                quantiteController.text.trim(),
                              );

                              try {
                                final produitReference =
                                    firestoreService.produits
                                        .doc(produitId);

                                final venteReference =
                                    firestoreService.ventes.doc();

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

                                    if (quantiteVendue >
                                        stockActuel) {
                                      throw Exception(
                                        'Stock insuffisant',
                                      );
                                    }

                                    final prixUnitaire =
                                        (produit['prixUnitaire'] ?? 0)
                                            as num;

                                    final montantTotal =
                                        quantiteVendue *
                                            prixUnitaire;

                                    transaction.update(
                                      produitReference,
                                      {
                                        'quantite':
                                            stockActuel -
                                                quantiteVendue,
                                      },
                                    );

                                    transaction.set(
                                      venteReference,
                                      {
                                        'produitId': produitId,
                                        'nomProduit': nomProduit,
                                        'quantite':
                                            quantiteVendue,
                                        'prixUnitaire':
                                            prixUnitaire,
                                        'montantTotal':
                                            montantTotal,
                                        'date':
                                            FieldValue.serverTimestamp(),
                                      },
                                    );

                                    transaction.set(
                                      activiteReference,
                                      {
                                        'titre':
                                            'Vente enregistrée',
                                        'description':
                                            '$quantiteVendue unité(s) de $nomProduit',
                                        'type': 'vente',
                                        'produitId': produitId,
                                        'venteId':
                                            venteReference.id,
                                        'date':
                                            FieldValue.serverTimestamp(),
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
                                      'Vente enregistrée avec succès',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().contains(
                                        'Stock insuffisant',
                                      )
                                          ? 'Stock insuffisant. Vente impossible.'
                                          : 'Une erreur est survenue lors de la vente.',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.shopping_cart_checkout,
                            ),
                            label: const Text(
                              'Enregistrer la vente',
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

    quantiteController.dispose();
  }

  Future<void> supprimerVente(
    String venteId,
    Map<String, dynamic> vente,
  ) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer la vente'),
          content: const Text(
            'Voulez-vous vraiment supprimer cette vente ? '
            'La quantité vendue sera remise dans le stock.',
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
      final produitId = vente['produitId'];
      final quantiteVendue =
          (vente['quantite'] ?? 0) as int;

      final produitReference =
          firestoreService.produits.doc(produitId);

      final venteReference =
          firestoreService.ventes.doc(venteId);

      final activitesSnapshot =
          await firestoreService.activites
              .where(
                'venteId',
                isEqualTo: venteId,
              )
              .get();

      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          final produitSnapshot =
              await transaction.get(produitReference);

          if (produitSnapshot.exists) {
            final produit = produitSnapshot.data()!;

            final stockActuel =
                (produit['quantite'] ?? 0) as int;

            transaction.update(
              produitReference,
              {
                'quantite':
                    stockActuel + quantiteVendue,
              },
            );
          }

          transaction.delete(venteReference);

          for (final activite
              in activitesSnapshot.docs) {
            transaction.delete(activite.reference);
          }
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vente supprimée et stock restauré.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de supprimer cette vente.',
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
          'Ventes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF15576B),
        foregroundColor: Colors.white,
        onPressed: nouvelleVente,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle vente'),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: firestoreService.ventes
            .orderBy(
              'date',
              descending: true,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Impossible de charger les ventes.',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final ventes = snapshot.data!.docs;

          double chiffreAffaires = 0;

          for (final vente in ventes) {
            final montant =
                vente.data()['montantTotal'] ?? 0;

            if (montant is num) {
              chiffreAffaires += montant.toDouble();
            }
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF15576B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chiffre d’affaires total',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${chiffreAffaires.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      '${ventes.length} vente(s) enregistrée(s)',
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ventes.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 80,
                              color: Color(0xFF15576B),
                            ),
                            SizedBox(height: 15),
                            Text(
                              'Aucune vente',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Vos ventes apparaîtront ici.',
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          100,
                        ),
                        itemCount: ventes.length,
                        itemBuilder:
                            (context, index) {
                          final document =
                              ventes[index];

                          final vente =
                              document.data();

                          final nomProduit =
                              vente['nomProduit']
                                      ?.toString() ??
                                  '';

                          final quantite =
                              vente['quantite'] ?? 0;

                          final montant =
                              (vente['montantTotal'] ??
                                      0)
                                  as num;

                          return Container(
                            margin:
                                const EdgeInsets.only(
                              bottom: 12,
                            ),
                            padding:
                                const EdgeInsets.all(
                              16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(
                                18,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        const Color(
                                      0xFFE0F2EE,
                                    ),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      14,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons
                                        .shopping_cart_outlined,
                                    color: Color(
                                      0xFF15576B,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  width: 14,
                                ),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        nomProduit,
                                        style:
                                            const TextStyle(
                                          fontSize: 17,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 5,
                                      ),

                                      Text(
                                        'Quantité vendue : $quantite',
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.grey,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 4,
                                      ),

                                      Text(
                                        '${montant.toStringAsFixed(0)} FCFA',
                                        style:
                                            const TextStyle(
                                          color: Color(
                                            0xFF15576B,
                                          ),
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value ==
                                        'supprimer') {
                                      supprimerVente(
                                        document.id,
                                        vente,
                                      );
                                    }
                                  },
                                  itemBuilder:
                                      (context) => const [
                                    PopupMenuItem(
                                      value:
                                          'supprimer',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons
                                                .delete_outline,
                                            color:
                                                Colors.red,
                                          ),
                                          SizedBox(
                                            width: 8,
                                          ),
                                          Text(
                                            'Supprimer',
                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.red,
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
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}