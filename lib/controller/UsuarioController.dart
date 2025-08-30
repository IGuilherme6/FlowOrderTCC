import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:floworder/firebase/UsuarioFirebase.dart';
import '../models/Usuario.dart';

class UsuarioController {
  final UsuarioFirebase _usuarioFirebase = UsuarioFirebase();



  /// Cadastro de Usuario
  Future<String> cadastrarUsuario(Usuario usuario) async {
    try {
      // Verificar se CPF já existe
      if (await _verificarCpfExistente(usuario.cpf)) {
        return 'Erro: CPF já cadastrado';
      }

      // Criar usuário no Firebase Auth

      // Salvar no Firestore
      return await _usuarioFirebase.salvarUsuario(usuario);

    } catch (e) {
      return 'Erro ao cadastrar: ${e.toString()}';
    }
  }

  /// Listagem de funcionários ativos
  Stream<QuerySnapshot> listarFuncionariosAtivos() {
    String? gerenteId = _usuarioFirebase.pegarIdUsuarioLogado();

    if (gerenteId == null) {
      throw Exception('Nenhum Usuario logado');
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

    return await _usuarioFirebase.atualizarStatusFuncionario( funcionarioId, false);
  }

  /// Ativar funcionário
  Future<String> ativarFuncionario(String funcionarioId) async {
    String? gerenteId = _usuarioFirebase.pegarIdUsuarioLogado();
    if (gerenteId == null) throw Exception('Nenhum gerente logado');

    return await _usuarioFirebase.atualizarStatusFuncionario( funcionarioId, true);
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


}