import 'package:floworder/controller/UsuarioController.dart';
import 'package:floworder/models/Usuario.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/services/text_formatter.dart';

import '../auxiliar/Validador.dart';
import '../auxiliar/Formatar.dart';

class Tela_Cadastro extends StatefulWidget {
  @override
  _TelaCadastro createState() => _TelaCadastro();
}

class _TelaCadastro extends State<Tela_Cadastro> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cpfController = TextEditingController();

  Usuario usuario = Usuario();
  Validador validar = Validador();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cpfController.dispose();
    super.dispose();
  }


  Future<void> _register() async {
    setState(() {
      _isLoading = true;
    });


    UsuarioController usuarioController = UsuarioController();
    String mensagem = await usuarioController.cadastrarUsuario(usuario);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(await mensagem),
        backgroundColor: Colors.blue,
      ),
    );
    if (mensagem == 'Usuário cadastrado com sucesso') {
      Navigator.pushReplacementNamed(context, '/telaCadastroUsuario');//mudar depois
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.grey[900]!,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(32),
              child: Container(
                constraints: BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo/Header
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red[900],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              'logo/Icone_FlowOrder.png', // Caminho relativo à raiz onde o asset foi declarado
                              height: 100,
                              // ...
                            ),


                          ],
                        ),
                      ),

                      SizedBox(height: 40),

                      Text(
                        'Criar Nova Conta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 8),

                      Text(
                        'Cadastrar Um Nova Conta de Um Gerente',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),

                      SizedBox(height: 40),

                      // Campo Nomes
                      _buildInputField(
                        controller: _nameController,
                        label: 'Nome Completo',
                        icon: Icons.person,
                        validator: (value) {
                          if (!validar.validarNome(value!)) {
                            return 'Por favor, insira seu nome';
                          }
                          return null;
                        }, inputFormatters: [],
                      ),

                      SizedBox(height: 20),

                      // Campo E-mail
                      _buildInputField(
                        controller: _emailController,
                        label: 'E-mail',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (!validar.validarEmail(value!)) {
                            return 'Email não esta Valido';
                          }
                          return null;
                        }, inputFormatters: [],
                      ),

                      SizedBox(height: 20),

                      //campo cpf
                      _buildInputField(
                        controller: _cpfController,
                        label: 'CPF',
                        icon: Icons.badge,
                        keyboardType: TextInputType.number,
                        inputFormatters: [Formatar.cpf()],
                        validator: (value) {
                          if (!validar.validarCPF(value!)) {
                            return 'CPF não esta Valido';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 20),

                      // Campo Senha
                      _buildInputField(
                        controller: _passwordController,
                        label: 'Senha',
                        icon: Icons.lock,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (!validar.validarSenha(value!)) {
                            return 'Por favor, insira uma senha, mínimo 6 caracteres';
                          }
                          return null;
                        }, inputFormatters: [],
                      ),

                      SizedBox(height: 20),



                      // Botão Cadastrar
                      Container(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () {
                            if (_formKey.currentState!.validate()) {
                              usuario.nome = _nameController.text;
                              usuario.email = _emailController.text;
                              usuario.senha = _passwordController.text;
                              usuario.cpf = _cpfController.text;
                              usuario.tipo = ['Gerente'];
                              _register();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 5,
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                              : Text(
                            'CADASTRAR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Já tem uma conta? ',
                            style: TextStyle(color: Colors.white70),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/telalogin');
                            },
                            child: Text(
                              'Entrar',
                              style: TextStyle(
                                color: Colors.red[400],
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator, required List<TextInputFormatter> inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.red),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          floatingLabelStyle: TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}