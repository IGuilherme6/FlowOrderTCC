import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/Usuario.dart';

class UsuarioFirebase {
  final CollectionReference _usuariosRef = FirebaseFirestore.instance
      .collection('Usuarios');

  /// Pegar ID do usuário logado
  String? pegarIdUsuarioLogado() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  /// Criar usuário no Firebase Auth
  Future<String> criarUsuarioAuth(String email, String senha) async {
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: senha);
    return userCredential.user!.uid;
  }

  /// Criar usuário no Firebase Auth usando instância secundária
  Future<String> criarUsuarioAuthSecundario(String email, String senha) async {
    FirebaseApp appSecundario = await Firebase.initializeApp(
      name: 'appSecundario',
      options: Firebase.app().options,
    );

    FirebaseAuth authSecundaria = FirebaseAuth.instanceFor(app: appSecundario);

    UserCredential funcionarioCredential = await authSecundaria
        .createUserWithEmailAndPassword(email: email, password: senha);

    String funcionarioId = funcionarioCredential.user!.uid;

    // Desloga da instância secundária e deleta
    await authSecundaria.signOut();
    await appSecundario.delete();

    return funcionarioId;
  }

  /// Salvar Usuario no Firebase
  Future<String> salvarUsuario(Usuario usuario) async {
    try {
      String? id = pegarIdUsuarioLogado();
      final doc = await _usuariosRef.doc(id).get();
      final userData = doc.data() as Map<String, dynamic>?;
      final cargo = userData?['cargo'] as String?;

      if (doc.exists && cargo != 'Gerente') {
        throw Exception(
          'Acesso negado: Apenas gerentes podem cadastrar funcionários',
        );
      }

      if (doc.exists && cargo == 'Gerente') {
        String userId = await criarUsuarioAuthSecundario(
          usuario.email,
          usuario.senha,
        );
        await _usuariosRef.doc(userId).set({
          'uid': userId,
          'nome': usuario.nome,
          'email': usuario.email,
          'telefone': usuario.telefone,
          'cargo': usuario.cargo,
          'cpf': usuario.cpf,
          'gerenteUid': id,
          'ativo': true,
          'criadoEm': FieldValue.serverTimestamp(),
        });
      } else {
        String userId = await criarUsuarioAuthSecundario(
          usuario.email,
          usuario.senha,
        );
        await _usuariosRef.doc(userId).set({
          'uid': userId,
          'nome': usuario.nome,
          'email': usuario.email,
          'telefone': usuario.telefone,
          'cargo': usuario.cargo,
          'cpf': usuario.cpf,
          'gerenteUid': userId,
          'ativo': true,
          'criadoEm': FieldValue.serverTimestamp(),
        });
        return 'Conta Criada com sucesso, acesse a tela de login';
      }
      return 'Conta Criada com sucesso';
    } catch (e) {
      throw Exception(e);
    }
  }

  /// Buscar dados do gerente
  Future<DocumentSnapshot> buscarGerente(String gerenteId) async {
    return await _usuariosRef.doc(gerenteId).get();
  }

  /// Verificar se CPF existe nos gerentes
  Future<bool> verificarCpfExistenteGerentes(String cpf) async {
    final gerentesCpf = await _usuariosRef.where('cpf', isEqualTo: cpf).get();
    return gerentesCpf.docs.isNotEmpty;
  }

  /// Listar funcionários ativos
  Stream<QuerySnapshot> listarFuncionariosAtivos(String gerenteId) {
    return _usuariosRef
        .where('ativo', isEqualTo: true)
        .where('gerenteUid', isEqualTo: gerenteId)
        .where('cargo', isNotEqualTo: "Gerente")
        .snapshots();
  }

  /// Listar funcionários inativos
  Stream<QuerySnapshot> listarFuncionariosInativos(String gerenteId) {
    return _usuariosRef
        .where('ativo', isEqualTo: false)
        .where('gerenteUid', isEqualTo: gerenteId)
        .where('cargo', isNotEqualTo: "Gerente")
        .snapshots();
  }

  /// Atualizar status do funcionário
  Future<String> atualizarStatusFuncionario(
    String funcionarioId,
    bool status,
  ) async {
    try {
      await _usuariosRef.doc(funcionarioId).update({'ativo': status});

      return "Ativar o usuário ocorreu com êxito";
    } catch (e) {
      return "Erro ao ativar o usuário: $e";
    }
  }

  /// Atualizar dados do funcionário
  Future<void> atualizarDadosFuncionario(
    String gerenteId,
    Usuario usuario,
  ) async {
    await _usuariosRef.doc(usuario.uid).update({
      'nome': usuario.nome,
      'telefone': usuario.telefone,
      'cargo': usuario.cargo,
      'cpf': usuario.cpf,
      'gerenteUid': gerenteId,
    });
  }

  Future<void> apagarFuncionario(String gerenteId, String id) async {
    await _usuariosRef.doc(id).delete();
  }
}
