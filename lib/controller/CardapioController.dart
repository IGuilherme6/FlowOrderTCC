import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/CardapioFirebase.dart';
import '../models/Cardapio.dart';

class CardapioController {
  final CardapioFirebase _cardapioFirebase = CardapioFirebase();

  Future<String> cadastrarCardapio(Cardapio cardapio) async {
    try {
      String? userId = _cardapioFirebase.pegarIdUsuarioLogado();
      if (userId == null) {
        throw Exception('Erro: Nenhum Gerente logado');
      }

      if (cardapio.nome.trim().isEmpty ||
          cardapio.descricao.trim().isEmpty ||
          !(cardapio.preco > 0)) {
        throw Exception('Erro: Nome, descrição ou preço inválidos');
      }

      String cardapioId = await _cardapioFirebase.adicionarCardapio(userId, cardapio);
      cardapio.uid = cardapioId;

      return 'Cardápio cadastrado com sucesso';
    } catch (e) {
      throw Exception('Erro ao cadastrar cardápio: ${e.toString()}');
    }
  }

  Future<List<Cardapio>> buscarCardapiosDoGerente() async {
    String? userId = _cardapioFirebase.pegarIdUsuarioLogado();
    if (userId == null) {
      throw Exception('Erro: Nenhum Gerente logado');
    }

    try {
      QuerySnapshot snapshot = await _cardapioFirebase.buscarCardapios(userId);
      return snapshot.docs.map((doc) {
        Cardapio cardapio = Cardapio();
        cardapio.nome = doc['nome'];
        cardapio.descricao = doc['descricao'];
        cardapio.preco = doc['preco'];
        cardapio.uid = doc['uid'];
        cardapio.ativo = doc['ativo'] ?? true;
        return cardapio;
      }).toList();
    } catch (e) {
      throw Exception('Erro ao buscar cardápios: ${e.toString()}');
    }
  }

  Future<void> atualizarCardapio(Cardapio cardapio) async {
    String? userId = _cardapioFirebase.pegarIdUsuarioLogado();
    if (userId == null) throw Exception('Erro: Nenhum Gerente logado');

    await _cardapioFirebase.atualizarCardapio(userId, cardapio);
  }

  Future<void> excluirCardapio(String cardapioId) async {
    String? userId = _cardapioFirebase.pegarIdUsuarioLogado();
    if (userId == null) throw Exception('Erro: Nenhum Gerente logado');

    await _cardapioFirebase.excluirCardapio(userId, cardapioId);
  }

  Future<void> suspenderCardapio(String cardapioId, bool ativo) async {
    String? userId = _cardapioFirebase.pegarIdUsuarioLogado();
    if (userId == null) throw Exception('Erro: Nenhum Gerente logado');

    await _cardapioFirebase.suspenderCardapio(userId, cardapioId, ativo);
  }
}
