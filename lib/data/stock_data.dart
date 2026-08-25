import 'package:flutter/foundation.dart';

class StockData extends ChangeNotifier {
  static final StockData instance = StockData._();

  StockData._();

  final List<Map<String, dynamic>> produits = [];
  final List<Map<String, dynamic>> ventes = [];
  final List<Map<String, dynamic>> approvisionnements = [];
  final List<Map<String, dynamic>> fournisseurs = [];

  int seuilGeneral = 5;

  double get valeurStock {
    double total = 0;

    for (final produit in produits) {
      total +=
          (produit['prix'] as num) *
          (produit['quantite'] as num);
    }

    return total;
  }

  int get nombreProduits {
    return produits.length;
  }

  int get nombreAlertes {
    int total = 0;

    for (final produit in produits) {
      final seuil = produit['seuil'] ?? seuilGeneral;

      if (produit['quantite'] <= seuil) {
        total++;
      }
    }

    return total;
  }

  void ajouterProduit({
    required String nom,
    required int quantite,
    required double prix,
    required int seuil,
  }) {
    produits.add({
      'nom': nom,
      'quantite': quantite,
      'prix': prix,
      'seuil': seuil,
    });

    notifyListeners();
  }

  void supprimerProduit(int index) {
    produits.removeAt(index);
    notifyListeners();
  }

  bool enregistrerVente({
    required int indexProduit,
    required int quantite,
  }) {
    final produit = produits[indexProduit];

    if (quantite <= 0 || quantite > produit['quantite']) {
      return false;
    }

    produit['quantite'] -= quantite;

    ventes.insert(0, {
      'produit': produit['nom'],
      'quantite': quantite,
      'prix': produit['prix'],
      'total': produit['prix'] * quantite,
      'date': DateTime.now(),
    });

    notifyListeners();

    return true;
  }

  void enregistrerApprovisionnement({
    required int indexProduit,
    required int quantite,
  }) {
    if (quantite <= 0) {
      return;
    }

    final produit = produits[indexProduit];

    produit['quantite'] += quantite;

    approvisionnements.insert(0, {
      'produit': produit['nom'],
      'quantite': quantite,
      'date': DateTime.now(),
    });

    notifyListeners();
  }

  void ajouterFournisseur({
    required String nom,
    required String telephone,
    required String adresse,
  }) {
    fournisseurs.add({
      'nom': nom,
      'telephone': telephone,
      'adresse': adresse,
    });

    notifyListeners();
  }

  void supprimerFournisseur(int index) {
    fournisseurs.removeAt(index);
    notifyListeners();
  }

  void modifierSeuil(int valeur) {
    seuilGeneral = valeur;
    notifyListeners();
  }
}