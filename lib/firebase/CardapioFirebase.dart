import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/Cardapio.dart';

class CardapioFirebase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Retorna o uid do usuário logado
  String? pegarIdUsuarioLogado() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  Future<String?> verificarGerenteUid() async {
    String? userId = pegarIdUsuarioLogado();
    if (userId == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(userId)
          .get();
      final userData = doc.data() as Map<String, dynamic>?;
      final gerenteUid = userData?['gerenteUid'] as String?;
      return gerenteUid;
    } catch (e) {
      print('Erro ao verificar gerenteUid: $e');
      return null;
    }
  }

  /// Adiciona um cardápio e retorna o id gerado
  Future<String> adicionarCardapio(String Id, Cardapio cardapio) async {
    try {
      if (Id.isEmpty) throw Exception('inválido');

      final doc = await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(Id)
          .get();
      final userData = doc.data() as Map<String, dynamic>?;
      final cargo = userData?['cargo'] as String?;

      if (cargo != 'Gerente') throw Exception('Nenhum Gerente Logado');

      final nome = (cardapio.nome ?? '').trim().isEmpty ? 'Item sem nome' : cardapio.nome!;
      final descricao = (cardapio.descricao ?? '').trim().isEmpty ? 'Descrição não informada' : cardapio.descricao!;
      final preco = cardapio.preco ?? 0.0;
      final categoria = (cardapio.categoria ?? 'Outros').trim();

      DocumentReference docRef = await _firestore.collection('Cardapios').add({
        'nome': nome,
        'descricao': descricao,
        'preco': preco,
        'categoria': categoria,
        'ativo': true,
        'gerenteUid': Id,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      await docRef.update({'uid': docRef.id});
      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao adicionar cardápio: ${e.toString()}');
    }
  }

  /// Busca uma vez os cardápios (sem orderBy para evitar necessidade de índice)
  Future<QuerySnapshot> buscarCardapios(String gerenteId) async {
    try {
      if (gerenteId.isEmpty) throw Exception('GerenteId inválido');
      return await _firestore
          .collection('Cardapios')
          .where('gerenteUid', isEqualTo: gerenteId)
          .get();
    } catch (e) {
      throw Exception('Erro ao buscar cardápios: ${e.toString()}');
    }
  }

  /// Stream em tempo real (snapshots) — sem orderBy para evitar índice composto
  Stream<QuerySnapshot> streamCardapios(String gerenteId) {
    try {
      if (gerenteId.isEmpty) return const Stream.empty();
      return _firestore
          .collection('Cardapios')
          .where('gerenteUid', isEqualTo: gerenteId)
          .snapshots();
    } catch (e) {
      return const Stream.empty();
    }
  }

  /// Converte QuerySnapshot -> List<Cardapio> e ordena localmente por categoria -> nome
  List<Cardapio> querySnapshotParaCardapios(QuerySnapshot snapshot) {
    final lista = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return Cardapio.fromMap(doc.id, data);
    }).toList();

    lista.sort((a, b) {
      final catA = (a.categoria ?? '').toLowerCase();
      final catB = (b.categoria ?? '').toLowerCase();
      final cmpCat = catA.compareTo(catB);
      if (cmpCat != 0) return cmpCat;
      final nomeA = (a.nome ?? '').toLowerCase();
      final nomeB = (b.nome ?? '').toLowerCase();
      return nomeA.compareTo(nomeB);
    });

    return lista;
  }

  /// Converte um DocumentSnapshot para Cardapio (opcionalmente usado pelo controller)
  Cardapio documentParaCardapio(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Cardapio.fromMap(doc.id, data);
  }

  /// Atualiza um cardápio (valida uid)
  Future<void> atualizarCardapio(String gerenteId, Cardapio cardapio) async {
    try {
      if (gerenteId.isEmpty) throw Exception('GerenteId inválido');
      if (cardapio.uid == null || cardapio.uid!.trim().isEmpty) {
        throw Exception('UID do cardápio é necessário para atualizar');
      }

      await _firestore.collection('Cardapios').doc(cardapio.uid).update({
        'nome': cardapio.nome,
        'descricao': cardapio.descricao,
        'preco': cardapio.preco,
        'categoria': cardapio.categoria,
        'ativo': cardapio.ativo,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erro ao atualizar cardápio: ${e.toString()}');
    }
  }

  /// Exclui um cardápio (valida uid)
  Future<void> excluirCardapio(String gerenteId, String cardapioId) async {
    try {
      if (gerenteId.isEmpty) throw Exception('GerenteId inválido');

      final doc = await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(gerenteId)
          .get();
      final userData = doc.data() as Map<String, dynamic>?;
      final cargo = userData?['cargo'] as String?;

      if (cargo == 'Gerente') {
        await _firestore.collection('Cardapios').doc(cardapioId).delete();
      } else
        throw Exception("Para Excluir deve ser O gerente do estabelecimento");
    } catch (e) {
      throw Exception('Erro ao excluir cardápio: ${e.toString()}');
    }
  }

  /// Suspende/reativa (atualiza campo 'ativo')
  Future<void> suspenderCardapio(
      String gerenteId,
      String cardapioId,
      bool ativo,
      ) async {
    try {
      if (gerenteId.isEmpty) throw Exception('GerenteId inválido');

      await _firestore.collection('Cardapios').doc(cardapioId).update({
        'ativo': ativo,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erro ao alterar status do cardápio: ${e.toString()}');
    }
  }

  // --- Novos métodos para Gerenciamento de Categorias ---

  /// Adiciona uma nova categoria e retorna o id gerado
  Future<String> adicionarCategoria(String gerenteId, String nomeCategoria) async {
    try {
      // Validação simples: não permitir nomes vazios ou apenas espaços
      if (nomeCategoria.trim().isEmpty) {
        throw Exception("O nome da categoria não pode estar vazio.");
      }
      DocumentReference docRef = await _firestore.collection('Categorias').add({
        'nome': nomeCategoria.trim(), // Salva o nome limpo
        'gerenteUid': gerenteId,
        'criadoEm': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao adicionar categoria: ${e.toString()}');
    }
  }

  /// Busca as categorias de um gerente em tempo real
  Stream<QuerySnapshot> streamCategorias(String gerenteId) {
    try {
      if (gerenteId.isEmpty) return const Stream.empty();
      return _firestore
          .collection('Categorias')
          .where('gerenteUid', isEqualTo: gerenteId)
          .snapshots();
    } catch (e) {
      print('Erro ao buscar stream de categorias: $e');
      return const Stream.empty();
    }
  }

  // Adicione essas funções à sua classe CardapioFirebase

  /// Verifica se uma categoria está sendo usada em algum produto
  Future<bool> categoriaEstaEmUso(String gerenteId, String nomeCategoria) async {
    try {
      if (gerenteId.isEmpty || nomeCategoria.trim().isEmpty) return false;

      final querySnapshot = await _firestore
          .collection('Cardapios')
          .where('gerenteUid', isEqualTo: gerenteId)
          .where('categoria', isEqualTo: nomeCategoria.trim())
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar se categoria está em uso: $e');
      return false;
    }
  }

  /// Conta quantos produtos usam uma categoria específica
  Future<int> contarProdutosPorCategoria(String gerenteId, String nomeCategoria) async {
    try {
      if (gerenteId.isEmpty || nomeCategoria.trim().isEmpty) return 0;

      final querySnapshot = await _firestore
          .collection('Cardapios')
          .where('gerenteUid', isEqualTo: gerenteId)
          .where('categoria', isEqualTo: nomeCategoria.trim())
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Erro ao contar produtos por categoria: $e');
      return 0;
    }
  }

  /// Atualiza o nome da categoria em todos os produtos que a utilizam
  Future<void> atualizarCategoriaEmProdutos(
      String gerenteId,
      String categoriaAntigaNome,
      String categoriaNovaNome
      ) async {
    try {
      if (gerenteId.isEmpty) throw Exception('GerenteId inválido');
      if (categoriaAntigaNome.trim().isEmpty || categoriaNovaNome.trim().isEmpty) {
        throw Exception('Nomes das categorias não podem estar vazios');
      }

      // Busca todos os produtos com a categoria antiga
      final querySnapshot = await _firestore
          .collection('Cardapios')
          .where('gerenteUid', isEqualTo: gerenteId)
          .where('categoria', isEqualTo: categoriaAntigaNome.trim())
          .get();

      // Cria um batch para atualizar todos os produtos de uma vez
      WriteBatch batch = _firestore.batch();

      for (DocumentSnapshot doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'categoria': categoriaNovaNome.trim(),
          'atualizadoEm': FieldValue.serverTimestamp(),
        });
      }

      // Executa todas as atualizações
      await batch.commit();

      print('Categoria atualizada em ${querySnapshot.docs.length} produtos');
    } catch (e) {
      throw Exception('Erro ao atualizar categoria em produtos: ${e.toString()}');
    }
  }

  /// Move todos os produtos de uma categoria para "Outros" antes de excluir a categoria
  Future<void> moverProdutosParaOutros(String gerenteId, String categoriaNome) async {
    try {
      if (gerenteId.isEmpty) throw Exception('GerenteId inválido');
      if (categoriaNome.trim().isEmpty) return;

      // Busca todos os produtos com a categoria a ser excluída
      final querySnapshot = await _firestore
          .collection('Cardapios')
          .where('gerenteUid', isEqualTo: gerenteId)
          .where('categoria', isEqualTo: categoriaNome.trim())
          .get();

      if (querySnapshot.docs.isEmpty) return;

      // Cria um batch para atualizar todos os produtos de uma vez
      WriteBatch batch = _firestore.batch();

      for (DocumentSnapshot doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'categoria': 'Outros',
          'atualizadoEm': FieldValue.serverTimestamp(),
        });
      }

      // Executa todas as atualizações
      await batch.commit();

      print('${querySnapshot.docs.length} produtos movidos para categoria "Outros"');
    } catch (e) {
      throw Exception('Erro ao mover produtos para categoria "Outros": ${e.toString()}');
    }
  }

  /// Versão aprimorada da função de atualizar categoria que sincroniza com produtos
  Future<void> atualizarCategoriaComSincronizacao(
      String gerenteId,
      String categoriaId,
      String categoriaAntigaNome,
      String novoNome
      ) async {
    try {
      if (gerenteId.isEmpty) throw Exception('GerenteId inválido');
      if (novoNome.trim().isEmpty) {
        throw Exception("O nome da categoria não pode estar vazio.");
      }

      // Primeiro, atualiza a categoria
      await _firestore.collection('Categorias').doc(categoriaId).update({
        'nome': novoNome.trim(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      // Depois, atualiza todos os produtos que usam essa categoria
      await atualizarCategoriaEmProdutos(gerenteId, categoriaAntigaNome, novoNome.trim());

    } catch (e) {
      throw Exception('Erro ao atualizar categoria com sincronização: ${e.toString()}');
    }
  }

  /// Versão aprimorada da função de deletar categoria que move produtos para "Outros"
  Future<void> deletarCategoriaComSincronizacao(
      String gerenteId,
      String categoriaId,
      String categoriaNome
      ) async {
    try {
      if (gerenteId.isEmpty) throw Exception('GerenteId inválido');

      // Primeiro, move todos os produtos para "Outros"
      await moverProdutosParaOutros(gerenteId, categoriaNome);

      // Depois, deleta a categoria
      await _firestore.collection('Categorias').doc(categoriaId).delete();

    } catch (e) {
      throw Exception('Erro ao deletar categoria com sincronização: ${e.toString()}');
    }
  }

// SUBSTITUA suas funções originais por estas versões:

  /// Atualiza o nome de uma categoria (VERSÃO COM SINCRONIZAÇÃO)
  @override
  Future<void> atualizarCategoria(String categoriaId, String novoNome) async {
    try {
      String? userId = pegarIdUsuarioLogado();
      String? gerenteId = await verificarGerenteUid();

      if (gerenteId == null) {
        throw Exception('Gerente não encontrado');
      }

      // Busca o nome atual da categoria antes de atualizar
      final categoriaDoc = await _firestore.collection('Categorias').doc(categoriaId).get();
      final categoriaData = categoriaDoc.data() as Map<String, dynamic>?;
      final nomeAntigo = categoriaData?['nome'] as String? ?? '';

      // Usa a função com sincronização
      await atualizarCategoriaComSincronizacao(gerenteId, categoriaId, nomeAntigo, novoNome);
    } catch (e) {
      throw Exception('Erro ao atualizar categoria: ${e.toString()}');
    }
  }

  /// Deleta uma categoria (VERSÃO COM SINCRONIZAÇÃO)
  @override
  Future<void> deletarCategoria(String categoriaId) async {
    try {
      String? userId = pegarIdUsuarioLogado();
      String? gerenteId = await verificarGerenteUid();

      if (gerenteId == null) {
        throw Exception('Gerente não encontrado');
      }

      // Busca o nome da categoria antes de deletar
      final categoriaDoc = await _firestore.collection('Categorias').doc(categoriaId).get();
      final categoriaData = categoriaDoc.data() as Map<String, dynamic>?;
      final nomeCategoria = categoriaData?['nome'] as String? ?? '';

      // Usa a função com sincronização (sem criar categoria "Outros")
      await deletarCategoriaComSincronizacao(gerenteId, categoriaId, nomeCategoria);
    } catch (e) {
      throw Exception('Erro ao deletar categoria: ${e.toString()}');
    }
  }


}