import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/CardapioFirebase.dart';
import '../models/Cardapio.dart';
import '../models/Categoria.dart'; // Importe o novo modelo

class CardapioController {
  final CardapioFirebase _cardapioFirebase = CardapioFirebase();

  /// Cadastrar cardápio
  Future<String> cadastrarCardapio(Cardapio cardapio) async {
    try {
      if (cardapio.nome.isEmpty) {
        return 'Erro: Nome do cardápio não pode estar vazio';
      }

      String? userId = await _cardapioFirebase.pegarIdUsuarioLogado();
      if (userId == null) {
        throw Exception('Erro: Nenhum Gerente logado');
      }

      String cardapioId = await _cardapioFirebase.adicionarCardapio(
        userId,
        cardapio,
      );
      cardapio.uid = cardapioId;

      return 'Cardápio cadastrado com sucesso';
    } catch (e) {
      throw Exception('Erro ao cadastrar cardápio: ${e.toString()}');
    }
  }

  /// Buscar cardápios do gerente logado (snapshot único)
  Future<List<Cardapio>> buscarCardapios() async {
    String? userId = await _cardapioFirebase.verificarGerenteUid();
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
  Future<Stream<List<Cardapio>>> buscarCardapioTempoReal() async {
    String? userId = await _cardapioFirebase.verificarGerenteUid();
    if (userId == null) {
      return Stream.value([]);
    }

    return _cardapioFirebase.streamCardapios(userId).map((snapshot) {
      return _cardapioFirebase.querySnapshotParaCardapios(snapshot); // Usa a função de conversão e ordenação
    });
  }

  /// Atualizar cardápio
  Future<String> atualizarCardapio(Cardapio cardapio) async {
    String? userId = await _cardapioFirebase.verificarGerenteUid();
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
    String? userId = await _cardapioFirebase.pegarIdUsuarioLogado();
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
    String? userId = await _cardapioFirebase.verificarGerenteUid();
    if (userId == null) {
      throw Exception('Erro: Nenhum Gerente logado');
    }

    try {
      await _cardapioFirebase.suspenderCardapio(userId, cardapioUid, suspender); // Corrigido: 'suspender' deve ser o novo estado (ativo ou inativo)
      return suspender
          ? 'Cardápio suspenso com sucesso'
          : 'Cardápio reativado com sucesso';
    } catch (e) {
      throw Exception('Erro ao alterar status do cardápio: ${e.toString()}');
    }
  }

  // --- Novos métodos para Categorias ---

  /// Stream de categorias do gerente (tempo real), combinando com as categorias padrão.
  Future<Stream<List<String>>> buscarCategoriasTempoReal() async {
    String? userId = await _cardapioFirebase.verificarGerenteUid();
    if (userId == null) {
      return Stream.value(['Todos', 'Bebida', 'Prato', 'Lanche', 'Outros']); // Retorna apenas as padrão
    }

    // Combina as categorias padrão com as do Firebase.
    return _cardapioFirebase.streamCategorias(userId).map((snapshot) {
      final categoriasDoGerente = snapshot.docs.map((doc) {
        return Categoria.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      final listaNomes = categoriasDoGerente.map((c) => c.nome).toList();

      final categoriasPadrao = ['Todos', 'Bebida', 'Prato', 'Lanche', 'Outros'];
      // Usa um Set para garantir que não haja duplicatas e depois converte de volta para lista.
      final todasCategorias = <String>{...categoriasPadrao, ...listaNomes}.toList();
      return todasCategorias;
    });
  }

  /// Adiciona uma nova categoria.
  Future<void> adicionarCategoria(String nome) async {
    String? userId = await _cardapioFirebase.pegarIdUsuarioLogado();
    if (userId == null) {
      throw Exception('Erro: Nenhum Gerente logado');
    }
    await _cardapioFirebase.adicionarCategoria(userId, nome);
  }

  /// Atualiza uma categoria.
  Future<void> atualizarCategoria(String categoriaUid, String novoNome) async {
    await _cardapioFirebase.atualizarCategoria(categoriaUid, novoNome);
  }

  /// Deleta uma categoria.
  Future<void> deletarCategoria(String categoriaUid) async {
    await _cardapioFirebase.deletarCategoria(categoriaUid);
  }

  // Método para buscar as categorias do Firebase (sem as padrão) para o gerenciamento.
  Future<Stream<List<Categoria>>> buscarCategoriasGerenciamento() async {
    String? userId = await _cardapioFirebase.verificarGerenteUid();
    if (userId == null) {
      return Stream.value([]);
    }
    return _cardapioFirebase.streamCategorias(userId).map((snapshot) {
      return snapshot.docs.map((doc) {
        return Categoria.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}