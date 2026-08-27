import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/firestore_service.dart';

class VenteFormPage extends StatefulWidget {
  final String? venteId;
  final Map<String, dynamic>? vente;

  const VenteFormPage({super.key, this.venteId, this.vente});

  @override
  State<VenteFormPage> createState() => _VenteFormPageState();
}

class _VenteFormPageState extends State<VenteFormPage> {
  
  // COULEURS
  

  static const Color couleurPrincipale = Color(0xFF15576B);
  static const Color couleurClaire = Color(0xFFE0F2EE);

  
  // FIRESTORE
  

  final FirestoreService firestoreService = FirestoreService();

  
  // VARIABLES
  

  final TextEditingController quantiteController = TextEditingController();

  List<QueryDocumentSnapshot<Map<String, dynamic>>> produitsDisponibles = [];

  List<Map<String, dynamic>> panier = [];

  String? produitSelectionneId;

  bool chargementProduits = true;
  bool enregistrement = false;

  
  // AJOUT OU MODIFICATION
  

  bool get modification {
    return widget.venteId != null && widget.vente != null;
  }

  
  // INITIALISATION
  

  @override
  void initState() {
    super.initState();

    if (modification) {
      panier = recupererProduitsVente(widget.vente!);
    }

    chargerProduits();
  }

  
  // LIBÉRATION
  

  @override
  void dispose() {
    quantiteController.dispose();

    super.dispose();
  }

  
  // RÉCUPÉRER LES PRODUITS D'UNE VENTE
  

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

    
    // COMPATIBILITÉ AVEC ANCIENNES VENTES
    

    final produitId = vente['produitId']?.toString();

    if (produitId != null && produitId.isNotEmpty) {
      final quantite = (vente['quantite'] as num?)?.toInt() ?? 0;

      final prix = (vente['prixUnitaire'] as num?)?.toDouble() ?? 0;

      final total =
          (vente['montantTotal'] as num?)?.toDouble() ?? quantite * prix;

      return [
        {
          'produitId': produitId,
          'nom': vente['nomProduit'] ?? vente['produit'] ?? 'Produit',
          'quantite': quantite,
          'prixUnitaire': prix,
          'sousTotal': total,
        },
      ];
    }

