import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class ParametresPage extends StatelessWidget {
  const ParametresPage({super.key});

  Future<void> modifierSeuil(
    BuildContext context,
    String produitId,
    String nomProduit,
    int seuilActuel,
  ) async {
    final formKey = GlobalKey<FormState>();

    final seuilController = TextEditingController(text: seuilActuel.toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Seuil : $nomProduit'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: seuilController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nouveau seuil d’alerte',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le seuil est obligatoire';
                }

                final seuil = int.tryParse(value);

                if (seuil == null || seuil < 0) {
                  return 'Veuillez saisir un nombre valide';
                }

                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15576B),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final firestoreService = FirestoreService();

                await firestoreService.produits.doc(produitId).update({
                  'seuilAlerte': int.parse(seuilController.text.trim()),
                });

                if (context.mounted) {
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Seuil d’alerte modifié avec succès'),
                    ),
                  );
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    seuilController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF15576B),
        foregroundColor: Colors.white,
        title: const Text(
          'Paramètres',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestoreService.produits.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Impossible de charger les produits.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final produits = snapshot.data!.docs;

          if (produits.isEmpty) {
            return const Center(child: Text('Aucun produit disponible.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: produits.length,
            itemBuilder: (context, index) {
              final document = produits[index];
              final produit = document.data();

              final nom = produit['nom'] ?? '';
              final quantite = produit['quantite'] ?? 0;
              final seuil = produit['seuilAlerte'] ?? 0;

              final alerte = quantite <= seuil;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: alerte
                            ? Colors.red.shade50
                            : const Color(0xFFE0F2EE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.warning_amber_outlined,
                        color: alerte ? Colors.red : const Color(0xFF15576B),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nom,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stock : $quantite',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            'Seuil d’alerte : $seuil',
                            style: TextStyle(
                              color: alerte ? Colors.red : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        modifierSeuil(context, document.id, nom, seuil);
                      },
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Color(0xFF15576B),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
