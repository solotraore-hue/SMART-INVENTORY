import 'package:flutter/material.dart';

import 'accueil_page.dart';
import 'produits_page.dart';
import 'ventes_page.dart';
import 'approvisionnement_page.dart';
import 'fournisseurs_page.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  // COULEURS

  static const Color couleurPrincipale = Color(0xFF15576B);

  static const Color couleurSelection = Color(0xFFE0F2EE);

  // PAGE SÉLECTIONNÉE

  int indexSelectionne = 0;

  // AFFICHER LA PAGE CORRESPONDANTE

  Widget afficherPage() {
    switch (indexSelectionne) {
      case 0:
        return const AccueilPage();

      case 1:
        return const ProduitsPage();

      case 2:
        return const VentesPage();

      case 3:
        return const ApprovisionnementPage();

      case 4:
        return const FournisseursPage();

      default:
        return const AccueilPage();
    }
  }

  // CHANGER DE PAGE

  void changerPage(int nouvelIndex) {
    if (nouvelIndex == indexSelectionne) {
      return;
    }

    setState(() {
      indexSelectionne = nouvelIndex;
    });
  }

  // INTERFACE

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),

      // Une seule page est présente à la fois.
      body: afficherPage(),

      // NAVIGATION DU BAS
      bottomNavigationBar: NavigationBar(
        selectedIndex: indexSelectionne,

        onDestinationSelected: changerPage,

        height: 75,

        backgroundColor: Colors.white,

        indicatorColor: couleurSelection,

        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,

        destinations: const [
          // ACCUEIL
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: couleurPrincipale),
            label: 'Accueil',
          ),

          // PRODUITS
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: couleurPrincipale),
            label: 'Produits',
          ),

          // VENTES
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart, color: couleurPrincipale),
            label: 'Ventes',
          ),

          // APPROVISIONNEMENT
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping, color: couleurPrincipale),
            label: 'Appro.',
          ),

          // FOURNISSEURS
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: couleurPrincipale),
            label: 'Fournisseurs',
          ),
        ],
      ),
    );
  }
}
