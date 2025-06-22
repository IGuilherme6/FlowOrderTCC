import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:floworder/controller/UsuarioController.dart';
import 'package:floworder/models/Usuario.dart';
import 'package:flutter/material.dart';
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

  final Validador _validador = Validador();
  final Usuario funcionario = Usuario();
  UsuarioController usuarioController = UsuarioController();

  String? _selectedCargo;
  bool _isPasswordVisible = false;

  List<String> _cargos = ['Garçom', 'Atendente', 'Cozinheiro',];

  // Cores do tema
  static const Color primaryRed = Color(0xFFDC2626);
  static const Color darkRed = Color(0xFF991B1B);
  static const Color lightRed = Color(0xFFEF4444);
  static const Color backgroundBlack = Color(0xFF111827);
  static const Color cardBlack = Color(0xFF1F2937);
  static const Color textWhite = Color(0xFFF9FAFB);
  static const Color textGray = Color(0xFF9CA3AF);
  static const Color borderGray = Color(0xFF374151);


  Future<void> _cadastrarFuncionario() async {
    UsuarioController usuarioController = UsuarioController();
    String mensagem = await usuarioController.cadastrarFuncionario(funcionario);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(await mensagem),
        backgroundColor: Colors.blue,
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1000;

    return Scaffold(
      backgroundColor: backgroundBlack,
      body: Row(
        children: [
          Barralateral(
            currentRoute: '/funcionarios',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestão de Funcionários',
                    style: TextStyle(
                      color: textWhite,
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
      constraints: BoxConstraints(
        minHeight: 400,
        maxHeight: 500, // 🔥 Altura fixa do card
      ),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryRed.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: primaryRed.withOpacity(0.1),
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
              Icon(Icons.list, color: primaryRed),
              SizedBox(width: 8),
              Text(
                'Funcionários Cadastrados',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // 🔥 StreamBuilder para dados dinâmicos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: usuarioController.listarFuncionarios(),
              builder: (context, snapshot) {
                // 🔥 Estados de carregamento e erro
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: primaryRed,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: primaryRed, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Erro ao carregar funcionários',
                          style: TextStyle(color: textWhite),
                        ),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(color: textGray, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // 🔥 Verifica se há dados
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, color: textGray, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum funcionário cadastrado',
                          style: TextStyle(color: textGray),
                        ),
                      ],
                    ),
                  );
                }

                // 🔥 Lista com dados do Firestore
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
                          color: backgroundBlack,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderGray.withOpacity(0.5),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primaryRed.withOpacity(0.2),
                            child: Icon(
                              Icons.person,
                              color: primaryRed,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            funcionario['nome'] ?? 'Nome não informado',
                            style: TextStyle(
                              color: textWhite,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                funcionario['cargo'] ?? 'Cargo não informado',
                                style: TextStyle(color: textGray),
                              ),
                              if (funcionario['email'] != null)
                                Text(
                                  funcionario['email'],
                                  style: TextStyle(
                                    color: textGray.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 🔥 Botão de Editar
                              IconButton(
                                icon: Icon(Icons.edit, color: lightRed, size: 20),
                                onPressed: () {
                                  usuarioController.atualizarFuncionario(doc.id, funcionario as Usuario);
                                },
                                tooltip: 'Editar funcionário',
                              ),
                              // 🔥 Botão de Deletar
                              IconButton(
                                icon: Icon(Icons.delete, color: primaryRed, size: 20),
                                onPressed: () {
                                  usuarioController.desativarFuncionario(doc.id);
                                },
                                tooltip: 'Excluir funcionário',
                              ),
                            ],
                          ),
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
        color: cardBlack,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryRed.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: primaryRed.withOpacity(0.1),
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
                Icon(Icons.person_add, color: primaryRed),
                SizedBox(width: 8),
                Text(
                  'Cadastro de Funcionário',
                  style: TextStyle(
                    color: textWhite,
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
            ),
            SizedBox(height: 16),
            _buildDropdownCargo(),
            SizedBox(height: 16),
            _buildInput(
              _passwordController,
              'Senha',
              Icons.lock,
              obscure: !_isPasswordVisible,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Senha é obrigatória';
                }
                if (!_validador.validarSenha(value)) {
                  return 'Senha deve ter pelo menos 6 caracteres';
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: textGray,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  funcionario.nome = _nameController.text;
                  funcionario.email = _emailController.text;
                  funcionario.telefone = _phoneController.text;
                  funcionario.cpf = _cpfController.text;
                  funcionario.cargo = (_selectedCargo ?? '');
                  funcionario.senha = _passwordController.text;

                  _cadastrarFuncionario();
                  // Limpar os campos após o cadastro
                  _formKey.currentState!.reset();


                }

              },
              child: Text(
                'Cadastrar Funcionário',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16),
              ),

            )
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
      }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: textWhite),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textGray),
        prefixIcon: Icon(icon, color: primaryRed),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
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
        fillColor: backgroundBlack,
        errorStyle: TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildDropdownCargo() {
    return DropdownButtonFormField<String>(
      value: _selectedCargo,
      style: TextStyle(color: textWhite),
      dropdownColor: cardBlack,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.work, color: primaryRed),
        labelText: 'Cargo',
        labelStyle: TextStyle(color: textGray),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        filled: true,
        fillColor: backgroundBlack,
      ),
      items: _cargos.map((String cargo) {
        return DropdownMenuItem<String>(
          value: cargo,
          child: Text(cargo),
        );
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
