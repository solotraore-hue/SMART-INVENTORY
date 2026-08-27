import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import 'parametres_page.dart';

class AccueilPage extends StatelessWidget {
  const AccueilPage({super.key});

  static const Color couleurPrincipale = Color(0xFF15576B);
  static const Color couleurSecondaire = Color(0xFF0E6B7F);
  static const Color couleurClaire = Color(0xFFE0F2EE);
  static const Color couleurFond = Color(0xFFF5F6F8);
  String salutation() {
    final heure = DateTime.now().hour;

    if (heure >= 18 || heure < 5) {
      return 'Bonsoir';
    }
    return 'Bonjour';
  }

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

  // FORMAT DATE
  String formaterDate(dynamic valeur) {
    if (valeur is! Timestamp) {
      return '';
    }
    final date = valeur.toDate();

    final jour = date.day.toString().padLeft(2, '0');

    final mois = date.month.toString().padLeft(2, '0');

    final heure = date.hour.toString().padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');

    return '$jour/$mois/${date.year} à $heure:$minute';
  }

  // ICÔNE ACTIVITÉ

  IconData iconeActivite(String type) {
    switch (type) {
      case 'produit':
        return Icons.inventory_2_outlined;

      case 'vente':
        return Icons.shopping_cart_outlined;

      case 'approvisionnement':
        return Icons.local_shipping_outlined;

      case 'fournisseur':
        return Icons.people_outline;

      default:
        return Icons.history;
    }
  }

  // VALEUR DU STOCK

