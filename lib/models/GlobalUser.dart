// lib/auxiliar/GlobalUser.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GlobalUser {
  // Instância única (Singleton)
  static final GlobalUser _instance = GlobalUser._internal();
  factory GlobalUser() => _instance;
  GlobalUser._internal();

  // Variáveis globais que persistem
  String? userType;
  String? userName;
  String? userEmail;
  String? userId;

  // Carregar dados do usuário logado
  Future<void> loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        clearUserData();
        return;
      }

      userId = user.uid;
      userEmail = user.email;

      // Buscar tipo e nome do usuário no Firestore
      final doc = await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        userType = data?['cargo'] as String?;
        userName = data?['nome'] as String?;
      }

      print('✅ Usuário carregado: $userName ($userType)');
    } catch (e) {
      print('❌ Erro ao carregar dados do usuário: $e');
    }
  }

  // Limpar dados ao fazer logout
  void clearUserData() {
    userType = null;
    userName = null;
    userEmail = null;
    userId = null;
    print('🗑️ Dados do usuário limpos');
  }

  // Verificar se está logado
  bool get isLoggedIn => userId != null;

  // Debug - mostrar dados
  void printUserData() {
    print('=== DADOS DO USUÁRIO ===');
    print('ID: $userId');
    print('Nome: $userName');
    print('Email: $userEmail');
    print('Tipo: $userType');
    print('========================');
  }
}

// Atalho global para acessar facilmente
final globalUser = GlobalUser();