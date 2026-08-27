import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import 'produit_form_page.dart';

class ProduitsPage extends StatefulWidget {
  const ProduitsPage({super.key});

  @override
  State<ProduitsPage> createState() => _ProduitsPageState();
}

class _ProduitsPageState extends State<ProduitsPage> {
  
  // COULEURS
  

  static const Color couleurPrincipale = Color(0xFF15576B);
  static const Color couleurClaire = Color(0xFFE0F2EE);

  
  // FIRESTORE
  

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

  
  // OUVRIR LE FORMULAIRE AJOUT / MODIFICATION
  

  Future<void> ouvrirFormulaire({
    String? produitId,
    Map<String, dynamic>? produit,
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
        SnackBar(
          content: Text(
            produitId == null
                ? 'Produit ajouté avec succès.'
                : 'Produit modifié avec succès.',
          ),
        ),
      );
    }
  }

  
  // AFFICHER LES ACTIONS
  

  Future<void> ouvrirActions({
    required String produitId,
    required Map<String, dynamic> produit,
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

    // Le premier dialogue est déjà fermé avant
    // d'effectuer l'action suivante.

    if (action == 'modifier') {
      await ouvrirFormulaire(produitId: produitId, produit: produit);
    }

    if (action == 'supprimer') {
      await supprimerProduit(produitId: produitId, produit: produit);
    }
  }

  
  // SUPPRIMER UN PRODUIT
  

  Future<void> supprimerProduit({
    required String produitId,
    required Map<String, dynamic> produit,
  }) async {
    final nom = produit['nom']?.toString() ?? 'ce produit';

    
    // CONFIRMATION
    

    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Supprimer le produit',
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
      
      // RÉCUPÉRER LES ACTIVITÉS LIÉES AU PRODUIT
      

      final activitesSnapshot = await firestoreService.activites
          .where('produitId', isEqualTo: produitId)
          .get();

      
      // BATCH FIRESTORE
      

      final batch = FirebaseFirestore.instance.batch();

      // Supprimer le produit.
      batch.delete(firestoreService.produits.doc(produitId));

      
      // SUPPRIMER LES ACTIVITÉS DE TYPE PRODUIT
      
      // Les ventes et approvisionnements historiques
      // ne sont pas supprimés.
      

      for (final document in activitesSnapshot.docs) {
        final activite = document.data();

        if (activite['type'] == 'produit') {
          batch.delete(document.reference);
        }
      }

      await batch.commit();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit supprimé avec succès.')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Impossible de supprimer le produit.'),
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

  
  // CARTE D'UN PRODUIT
  

  Widget carteProduit({
    required String produitId,
    required Map<String, dynamic> produit,
  }) {
    final nom = produit['nom']?.toString() ?? 'Produit';

    final quantite = (produit['quantite'] as num?)?.toInt() ?? 0;

    final prix = (produit['prixUnitaire'] as num?)?.toDouble() ?? 0;

    final seuil = (produit['seuil'] as num?)?.toInt() ?? 0;

    // Un produit passe en alerte lorsque sa quantité
    // devient inférieure ou égale au seuil.
    final enAlerte = quantite <= seuil;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        // Petite bordure orange en cas d'alerte.
        border: enAlerte
            ? Border.all(color: Colors.orange.withOpacity(0.5))
            : null,

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
          
          // ICÔNE DU PRODUIT
          
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: enAlerte ? Colors.orange.withOpacity(0.12) : couleurClaire,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              enAlerte
                  ? Icons.warning_amber_rounded
                  : Icons.inventory_2_outlined,
              color: enAlerte ? Colors.orange : couleurPrincipale,
            ),
          ),

          const SizedBox(width: 14),

          
          // INFORMATIONS DU PRODUIT
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: couleurPrincipale,
                  ),
                ),

                const SizedBox(height: 8),

                Text('Qté : $quantite', style: const TextStyle(fontSize: 13)),

                const SizedBox(height: 4),

                Text(
                  'P.U. : ${formaterMontant(prix)} FCFA',
                  style: const TextStyle(fontSize: 13),
                ),

                const SizedBox(height: 4),

                Text('Seuil : $seuil', style: const TextStyle(fontSize: 13)),

                
                // ALERTE
                
                if (enAlerte) ...[
                  const SizedBox(height: 7),
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

          
          // BOUTON TROIS POINTS
          
          IconButton(
            tooltip: 'Actions',
            icon: const Icon(Icons.more_vert, color: couleurPrincipale),
            onPressed: () {
              ouvrirActions(produitId: produitId, produit: produit);
            },
          ),
        ],
      ),
    );
  }

  
  // INTERFACE DE LA PAGE
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),

      
      // BARRE DU HAUT
      
      appBar: AppBar(title: const Text('Produits')),

      
      // BOUTON AJOUTER
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ouvrirFormulaire();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouveau produit'),
      ),

      
      // PRODUITS FIRESTORE
      
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
       
        
        // Nous n'utilisons volontairement PAS :
        // .orderBy('dateCreation')
        // afin que les anciens produits qui n'ont pas encore
        // dateCreation soient aussi affichés.
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
                  'Impossible de charger les produits.\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final produits = snapshot.data?.docs ?? [];

          
          // AUCUN PRODUIT
          

          if (produits.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 85,
                      height: 85,
                      decoration: const BoxDecoration(
                        color: couleurClaire,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: couleurPrincipale,
                        size: 42,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Aucun produit',
                      style: TextStyle(
                        color: couleurPrincipale,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Appuyez sur "Nouveau produit" '
                      'pour enregistrer votre premier produit.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          
          // LISTE DES PRODUITS
          

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: produits.length,
            itemBuilder: (context, index) {
              final document = produits[index];

              return carteProduit(
                produitId: document.id,
                produit: document.data(),
              );
            },
          );
        },
      ),
    );
  }
}
