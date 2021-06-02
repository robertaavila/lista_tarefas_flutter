import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

//funcao principal do app
void main() {
  runApp(MaterialApp(
    //chama a pagina inicial do app
    home: Home(),
  ));
}

//stateful pq tem atualizaçao de estado na tela
class Home extends StatefulWidget {
  const Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //controller do textField - acessa o texto digitado
  final _toDoController = TextEditingController();

  //lista de tarefas
  List _toDoList = [];
  //normalmente com json o map vai ser String, dynamic
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPosition;

  @override
  void initState() {
    //sobrescreve o initState para ler o arquivo json ao inicializar
    super.initState();
    _readData().then((data) => setState(() {
          //decode transforma o json para string com o decoder do dart
          _toDoList = json.decode(data);
        }));
  }
  //adiciona tarefas
  void _addToDo() {
    //setState para atualizar o estado da tela
    setState(() {
      Map<String, dynamic> newToDo = Map();
      //pega o titulo do text field
      newToDo["title"] = _toDoController.text;
      //limpa o campo depois de inserir a tarefa na lista
      _toDoController.text = "";
      //tarefa começa como não concluída, então false no ok
      newToDo["ok"] = false;
      //adicionando a tarefa na lista
      _toDoList.add(newToDo);
      //salvando os dados no json
      _saveData();
    });
  }

  //funcao que orgainza as tarefas de acordo com terem sido ou nao marcadas com ok
  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    //verifica se está ok
    setState(() {
      //funcao sort é a ordenacao do dart
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });
      _saveData();
    });
    return null;
  }

  @override
  //builda o projeto, com o Scaffold, Appbar e as colunas e linhas de tarefas
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                //ElevatedButton substitui o depreciado RaisedButton
                ElevatedButton(
                  onPressed: _addToDo,
                  child: Text("Add"),
                )
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
                  //chama a função refresh
                  onRefresh: _refresh,
                  //monta a lista de tarefas, chamando a função buildItem
                  //renderiza conforme os itens são mostrados na tela, economizando recursos
                  child: ListView.builder(
                      padding: EdgeInsets.only(top: 10.0),
                      itemCount: _toDoList.length,
                      itemBuilder: buildItem)))
        ],
      ),
    );
  }

  //a funçao retorna um widget
  Widget buildItem(context, index) {
    //Dismissable é um widget que permite arrastar para deletar
    return Dismissible(
      background: Container(
        //ao deslizar vai aparecer uma faixa vermelha
        color: Colors.red,
        //alinha o widget no canto esquerdo (Align/Alignment)
        child: Align(
          //Alignment 0 e 0 fica bem no centro
          alignment: Alignment(-0.9, 0.0),
          //mostra o icone da lixeira ao arrastar
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      //direçao para onde pode ser arrastado
      direction: DismissDirection.startToEnd,
      //key é uma String que identifica o elemento dismissible
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      child: (CheckboxListTile(
        //titulo e value vem da lista
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          //muda o icone se o checkbox for clicado
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        //verifica se o check foi marcado no app
        onChanged: (checked) {
          setState(() {
            //muda o estado para OK quando o usuario marca o checkbox
            _toDoList[index]["ok"] = checked;
            //salva a informação atualizada no json
            _saveData();
          });
        },
      )),
      onDismissed: (direction) {
        //se um item é deletado, é removido da lista
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPosition = index;
          _toDoList.removeAt(index);
          //a lista atualizada é salva no json
          _saveData();

          final snack = SnackBar(
            //após deletar o item aparece a SnackBar com a opcao de desfazer
            content: Text("Tarefa ${_lastRemoved["title"]} removida!"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovedPosition, _lastRemoved);
                    _saveData();
                  });
                }),
            //duraçao da SnackBar na tela
            duration: Duration(seconds: 5),
          );
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

  //retorna o arquivo com as tarefas armazenadas em memória
  //Future pq não é executado imediatamente
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  //tudo que envolve leitura e salvamento de arquivos é assíncrono
  //não é imediato
  Future<File> _saveData() async {
    //transforma a lista atual em um json
    String data = json.encode(_toDoList);
    final file = await _getFile();
    //salva o conteudo como String
    return file.writeAsString(data);
  }

  //ler os dados do arquivo
  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      //faltou lidar com o erro melhor
      return null;
    }
  }
}
