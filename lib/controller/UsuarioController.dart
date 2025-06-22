import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Usuario.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsuarioController {
  final CollectionReference _usuariosRef =
  FirebaseFirestore.instance.collection('Gerentes');

  Future<String> cadastrarGerente(Usuario usuario) async {
    return await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: usuario.email,
      password: usuario.senha,
    ).then((userCredential) async {
      // Salvar usuário no Firestore
      await _usuariosRef.doc(userCredential.user?.uid).set({
        'nome': usuario.nome,
        'email': usuario.email,
        'cargo': usuario.cargo,
        'cpf': usuario.cpf,
        'uid': userCredential.user?.uid,
        'criadoEm': FieldValue.serverTimestamp(),
      });
      return 'Usuário cadastrado com sucesso';
    }).catchError((error) {
      return 'Erro ao cadastrar usuário: ${error.toString()}';
    });
  }

  String? pegarIdUsuarioLogado() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  Future<String> cadastrarFuncionario(Usuario usuario) async {
    try {
      // Pegar ID do gerente logado
      String? gerenteId = pegarIdUsuarioLogado();

      if (gerenteId == null) {
        return 'Erro: Nenhum usuário logado';
      }

      // Verificar se o usuário logado é realmente um gerente
      DocumentSnapshot gerenteDoc = await _usuariosRef.doc(gerenteId).get();

      if (!gerenteDoc.exists) {
        return 'Erro: Usuário não encontrado';
      }

      Map<String, dynamic> dadosGerente = gerenteDoc.data() as Map<String, dynamic>;

      if (dadosGerente['cargo'] != 'Gerente') {
        return 'Erro: Apenas gerentes podem cadastrar funcionários';
      }

      // 1. CRIAR USUÁRIO NO FIREBASE AUTH
      UserCredential funcionarioCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: usuario.email,
        password: usuario.senha,
      );

      String funcionarioId = funcionarioCredential.user!.uid;

      // 3. TAMBÉM SALVAR NA SUBCOLEÇÃO DO GERENTE (para facilitar consultas)
      await _usuariosRef
          .doc(gerenteId)
          .collection('funcionarios')
          .doc(funcionarioId)  // Mesmo ID do usuário principal
          .set({
        'nome': usuario.nome,
        'email': usuario.email,
        'cargo': usuario.cargo,
        'cpf': usuario.cpf,
        'funcionarioId': funcionarioId,
        'ativo': true,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      return 'Funcionário cadastrado com sucesso';

    } catch (error) {
      return 'Erro ao cadastrar funcionário: ${error.toString()}';
    }
  }


  // Método para listar funcionários do gerente logado
  Stream<QuerySnapshot> listarFuncionarios() {
    String? gerenteId = pegarIdUsuarioLogado();

    if (gerenteId == null) {
      throw Exception('Nenhum usuário logado');
    }

    return _usuariosRef
        .doc(gerenteId)
        .collection('funcionarios')
        .where('ativo', isEqualTo: true)
        .snapshots();
  }

  // Método para buscar funcionário específico
  Future<DocumentSnapshot?> buscarFuncionario(String funcionarioId) async {
    String? gerenteId = pegarIdUsuarioLogado();

    if (gerenteId == null) {
      return null;
    }

    return await _usuariosRef
        .doc(gerenteId)
        .collection('funcionarios')
        .doc(funcionarioId)
        .get();
  }

  // Método para atualizar funcionário
  Future<String> atualizarFuncionario(String funcionarioId, Usuario usuario) async {
    try {
      String? gerenteId = pegarIdUsuarioLogado();

      if (gerenteId == null) {
        return 'Erro: Nenhum usuário logado';
      }

      await _usuariosRef
          .doc(gerenteId)
          .collection('funcionarios')
          .doc(funcionarioId)
          .update({
        'nome': usuario.nome,
        'email': usuario.email,
        'tipo': usuario.cargo,
        'cpf': usuario.cpf,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      return 'Funcionário atualizado com sucesso';

    } catch (error) {
      return 'Erro ao atualizar funcionário: ${error.toString()}';
    }
  }

  // Método para desativar funcionário (soft delete)
  Future<String> desativarFuncionario(String funcionarioId) async {
    try {
      String? gerenteId = pegarIdUsuarioLogado();

      if (gerenteId == null) {
        return 'Erro: Nenhum usuário logado';
      }

      await _usuariosRef
          .doc(gerenteId)
          .collection('funcionarios')
          .doc(funcionarioId)
          .update({
        'ativo': false,
        'desativadoEm': FieldValue.serverTimestamp(),
      });

      return 'Funcionário desativado com sucesso';

    } catch (error) {
      return 'Erro ao desativar funcionário: ${error.toString()}';
    }
  }

  Future<void> atualizarUsuario(String id, Usuario usuario) async {
    await _usuariosRef.doc(id).update({
      'nome': usuario.nome,
      'email': usuario.email,
      'tipo': usuario.cargo,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }
}