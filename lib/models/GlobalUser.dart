import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:html' as html;

class GlobalUser extends ChangeNotifier {
  // Singleton
  static final GlobalUser _instance = GlobalUser._internal();
  factory GlobalUser() => _instance;
  GlobalUser._internal();

  // Dados persistentes
  String? userId;
  String? userEmail;
  String? userType;
  String? userName;

  // Carregar dados do Firestore e salvar localmente
  Future<void> loadUserDataFromFirebase(
      String uid, Map<String, dynamic> userData) async {
    userId = uid;
    userEmail = userData['email'];
    userType = userData['cargo'];
    userName = userData['nome'];

    await _saveToLocal();
    notifyListeners();
  }


  // Salvar dados no armazenamento local (Web ou Mobile)
  Future<void> _saveToLocal() async {
    final data = {
      'userId': userId,
      'userEmail': userEmail,
      'userType': userType,
      'userName': userName,
    };

    final json = jsonEncode(data);

    if (kIsWeb) {
      html.window.localStorage['globalUser'] = json;
    } else {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('globalUser', json);
    }
  }

  //Carregar dados salvos no armazenamento local na inicialização
  Future<void> loadFromLocalStorage() async {
    String? json;

    if (kIsWeb) {
      json = html.window.localStorage['globalUser'];
    } else {
      final prefs = await SharedPreferences.getInstance();
      json = prefs.getString('globalUser');
    }

    if (json == null) return;

    final data = jsonDecode(json);

    userId = data['userId'];
    userEmail = data['userEmail'];
    userType = data['userType'];
    userName = data['userName'];

    notifyListeners();
  }

  //Limpar dados (logout)
  Future<void> clearUserData() async {
    userId = null;
    userEmail = null;
    userType = null;
    userName = null;

    if (kIsWeb) {
      html.window.localStorage.remove('globalUser');
    } else {
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('globalUser');
    }

    notifyListeners();
  }

  // Verificar se está logado
  bool get isLoggedIn => userId != null;

}

// Instância global
final globalUser = GlobalUser();
