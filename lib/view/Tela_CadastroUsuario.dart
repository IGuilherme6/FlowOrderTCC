import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:floworder/controller/UsuarioController.dart';
import 'package:floworder/models/Usuario.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../auxiliar/Cores.dart';
import '../auxiliar/Formatar.dart';
import '../auxiliar/Validador.dart';
import 'BarraLateral.dart';

class TelaCadastroUsuario extends StatefulWidget {
  @override
  State<TelaCadastroUsuario> createState() => _TelaCadastroUsuarioState();
}

class _TelaCadastroUsuarioState extends State<TelaCadastroUsuario> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cpfController = TextEditingController();
  String? _uidController = null;

  final Validador _validador = Validador();
  UsuarioController usuarioController = UsuarioController();
  late bool _editarFuncionario = false;
  late bool _tipoLista = true;

  String? _selectedCargo;
  bool _isPasswordVisible = false;

  List<String> _cargos = ['Garçom', 'Atendente', 'Cozinheiro'];

  Future<void> _cadastrarFuncionario(funcionario) async {
    String mensagem = await usuarioController.cadastrarFuncionario(funcionario);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(await mensagem), backgroundColor: Colors.blue),
    );
  }

  Future<void> _EdiatarFuncionario(funcionario) async {
    String mensagem = await usuarioController.editarFuncionario(funcionario);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(await mensagem), backgroundColor: Colors.blue),
    );
  }
  Future<void> _ExcluirFuncionario(String idFuncionario) async{
    String mensagem = await usuarioController.deletarFuncionario(idFuncionario);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(await mensagem), backgroundColor: Colors.blue),
    );
  }

  Future<void> _ativarFuncionario(String id) async{
    String mensagem = await usuarioController.ativarFuncionario(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(await mensagem), backgroundColor: Colors.blue),
    );
  }

  Future<void> _desativarFuncionario(String id) async{
    String mensagem = await usuarioController.desativarFuncionario(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(await mensagem), backgroundColor: Colors.blue),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1000;

    return Scaffold(
      backgroundColor: Cores.backgroundBlack,
      body: Row(
        children: [
          Barralateral(currentRoute: '/funcionarios'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestão de Funcionários',
                    style: TextStyle(
                      color: Cores.textWhite,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),

                  // Layout principal
                  isWideScreen
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildListagemUsuarios()),
                            SizedBox(width: 24),
                            Expanded(child: _buildFormCard()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildListagemUsuarios(),
                            SizedBox(height: 24),
                            _buildFormCard(),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Listagem
  Widget _buildListagemUsuarios() {
    return Container(
      constraints: BoxConstraints(minHeight: 400, maxHeight: 500),
      decoration: BoxDecoration(
        color: Cores.cardBlack,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Cores.primaryRed.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Cores.primaryRed.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list, color: Cores.primaryRed),
              SizedBox(width: 8),
              Text(
                'Funcionários Cadastrados',
                style: TextStyle(
                  color: Cores.textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 16),
              _buildDropdownStatus(),
            ],

          ),
          SizedBox(height: 16),

          // StreamBuilder para dados dinâmicos
          Container(
            height: 360,
            child: StreamBuilder<QuerySnapshot>(
              stream: _tipoLista ? usuarioController.listarFuncionariosAtivos() : usuarioController.listarFuncionariosInativos(),
              builder: (context, snapshot) {
                // Estados de carregamento e erro
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: Cores.primaryRed),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Cores.primaryRed, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Erro ao carregar funcionários',
                          style: TextStyle(color: Cores.textWhite),
                        ),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(color: Cores.textGray, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Verifica se há dados
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, color: Cores.textGray, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum funcionário cadastrado',
                          style: TextStyle(color: Cores.textGray),
                        ),
                      ],
                    ),
                  );
                }

                // Lista com dados do Firestore
                final funcionarios = snapshot.data!.docs;

                return Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                    itemCount: funcionarios.length,
                    itemBuilder: (context, index) {
                      final doc = funcionarios[index];
                      final funcionario = doc.data() as Map<String, dynamic>;

                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Cores.backgroundBlack,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Cores.borderGray.withOpacity(0.5),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Cores.primaryRed.withOpacity(0.2),
                            child: Icon(
                              Icons.person,
                              color: Cores.primaryRed,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            funcionario['nome'] ?? 'Nome não informado',
                            style: TextStyle(
                              color: Cores.textWhite,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                funcionario['cargo'] ?? 'Cargo não informado',
                                style: TextStyle(color: Cores.textGray),
                              ),
                              if (funcionario['email'] != null)
                                Text(
                                  funcionario['email'],
                                  style: TextStyle(
                                    color: Cores.textGray.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                /// Botão de Editar ou Deletar
                                _tipoLista
                                    ? IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: Cores.lightRed,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _editarFuncionario = true;
                                      _selectedCargo = funcionario['cargo'];
                                      _phoneController.text = funcionario['telefone'] ?? '';
                                      _nameController.text = funcionario['nome'] ?? '';
                                      _emailController.text = funcionario['email'] ?? '';
                                      _cpfController.text = funcionario['cpf'] ?? '';
                                      _uidController = funcionario['uid'] ?? '';
                                    });
                                  },
                                  tooltip: 'Editar funcionário',
                                )
                                    : IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Cores.lightRed,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    final confirmar = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: Cores.backgroundBlack,
                                        title: Text(
                                          'Confirmar Exclusão',
                                          style: TextStyle(color: Cores.textWhite),
                                        ),
                                        content: Text(
                                          'Tem certeza que deseja excluir este funcionário? a exclusão será permanente',
                                          style: TextStyle(color: Cores.textWhite),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: Text(
                                              'Cancelar',
                                              style: TextStyle(color: Cores.primaryRed),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: Text(
                                              'Excluir',
                                              style: TextStyle(color: Cores.primaryRed),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmar == true) {
                                      _ExcluirFuncionario(doc.id);
                                    }
                                  },
                                  tooltip: 'Excluir funcionário',
                                ),

                                /// Botão Ativar / Desativar
                                _tipoLista
                                    ? IconButton(
                                  icon: Icon(
                                    Icons.person_remove,
                                    color: Cores.primaryRed,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    final confirmar = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: Cores.backgroundBlack,
                                        title: Text('Confirmar Desativação',
                                            style: TextStyle(color: Cores.textWhite)),
                                        content: Text(
                                            'Tem certeza que deseja desativar este funcionário?',
                                            style: TextStyle(color: Cores.textWhite)),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: Text('Cancelar',
                                                style: TextStyle(color: Cores.primaryRed)),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: Text('Desativar',
                                                style: TextStyle(color: Cores.primaryRed)),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmar == true) {
                                      _desativarFuncionario(doc.id);
                                    }
                                  },
                                  tooltip: 'Desativar funcionário',
                                )
                                    : IconButton(
                                  icon: Icon(
                                    Icons.person_add,
                                    color: Cores.primaryRed,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    final confirmar = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: Cores.backgroundBlack,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          side: BorderSide(color: Cores.borderGray),
                                        ),
                                        title: Text('Confirmar Ativação',
                                            style: TextStyle(color: Cores.textWhite)),
                                        content: Text(
                                            'Tem certeza que deseja ativar este funcionário?',
                                            style: TextStyle(color: Cores.textWhite)),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: Text('Cancelar',
                                                style: TextStyle(color: Cores.primaryRed)),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: Text('Ativar',
                                                style: TextStyle(color: Cores.primaryRed)),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmar == true) {
                                      _ativarFuncionario(doc.id);
                                    }
                                  },
                                  tooltip: 'Ativar funcionário',
                                ),
                              ],
                            )

                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Formulário
  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Cores.cardBlack,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Cores.primaryRed.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Cores.primaryRed.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.person_add, color: Cores.primaryRed),
                SizedBox(width: 8),
                Text(
                  'Dados de Funcionário',
                  style: TextStyle(
                    color: Cores.textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            _buildInput(
              _nameController,
              'Nome',
              Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nome é obrigatório';
                }
                if (!_validador.validarNome(value)) {
                  return 'Nome deve ter pelo menos 3 caracteres';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            _buildInput(
              _emailController,
              'Email',
              Icons.email,
              enabled: !_editarFuncionario,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email é obrigatório';
                }
                if (!_validador.validarEmail(value)) {
                  return 'Email inválido';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            _buildInput(
              _phoneController,
              'Telefone',
              Icons.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Telefone é obrigatório';
                }
                if (!_validador.validarTelefone(value)) {
                  return 'Telefone deve ter 10 ou 11 dígitos';
                }
                return null;
              },
              inputFormatters: [Formatar.telefone()],
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            _buildInput(
              _cpfController,
              'CPF',
              Icons.badge,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'CPF é obrigatório';
                }
                if (!_validador.validarCPF(value)) {
                  return 'CPF inválido';
                }
                return null;
              },
              inputFormatters: [Formatar.cpf()],
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            _buildDropdownCargo(),
            SizedBox(height: 16),
            _buildInput(
              _passwordController,
              'Senha',
              Icons.lock,
              obscure: !_isPasswordVisible,
              enabled: !_editarFuncionario,
              validator: (value) {
                if (value == null || value.isEmpty && !_editarFuncionario) {
                  return 'Senha é obrigatória';
                }
                if (!_validador.validarSenha(value) && !_editarFuncionario) {
                  return 'Senha deve ter pelo menos 6 caracteres';
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: Cores.textGray,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Cores.primaryRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: Cores.primaryRed.withOpacity(0.3),
                      ),
                      icon: Icon(Icons.save, color: Colors.white),
                      label: Text(
                        'Salvar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: () async {
                        if (_editarFuncionario && _formKey.currentState!.validate()) {
                          final funcionario = Usuario();
                          funcionario.nome = _nameController.text;
                          funcionario.telefone = _phoneController.text;
                          funcionario.cpf = _cpfController.text;
                          funcionario.cargo = _selectedCargo ?? '';
                          funcionario.uid = _uidController ?? '';

                          await _EdiatarFuncionario(funcionario);

                          await Future.delayed(Duration(milliseconds: 100));
                          _nameController.clear();
                          _emailController.clear();
                          _phoneController.clear();
                          _cpfController.clear();
                          _passwordController.clear();
                          setState(() {
                            _editarFuncionario = false;
                            _selectedCargo = null;
                          });
                        } else if (_formKey.currentState!.validate()) {
                          final novoFuncionario = Usuario();
                          novoFuncionario.nome = _nameController.text;
                          novoFuncionario.email = _emailController.text;
                          novoFuncionario.telefone = _phoneController.text;
                          novoFuncionario.cpf = _cpfController.text;
                          novoFuncionario.cargo = _selectedCargo ?? '';
                          novoFuncionario.senha = _passwordController.text;

                          await _cadastrarFuncionario(novoFuncionario);

                          await Future.delayed(Duration(milliseconds: 100));
                          _nameController.clear();
                          _emailController.clear();
                          _phoneController.clear();
                          _cpfController.clear();
                          _passwordController.clear();
                          setState(() {
                            _selectedCargo = null;
                          });
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.2),
                      ),
                      icon: Icon(Icons.cleaning_services, color: Colors.white),
                      label: Text(
                        'Limpar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: () {
                        _nameController.clear();
                        _emailController.clear();
                        _phoneController.clear();
                        _cpfController.clear();
                        _passwordController.clear();
                        setState(() {
                          _editarFuncionario = false;
                          _selectedCargo = null;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
        bool enabled = true,
        List<TextInputFormatter>? inputFormatters,
        TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: Cores.textWhite),
      validator: validator,
      inputFormatters: inputFormatters,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Cores.textGray),
        prefixIcon: Icon(icon, color: Cores.primaryRed),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Cores.borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Cores.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Cores.primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Cores.backgroundBlack,
        errorStyle: TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildDropdownStatus() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 0),
      decoration: BoxDecoration(
        color: Cores.backgroundBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Cores.borderGray),
      ),
      child: DropdownButton<String>(
        value: _tipoLista ? 'Ativos' : 'Inativos',
        style: TextStyle(color: Cores.textWhite, fontSize: 14),
        dropdownColor: Cores.cardBlack,
        underline: SizedBox(), // Remove a linha padrão do dropdown
        icon: Icon(Icons.arrow_drop_down, color: Cores.textWhite),
        items: ['Ativos', 'Inativos'].map((String status) {
          return DropdownMenuItem<String>(
            value: status,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person,
                  color: Cores.primaryRed,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(status),
              ],
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            if (newValue == 'Ativos') {
              _tipoLista = true;
            } else {
              _tipoLista = false;
            }
          });
        },
      ),
    );
  }


  Widget _buildDropdownCargo() {
    return DropdownButtonFormField<String>(
      value: _selectedCargo,
      style: TextStyle(color: Cores.textWhite),
      dropdownColor: Cores.cardBlack,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.work, color: Cores.primaryRed),
        labelText: 'Cargo',
        labelStyle: TextStyle(color: Cores.textGray),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Cores.borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Cores.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Cores.primaryRed, width: 2),
        ),
        filled: true,
        fillColor: Cores.backgroundBlack,
      ),
      items: _cargos.map((String cargo) {
        return DropdownMenuItem<String>(value: cargo, child: Text(cargo));
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedCargo = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Cargo é obrigatório';
        }
        return null;
      },
    );
  }
}
