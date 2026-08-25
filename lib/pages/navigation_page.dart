import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'accueil_page.dart';
import 'approvisionnement_page.dart';
import 'fournisseurs_page.dart';
import 'produits_page.dart';
import 'ventes_page.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int indexSelectionne = 0;

  final List<Widget> pages = const [
    AccueilPage(),
    ProduitsPage(),
    VentesPage(),
    ApprovisionnementPage(),
    FournisseursPage(),
  ];

  Future<void> deconnexion() async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.logout,
                color: Color(0xFF15576B),
              ),
              SizedBox(width: 10),
              Text('Déconnexion'),
            ],
          ),
          content: const Text(
            'Voulez-vous vraiment vous déconnecter de SmartInventory ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Annuler',
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15576B),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Se déconnecter',
              ),
            ),
          ],
        );
      },
    );

    if (confirmation != true) return;

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de vous déconnecter pour le moment.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: indexSelectionne,
        children: pages,
      ),

      bottomNavigationBar: NavigationBar(
        height: 72,
        backgroundColor: Colors.white,
        selectedIndex: indexSelectionne,
        indicatorColor: const Color(0xFFE0F2EE),
        onDestinationSelected: (index) {
          setState(() {
            indexSelectionne = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Produits',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Ventes',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Appro.',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Fournisseurs',
          ),
        ],
      ),

      floatingActionButton: indexSelectionne == 0
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF15576B),
              foregroundColor: Colors.white,
              tooltip: 'Déconnexion',
              onPressed: deconnexion,
              child: const Icon(Icons.logout),
            )
          : null,
    );
  }
}