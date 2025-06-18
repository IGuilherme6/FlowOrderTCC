import 'Pedido.dart';

class Mesa {
  late int _numero;
  late List<Pedido> _itens;
  List<String> _Status = ['Abertod', 'Em Preparo'];

  int get numero => _numero;

  set numero(int value) {
    _numero = value;
  }

  List<Pedido> get itens => _itens;

  set itens(List<Pedido> value) {
    _itens = value;
  }

  List<String> get Status => _Status;

  set Status(List<String> value) {
    _Status = value;
  }

  void AdicionarMesa(){

  }

  void gerenciarMesa(){

  }

}
