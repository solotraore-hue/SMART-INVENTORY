import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String get uid {
    final utilisateur = FirebaseAuth.instance.currentUser;

    if (utilisateur == null) {
      throw Exception('Utilisateur non connecté');
    }

    return utilisateur.uid;
  }

  DocumentReference<Map<String, dynamic>> get utilisateur {
    return firestore.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> get produits {
    return utilisateur.collection('produits');
  }

  CollectionReference<Map<String, dynamic>> get ventes {
    return utilisateur.collection('ventes');
  }

  CollectionReference<Map<String, dynamic>> get approvisionnements {
    return utilisateur.collection('approvisionnements');
  }

  CollectionReference<Map<String, dynamic>> get fournisseurs {
    return utilisateur.collection('fournisseurs');
  }

  CollectionReference<Map<String, dynamic>> get activites {
    return utilisateur.collection('activites');
  }
}