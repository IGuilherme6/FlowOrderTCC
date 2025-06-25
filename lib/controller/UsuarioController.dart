import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/Usuario.dart';

class UsuarioController {
  final CollectionReference _usuariosRef = FirebaseFirestore.instance
      .collection('Gerentes');

  /// Pega o ID do usuário logado
  String? pegarIdUsuarioLogado() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  /// Cadastro de gerente
  Future<String> cadastrarGerente(Usuario usuario) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: usuario.email,
            password: usuario.senha,
          );

      String userId = userCredential.user!.uid;

      await _usuariosRef.doc(userId).set({
        'nome': usuario.nome,
        'email': usuario.email,
        'cargo': 'Gerente',
        'cpf': usuario.cpf,
        'uid': userId,
        'ativo': true,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      return 'Gerente cadastrado com sucesso';
    } catch (e) {
      return 'Erro ao cadastrar gerente: ${e.toString()}';
    }
  }

  /// Cadastro de funcionário
  Future<String> cadastrarFuncionario(Usuario usuario) async {
    try {
      String? gerenteId = pegarIdUsuarioLogado();
      if (gerenteId == null) return 'Erro: Nenhum gerente logado';

      // Verificar se é gerente
      DocumentSnapshot gerenteDoc = await _usuariosRef.doc(gerenteId).get();
      if (!gerenteDoc.exists) return 'Erro: Gerente não encontrado';

      Map<String, dynamic> dadosGerente =
          gerenteDoc.data() as Map<String, dynamic>;

      if (dadosGerente['cargo'] != 'Gerente') {
        return 'Erro: Apenas gerentes podem cadastrar funcionários';
      }

      // Criar instância secundária do Firebase
      FirebaseApp appSecundario = await Firebase.initializeApp(
        name: 'appSecundario',
        options: Firebase.app().options,
      );

      FirebaseAuth authSecundaria = FirebaseAuth.instanceFor(
        app: appSecundario,
      );

      // Cadastrar funcionário sem deslogar o gerente
      UserCredential funcionarioCredential = await authSecundaria
          .createUserWithEmailAndPassword(
            email: usuario.email,
            password: usuario.senha,
          );

      String funcionarioId = funcionarioCredential.user!.uid;

      // Desloga da instância secundária e deleta
      await authSecundaria.signOut();
      await appSecundario.delete();

      // Salvar funcionário na subcoleção do gerente
      await _usuariosRef
          .doc(gerenteId)
          .collection('funcionarios')
          .doc(funcionarioId)
          .set({
            'uid': funcionarioId,
            'nome': usuario.nome,
            'email': usuario.email,
            'telefone': usuario.telefone,
            'cargo': usuario.cargo,
            'cpf': usuario.cpf,
            'funcionarioId': funcionarioId,
            'ativo': true,
            'criadoEm': FieldValue.serverTimestamp(),
          });

      return 'Funcionário cadastrado com sucesso';
    } catch (e) {
      return 'Erro ao cadastrar funcionário: ${e.toString()}';
    }
  }

  /// Listagem de funcionários
  Stream<QuerySnapshot> listarFuncionariosAtivos() {
    String? gerenteId = pegarIdUsuarioLogado();

    if (gerenteId == null) {
      throw Exception('Nenhum gerente logado');
    }

    return _usuariosRef
        .doc(gerenteId)
        .collection('funcionarios')
        .where('ativo', isEqualTo: true)
        .snapshots();
  }

  Stream<QuerySnapshot> listarFuncionariosInativos() {
    String? gerenteId = pegarIdUsuarioLogado();

    if (gerenteId == null) {
      throw Exception('Nenhum gerente logado');
    }

    return _usuariosRef
        .doc(gerenteId)
        .collection('funcionarios')
        .where('ativo', isEqualTo: false)
        .snapshots();
  }

  /// Desativar funcionário
  Future<void> desativarFuncionario(String funcionarioId) async {
    String? gerenteId = pegarIdUsuarioLogado();
    if (gerenteId == null) throw Exception('Nenhum gerente logado');

    await _usuariosRef
        .doc(gerenteId)
        .collection('funcionarios')
        .doc(funcionarioId)
        .update({'ativo': false});
  }

  /// editar funcionário
  Future<String> editarFuncionario(Usuario usuario) async {
    String? gerenteId = pegarIdUsuarioLogado();
    if (gerenteId == null) return 'Erro: Nenhum gerente logado';

    try {
      await _usuariosRef
          .doc(gerenteId)
          .collection('funcionarios')
          .doc(usuario.uid)
          .update({
            'nome': usuario.nome,
            'telefone': usuario.telefone,
            'cargo': usuario.cargo,
            'cpf': usuario.cpf,
          });
      return 'Funcionário editado com sucesso';
    } catch (e) {
      return 'Erro ao editar funcionário: ${e.toString()}';
    }
  }
}
