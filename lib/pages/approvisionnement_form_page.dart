import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/firestore_service.dart';

class ApprovisionnementFormPage extends StatefulWidget {
  final String? approvisionnementId;
  final Map<String, dynamic>? approvisionnement;

  const ApprovisionnementFormPage({
    super.key,
    this.approvisionnementId,
    this.approvisionnement,
  });

  @override
  State<ApprovisionnementFormPage> createState() =>
      _ApprovisionnementFormPageState();
}

class _ApprovisionnementFormPageState extends State<ApprovisionnementFormPage> {
  // COULEURS

  static const Color couleurPrincipale = Color(0xFF15576B);
  static const Color couleurClaire = Color(0xFFE0F2EE);

  // FIRESTORE

  final FirestoreService firestoreService = FirestoreService();

  // FORMULAIRE

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late TextEditingController quantiteController;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> produitsDisponibles = [];

  String? produitSelectionneId;

  bool chargementProduits = true;
  bool enregistrement = false;

  // AJOUT OU MODIFICATION

  bool get modification {
    return widget.approvisionnementId != null &&
        widget.approvisionnement != null;
  }

  // INITIALISATION

  @override
  void initState() {
    super.initState();

    quantiteController = TextEditingController(
      text: widget.approvisionnement?['quantite']?.toString() ?? '',
    );

    produitSelectionneId = widget.approvisionnement?['produitId']?.toString();

    chargerProduits();
  }

  // LIBÉRER LE CONTROLLER

  @override
  void dispose() {
    quantiteController.dispose();

    super.dispose();
  }

  // CHARGER LES PRODUITS

  Future<void> chargerProduits() async {
    try {
      final snapshot = await firestoreService.produits.get();

      if (!mounted) {
        return;
      }

      bool produitExiste = false;

      if (produitSelectionneId != null) {
        for (final document in snapshot.docs) {
          if (document.id == produitSelectionneId) {
            produitExiste = true;
            break;
          }
        }
      }

      setState(() {
        produitsDisponibles = snapshot.docs;

        if (!produitExiste) {
          produitSelectionneId = null;
        }

        chargementProduits = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        chargementProduits = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de charger les produits.')),
      );
    }
  }

  // TROUVER LE PRODUIT SÉLECTIONNÉ

  QueryDocumentSnapshot<Map<String, dynamic>>? recupererProduitSelectionne() {
    if (produitSelectionneId == null) {
      return null;
    }

    for (final document in produitsDisponibles) {
      if (document.id == produitSelectionneId) {
        return document;
      }
    }

    return null;
  }

  // GÉNÉRER UNE RÉFÉRENCE

  String genererReferenceCommande() {
    final maintenant = DateTime.now();

    final mois = maintenant.month.toString().padLeft(2, '0');

    final jour = maintenant.day.toString().padLeft(2, '0');

    final heure = maintenant.hour.toString().padLeft(2, '0');

    final minute = maintenant.minute.toString().padLeft(2, '0');

    final seconde = maintenant.second.toString().padLeft(2, '0');

    return 'C-${maintenant.year}-$mois$jour$heure$minute$seconde';
  }

  // ENREGISTRER

  Future<void> enregistrerApprovisionnement() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (produitSelectionneId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un produit.')),
      );

      return;
    }

    if (enregistrement) {
      return;
    }

    final nouvelleQuantite = int.tryParse(quantiteController.text.trim());

    if (nouvelleQuantite == null || nouvelleQuantite <= 0) {
      return;
    }

    setState(() {
      enregistrement = true;
    });

