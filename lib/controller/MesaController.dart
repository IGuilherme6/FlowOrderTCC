import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/MesaFirebase.dart';
import '../models/Mesa.dart';

class MesaController {
  final MesaFirebase _mesaFirebase = MesaFirebase();

  /// Cadastrar mesa
  Future<String> cadastrarMesa(Mesa mesa) async {
    try {
     if (await verificarMesaExistente(mesa.numero)) {
        return 'Erro: Mesa já cadastrada';
      }
      String? userId = _mesaFirebase.pegarIdUsuarioLogado();
      if (userId == null) {
        throw Exception('Erro: Nenhum Gerente logado');
      }

      // Aplicar regra de negócio: nome padrão se não informado
      if (mesa.nome == null || mesa.nome!.isEmpty) {
        mesa.nome = "Mesa ${mesa.numero}";
      }

      // Adicionar mesa e capturar o ID
      String mesaId = await _mesaFirebase.adicionarMesa(userId, mesa);
      mesa.uid = mesaId;

      return 'Mesa cadastrada com sucesso';
    } catch (e) {
      throw Exception('Erro ao cadastrar mesa: ${e.toString()}');
    }
  }

  /// Buscar mesas do gerente logado
  Future<List<Mesa>> buscarMesasDoGerente() async {
    String? userId = _mesaFirebase.pegarIdUsuarioLogado();
    if (userId == null) {
      throw Exception('Erro: Nenhum Gerente logado');
    }

    try {
      QuerySnapshot snapshot = await _mesaFirebase.buscarMesas(userId);
      return _mesaFirebase.querySnapshotParaMesas(snapshot);
    } catch (e) {
      throw Exception('Erro ao buscar mesas: ${e.toString()}');
    }
  }

  /// Stream para escutar mudanças em tempo real
  Stream<List<Mesa>> streamMesasDoGerente() {
    String? userId = _mesaFirebase.pegarIdUsuarioLogado();
    if (userId == null) {
      return Stream.empty();
    }

    return _mesaFirebase.streamMesas(userId).map((snapshot) {
      return _mesaFirebase.querySnapshotParaMesas(snapshot);
    });
  }

  /// Deletar mesa usando o UID
  Future<String> deletarMesa(String mesaUid) async {
    String? userId = _mesaFirebase.pegarIdUsuarioLogado();
    if (userId == null) {
      throw Exception('Erro: Nenhum Gerente logado');
    }

    try {
      await _mesaFirebase.deletarMesa(userId, mesaUid);
      return 'Mesa deletada com sucesso';
    } catch (e) {
      throw Exception('Erro ao deletar mesa: ${e.toString()}');
    }
  }

  /// Atualizar mesa usando o UID
  Future<String> atualizarMesa(Mesa mesa) async {
    String? userId = _mesaFirebase.pegarIdUsuarioLogado();
    if (userId == null) {
      throw Exception('Erro: Nenhum Gerente logado');
    }

    if (mesa.uid == null) {
      throw Exception('UID da mesa é necessário para atualizar');
    }

    try {
      await _mesaFirebase.atualizarMesa(userId, mesa);
      return 'Mesa atualizada com sucesso';
    } catch (e) {
      throw Exception('Erro ao atualizar mesa: ${e.toString()}');
    }
  }

  /// Buscar uma mesa específica pelo UID
  Future<Mesa?> buscarMesaPorUid(String mesaUid) async {
    String? userId = _mesaFirebase.pegarIdUsuarioLogado();
    if (userId == null) {
      throw Exception('Erro: Nenhum Gerente logado');
    }

    try {
      DocumentSnapshot doc = await _mesaFirebase.buscarMesaPorUid(userId, mesaUid);

      if (doc.exists) {
        return _mesaFirebase.documentParaMesa(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar mesa: ${e.toString()}');
    }
  }

  Future<bool> verificarMesaExistente(int numero) async {
    String? userId = _mesaFirebase.pegarIdUsuarioLogado();
    if (userId == null) {
      throw Exception('Erro: Nenhum Gerente logado');
    }

    try {
      return await _mesaFirebase.verificarMesaExistente(userId, numero);
    } catch (e) {
      throw Exception('Erro ao verificar mesa existente: ${e.toString()}');
    }
  }
}