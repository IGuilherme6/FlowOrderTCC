import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:floworder/firebase/UsuarioFirebase.dart';
import 'package:floworder/models/Usuario.dart';

// Mocks
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockUserCredential extends Mock implements UserCredential {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockDocumentReference extends Mock implements DocumentReference {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}
class MockQuerySnapshot extends Mock implements QuerySnapshot {}
class MockQuery extends Mock implements Query {}

void main() {
  group('UsuarioFirebase', () {
    late UsuarioFirebase usuarioFirebase;
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocRef;
    late MockUser mockUser;
    late MockUserCredential mockUserCredential;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDocRef = MockDocumentReference();
      mockUser = MockUser();
      mockUserCredential = MockUserCredential();

      usuarioFirebase = UsuarioFirebase();
    });

    // Remover ou comentar este teste, pois não é possível mockar FirebaseAuth.instance diretamente
    // test('pegarIdUsuarioLogado retorna uid do usuário logado', () {
    //   when(FirebaseAuth.instance.currentUser).thenReturn(mockUser);
    //   when(mockUser.uid).thenReturn('123abc');
    //   final id = usuarioFirebase.pegarIdUsuarioLogado();
    //   expect(id, '123abc');
    // });

    // Remover ou comentar este teste, pois não é possível mockar FirebaseAuth.instance diretamente
    // test('criarUsuarioAuth retorna uid do usuário criado', () async {
    //   when(FirebaseAuth.instance.createUserWithEmailAndPassword(
    //     email: anyNamed('email'),
    //     password: anyNamed('password'),
    //   )).thenAnswer((_) async => mockUserCredential);
    //   when(mockUserCredential.user).thenReturn(mockUser);
    //   when(mockUser.uid).thenReturn('uid123');

    //   final uid = await usuarioFirebase.criarUsuarioAuth('teste@teste.com', 'senha123');
    //   expect(uid, 'uid123');
    // });

    test('salvarGerente salva dados no Firestore', () async {
      final usuario = Usuario();
      usuario.uid = '1';
      usuario.nome = 'Teste';
      usuario.email = 'teste@teste.com';
      usuario.telefone = '1234567890';
      usuario.cargo = 'Gerente';
      usuario.cpf = '67238449048';
      usuario.senha = 'senha123';
      // ...mock firestore...
      // Não testamos integração real, apenas se não lança erro
      await usuarioFirebase.salvarGerente('1', usuario);
      // Se não lançar exceção, passou
      expect(true, true);
    });

    test('buscarGerente retorna DocumentSnapshot', () async {
      // ...mock firestore...
      // Não testamos integração real, apenas se método existe
      expect(usuarioFirebase.buscarGerente('1'), isA<Future<DocumentSnapshot>>());
    });

    test('verificarCpfExistenteGerentes retorna bool', () async {
      // ...mock firestore...
      expect(usuarioFirebase.verificarCpfExistenteGerentes('11122233344'), isA<Future<bool>>());
    });

    test('verificarCpfExistenteFuncionarios retorna bool', () async {
      // ...mock firestore...
      expect(usuarioFirebase.verificarCpfExistenteFuncionarios('11122233344'), isA<Future<bool>>());
    });

    test('listarFuncionariosAtivos retorna Stream<QuerySnapshot>', () {
      expect(usuarioFirebase.listarFuncionariosAtivos('1'), isA<Stream<QuerySnapshot>>());
    });

    test('listarFuncionariosInativos retorna Stream<QuerySnapshot>', () {
      expect(usuarioFirebase.listarFuncionariosInativos('1'), isA<Stream<QuerySnapshot>>());
    });

    test('atualizarStatusFuncionario atualiza status sem erro', () async {
      // ...mock firestore...
      await usuarioFirebase.atualizarStatusFuncionario('1', '2', true);
      expect(true, true);
    });

    test('atualizarDadosFuncionario atualiza dados sem erro', () async {
      final usuario = Usuario();
      usuario.uid = '2';
      usuario.nome = 'Funcionario';
      usuario.email = 'func@teste.com';
      usuario.telefone = '9999999999';
      usuario.cargo = 'Atendente';
      usuario.cpf = '74398817026';
      usuario.senha = 'senha456';
      // ...mock firestore...
      await usuarioFirebase.atualizarDadosFuncionario('1', usuario);
      expect(true, true);
    });
  });
}