import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import 'approvisionnement_form_page.dart';

class ApprovisionnementPage extends StatefulWidget {
  const ApprovisionnementPage({super.key});

  @override
  State<ApprovisionnementPage> createState() => _ApprovisionnementPageState();
}

class _ApprovisionnementPageState extends State<ApprovisionnementPage> {
  // COULEURS

  static const Color couleurPrincipale = Color(0xFF15576B);
  static const Color couleurSecondaire = Color(0xFF0E6B7F);
  static const Color couleurClaire = Color(0xFFE0F2EE);
  static const Color couleurFond = Color(0xFFF5F6F8);

  // FIRESTORE

  final FirestoreService firestoreService = FirestoreService();

  // OUVRIR LE FORMULAIRE
  // AJOUT OU MODIFICATION

  Future<void> ouvrirFormulaire({
    String? approvisionnementId,
    Map<String, dynamic>? approvisionnement,
  }) async {
    final resultat = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ApprovisionnementFormPage(
          approvisionnementId: approvisionnementId,
          approvisionnement: approvisionnement,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (resultat == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approvisionnementId == null
                ? 'Approvisionnement enregistré avec succès.'
                : 'Approvisionnement modifié avec succès.',
          ),
        ),
      );
    }
  }

  // TROIS POINTS

  Future<void> ouvrirActions({
    required String approvisionnementId,
    required Map<String, dynamic> approvisionnement,
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

    // MODIFIER

    if (action == 'modifier') {
      await ouvrirFormulaire(
        approvisionnementId: approvisionnementId,
        approvisionnement: approvisionnement,
      );
    }

    // SUPPRIMER

    if (action == 'supprimer') {
      await supprimerApprovisionnement(
        approvisionnementId: approvisionnementId,
        approvisionnement: approvisionnement,
      );
    }
  }

  // SUPPRIMER

  Future<void> supprimerApprovisionnement({
    required String approvisionnementId,
    required Map<String, dynamic> approvisionnement,
  }) async {
    final nomProduit = approvisionnement['nomProduit']?.toString() ?? 'Produit';

    final quantite = (approvisionnement['quantite'] as num?)?.toInt() ?? 0;

    final confirmation = await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          title: const Text(
            'Supprimer l’approvisionnement',
            style: TextStyle(
              color: couleurPrincipale,
              fontWeight: FontWeight.bold,
            ),
          ),

          content: Text(
            'Voulez-vous vraiment supprimer la réception '
            'de $quantite unité(s) de "$nomProduit" ?\n\n'
            'La quantité correspondante sera retirée du stock.',
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
      final produitId = approvisionnement['produitId']?.toString();

      // ACTIVITÉS

      final activitesSnapshot = await firestoreService.activites
          .where('approvisionnementId', isEqualTo: approvisionnementId)
          .get();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // RETIRER DU STOCK

        if (produitId != null && produitId.isNotEmpty) {
          final produitReference = firestoreService.produits.doc(produitId);

          final produitSnapshot = await transaction.get(produitReference);

          if (produitSnapshot.exists) {
            final produit = produitSnapshot.data();

            final stockActuel = (produit?['quantite'] as num?)?.toInt() ?? 0;

            if (stockActuel < quantite) {
              throw Exception(
                'Impossible de supprimer cet approvisionnement. '
                'Le stock actuel de "$nomProduit" est insuffisant.',
              );
            }

            transaction.update(produitReference, {
              'quantite': stockActuel - quantite,

              'dateModification': FieldValue.serverTimestamp(),
            });
          }
        }

        // SUPPRIMER APPROVISIONNEMENT

        transaction.delete(
          firestoreService.approvisionnements.doc(approvisionnementId),
        );

        // SUPPRIMER ACTIVITÉ

        for (final activite in activitesSnapshot.docs) {
          transaction.delete(activite.reference);
        }
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Approvisionnement supprimé avec succès.'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      String message = e.toString();

      message = message.replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // TOTAL REÇU

  Widget carteTotalRecu({
    required int totalQuantite,
    required int totalReceptions,
  }) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.fromLTRB(18, 18, 18, 10),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),

        gradient: const LinearGradient(
          colors: [couleurPrincipale, couleurSecondaire],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.10),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,

            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(15),
            ),

            child: const Icon(
              Icons.local_shipping_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Total reçu',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),

                const SizedBox(height: 5),

                Text(
                  '$totalQuantite unité(s)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '$totalReceptions réception(s) enregistrée(s)',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // CARTE APPROVISIONNEMENT

  Widget carteApprovisionnement({
    required String approvisionnementId,
    required Map<String, dynamic> approvisionnement,
  }) {
    final nomProduit = approvisionnement['nomProduit']?.toString() ?? 'Produit';

    final quantite = (approvisionnement['quantite'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          // ICÔNE
          Container(
            width: 64,
            height: 64,

            decoration: BoxDecoration(
              color: couleurClaire,
              borderRadius: BorderRadius.circular(18),
            ),

            child: const Icon(
              Icons.local_shipping_outlined,
              color: couleurPrincipale,
              size: 30,
            ),
          ),

          const SizedBox(width: 16),

          // INFORMATIONS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  nomProduit,

                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Quantité reçue : $quantite',

                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),

          // TROIS POINTS
          IconButton(
            tooltip: 'Actions',

            onPressed: () {
              ouvrirActions(
                approvisionnementId: approvisionnementId,

                approvisionnement: approvisionnement,
              );
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
          'Approvisionnement',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
      ),

      // AJOUTER
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ouvrirFormulaire();
        },

        icon: const Icon(Icons.add, size: 27),

        label: const Text(
          'Ajouter',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // FIRESTORE
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestoreService.approvisionnements.snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: couleurPrincipale),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(25),

                child: Text(
                  'Impossible de charger les approvisionnements.\n'
                  '${snapshot.error}',

                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final approvisionnements =
              List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                snapshot.data?.docs ?? [],
              );

          // TRI DU PLUS RÉCENT

          approvisionnements.sort((a, b) {
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

          // TOTAL REÇU

          int totalQuantiteRecue = 0;

          for (final document in approvisionnements) {
            totalQuantiteRecue +=
                (document.data()['quantite'] as num?)?.toInt() ?? 0;
          }

          return Column(
            children: [
              // TOTAL EN HAUT
              carteTotalRecu(
                totalQuantite: totalQuantiteRecue,

                totalReceptions: approvisionnements.length,
              ),

              const SizedBox(height: 8),

              // LISTE
              Expanded(
                child: approvisionnements.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),

                          child: Column(
                            mainAxisSize: MainAxisSize.min,

                            children: [
                              Icon(
                                Icons.local_shipping_outlined,
                                size: 65,
                                color: couleurPrincipale,
                              ),

                              SizedBox(height: 18),

                              Text(
                                'Aucun approvisionnement',
                                style: TextStyle(
                                  color: couleurPrincipale,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: 8),

                              Text(
                                'Appuyez sur "Ajouter" pour enregistrer votre première réception.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 105),

                        itemCount: approvisionnements.length,

                        itemBuilder: (context, index) {
                          final document = approvisionnements[index];

                          return carteApprovisionnement(
                            approvisionnementId: document.id,

                            approvisionnement: document.data(),
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