  Widget carteValeurStock({required double valeurStock}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [couleurPrincipale, couleurSecondaire],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.10),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 27,
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Text(
                  'Valeur du stock',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${formaterMontant(valeurStock)} FCFA',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PETITE CARTE

  Widget petiteCarte({
    required String titre,
    required String valeur,
    required IconData icone,
    bool alerte = false,
  }) {
    return Container(
      height: 175,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: alerte
            ? Border.all(color: Colors.orange.withValues(alpha: 0.40))
            : null,
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: alerte
                  ? Colors.orange.withValues(alpha: 0.12)
                  : couleurClaire,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icone,
              color: alerte ? Colors.orange : couleurPrincipale,
            ),
          ),

          const Spacer(),

          Text(
            titre,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),

          const SizedBox(height: 8),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valeur,
              style: TextStyle(
                color: alerte ? Colors.orange : couleurPrincipale,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // CARTE ACTIVITÉ

  Widget carteActivite(Map<String, dynamic> activite) {
    final titre = activite['titre']?.toString() ?? 'Activité';

    final description = activite['description']?.toString() ?? '';

    final type = activite['type']?.toString() ?? '';

    final date = formaterDate(activite['date']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: couleurClaire,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(iconeActivite(type), color: couleurPrincipale),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: const TextStyle(
                    color: couleurPrincipale,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),

                  Text(
                    description,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],

                if (date.isNotEmpty) ...[
                  const SizedBox(height: 6),

                  Text(
                    date,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // CONTENU PRINCIPAL

  Widget contenuAccueil({
    required BuildContext context,
    required FirestoreService firestoreService,
    required String nomUtilisateur,
    required double valeurStock,
    required int totalProduits,
    required int totalAlertes,
    required int totalFournisseurs,
    required double chiffreAffaires,
    required AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
    activitesSnapshot,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EN-TÊTE
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${salutation()}, $nomUtilisateur',
                      style: const TextStyle(
                        color: couleurPrincipale,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Bienvenue dans SmartInventory',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Paramètres',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ParametresPage()),
                  );
                },
                icon: const Icon(
                  Icons.settings_outlined,
                  color: couleurPrincipale,
                  size: 30,
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          // VALEUR DU STOCK
          carteValeurStock(valeurStock: valeurStock),

          const SizedBox(height: 16),

          // PRODUITS + ALERTES
          Row(
            children: [
              Expanded(
                child: petiteCarte(
                  titre: 'Produits',
                  valeur: totalProduits == 0 ? 'Aucun' : '$totalProduits',
                  icone: Icons.inventory_2_outlined,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: petiteCarte(
                  titre: 'Alertes',
                  valeur: totalAlertes == 0 ? 'Aucune' : '$totalAlertes',
                  icone: Icons.warning_amber_rounded,
                  alerte: totalAlertes > 0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // RÉSUMÉ
          const Text(
            'Résumé',
            style: TextStyle(
              color: couleurPrincipale,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          // FOURNISSEURS + CHIFFRE D'AFFAIRES
          Row(
            children: [
              Expanded(
                child: petiteCarte(
                  titre: 'Fournisseurs',
                  valeur: '$totalFournisseurs',
                  icone: Icons.people_outline,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: petiteCarte(
                  titre: 'Chiffre d’affaires',
                  valeur: '${formaterMontant(chiffreAffaires)} FCFA',
                  icone: Icons.payments_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // ACTIVITÉS RÉCENTES
          const Text(
            'Activités récentes',
            style: TextStyle(
              color: couleurPrincipale,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          if (activitesSnapshot.hasError)
            const CarteMessageAccueil(
              message: 'Impossible de charger les activités.',
            )
          else if (!activitesSnapshot.hasData ||
              activitesSnapshot.data!.docs.isEmpty)
            const CarteMessageAccueil(message: 'Aucune activité récente.')
          else
            Column(
              children: activitesSnapshot.data!.docs.map((document) {
                return carteActivite(document.data());
              }).toList(),
            ),
        ],
      ),
    );
  }

  // INTERFACE

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: couleurFond,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: firestoreService.utilisateur.snapshots(),
          builder: (context, utilisateurSnapshot) {
            String nomUtilisateur = 'Utilisateur';

            if (utilisateurSnapshot.hasData &&
                utilisateurSnapshot.data!.exists) {
              final donnees = utilisateurSnapshot.data!.data();

              final nom = donnees?['nom']?.toString().trim();

              if (nom != null && nom.isNotEmpty) {
                nomUtilisateur = nom;
              }
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: firestoreService.produits.snapshots(),
              builder: (context, produitsSnapshot) {
                double valeurStock = 0;
                int totalProduits = 0;
                int totalAlertes = 0;

                if (produitsSnapshot.hasData) {
                  final produits = produitsSnapshot.data!.docs;

                  totalProduits = produits.length;

                  for (final document in produits) {
                    final produit = document.data();

                    final quantite =
                        (produit['quantite'] as num?)?.toInt() ?? 0;

                    final prix =
                        (produit['prixUnitaire'] as num?)?.toDouble() ?? 0;

                    final seuil = (produit['seuil'] as num?)?.toInt() ?? 0;

                    valeurStock += quantite * prix;

                    if (quantite <= seuil) {
                      totalAlertes++;
                    }
                  }
                }

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: firestoreService.fournisseurs.snapshots(),
                  builder: (context, fournisseursSnapshot) {
                    int totalFournisseurs = 0;

                    if (fournisseursSnapshot.hasData) {
                      totalFournisseurs =
                          fournisseursSnapshot.data!.docs.length;
                    }

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: firestoreService.ventes.snapshots(),
                      builder: (context, ventesSnapshot) {
                        double chiffreAffaires = 0;

                        if (ventesSnapshot.hasData) {
                          for (final document in ventesSnapshot.data!.docs) {
                            chiffreAffaires +=
                                (document.data()['montantTotal'] as num?)
                                    ?.toDouble() ??
                                0;
                          }
                        }

                        return StreamBuilder<
                          QuerySnapshot<Map<String, dynamic>>
                        >(
                          stream: firestoreService.activites
                              .orderBy('date', descending: true)
                              .limit(10)
                              .snapshots(),
                          builder: (context, activitesSnapshot) {
                            return contenuAccueil(
                              context: context,
                              firestoreService: firestoreService,
                              nomUtilisateur: nomUtilisateur,
                              valeurStock: valeurStock,
                              totalProduits: totalProduits,
                              totalAlertes: totalAlertes,
                              totalFournisseurs: totalFournisseurs,
                              chiffreAffaires: chiffreAffaires,
                              activitesSnapshot: activitesSnapshot,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// MESSAGE VIDE / ERREUR

class CarteMessageAccueil extends StatelessWidget {
  final String message;

  const CarteMessageAccueil({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
