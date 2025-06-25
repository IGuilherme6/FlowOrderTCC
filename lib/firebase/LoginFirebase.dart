import 'package:firebase_auth/firebase_auth.dart';

class LoginFirebase {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> login(String email, String password) async {
    try {
      // Validações básicas
      if (email.isEmpty) {
        return 'Email não pode estar vazio';
      }

      if (password.isEmpty) {
        return 'Senha não pode estar vazia';
      }

      if (!_isValidEmail(email)) {
        return 'Email inválido';
      }

      // Tentativa de login
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Verifica se o usuário foi autenticado
      if (result.user != null) {
        return 'success'; // Login bem-sucedido
      } else {
        return 'Falha na autenticação';
      }
    } on FirebaseAuthException catch (e) {
      // Tratamento específico dos erros do Firebase Auth
      return _handleFirebaseError(e.code);
    } catch (e) {
      // Outros erros
      return 'Erro desconhecido: ${e.toString()}';
    }
  }

  // Método para validar email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

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

      if (!_isValidEmail(email)) {
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
}