    try {
      // MODIFICATION

      if (modification) {
        await modifierApprovisionnement(nouvelleQuantite);
      }
      // AJOUT
      else {
        await ajouterApprovisionnement(nouvelleQuantite);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      String message = e.toString();

      message = message.replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          enregistrement = false;
        });
      }
    }
  }

  // AJOUTER UN APPROVISIONNEMENT

  Future<void> ajouterApprovisionnement(int quantite) async {
    final produitId = produitSelectionneId!;

    final produitReference = firestoreService.produits.doc(produitId);

    final approvisionnementReference = firestoreService.approvisionnements
        .doc();

    final activiteReference = firestoreService.activites.doc();

    final referenceCommande = genererReferenceCommande();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // LIRE LE PRODUIT

      final produitSnapshot = await transaction.get(produitReference);

      if (!produitSnapshot.exists) {
        throw Exception('Ce produit n’existe plus.');
      }

      final produit = produitSnapshot.data();

      final nomProduit = produit?['nom']?.toString() ?? 'Produit';

      final stockActuel = (produit?['quantite'] as num?)?.toInt() ?? 0;

      // AUGMENTER LE STOCK

      transaction.update(produitReference, {
        'quantite': stockActuel + quantite,
        'dateModification': FieldValue.serverTimestamp(),
      });

      // CRÉER L'APPROVISIONNEMENT

      transaction.set(approvisionnementReference, {
        'produitId': produitId,
        'nomProduit': nomProduit,
        'quantite': quantite,
        'referenceCommande': referenceCommande,
        'date': FieldValue.serverTimestamp(),
      });

      // CRÉER L'ACTIVITÉ

      transaction.set(activiteReference, {
        'titre': 'Approvisionnement enregistré',
        'description': '$nomProduit : +$quantite unité(s)',
        'type': 'approvisionnement',
        'produitId': produitId,
        'approvisionnementId': approvisionnementReference.id,
        'date': FieldValue.serverTimestamp(),
      });
    });
  }

  // MODIFIER UN APPROVISIONNEMENT

  Future<void> modifierApprovisionnement(int nouvelleQuantite) async {
    final approvisionnementId = widget.approvisionnementId!;

    final ancienApprovisionnement = widget.approvisionnement!;

    final ancienProduitId = ancienApprovisionnement['produitId']?.toString();

    final ancienneQuantite =
        (ancienApprovisionnement['quantite'] as num?)?.toInt() ?? 0;

    final nouveauProduitId = produitSelectionneId!;

    if (ancienProduitId == null || ancienProduitId.isEmpty) {
      throw Exception(
        'L’ancien produit de cet approvisionnement est introuvable.',
      );
    }

    final approvisionnementReference = firestoreService.approvisionnements.doc(
      approvisionnementId,
    );

    // RÉCUPÉRER LES ACTIVITÉS

    final activitesSnapshot = await firestoreService.activites
        .where('approvisionnementId', isEqualTo: approvisionnementId)
        .get();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // MÊME PRODUIT

      if (ancienProduitId == nouveauProduitId) {
        final produitReference = firestoreService.produits.doc(
          nouveauProduitId,
        );

        final produitSnapshot = await transaction.get(produitReference);

        if (!produitSnapshot.exists) {
          throw Exception('Ce produit n’existe plus.');
        }

        final produit = produitSnapshot.data();

        final nomProduit = produit?['nom']?.toString() ?? 'Produit';

        final stockActuel = (produit?['quantite'] as num?)?.toInt() ?? 0;

        // Différence entre nouvelle et ancienne réception.
        final difference = nouvelleQuantite - ancienneQuantite;

        final nouveauStock = stockActuel + difference;

        if (nouveauStock < 0) {
          throw Exception(
            'Impossible de réduire cette réception. '
            'Le stock disponible est insuffisant.',
          );
        }

        transaction.update(produitReference, {
          'quantite': nouveauStock,
          'dateModification': FieldValue.serverTimestamp(),
        });

        transaction.update(approvisionnementReference, {
          'produitId': nouveauProduitId,
          'nomProduit': nomProduit,
          'quantite': nouvelleQuantite,
          'dateModification': FieldValue.serverTimestamp(),
        });

        // METTRE À JOUR LES ACTIVITÉS

        if (activitesSnapshot.docs.isEmpty) {
          final activiteReference = firestoreService.activites.doc();

          transaction.set(activiteReference, {
            'titre': 'Approvisionnement modifié',
            'description': '$nomProduit : $nouvelleQuantite unité(s)',
            'type': 'approvisionnement',
            'produitId': nouveauProduitId,
            'approvisionnementId': approvisionnementId,
            'date': FieldValue.serverTimestamp(),
          });
        } else {
          for (final activite in activitesSnapshot.docs) {
            transaction.update(activite.reference, {
              'titre': 'Approvisionnement modifié',
              'description': '$nomProduit : $nouvelleQuantite unité(s)',
              'produitId': nouveauProduitId,
              'date': FieldValue.serverTimestamp(),
            });
          }
        }
      }
      // LE PRODUIT A ÉTÉ CHANGÉ
      else {
        final ancienProduitReference = firestoreService.produits.doc(
          ancienProduitId,
        );

        final nouveauProduitReference = firestoreService.produits.doc(
          nouveauProduitId,
        );

        // toutes les lectures sont faites avant les écritures.

        final ancienProduitSnapshot = await transaction.get(
          ancienProduitReference,
        );

        final nouveauProduitSnapshot = await transaction.get(
          nouveauProduitReference,
        );

        if (!ancienProduitSnapshot.exists) {
          throw Exception('L’ancien produit n’existe plus.');
        }

        if (!nouveauProduitSnapshot.exists) {
          throw Exception('Le nouveau produit n’existe plus.');
        }

        final ancienProduit = ancienProduitSnapshot.data();

        final nouveauProduit = nouveauProduitSnapshot.data();

        final ancienStock = (ancienProduit?['quantite'] as num?)?.toInt() ?? 0;

        final nouveauStockActuel =
            (nouveauProduit?['quantite'] as num?)?.toInt() ?? 0;

        final nomNouveauProduit =
            nouveauProduit?['nom']?.toString() ?? 'Produit';

        // RETIRER L'ANCIENNE RÉCEPTION

        if (ancienStock < ancienneQuantite) {
          throw Exception(
            'Impossible de changer le produit. '
            'Le stock de l’ancien produit est insuffisant '
            'pour annuler cette réception.',
          );
        }

        transaction.update(ancienProduitReference, {
          'quantite': ancienStock - ancienneQuantite,
          'dateModification': FieldValue.serverTimestamp(),
        });

        // AJOUTER AU NOUVEAU PRODUIT

        transaction.update(nouveauProduitReference, {
          'quantite': nouveauStockActuel + nouvelleQuantite,
          'dateModification': FieldValue.serverTimestamp(),
        });

        // MODIFIER L'APPROVISIONNEMENT

        transaction.update(approvisionnementReference, {
          'produitId': nouveauProduitId,
          'nomProduit': nomNouveauProduit,
          'quantite': nouvelleQuantite,
          'dateModification': FieldValue.serverTimestamp(),
        });

        // ACTIVITÉ

        if (activitesSnapshot.docs.isEmpty) {
          final activiteReference = firestoreService.activites.doc();

          transaction.set(activiteReference, {
            'titre': 'Approvisionnement modifié',
            'description': '$nomNouveauProduit : $nouvelleQuantite unité(s)',
            'type': 'approvisionnement',
            'produitId': nouveauProduitId,
            'approvisionnementId': approvisionnementId,
            'date': FieldValue.serverTimestamp(),
          });
        } else {
          for (final activite in activitesSnapshot.docs) {
            transaction.update(activite.reference, {
              'titre': 'Approvisionnement modifié',
              'description': '$nomNouveauProduit : $nouvelleQuantite unité(s)',
              'produitId': nouveauProduitId,
              'date': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    });
  }

  // INTERFACE

  @override
  Widget build(BuildContext context) {
    final selection = recupererProduitSelectionne();

    final donnees = selection?.data();

    final stockActuel = (donnees?['quantite'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),

      appBar: AppBar(
        title: Text(
          modification
              ? 'Modifier l’approvisionnement'
              : 'Nouvel approvisionnement',
        ),
      ),

      body: SafeArea(
        child: chargementProduits
            ? const Center(
                child: CircularProgressIndicator(color: couleurPrincipale),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),

                child: Form(
                  key: formKey,

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        modification
                            ? 'Modifier la réception'
                            : 'Réception du stock',
                        style: const TextStyle(
                          color: couleurPrincipale,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        modification
                            ? 'Modifiez le produit ou la quantité reçue.'
                            : 'Sélectionnez le produit reçu et indiquez la quantité.',
                        style: const TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 25),

                      // AUCUN PRODUIT
                      if (produitsDisponibles.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Text(
                            'Aucun produit disponible.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      else ...[
                        // PRODUIT
                        DropdownButtonFormField<String>(
                          initialValue: produitSelectionneId,

                          decoration: const InputDecoration(
                            labelText: 'Produit',
                            prefixIcon: Icon(
                              Icons.inventory_2_outlined,
                              color: couleurPrincipale,
                            ),
                          ),

                          items: produitsDisponibles.map((document) {
                            final produit = document.data();

                            final nom = produit['nom']?.toString() ?? 'Produit';

                            final quantite =
                                (produit['quantite'] as num?)?.toInt() ?? 0;

                            return DropdownMenuItem<String>(
                              value: document.id,
                              child: Text(
                                '$nom — Stock : $quantite',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),

                          onChanged: enregistrement
                              ? null
                              : (value) {
                                  setState(() {
                                    produitSelectionneId = value;
                                  });
                                },

                          validator: (value) {
                            if (value == null) {
                              return 'Veuillez sélectionner un produit';
                            }

                            return null;
                          },
                        ),

                        if (selection != null) ...[
                          const SizedBox(height: 14),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: couleurClaire,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.inventory_outlined,
                                  color: couleurPrincipale,
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Text(
                                    'Stock actuel : $stockActuel unité(s)',
                                    style: const TextStyle(
                                      color: couleurPrincipale,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 18),

                        // QUANTITÉ
                        TextFormField(
                          controller: quantiteController,

                          keyboardType: TextInputType.number,

                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],

                          textInputAction: TextInputAction.done,

                          decoration: const InputDecoration(
                            labelText: 'Quantité reçue',
                            prefixIcon: Icon(
                              Icons.add_box_outlined,
                              color: couleurPrincipale,
                            ),
                          ),

                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La quantité est obligatoire';
                            }

                            final quantite = int.tryParse(value);

                            if (quantite == null) {
                              return 'Quantité invalide';
                            }

                            if (quantite <= 0) {
                              return 'La quantité doit être supérieure à 0';
                            }

                            return null;
                          },

                          onFieldSubmitted: (_) {
                            enregistrerApprovisionnement();
                          },
                        ),

                        const SizedBox(height: 30),

                        // ENREGISTRER
                        SizedBox(
                          width: double.infinity,
                          height: 55,

                          child: ElevatedButton.icon(
                            onPressed: enregistrement
                                ? null
                                : enregistrerApprovisionnement,

                            icon: enregistrement
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    modification
                                        ? Icons.save_outlined
                                        : Icons.check_circle_outline,
                                  ),

                            label: Text(
                              enregistrement
                                  ? 'Enregistrement...'
                                  : modification
                                  ? 'Enregistrer les modifications'
                                  : 'Enregistrer la réception',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
