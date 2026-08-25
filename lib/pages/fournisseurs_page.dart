import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class FournisseursPage extends StatefulWidget {
  const FournisseursPage({super.key});

  @override
  State<FournisseursPage> createState() => _FournisseursPageState();
}

class _FournisseursPageState extends State<FournisseursPage> {
  final firestoreService = FirestoreService();

  Future<void> afficherFormulaire({
    String? fournisseurId,
    Map<String, dynamic>? fournisseur,
  }) async {
    final formKey = GlobalKey<FormState>();

    final nomController = TextEditingController(
      text: fournisseur?['nom'] ?? '',
    );

    final telephoneController = TextEditingController(
      text: fournisseur?['telephone'] ?? '',
    );

    final adresseController = TextEditingController(
      text: fournisseur?['adresse'] ?? '',
    );

    final modification = fournisseurId != null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      modification
                          ? 'Modifier le fournisseur'
                          : 'Ajouter un fournisseur',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15576B),
                      ),
                    ),

                    const SizedBox(height: 25),

                    TextFormField(
                      controller: nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du fournisseur',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom est obligatoire';
                        }

                        if (value.trim().length < 3 ||
                            value.trim().length > 20) {
                          return 'Le nom doit contenir entre 3 et 20 caractères';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: telephoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 8,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le téléphone est obligatoire';
                        }

                        if (!RegExp(r'^\d{8}$').hasMatch(value.trim())) {
                          return 'Le téléphone doit contenir exactement 8 chiffres';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: adresseController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Adresse',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'L’adresse est obligatoire';
                        }

                        if (value.trim().length < 3) {
                          return 'L’adresse doit contenir au moins 3 caractères';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF15576B),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          final Map<String, dynamic> donnees = {
                            'nom': nomController.text.trim(),
                            'telephone': telephoneController.text.trim(),
                            'adresse': adresseController.text.trim(),
                          };

                          try {
                            if (modification) {
                              await firestoreService.fournisseurs
                                  .doc(fournisseurId)
                                  .update(donnees);

                              await firestoreService.activites.add({
                                'titre': 'Fournisseur modifié',
                                'description': nomController.text.trim(),
                                'type': 'fournisseur',
                                'date': FieldValue.serverTimestamp(),
                              });
                            } else {
                              donnees['dateCreation'] =
                                  FieldValue.serverTimestamp();

                              await firestoreService.fournisseurs.add(donnees);

                              await firestoreService.activites.add({
                                'titre': 'Nouveau fournisseur',
                                'description': nomController.text.trim(),
                                'type': 'fournisseur',
                                'date': FieldValue.serverTimestamp(),
                              });
                            }

                            if (context.mounted) {
                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    modification
                                        ? 'Fournisseur modifié avec succès'
                                        : 'Fournisseur ajouté avec succès',
                                  ),
                                ),
                              ); 
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Une erreur est survenue.'),
                                ),
                              );
                            }
                          }
                        },
                        icon: Icon(
                          modification ? Icons.save_outlined : Icons.add,
                        ),
                        label: Text(
                          modification ? 'Enregistrer' : 'Ajouter',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    nomController.dispose();
    telephoneController.dispose();
    adresseController.dispose();
  }

  Future<void> supprimerFournisseur(String id, String nom) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le fournisseur'),
          content: Text('Voulez-vous vraiment supprimer "$nom" ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmation == true) {
      try {
        await firestoreService.fournisseurs.doc(id).delete();

        await firestoreService.activites.add({
          'titre': 'Fournisseur supprimé',
          'description': nom,
          'type': 'fournisseur',
          'date': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fournisseur supprimé avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de supprimer le fournisseur.'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF15576B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Fournisseurs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF15576B),
        foregroundColor: Colors.white,
        onPressed: () {
          afficherFormulaire();
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestoreService.fournisseurs
            .orderBy('dateCreation', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Impossible de charger les fournisseurs.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final fournisseurs = snapshot.data!.docs;

          if (fournisseurs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Color(0xFF15576B),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Aucun fournisseur',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text('Ajoutez votre premier fournisseur.'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: fournisseurs.length,
            itemBuilder: (context, index) {
              final document = fournisseurs[index];
              final fournisseur = document.data();

              final nom = fournisseur['nom'] ?? '';
              final telephone = fournisseur['telephone'] ?? '';
              final adresse = fournisseur['adresse'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2EE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF15576B),
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
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Row(
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                telephone,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),

                              const SizedBox(width: 5),

                              Expanded(
                                child: Text(
                                  adresse,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Color(0xFF15576B),
                      ),
                      onSelected: (value) {
                        if (value == 'modifier') {
                          afficherFormulaire(
                            fournisseurId: document.id,
                            fournisseur: fournisseur,
                          );
                        }

                        if (value == 'supprimer') {
                          supprimerFournisseur(document.id, nom);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'modifier',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 10),
                              Text('Modifier'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'supprimer',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 10),
                              Text(
                                'Supprimer',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
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
