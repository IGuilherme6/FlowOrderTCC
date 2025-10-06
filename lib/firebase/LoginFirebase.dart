import 'package:firebase_auth/firebase_auth.dart';
import 'package:floworder/auxiliar/Validador.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginFirebase {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Validador validador = Validador();

  Future<String> login(String email, String password) async {
    try {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

      // Validações básicas
      if (email.isEmpty) {
        return 'Email não pode estar vazio';
      }

      if (password.isEmpty) {
        return 'Senha não pode estar vazia';
      }

      if (!validador.validarEmail(email)) {
        return 'Email inválido';
      }

      // Tentativa de login
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Verifica se o usuário foi autenticado
      if (result.user != null) {
        // Busca os dados do usuário no Firestore
        var userDoc = await FirebaseFirestore.instance
            .collection('Usuarios') // ajuste o nome da collection conforme seu projeto
            .doc(result.user!.uid)
            .get();

        // Verifica se o documento existe
        if (!userDoc.exists) {
          await _auth.signOut(); // Faz logout
          return 'Usuário não encontrado no sistema';
        }

        // Obtém os dados do documento
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Verifica se a conta está ativa
        bool ativo = userData['ativo'] ?? false;
        if (!ativo) {
          await _auth.signOut(); // Faz logout
          return 'Conta desativada. Entre em contato com o administrador';
        }

        // Verifica o cargo do usuário
        String cargo = userData['cargo'] ?? '';

        // Garçom não pode fazer login
        if (cargo.toLowerCase() == 'garçom') {
          await _auth.signOut(); // Faz logout
          return 'Garçons não têm permissão para acessar o sistema';
        }

        // Valida se o cargo é válido
        List<String> cargosPermitidos = ['gerente', 'atendente', 'cozinheiro'];
        if (!cargosPermitidos.contains(cargo.toLowerCase())) {
          await _auth.signOut(); // Faz logout
          return 'Cargo não autorizado para acesso ao sistema';
        }

        // Aqui você pode salvar o cargo em algum gerenciador de estado
        // para controlar o nível de acesso em outras partes do app
        // Exemplo: await _salvarCargoLocalmente(cargo);

        return 'success'; // Login bem-sucedido
      } else {
        return 'Falha na autenticação';
      }
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e.code);
    } catch (e) {
      // Se houver erro ao buscar dados do Firestore, faz logout preventivo
      try {
        await _auth.signOut();
      } catch (_) {}
      return 'Erro ao validar usuário: ${e.toString()}';
    }
  }

  // Método para validar email

  // Tratamento dos erros do Firebase Auth em português
  String _handleFirebaseError(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Conta desabilitada';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde';
      case 'invalid-credential':
        return 'Credenciais inválidas';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet';
      case 'operation-not-allowed':
        return 'Operação não permitida';
      case 'weak-password':
        return 'Senha muito fraca';
      case 'email-already-in-use':
        return 'Email já está em uso';
      default:
        return 'Erro de autenticação: $errorCode';
    }
  }

  // Métodos adicionais úteis

  // Verificar se há usuário logado
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Fazer logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Stream para escutar mudanças no estado de autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Verificar se usuário está logado
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  // Enviar email de recuperação de senha
  Future<String> sendPasswordReset(String email) async {
    try {
      if (email.isEmpty) {
        return 'Email não pode estar vazio';
      }

      if (!validador.validarEmail(email)) {
        return 'Email inválido';
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
      return 'success';
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e.code);
    } catch (e) {
      return 'Erro ao enviar email: ${e.toString()}';
    }
  }

  Future<String> resetPassword(String email) async {
    try {
      if (email.isEmpty) {
        return 'Email não pode estar vazio';
      }

      if (!validador.validarEmail(email)) {
        return 'Email inválido';
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
      return 'E-mail de recuperação enviado com sucesso! Verifique sua caixa de entrada e spam.';
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e.code);
    } catch (e) {
      return 'Erro ao enviar email: ${e.toString()}';
    }
  }
}
