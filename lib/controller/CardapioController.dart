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

      // Aplicar regra de negócio: nome padrão se não informado
      if (cardapio.nome.trim().isEmpty ||
          cardapio.descricao.trim().isEmpty ||
          cardapio.preco == null ||
          !(cardapio.preco > 0)) {
        throw Exception('Erro: Nome, descrição ou preço inválidos');
      }


      // Adicionar cardápio e capturar o ID
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
        return cardapio;
      }).toList();
    } catch (e) {
      throw Exception('Erro ao buscar cardápios: ${e.toString()}');
    }
  }


}
