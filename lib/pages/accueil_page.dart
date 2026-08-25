import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import 'parametres_page.dart';

class AccueilPage extends StatelessWidget {
  const AccueilPage({super.key});

  String _salutation() {
    final heure = DateTime.now().hour;

    if (heure < 18) {
      return 'Bonjour';
    }

    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: firestoreService.produits.snapshots(),
          builder: (context, produitsSnapshot) {
            if (!produitsSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final produits = produitsSnapshot.data!.docs;

            double valeurStock = 0;
            int nombreProduits = produits.length;
            int nombreAlertes = 0;

            for (final document in produits) {
              final produit = document.data();

              final quantite =
                  (produit['quantite'] ?? 0) as num;

              final prix =
                  (produit['prixUnitaire'] ?? 0) as num;

              final seuil =
                  (produit['seuilAlerte'] ?? 0) as num;

              valeurStock +=
                  quantite.toDouble() * prix.toDouble();

              if (quantite <= seuil) {
                nombreAlertes++;
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                100,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  /// ==============================
                  /// EN-TÊTE
                  /// ==============================
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_salutation()}, ${user?.displayName ?? 'Utilisateur'}',
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15576B),
                              ),
                            ),

                            const SizedBox(height: 4),

                            const Text(
                              'Bienvenue dans SmartInventory',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        tooltip: 'Paramètres',
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: Color(0xFF15576B),
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ParametresPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  /// ==============================
                  /// VALEUR DU STOCK
                  /// ==============================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15576B),
                      borderRadius:
                          BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.white,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Valeur du stock',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Text(
                          '${valeurStock.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  /// ==============================
                  /// PRODUITS ET ALERTES
                  /// ==============================
                  Row(
                    children: [
                      Expanded(
                        child: _resumeCard(
                          icon: Icons.inventory_2_outlined,
                          titre: 'Produits',
                          valeur: nombreProduits == 0
                              ? 'Aucun'
                              : '$nombreProduits',
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: _resumeCard(
                          icon: Icons.warning_amber_outlined,
                          titre: 'Alertes',
                          valeur: nombreAlertes == 0
                              ? 'Aucune'
                              : '$nombreAlertes',
                          alerte: nombreAlertes > 0,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  /// ==============================
                  /// RÉSUMÉ
                  /// ==============================
                  const Text(
                    'Résumé',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15576B),
                    ),
                  ),

                  const SizedBox(height: 15),

                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: firestoreService.ventes.snapshots(),
                    builder: (context, ventesSnapshot) {
                      final ventes =
                          ventesSnapshot.data?.docs ?? [];

                      double chiffreAffaires = 0;

                      for (final document in ventes) {
                        final vente = document.data();

                        final montant =
                            vente['montantTotal'] ?? 0;

                        if (montant is num) {
                          chiffreAffaires +=
                              montant.toDouble();
                        }
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: _resumeCard(
                              icon:
                                  Icons.shopping_cart_outlined,
                              titre: 'Ventes',
                              valeur: ventes.isEmpty
                                  ? 'Aucune'
                                  : '${ventes.length}',
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: _resumeCard(
                              icon: Icons.payments_outlined,
                              titre: 'Chiffre d’affaires',
                              valeur:
                                  '${chiffreAffaires.toStringAsFixed(0)} FCFA',
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  /// ==============================
                  /// ACTIVITÉS RÉCENTES
                  /// ==============================
                  const Text(
                    'Activités récentes',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15576B),
                    ),
                  ),

                  const SizedBox(height: 15),

                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: firestoreService.activites
                        .orderBy(
                          'date',
                          descending: true,
                        )
                        .limit(10)
                        .snapshots(),
                    builder: (context, activitesSnapshot) {
                      if (!activitesSnapshot.hasData) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child:
                                CircularProgressIndicator(),
                          ),
                        );
                      }

                      final activites =
                          activitesSnapshot.data!.docs;

                      if (activites.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Aucune activité récente',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: activites.map((document) {
                          final activite =
                              document.data();

                          final titre =
                              activite['titre']
                                      ?.toString() ??
                                  '';

                          final description =
                              activite['description']
                                      ?.toString() ??
                                  '';

                          final type =
                              activite['type']
                                      ?.toString() ??
                                  '';

                          IconData icon;
                          Color couleur;

                          switch (type) {
                            case 'vente':
                              icon =
                                  Icons.shopping_cart_outlined;
                              couleur =
                                  const Color(0xFF15576B);
                              break;

                            case 'produit':
                              icon =
                                  Icons.inventory_2_outlined;
                              couleur =
                                  const Color(0xFF15576B);
                              break;

                            case 'fournisseur':
                              icon =
                                  Icons.people_outline;
                              couleur =
                                  const Color(0xFF15576B);
                              break;

                            case 'approvisionnement':
                              icon =
                                  Icons.local_shipping_outlined;
                              couleur =
                                  const Color(0xFF15576B);
                              break;

                            default:
                              icon = Icons.info_outline;
                              couleur = Colors.grey;
                          }

                          return Container(
                            margin:
                                const EdgeInsets.only(
                              bottom: 10,
                            ),
                            padding:
                                const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color:
                                        couleur.withOpacity(
                                      0.12,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(
                                      12,
                                    ),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: couleur,
                                  ),
                                ),

                                const SizedBox(width: 14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        titre,
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 4,
                                      ),

                                      Text(
                                        description,
                                        style:
                                            const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget _resumeCard({
    required IconData icon,
    required String titre,
    required String valeur,
    bool alerte = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: alerte
                ? Colors.red
                : const Color(0xFF15576B),
          ),

          const SizedBox(height: 15),

          Text(
            titre,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            valeur,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: alerte
                  ? Colors.red
                  : const Color(0xFF15576B),
            ),
          ),
        ],
      ),
    );
  }
}