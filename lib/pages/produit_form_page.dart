import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/firestore_service.dart';

class ProduitFormPage extends StatefulWidget {
  final String? produitId;
  final Map<String, dynamic>? produit;

  const ProduitFormPage({super.key, this.produitId, this.produit});

  @override
  State<ProduitFormPage> createState() => _ProduitFormPageState();
}

class _ProduitFormPageState extends State<ProduitFormPage> {
  static const Color couleurPrincipale = Color(0xFF15576B);

  final FirestoreService firestoreService = FirestoreService();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late TextEditingController nomController;
  late TextEditingController quantiteController;
  late TextEditingController prixController;
  late TextEditingController seuilController;

  bool chargement = false;

  
  // SAVOIR SI ON AJOUTE OU MODIFIE
  

  bool get modification {
    return widget.produitId != null && widget.produit != null;
  }

  
  // INITIALISATION
  

  @override
  void initState() {
    super.initState();

    nomController = TextEditingController(
      text: widget.produit?['nom']?.toString() ?? '',
    );

    quantiteController = TextEditingController(
      text: widget.produit?['quantite']?.toString() ?? '',
    );

    prixController = TextEditingController(
      text: widget.produit?['prixUnitaire']?.toString() ?? '',
    );

    seuilController = TextEditingController(
      text: widget.produit?['seuil']?.toString() ?? '',
    );
  }

  
  // LIBÉRER LES CONTROLLERS
  

  @override
  void dispose() {
    nomController.dispose();
    quantiteController.dispose();
    prixController.dispose();
    seuilController.dispose();

    super.dispose();
  }

  
  // ENREGISTRER
  

  Future<void> enregistrerProduit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (chargement) {
      return;
    }

    setState(() {
      chargement = true;
    });

    final nom = nomController.text.trim();

    final quantite = int.parse(quantiteController.text.trim());

    final prixUnitaire = double.parse(prixController.text.trim());

    final seuil = int.parse(seuilController.text.trim());

    try {
      
      // MODIFICATION
      

      if (modification) {
        final produitReference = firestoreService.produits.doc(
          widget.produitId,
        );

        final activiteReference = firestoreService.activites.doc();

        final batch = FirebaseFirestore.instance.batch();

        batch.update(produitReference, {
          'nom': nom,
          'quantite': quantite,
          'prixUnitaire': prixUnitaire,
          'seuil': seuil,
          'dateModification': FieldValue.serverTimestamp(),
        });

        batch.set(activiteReference, {
          'titre': 'Produit modifié',
          'description': '$nom a été modifié.',
          'type': 'produit',
          'produitId': widget.produitId,
          'date': FieldValue.serverTimestamp(),
        });

        await batch.commit();
      }
      
      // AJOUT
      
      else {
        final produitReference = firestoreService.produits.doc();

        final activiteReference = firestoreService.activites.doc();

        final batch = FirebaseFirestore.instance.batch();

        batch.set(produitReference, {
          'nom': nom,
          'quantite': quantite,
          'prixUnitaire': prixUnitaire,
          'seuil': seuil,
          'dateCreation': FieldValue.serverTimestamp(),
        });

        batch.set(activiteReference, {
          'titre': 'Nouveau produit ajouté',
          'description': '$nom a été ajouté au stock.',
          'type': 'produit',
          'produitId': produitReference.id,
          'date': FieldValue.serverTimestamp(),
        });

        await batch.commit();
      }

      if (!mounted) {
        return;
      }

      // Retour vers ProduitsPage.
      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Impossible d’enregistrer le produit.'),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une erreur est survenue pendant l’enregistrement.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          chargement = false;
        });
      }
    }
  }

  
  // INTERFACE
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),

      appBar: AppBar(
        title: Text(
          modification ? 'Modifier le produit' : 'Ajouter un produit',
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Form(
            key: formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Informations du produit',
                  style: TextStyle(
                    color: couleurPrincipale,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Tous les champs sont obligatoires.',
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 25),

                
                // NOM
                
                TextFormField(
                  controller: nomController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,

                  decoration: const InputDecoration(
                    labelText: 'Nom du produit',
                    prefixIcon: Icon(
                      Icons.inventory_2_outlined,
                      color: couleurPrincipale,
                    ),
                  ),

                  validator: (value) {
                    final nom = value?.trim() ?? '';

                    if (nom.isEmpty) {
                      return 'Le nom du produit est obligatoire';
                    }

                    if (nom.length < 2) {
                      return 'Le nom est trop court';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                
                // QUANTITÉ
                
                TextFormField(
                  controller: quantiteController,

                  keyboardType: TextInputType.number,

                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],

                  textInputAction: TextInputAction.next,

                  decoration: const InputDecoration(
                    labelText: 'Quantité',
                    prefixIcon: Icon(Icons.numbers, color: couleurPrincipale),
                  ),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La quantité est obligatoire';
                    }

                    final quantite = int.tryParse(value);

                    if (quantite == null) {
                      return 'Quantité invalide';
                    }

                    if (quantite < 0) {
                      return 'La quantité ne peut pas être négative';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                
                // PRIX UNITAIRE
                
                TextFormField(
                  controller: prixController,

                  keyboardType: TextInputType.number,

                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],

                  textInputAction: TextInputAction.next,

                  decoration: const InputDecoration(
                    labelText: 'Prix unitaire (FCFA)',
                    prefixIcon: Icon(
                      Icons.payments_outlined,
                      color: couleurPrincipale,
                    ),
                  ),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le prix unitaire est obligatoire';
                    }

                    final prix = double.tryParse(value);

                    if (prix == null) {
                      return 'Prix invalide';
                    }

                    if (prix <= 0) {
                      return 'Le prix doit être supérieur à 0';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                
                // SEUIL
                
                TextFormField(
                  controller: seuilController,

                  keyboardType: TextInputType.number,

                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],

                  textInputAction: TextInputAction.done,

                  decoration: const InputDecoration(
                    labelText: 'Seuil d’alerte',
                    prefixIcon: Icon(
                      Icons.warning_amber_outlined,
                      color: couleurPrincipale,
                    ),
                  ),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le seuil d’alerte est obligatoire';
                    }

                    final seuil = int.tryParse(value);

                    if (seuil == null) {
                      return 'Seuil invalide';
                    }

                    if (seuil < 0) {
                      return 'Le seuil ne peut pas être négatif';
                    }

                    return null;
                  },

                  onFieldSubmitted: (_) {
                    enregistrerProduit();
                  },
                ),

                const SizedBox(height: 30),

                
                // BOUTON ENREGISTRER
                
                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton.icon(
                    onPressed: chargement ? null : enregistrerProduit,

                    icon: chargement
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
                                : Icons.add_circle_outline,
                          ),

                    label: Text(
                      chargement
                          ? 'Enregistrement...'
                          : modification
                          ? 'Enregistrer les modifications'
                          : 'Ajouter le produit',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
