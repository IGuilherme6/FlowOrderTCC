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
    // Usa a função que você já tem
    String? userId = pegarIdUsuarioLogado();
    if (userId == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Usuarios').doc(userId).get();
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

      final doc = await  FirebaseFirestore.instance
          .collection('Usuarios').doc(Id).get();
      final userData = doc.data() as Map<String, dynamic>?;
      final cargo = userData?['cargo'] as String?;

      if(cargo != 'Gerente') throw Exception('Nenhum Gerente Logado');

      // Normaliza/valida campos mínimos
      final nome = (cardapio.nome ?? '').trim().isEmpty
          ? 'Item sem nome'
          : cardapio.nome!;
      final descricao = (cardapio.descricao ?? '').trim().isEmpty
          ? 'Descrição não informada'
          : cardapio.descricao!;
      final preco = cardapio.preco ?? 0.0;
      final categoria = (cardapio.categoria ?? 'Outros').trim();

      DocumentReference docRef = await _firestore
          .collection('Cardapios')
          .add({
            'nome': nome,
            'descricao': descricao,
            'preco': preco,
            'categoria': categoria,
            'ativo': true,
            'gerenteUid': Id,
            'criadoEm': FieldValue.serverTimestamp(),
          });

      // atualiza campo uid no documento (opcional)
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
          .where('gerenteUid',isEqualTo: gerenteId)
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

      await _firestore
          .collection('Cardapios')
          .doc(cardapio.uid)
          .update({
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

      final doc = await  FirebaseFirestore.instance
          .collection('Usuarios').doc(gerenteId).get();
      final userData = doc.data() as Map<String, dynamic>?;
      final cargo = userData?['cargo'] as String?;

      if(cargo == 'Gerente') {
        await _firestore
            .collection('Cardapios')
            .doc(cardapioId)
            .delete();
      }else throw Exception("Para Excluir deve ser O gerente do estabelecimento");
    } catch (e) {
      throw Exception('Erro ao excluir cardápio:');
    }
  }

  /// Suspende/reativa (atualiza campo 'ativo')
  Future<void> suspenderCardapio(String gerenteId, String cardapioId, bool ativo) async {
    try {
      if (gerenteId.isEmpty) throw Exception('GerenteId inválido');

      await _firestore
          .collection('Cardapios')
          .doc(cardapioId)
          .update({
            'ativo': ativo,
            'atualizadoEm': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Erro ao alterar status do cardápio: ${e.toString()}');
    }
  }

}
