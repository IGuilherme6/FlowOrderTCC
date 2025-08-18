import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:floworder/firebase/UsuarioFirebase.dart';
import '../models/Usuario.dart';

class UsuarioController {
  final UsuarioFirebase _usuarioFirebase = UsuarioFirebase();

  /// Cadastro de gerente
  Future<String> cadastrarGerente(Usuario usuario) async {
    try {
      // Verificar se CPF já existe
      if (await _verificarCpfExistente(usuario.cpf)) {
        return 'Erro: CPF já cadastrado';
      }

      // Criar usuário no Firebase Auth
      String userId = await _usuarioFirebase.criarUsuarioAuth(
        usuario.email,
        usuario.senha,
      );
      // Salvar gerente no Firestore
      await _usuarioFirebase.salvarGerente(userId, usuario);

      return 'Gerente cadastrado com sucesso';
    } catch (e) {
      return 'Erro ao cadastrar: ${e.toString()}';
    }
  }

  /// Cadastro de funcionário
  Future<String> cadastrarFuncionario(Usuario usuario) async {
    try {
      // Verificar se CPF já existe
      if (await _verificarCpfExistente(usuario.cpf)) {
        return 'Erro: CPF já cadastrado';
      }

      // Verificar se há gerente logado
      String? gerenteId = _usuarioFirebase.pegarIdUsuarioLogado();
      if (gerenteId == null) return 'Erro: Nenhum gerente logado';

      // Verificar se é gerente
      if (!await _validarGerente(gerenteId)) {
        return 'Erro: Apenas gerentes podem cadastrar funcionários';
      }

      // Criar funcionário no Firebase Auth usando instância secundária
      String funcionarioId = await _usuarioFirebase.criarUsuarioAuthSecundario(
        usuario.email,
        usuario.senha,
      );

      // Salvar funcionário no Firestore
      await _usuarioFirebase.salvarFuncionario(gerenteId, funcionarioId, usuario);

      return 'Funcionário cadastrado com sucesso';
    } catch (e) {
      return 'Erro ao cadastrar funcionário: ${e.toString()}';
    }
  }

  /// Listagem de funcionários ativos
  Stream<QuerySnapshot> listarFuncionariosAtivos() {
    String? gerenteId = _usuarioFirebase.pegarIdUsuarioLogado();

    if (gerenteId == null) {
      throw Exception('Nenhum gerente logado');
    }

    return _usuarioFirebase.listarFuncionariosAtivos(gerenteId);
  }

  /// Listagem de funcionários inativos
  Stream<QuerySnapshot> listarFuncionariosInativos() {
    String? gerenteId = _usuarioFirebase.pegarIdUsuarioLogado();

    if (gerenteId == null) {
      throw Exception('Nenhum gerente logado');
    }

    return _usuarioFirebase.listarFuncionariosInativos(gerenteId);
  }

  /// Desativar funcionário
  Future<String> desativarFuncionario(String funcionarioId) async {
    String? gerenteId = _usuarioFirebase.pegarIdUsuarioLogado();
    if (gerenteId == null) throw Exception('Nenhum gerente logado');

    return await _usuarioFirebase.atualizarStatusFuncionario(gerenteId, funcionarioId, false);
  }

  /// Ativar funcionário
  Future<String> ativarFuncionario(String funcionarioId) async {
    String? gerenteId = _usuarioFirebase.pegarIdUsuarioLogado();
    if (gerenteId == null) throw Exception('Nenhum gerente logado');

    return await _usuarioFirebase.atualizarStatusFuncionario(gerenteId, funcionarioId, true);
  }

  /// Editar funcionário
  Future<String> editarFuncionario(Usuario usuario) async {
    String? gerenteId = _usuarioFirebase.pegarIdUsuarioLogado();
    if (gerenteId == null) return 'Erro: Nenhum gerente logado';

    try {
      await _usuarioFirebase.atualizarDadosFuncionario(gerenteId, usuario);
      return 'Funcionário editado com sucesso';
    } catch (e) {
      return 'Erro ao editar funcionário: ${e.toString()}';
    }
  }

  /// Verificar se CPF já existe
  Future<bool> _verificarCpfExistente(String cpf) async {
    try {
      // Verificar nos gerentes
      if (await _usuarioFirebase.verificarCpfExistenteGerentes(cpf)) {
        return true;
      }

      // Verificar nos funcionários
      if (await _usuarioFirebase.verificarCpfExistenteFuncionarios(cpf)) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String> deletarFuncionario(String id) async{
    String? gerenteId = _usuarioFirebase.pegarIdUsuarioLogado();
    if (gerenteId == null) return 'Erro: Nenhum gerente logado';

    try{
      await _usuarioFirebase.apagarFuncionario(gerenteId, id);
      return 'Funcioanrio foi apagado com sucesso';
    }catch (e){
      return 'erro ao deletar';
    }

  }

  /// Validar se o usuário é gerente
  Future<bool> _validarGerente(String gerenteId) async {
    try {
      DocumentSnapshot gerenteDoc = await _usuarioFirebase.buscarGerente(gerenteId);

      if (!gerenteDoc.exists) return false;

      Map<String, dynamic> dadosGerente = gerenteDoc.data() as Map<String, dynamic>;
      return dadosGerente['cargo'] == 'Gerente';
    } catch (e) {
      print('Erro ao validar gerente: $e');
      return false;
    }
  }


}