    return [];
  }

  
  // CHARGER LES PRODUITS
  

  Future<void> chargerProduits() async {
    try {
      final snapshot = await firestoreService.produits.get();

      if (!mounted) {
        return;
      }

      setState(() {
        produitsDisponibles = snapshot.docs;
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

  
  // PRODUIT SÉLECTIONNÉ
  

  QueryDocumentSnapshot<Map<String, dynamic>>? recupererProduitSelectionne() {
    if (produitSelectionneId == null) {
      return null;
    }

    for (final produit in produitsDisponibles) {
      if (produit.id == produitSelectionneId) {
        return produit;
      }
    }

    return null;
  }

  
  // ANCIENNE QUANTITÉ VENDUE D'UN PRODUIT
  

  int ancienneQuantiteProduit(String produitId) {
    if (!modification) {
      return 0;
    }

    final anciensProduits = recupererProduitsVente(widget.vente!);

    int quantite = 0;

    for (final produit in anciensProduits) {
      if (produit['produitId']?.toString() == produitId) {
        quantite += (produit['quantite'] as num?)?.toInt() ?? 0;
      }
    }

    return quantite;
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

  
  // TOTAL
  

  double calculerTotal() {
    double total = 0;

    for (final produit in panier) {
      total += (produit['sousTotal'] as num?)?.toDouble() ?? 0;
    }

    return total;
  }

  
  // AJOUTER UN PRODUIT AU PANIER
  

  void ajouterAuPanier() {
    final produitDocument = recupererProduitSelectionne();

    if (produitDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un produit.')),
      );

      return;
    }

    final quantiteVendue = int.tryParse(quantiteController.text.trim());

    if (quantiteVendue == null || quantiteVendue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La quantité doit être supérieure à 0.')),
      );

      return;
    }

    
    // EMPÊCHER UN PRODUIT DEUX FOIS
    

    final dejaAjoute = panier.any(
      (produit) => produit['produitId']?.toString() == produitDocument.id,
    );

    if (dejaAjoute) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ce produit est déjà dans cette vente. '
            'Supprimez-le de la liste avant de saisir une nouvelle quantité.',
          ),
        ),
      );

      return;
    }

    final donnees = produitDocument.data();

    final nom = donnees['nom']?.toString() ?? 'Produit';

    final stockActuel = (donnees['quantite'] as num?)?.toInt() ?? 0;

    final prixUnitaire = (donnees['prixUnitaire'] as num?)?.toDouble() ?? 0;

    
    // EN MODIFICATION
    
    // Le stock actuel a déjà été diminué par l'ancienne vente.
    // On ajoute donc l'ancienne quantité disponible.
    

    final ancienneQuantite = ancienneQuantiteProduit(produitDocument.id);

    final quantiteDisponible = stockActuel + ancienneQuantite;

    if (quantiteVendue > quantiteDisponible) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stock insuffisant. Quantité disponible : '
            '$quantiteDisponible.',
          ),
        ),
      );

      return;
    }

    final sousTotal = quantiteVendue * prixUnitaire;

    setState(() {
      panier.add({
        'produitId': produitDocument.id,
        'nom': nom,
        'quantite': quantiteVendue,
        'prixUnitaire': prixUnitaire,
        'sousTotal': sousTotal,
      });

      produitSelectionneId = null;
      quantiteController.clear();
    });
  }

  
  // RETIRER DU PANIER
  

  void supprimerDuPanier(int index) {
    setState(() {
      panier.removeAt(index);
    });
  }

  
  // ENREGISTRER
  

  Future<void> enregistrerVente() async {
    if (panier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez au moins un produit à la vente.'),
        ),
      );

      return;
    }

    if (enregistrement) {
      return;
    }

    setState(() {
      enregistrement = true;
    });

    try {
      if (modification) {
        await modifierVente();
      } else {
        await ajouterVente();
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

  
  // AJOUTER UNE NOUVELLE VENTE
  

  Future<void> ajouterVente() async {
    final venteReference = firestoreService.ventes.doc();

    final activiteReference = firestoreService.activites.doc();

    final montantTotal = calculerTotal();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final Map<String, DocumentSnapshot<Map<String, dynamic>>>
      produitsSnapshots = {};

      
      // TOUTES LES LECTURES D'ABORD
      

      for (final produit in panier) {
        final produitId = produit['produitId'].toString();

        final reference = firestoreService.produits.doc(produitId);

        final snapshot = await transaction.get(reference);

        produitsSnapshots[produitId] = snapshot;
      }

      
      // VÉRIFIER LES STOCKS
      

      for (final produit in panier) {
        final produitId = produit['produitId'].toString();

        final snapshot = produitsSnapshots[produitId]!;

        if (!snapshot.exists) {
          throw Exception('Un produit de cette vente n’existe plus.');
        }

        final stock = (snapshot.data()?['quantite'] as num?)?.toInt() ?? 0;

        final quantite = (produit['quantite'] as num?)?.toInt() ?? 0;

        if (quantite > stock) {
          throw Exception(
            'Stock insuffisant pour '
            '${produit['nom']}. '
            'Disponible : $stock.',
          );
        }
      }

      
      // DIMINUER LE STOCK
      

      for (final produit in panier) {
        final produitId = produit['produitId'].toString();

        final snapshot = produitsSnapshots[produitId]!;

        final stock = (snapshot.data()?['quantite'] as num?)?.toInt() ?? 0;

        final quantite = (produit['quantite'] as num?)?.toInt() ?? 0;

        transaction.update(snapshot.reference, {
          'quantite': stock - quantite,
          'dateModification': FieldValue.serverTimestamp(),
        });
      }

      
      // CRÉER LA VENTE
      

      transaction.set(venteReference, {
        'produits': panier,
        'montantTotal': montantTotal,
        'date': FieldValue.serverTimestamp(),
      });

      
      // ACTIVITÉ
      

      transaction.set(activiteReference, {
        'titre': 'Nouvelle vente enregistrée',
        'description':
            '${panier.length} produit(s) vendu(s) • '
            '${formaterMontant(montantTotal)} FCFA',
        'type': 'vente',
        'venteId': venteReference.id,
        'date': FieldValue.serverTimestamp(),
      });
    });
  }

  
  // MODIFIER UNE VENTE
  

  Future<void> modifierVente() async {
    final venteId = widget.venteId!;

    final venteReference = firestoreService.ventes.doc(venteId);

    final activitesSnapshot = await firestoreService.activites
        .where('venteId', isEqualTo: venteId)
        .get();

    final nouveauTotal = calculerTotal();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      
      // LIRE LA VENTE ACTUELLE
      

      final venteSnapshot = await transaction.get(venteReference);

      if (!venteSnapshot.exists) {
        throw Exception('Cette vente n’existe plus.');
      }

      final ancienneVente = venteSnapshot.data()!;

      final anciensProduits = recupererProduitsVente(ancienneVente);

      
      // QUANTITÉS ANCIENNES
      

      final Map<String, int> anciennesQuantites = {};

      for (final produit in anciensProduits) {
        final id = produit['produitId']?.toString();

        if (id == null || id.isEmpty) {
          continue;
        }

        final quantite = (produit['quantite'] as num?)?.toInt() ?? 0;

        anciennesQuantites[id] = (anciennesQuantites[id] ?? 0) + quantite;
      }

      
      // NOUVELLES QUANTITÉS
      

      final Map<String, int> nouvellesQuantites = {};

      for (final produit in panier) {
        final id = produit['produitId']?.toString();

        if (id == null || id.isEmpty) {
          continue;
        }

        final quantite = (produit['quantite'] as num?)?.toInt() ?? 0;

        nouvellesQuantites[id] = (nouvellesQuantites[id] ?? 0) + quantite;
      }

      
      // TOUS LES PRODUITS CONCERNÉS
      

      final idsProduits = <String>{
        ...anciennesQuantites.keys,
        ...nouvellesQuantites.keys,
      };

      final Map<String, DocumentSnapshot<Map<String, dynamic>>>
      snapshotsProduits = {};

      
      // TOUTES LES LECTURES AVANT LES ÉCRITURES
      

      for (final id in idsProduits) {
        final snapshot = await transaction.get(
          firestoreService.produits.doc(id),
        );

        snapshotsProduits[id] = snapshot;
      }

      
      // RECALCULER CHAQUE STOCK
      
      // stock actuel
      // + ancienne quantité vendue
      // - nouvelle quantité vendue
      

      for (final id in idsProduits) {
        final ancienneQuantite = anciennesQuantites[id] ?? 0;

        final nouvelleQuantite = nouvellesQuantites[id] ?? 0;

        final snapshot = snapshotsProduits[id]!;

        if (!snapshot.exists) {
          if (nouvelleQuantite > 0) {
            throw Exception('Un produit sélectionné n’existe plus.');
          }

          continue;
        }

        final stockActuel =
            (snapshot.data()?['quantite'] as num?)?.toInt() ?? 0;

        final nouveauStock = stockActuel + ancienneQuantite - nouvelleQuantite;

        if (nouveauStock < 0) {
          final nom = snapshot.data()?['nom']?.toString() ?? 'Produit';

          throw Exception('Stock insuffisant pour $nom.');
        }

        if (ancienQuantiteDifferente(ancienneQuantite, nouvelleQuantite)) {
          transaction.update(snapshot.reference, {
            'quantite': nouveauStock,
            'dateModification': FieldValue.serverTimestamp(),
          });
        }
      }

      
      // MODIFIER LA VENTE
      

      transaction.update(venteReference, {
        'produits': panier,
        'montantTotal': nouveauTotal,
        'dateModification': FieldValue.serverTimestamp(),
      });

      
      // ACTIVITÉ
      

      if (activitesSnapshot.docs.isEmpty) {
        final activiteReference = firestoreService.activites.doc();

        transaction.set(activiteReference, {
          'titre': 'Vente modifiée',
          'description':
              '${panier.length} produit(s) • '
              '${formaterMontant(nouveauTotal)} FCFA',
          'type': 'vente',
          'venteId': venteId,
          'date': FieldValue.serverTimestamp(),
        });
      } else {
        for (final activite in activitesSnapshot.docs) {
          transaction.update(activite.reference, {
            'titre': 'Vente modifiée',
            'description':
                '${panier.length} produit(s) • '
                '${formaterMontant(nouveauTotal)} FCFA',
            'date': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }

  bool ancienQuantiteDifferente(int ancienne, int nouvelle) {
    return ancienne != nouvelle;
  }

  
  // INTERFACE
  

  @override
  Widget build(BuildContext context) {
    final selection = recupererProduitSelectionne();

    final donnees = selection?.data();

    final stock = (donnees?['quantite'] as num?)?.toInt() ?? 0;

    final prix = (donnees?['prixUnitaire'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),

      appBar: AppBar(
        title: Text(modification ? 'Modifier la vente' : 'Nouvelle vente'),
      ),

      body: SafeArea(
        child: chargementProduits
            ? const Center(
                child: CircularProgressIndicator(color: couleurPrincipale),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modification
                          ? 'Modifier les produits vendus'
                          : 'Ajouter des produits',
                      style: const TextStyle(
                        color: couleurPrincipale,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      modification
                          ? 'Modifiez les produits ou les quantités de cette vente.'
                          : 'Sélectionnez un produit et indiquez la quantité vendue.',
                      style: const TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 25),

                    
                    // PRODUIT
                    
                    if (produitsDisponibles.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        key: ValueKey(produitSelectionneId),
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
                        onChanged: (value) {
                          setState(() {
                            produitSelectionneId = value;
                          });
                        },
                      ),

                      if (selection != null) ...[
                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: couleurClaire,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Stock : $stock',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '${formaterMontant(prix)} FCFA / unité',
                                style: const TextStyle(
                                  color: couleurPrincipale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      TextFormField(
                        controller: quantiteController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Quantité vendue',
                          prefixIcon: Icon(
                            Icons.numbers,
                            color: couleurPrincipale,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: ajouterAuPanier,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: couleurPrincipale,
                            minimumSize: const Size(double.infinity, 52),
                            side: const BorderSide(color: couleurPrincipale),
                          ),
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Ajouter à la vente'),
                        ),
                      ),
                    ],

                    const SizedBox(height: 30),

                    
                    // PRODUITS DE LA VENTE
                    
                    const Text(
                      'Produits de la vente',
                      style: TextStyle(
                        color: couleurPrincipale,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    if (panier.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          'Aucun produit ajouté.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: panier.length,
                        itemBuilder: (context, index) {
                          final produit = panier[index];

                          final nom = produit['nom'].toString();

                          final quantite = (produit['quantite'] as num).toInt();

                          final prix = (produit['prixUnitaire'] as num)
                              .toDouble();

                          final sousTotal = (produit['sousTotal'] as num)
                              .toDouble();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: couleurClaire,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_cart_outlined,
                                    color: couleurPrincipale,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nom,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        '$quantite × '
                                        '${formaterMontant(prix)} FCFA',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        '${formaterMontant(sousTotal)} FCFA',
                                        style: const TextStyle(
                                          color: couleurPrincipale,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                IconButton(
                                  onPressed: () {
                                    supprimerDuPanier(index);
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 25),

                    
                    // TOTAL
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: couleurPrincipale,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Total de la vente',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          Text(
                            '${formaterMontant(calculerTotal())} FCFA',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    
                    // ENREGISTRER
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: enregistrement ? null : enregistrerVente,
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
                              : 'Enregistrer la vente',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
