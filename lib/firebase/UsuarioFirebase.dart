import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/Usuario.dart';

class UsuarioFirebase {
  final CollectionReference _usuariosRef = FirebaseFirestore.instance
      .collection('Gerentes');

  /// Pegar ID do usuário logado
  String? pegarIdUsuarioLogado() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  /// Criar usuário no Firebase Auth
  Future<String> criarUsuarioAuth(String email, String senha) async {
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: email,
      password: senha,
    );
    return userCredential.user!.uid;
  }

  /// Criar usuário no Firebase Auth usando instância secundária
  Future<String> criarUsuarioAuthSecundario(String email, String senha) async {
    FirebaseApp appSecundario = await Firebase.initializeApp(
      name: 'appSecundario',
      options: Firebase.app().options,
    );

    FirebaseAuth authSecundaria = FirebaseAuth.instanceFor(
      app: appSecundario,
    );

    UserCredential funcionarioCredential = await authSecundaria
        .createUserWithEmailAndPassword(
      email: email,
      password: senha,
    );

    String funcionarioId = funcionarioCredential.user!.uid;

    // Desloga da instância secundária e deleta
    await authSecundaria.signOut();
    await appSecundario.delete();

    return funcionarioId;
  }

  /// Salvar gerente no Firestore
  Future<void> salvarGerente(String userId, Usuario usuario) async {
    await _usuariosRef.doc(userId).set({
      'uid': userId,
      'nome': usuario.nome,
      'email': usuario.email,
      'telefone': usuario.telefone,
      'cargo': 'Gerente',
      'cpf': usuario.cpf,
      'ativo': true,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Salvar funcionário no Firestore
  Future<void> salvarFuncionario(String gerenteId, String funcionarioId, Usuario usuario) async {
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
      'gerenteUid': gerenteId,
      'ativo': true,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Buscar dados do gerente
  Future<DocumentSnapshot> buscarGerente(String gerenteId) async {
    return await _usuariosRef.doc(gerenteId).get();
  }

  /// Verificar se CPF existe nos gerentes
  Future<bool> verificarCpfExistenteGerentes(String cpf) async {
    final gerentesCpf = await _usuariosRef

        .where('cpf', isEqualTo: cpf)
        .get();
    return gerentesCpf.docs.isNotEmpty;
  }

  /// Verificar se CPF existe nos funcionários
  Future<bool> verificarCpfExistenteFuncionarios(String cpf) async {
    final gerentesSnapshot = await _usuariosRef.get();

    for (var gerenteDoc in gerentesSnapshot.docs) {
      final funcionariosSnapshot = await _usuariosRef
          .doc(gerenteDoc.id)
          .collection('funcionarios')

          .where('cpf', isEqualTo: cpf)
          .get();

      if (funcionariosSnapshot.docs.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  /// Listar funcionários ativos
  Stream<QuerySnapshot> listarFuncionariosAtivos(String gerenteId) {
    return _usuariosRef
        .doc(gerenteId)
        .collection('funcionarios')
        .where('ativo', isEqualTo: true)
        .snapshots();
  }

  /// Listar funcionários inativos
  Stream<QuerySnapshot> listarFuncionariosInativos(String gerenteId) {
    return _usuariosRef
        .doc(gerenteId)
        .collection('funcionarios')
        .where('ativo', isEqualTo: false)
        .snapshots();

  }

  /// Atualizar status do funcionário
  Future<void> atualizarStatusFuncionario(String gerenteId, String funcionarioId, bool ativo) async {
    await _usuariosRef
        .doc(gerenteId)
        .collection('funcionarios')
        .doc(funcionarioId)
        .update({'ativo': ativo});
  }

  /// Atualizar dados do funcionário
  Future<void> atualizarDadosFuncionario(String gerenteId, Usuario usuario) async {
    await _usuariosRef
        .doc(gerenteId)
        .collection('funcionarios')
        .doc(usuario.uid)
        .update({
      'nome': usuario.nome,
      'telefone': usuario.telefone,
      'cargo': usuario.cargo,
      'cpf': usuario.cpf,
      'gerenteUid': gerenteId,
    });
  }

  Future<void> apagarFuncionario(String gerenteId,String id) async{
    await _usuariosRef
        .doc(gerenteId)
        .collection('funcionarios')
        .doc(id)
        .delete();

  }
}