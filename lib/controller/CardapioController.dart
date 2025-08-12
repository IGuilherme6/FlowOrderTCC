import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/CardapioFirebase.dart';
import '../models/Cardapio.dart';

class CardapioController {
  final CardapioFirebase _cardapioFirebase = CardapioFirebase();

  /// Cadastrar cardápio
  Future<String> cadastrarCardapio(Cardapio cardapio) async {
    try {
      if (cardapio.nome.isEmpty) {
        return 'Erro: Nome do cardápio não pode estar vazio';
      }


      String? userId = _cardapioFirebase.pegarIdUsuarioLogado();
      if (userId == null) {
        throw Exception('Erro: Nenhum Gerente logado');
      }

      String cardapioId = await _cardapioFirebase.adicionarCardapio(userId, cardapio);
      cardapio.uid = cardapioId;

      return 'Cardápio cadastrado com sucesso';
    } catch (e) {
      throw Exception('Erro ao cadastrar cardápio: ${e.toString()}');
    }
  }

  /// Buscar cardápios do gerente logado (snapshot único)
  Future<List<Cardapio>> buscarCardapios() async {
    String? userId = _cardapioFirebase.pegarIdUsuarioLogado();
    if (userId == null) {
      throw Exception('Erro: Nenhum Gerente logado');
    }

    try {
      QuerySnapshot snapshot = await _cardapioFirebase.buscarCardapios(userId);

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Cardapio.fromMap(doc.id, data);
      }).toList();
    } catch (e) {
      throw Exception('Erro ao buscar cardápios: ${e.toString()}');
    }
  }

  /// Stream de cardápios do gerente (tempo real)
  Stream<List<Cardapio>> buscarCardapioTempoReal() {
    String? userId = _cardapioFirebase.pegarIdUsuarioLogado();
    if (userId == null) {
      return Stream.value([]);
    }

    return _cardapioFirebase.streamCardapios(userId).map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Cardapio.fromMap(doc.id, data);
      }).toList();
    });
  }



  /// Atualizar cardápio
  Future<String> atualizarCardapio(Cardapio cardapio) async {
    String? userId = _cardapioFirebase.pegarIdUsuarioLogado();
    if (userId == null) {
      throw Exception('Erro: Nenhum Gerente logado');
    }

    if (cardapio.uid == null || cardapio.uid!.isEmpty) {
      throw Exception('UID do cardápio é necessário para atualizar');
    }

    try {
      await _cardapioFirebase.atualizarCardapio(userId, cardapio);
      return 'Cardápio atualizado com sucesso';
    } catch (e) {
      throw Exception('Erro ao atualizar cardápio: ${e.toString()}');
    }
  }

  /// Deletar cardápio
  Future<String> deletarCardapio(String cardapioUid) async {
    String? userId = _cardapioFirebase.pegarIdUsuarioLogado();
    if (userId == null) {
      throw Exception('Erro: Nenhum Gerente logado');
    }

    try {
      await _cardapioFirebase.excluirCardapio(userId, cardapioUid);
      return 'Cardápio deletado com sucesso';
    } catch (e) {
      throw Exception('Erro ao deletar cardápio: ${e.toString()}');
    }
  }

  /// Suspender ou reativar cardápio
  Future<String> suspenderCardapio(String cardapioUid, bool suspender) async {
    String? userId = _cardapioFirebase.pegarIdUsuarioLogado();
    if (userId == null) {
      throw Exception('Erro: Nenhum Gerente logado');
    }

    try {
      await _cardapioFirebase.suspenderCardapio(userId, cardapioUid, suspender);
      return suspender
          ? 'Cardápio suspenso com sucesso'
          : 'Cardápio reativado com sucesso';
    } catch (e) {
      throw Exception('Erro ao alterar status do cardápio: ${e.toString()}');
    }
  }

}
