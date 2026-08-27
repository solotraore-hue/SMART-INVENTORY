import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import 'vente_form_page.dart';

class VentesPage extends StatefulWidget {
  const VentesPage({super.key});

  @override
  State<VentesPage> createState() => _VentesPageState();
}

class _VentesPageState extends State<VentesPage> {
  static const Color couleurPrincipale = Color(0xFF15576B);
  static const Color couleurSecondaire = Color(0xFF0E6B7F);
  static const Color couleurClaire = Color(0xFFE0F2EE);
  static const Color couleurFond = Color(0xFFF5F6F8);

  final FirestoreService firestoreService = FirestoreService();

  // FORMAT DES MONTANTS

  String formaterMontant(num montant) {
    final texte = montant.toStringAsFixed(0);
    final resultat = StringBuffer();

    for (int i = 0; i < texte.length; i++) {
      final positionRestante = texte.length - i;

      resultat.write(texte[i]);

      if (positionRestante > 1 && positionRestante % 3 == 1) {
        resultat.write(' ');
      }
    }

    return resultat.toString();
  }

  // PRODUITS D'UNE VENTE

  List<Map<String, dynamic>> recupererProduitsVente(
    Map<String, dynamic> vente,
  ) {
    final valeur = vente['produits'];

    if (valeur is List) {
      return valeur
          .whereType<Map>()
          .map((produit) => Map<String, dynamic>.from(produit))
          .toList();
    }

    final produitId = vente['produitId']?.toString();

    if (produitId != null && produitId.isNotEmpty) {
      return [
        {
          'produitId': produitId,
          'nom': vente['nomProduit'] ?? vente['produit'] ?? 'Produit',
          'quantite': vente['quantite'] ?? 0,
          'prixUnitaire': vente['prixUnitaire'] ?? 0,
          'sousTotal': vente['montantTotal'] ?? 0,
        },
      ];
    }

    return [];
  }

  // OUVRIR AJOUT / MODIFICATION

