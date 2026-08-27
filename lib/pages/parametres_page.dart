import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import 'produit_form_page.dart';

class ParametresPage extends StatefulWidget {
  const ParametresPage({super.key});

  @override
  State<ParametresPage> createState() => _ParametresPageState();
}

class _ParametresPageState extends State<ParametresPage> {
  // COULEURS

  static const Color couleurPrincipale = Color(0xFF15576B);
  static const Color couleurClaire = Color(0xFFE0F2EE);

  // FIRESTORE

  final FirestoreService firestoreService = FirestoreService();

  // OUVRIR LA MODIFICATION D'UN PRODUIT

  Future<void> modifierProduit({
    required String produitId,
    required Map<String, dynamic> produit,
  }) async {
    final resultat = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProduitFormPage(produitId: produitId, produit: produit),
      ),
    );

    if (!mounted) {
      return;
    }

    if (resultat == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seuil du produit mis à jour.')),
      );
    }
  }

  // DÉCONNEXION

  Future<void> seDeconnecter() async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Déconnexion',
            style: TextStyle(
              color: couleurPrincipale,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Voulez-vous vraiment vous déconnecter de SmartInventory ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmation != true) {
      return;
    }

    try {
      // PAS DE NAVIGATOR APRÈS SIGNOUT

      // AuthGate dans main.dart détectera automatiquement
      // que l'utilisateur n'est plus connecté.

      await FirebaseAuth.instance.signOut();

      if (!mounted) {
        return;
      }

      // On ferme simplement ParametresPage.
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de vous déconnecter.')),
      );
    }
  }

  // CARTE DU COMPTE

  Widget carteCompte() {
    final utilisateur = FirebaseAuth.instance.currentUser;

    final nom = utilisateur?.displayName?.trim();

    final email = utilisateur?.email ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          // AVATAR
          Container(
            width: 55,
            height: 55,
            decoration: const BoxDecoration(
              color: couleurClaire,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: couleurPrincipale,
              size: 30,
            ),
          ),

          const SizedBox(width: 15),

          // INFORMATIONS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom != null && nom.isNotEmpty ? nom : 'Utilisateur',
                  style: const TextStyle(
                    color: couleurPrincipale,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  email,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // CARTE RÉSUMÉ ALERTES

  Widget carteAlertes({required int totalProduits, required int totalAlertes}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: couleurPrincipale,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alertes de stock',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),

                const SizedBox(height: 5),

                Text(
                  totalAlertes == 0
                      ? 'Aucune alerte'
                      : '$totalAlertes produit(s) en alerte',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '$totalProduits produit(s) enregistré(s)',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // CARTE SEUIL D'UN PRODUIT

  Widget carteProduit({
    required String produitId,
    required Map<String, dynamic> produit,
  }) {
    final nom = produit['nom']?.toString() ?? 'Produit';

    final quantite = (produit['quantite'] as num?)?.toInt() ?? 0;

    final seuil = (produit['seuil'] as num?)?.toInt() ?? 0;

    final enAlerte = quantite <= seuil;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: enAlerte
            ? Border.all(color: Colors.orange.withOpacity(0.5))
            : null,
      ),
      child: Row(
        children: [
          // ICÔNE
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: enAlerte ? Colors.orange.withOpacity(0.12) : couleurClaire,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              enAlerte
                  ? Icons.warning_amber_rounded
                  : Icons.inventory_2_outlined,
              color: enAlerte ? Colors.orange : couleurPrincipale,
            ),
          ),

          const SizedBox(width: 12),

          // INFORMATIONS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: couleurPrincipale,
                  ),
                ),

                const SizedBox(height: 5),

                Text('Stock : $quantite', style: const TextStyle(fontSize: 13)),

                const SizedBox(height: 3),

                Text(
                  'Seuil d’alerte : $seuil',
                  style: const TextStyle(fontSize: 13),
                ),

                if (enAlerte) ...[
                  const SizedBox(height: 5),

                  const Text(
                    'Stock en alerte',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // MODIFIER
          IconButton(
            tooltip: 'Modifier le seuil',
            onPressed: () {
              modifierProduit(produitId: produitId, produit: produit);
            },
            icon: const Icon(Icons.edit_outlined, color: couleurPrincipale),
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

      appBar: AppBar(title: const Text('Paramètres')),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestoreService.produits.snapshots(),

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
                  'Impossible de charger les paramètres.\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final produits =
              List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                snapshot.data?.docs ?? [],
              );

          int totalAlertes = 0;

          for (final document in produits) {
            final produit = document.data();

            final quantite = (produit['quantite'] as num?)?.toInt() ?? 0;

            final seuil = (produit['seuil'] as num?)?.toInt() ?? 0;

            if (quantite <= seuil) {
              totalAlertes++;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // COMPTE
                const Text(
                  'Mon compte',
                  style: TextStyle(
                    color: couleurPrincipale,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                carteCompte(),

                const SizedBox(height: 28),

                // ALERTES
                const Text(
                  'Seuils et alertes',
                  style: TextStyle(
                    color: couleurPrincipale,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Un produit passe en alerte lorsque sa quantité est inférieure ou égale à son seuil.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),

                const SizedBox(height: 15),

                carteAlertes(
                  totalProduits: produits.length,
                  totalAlertes: totalAlertes,
                ),

                const SizedBox(height: 20),

                // LISTE DES SEUILS
                if (produits.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          color: couleurPrincipale,
                          size: 45,
                        ),

                        SizedBox(height: 12),

                        Text(
                          'Aucun produit enregistré.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...produits.map((document) {
                    return carteProduit(
                      produitId: document.id,
                      produit: document.data(),
                    );
                  }),

                const SizedBox(height: 28),

                // APPLICATION
                const Text(
                  'Application',
                  style: TextStyle(
                    color: couleurPrincipale,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.inventory_2_outlined,
                          color: couleurPrincipale,
                        ),
                        title: Text(
                          'SmartInventory',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Application de gestion de stock'),
                      ),

                      Divider(),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.info_outline,
                          color: couleurPrincipale,
                        ),
                        title: Text('Version'),
                        trailing: Text('1.0.0'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // DÉCONNEXION
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: seDeconnecter,

                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),

                    icon: const Icon(Icons.logout),

                    label: const Text('Se déconnecter'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
