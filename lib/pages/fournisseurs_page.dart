import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import 'fournisseur_form_page.dart';

class FournisseursPage extends StatefulWidget {
  const FournisseursPage({super.key});

  @override
  State<FournisseursPage> createState() => _FournisseursPageState();
}

class _FournisseursPageState extends State<FournisseursPage> {
  // COULEURS

  static const Color couleurPrincipale = Color(0xFF15576B);
  static const Color couleurClaire = Color(0xFFE0F2EE);

  // FIRESTORE

  final FirestoreService firestoreService = FirestoreService();

  // OUVRIR AJOUT / MODIFICATION

  Future<void> ouvrirFormulaire({
    String? fournisseurId,
    Map<String, dynamic>? fournisseur,
  }) async {
    final resultat = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FournisseurFormPage(
          fournisseurId: fournisseurId,
          fournisseur: fournisseur,
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
            fournisseurId == null
                ? 'Fournisseur ajouté avec succès.'
                : 'Fournisseur modifié avec succès.',
          ),
        ),
      );
    }
  }

  // ACTIONS DES TROIS POINTS

  Future<void> ouvrirActions({
    required String fournisseurId,
    required Map<String, dynamic> fournisseur,
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
      await ouvrirFormulaire(
        fournisseurId: fournisseurId,
        fournisseur: fournisseur,
      );
    }

    if (action == 'supprimer') {
      await supprimerFournisseur(
        fournisseurId: fournisseurId,
        fournisseur: fournisseur,
      );
    }
  }

  // SUPPRIMER UN FOURNISSEUR

  Future<void> supprimerFournisseur({
    required String fournisseurId,
    required Map<String, dynamic> fournisseur,
  }) async {
    final nom = fournisseur['nom']?.toString() ?? 'ce fournisseur';

    // CONFIRMATION

    final confirmation = await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          title: const Text(
            'Supprimer le fournisseur',
            style: TextStyle(
              color: couleurPrincipale,
              fontWeight: FontWeight.bold,
            ),
          ),

          content: Text('Voulez-vous vraiment supprimer "$nom" ?'),

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
      // RÉCUPÉRER LES ACTIVITÉS DE CE FOURNISSEUR

      final activitesSnapshot = await firestoreService.activites
          .where('fournisseurId', isEqualTo: fournisseurId)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      // SUPPRIMER LE FOURNISSEUR

      batch.delete(firestoreService.fournisseurs.doc(fournisseurId));

      // SUPPRIMER SES ACTIVITÉS RÉCENTES

      for (final activite in activitesSnapshot.docs) {
        batch.delete(activite.reference);
      }

      await batch.commit();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fournisseur supprimé avec succès.')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Impossible de supprimer le fournisseur.'),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une erreur est survenue pendant la suppression.'),
        ),
      );
    }
  }

  // CARTE TOTAL FOURNISSEURS

  Widget carteTotalFournisseurs(int totalFournisseurs) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.fromLTRB(16, 16, 16, 6),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: couleurPrincipale,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        children: [
          // ICÔNE
          Container(
            width: 55,
            height: 55,

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
            ),

            child: const Icon(
              Icons.people_alt_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),

          const SizedBox(width: 16),

          // TOTAL
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Total fournisseurs',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),

                const SizedBox(height: 5),

                Text(
                  '$totalFournisseurs',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  totalFournisseurs <= 1 ? 'Fournisseur' : 'Fournisseurs',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // CARTE D'UN FOURNISSEUR

  Widget carteFournisseur({
    required String fournisseurId,
    required Map<String, dynamic> fournisseur,
  }) {
    final nom = fournisseur['nom']?.toString() ?? 'Fournisseur';

    final telephone = fournisseur['telephone']?.toString() ?? 'Non renseigné';

    final produitFourni =
        fournisseur['produitFourni']?.toString() ??
        fournisseur['produit']?.toString() ??
        'Non renseigné';

    final adresse = fournisseur['adresse']?.toString() ?? 'Non renseignée';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ICÔNE
          Container(
            width: 50,
            height: 50,

            decoration: BoxDecoration(
              color: couleurClaire,
              borderRadius: BorderRadius.circular(14),
            ),

            child: const Icon(
              Icons.person_outline,
              color: couleurPrincipale,
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          // INFORMATIONS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  nom,
                  style: const TextStyle(
                    color: couleurPrincipale,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 9),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 17,
                      color: Colors.grey,
                    ),

                    const SizedBox(width: 7),

                    Expanded(
                      child: Text(
                        telephone,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 17,
                      color: Colors.grey,
                    ),

                    const SizedBox(width: 7),

                    Expanded(
                      child: Text(
                        'Produit fourni : $produitFourni',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 17,
                      color: Colors.grey,
                    ),

                    const SizedBox(width: 7),

                    Expanded(
                      child: Text(
                        adresse,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // TROIS POINTS
          IconButton(
            tooltip: 'Actions',

            icon: const Icon(Icons.more_vert, color: couleurPrincipale),

            onPressed: () {
              ouvrirActions(
                fournisseurId: fournisseurId,
                fournisseur: fournisseur,
              );
            },
          ),
        ],
      ),
    );
  }

  // INTERFACE

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),

      // APP BAR
      appBar: AppBar(title: const Text('Fournisseurs')),

      // AJOUTER
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ouvrirFormulaire();
        },

        icon: const Icon(Icons.person_add_alt_1),

        label: const Text('Nouveau fournisseur'),
      ),

      // FIRESTORE
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // Nous n'utilisons pas orderBy afin que les anciens
        // fournisseurs soient également affichés.
        stream: firestoreService.fournisseurs.snapshots(),

        builder: (context, snapshot) {
          // CHARGEMENT

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: couleurPrincipale),
            );
          }

          // ERREUR

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Text(
                  'Impossible de charger les fournisseurs.\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final fournisseurs =
              List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                snapshot.data?.docs ?? [],
              );

          // TRI LOCAL PAR DATE

          fournisseurs.sort((a, b) {
            final donneesA = a.data();
            final donneesB = b.data();

            final dateA =
                donneesA['dateCreation'] ?? donneesA['dateModification'];

            final dateB =
                donneesB['dateCreation'] ?? donneesB['dateModification'];

            if (dateA is Timestamp && dateB is Timestamp) {
              return dateB.compareTo(dateA);
            }

            return 0;
          });

          // TOTAL FOURNISSEURS

          final totalFournisseurs = fournisseurs.length;

          return Column(
            children: [
              // TOTAL EN HAUT
              carteTotalFournisseurs(totalFournisseurs),

              const SizedBox(height: 8),

              // LISTE
              Expanded(
                child: fournisseurs.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),

                          child: Column(
                            mainAxisSize: MainAxisSize.min,

                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 65,
                                color: couleurPrincipale,
                              ),

                              SizedBox(height: 18),

                              Text(
                                'Aucun fournisseur',
                                style: TextStyle(
                                  color: couleurPrincipale,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: 8),

                              Text(
                                'Appuyez sur "Nouveau fournisseur" pour enregistrer votre premier partenaire.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),

                        itemCount: fournisseurs.length,

                        itemBuilder: (context, index) {
                          final document = fournisseurs[index];

                          return carteFournisseur(
                            fournisseurId: document.id,
                            fournisseur: document.data(),
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