  Future<void> ouvrirFormulaire({
    String? venteId,
    Map<String, dynamic>? vente,
  }) async {
    final resultat = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VenteFormPage(venteId: venteId, vente: vente),
      ),
    );

    if (!mounted) {
      return;
    }

    if (resultat == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            venteId == null
                ? 'Vente enregistrée avec succès.'
                : 'Vente modifiée avec succès.',
          ),
        ),
      );
    }
  }

  // TROIS POINTS

  Future<void> ouvrirActions({
    required String venteId,
    required Map<String, dynamic> vente,
  }) async {
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Actions',
            style: TextStyle(
              color: couleurPrincipale,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // MODIFIER
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: couleurPrincipale,
                ),
                title: const Text('Modifier'),
                onTap: () {
                  Navigator.of(dialogContext).pop('modifier');
                },
              ),

              // SUPPRIMER
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Supprimer'),
                onTap: () {
                  Navigator.of(dialogContext).pop('supprimer');
                },
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    if (action == 'modifier') {
      await ouvrirFormulaire(venteId: venteId, vente: vente);
    }

    if (action == 'supprimer') {
      await supprimerVente(venteId: venteId, vente: vente);
    }
  }

  // SUPPRIMER UNE VENTE

  Future<void> supprimerVente({
    required String venteId,
    required Map<String, dynamic> vente,
  }) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Supprimer la vente',
            style: TextStyle(
              color: couleurPrincipale,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Voulez-vous vraiment supprimer cette vente ?\n\n'
            'Les quantités vendues seront remises dans le stock.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Annuler'),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmation != true) {
      return;
    }

    try {
      final produits = recupererProduitsVente(vente);

      final activitesSnapshot = await firestoreService.activites
          .where('venteId', isEqualTo: venteId)
          .get();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final List<DocumentSnapshot<Map<String, dynamic>>> produitsSnapshots =
            [];

        final List<Map<String, dynamic>> produitsExistants = [];

        // LECTURES

        for (final produit in produits) {
          final produitId = produit['produitId']?.toString();

          if (produitId == null || produitId.isEmpty) {
            continue;
          }

          final snapshot = await transaction.get(
            firestoreService.produits.doc(produitId),
          );

          if (snapshot.exists) {
            produitsSnapshots.add(snapshot);

            produitsExistants.add(produit);
          }
        }

        // RESTAURER STOCK

        for (int i = 0; i < produitsSnapshots.length; i++) {
          final snapshot = produitsSnapshots[i];

          final produit = produitsExistants[i];

          final stock = (snapshot.data()?['quantite'] as num?)?.toInt() ?? 0;

          final quantite = (produit['quantite'] as num?)?.toInt() ?? 0;

          transaction.update(snapshot.reference, {
            'quantite': stock + quantite,
            'dateModification': FieldValue.serverTimestamp(),
          });
        }

        // SUPPRIMER VENTE

        transaction.delete(firestoreService.ventes.doc(venteId));

        // SUPPRIMER ACTIVITÉS

        for (final activite in activitesSnapshot.docs) {
          transaction.delete(activite.reference);
        }
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vente supprimée. Le stock a été restauré.'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de supprimer la vente : $e')),
      );
    }
  }

  // CARTE TOTAL

  Widget carteTotalVentes({
    required double chiffreAffaires,
    required int nombreVentes,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [couleurPrincipale, couleurSecondaire],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chiffre d’affaires total',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),

          const SizedBox(height: 12),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${formaterMontant(chiffreAffaires)} FCFA',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            '$nombreVentes vente(s) enregistrée(s)',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // CARTE VENTE

  Widget carteVente({
    required String venteId,
    required Map<String, dynamic> vente,
  }) {
    final produits = recupererProduitsVente(vente);

    final montantTotal = (vente['montantTotal'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: couleurClaire,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: couleurPrincipale,
              size: 31,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: produits.isEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vente',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '${formaterMontant(montantTotal)} FCFA',
                        style: const TextStyle(
                          color: couleurPrincipale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...produits.asMap().entries.map((entree) {
                        final produit = entree.value;

                        final nom = produit['nom']?.toString() ?? 'Produit';

                        final quantite =
                            (produit['quantite'] as num?)?.toInt() ?? 0;

                        final sousTotal =
                            (produit['sousTotal'] as num?)?.toDouble() ?? 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
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

                              Text(
                                'Quantité vendue : $quantite',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                '${formaterMontant(sousTotal)} FCFA',
                                style: const TextStyle(
                                  color: couleurPrincipale,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      if (produits.length > 1) ...[
                        const Divider(),

                        Text(
                          'Total : ${formaterMontant(montantTotal)} FCFA',
                          style: const TextStyle(
                            color: couleurPrincipale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),

          // TROIS POINTS
          IconButton(
            tooltip: 'Actions',
            onPressed: () {
              ouvrirActions(venteId: venteId, vente: vente);
            },
            icon: const Icon(
              Icons.more_vert,
              color: couleurPrincipale,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  // INTERFACE

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: couleurFond,

      appBar: AppBar(
        toolbarHeight: 82,
        title: const Text(
          'Ventes',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ouvrirFormulaire();
        },
        icon: const Icon(Icons.add, size: 27),
        label: const Text(
          'Nouvelle vente',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestoreService.ventes.snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: couleurPrincipale),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Impossible de charger les ventes.\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final ventes = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            snapshot.data?.docs ?? [],
          );

          // TRI

          ventes.sort((a, b) {
            final dateA = a.data()['date'];

            final dateB = b.data()['date'];

            if (dateA is Timestamp && dateB is Timestamp) {
              return dateB.compareTo(dateA);
            }

            if (dateA is Timestamp) {
              return -1;
            }

            if (dateB is Timestamp) {
              return 1;
            }

            return 0;
          });

          // TOTAL

          double chiffreAffaires = 0;

          for (final document in ventes) {
            chiffreAffaires +=
                (document.data()['montantTotal'] as num?)?.toDouble() ?? 0;
          }

          return Column(
            children: [
              carteTotalVentes(
                chiffreAffaires: chiffreAffaires,
                nombreVentes: ventes.length,
              ),

              const SizedBox(height: 5),

              Expanded(
                child: ventes.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune vente enregistrée.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 105),
                        itemCount: ventes.length,
                        itemBuilder: (context, index) {
                          final document = ventes[index];

                          return carteVente(
                            venteId: document.id,
                            vente: document.data(),
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
