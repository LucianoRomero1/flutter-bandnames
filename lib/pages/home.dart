import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';

import 'package:band_names/models/band.dart';
import 'package:band_names/services/socket_service.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [
    // Band(id: '1', name: 'Nirvana', votes: 5),
    // Band(id: '2', name: 'Linkin Park', votes: 4),
    // Band(id: '3', name: 'Metallica', votes: 3),
    // Band(id: '4', name: 'Queen', votes: 2),
  ];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.on('active-bands', _handleActiveBands);

    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    bands = (payload as List).map((band) => Band.fromMap(band)).toList();
    setState(() {});
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('active-bands');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('BandNames',
            style: TextStyle(color: Colors.black87),
            textAlign: TextAlign.center),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Container(
              margin: EdgeInsets.only(right: 10),
              child: (socketService.serverStatus == ServerStatus.Online)
                  ? Icon(Icons.check_circle, color: Colors.blue[300])
                  : Icon(Icons.offline_bolt, color: Colors.red))
        ],
      ),
      body: Column(
        children: [
          //El expanded toma el espacio disponible
          _showGraph(),
          Expanded(
            child: ListView.builder(
                itemCount: bands.length,
                itemBuilder: (context, i) => _bandTile(bands[i])),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
          elevation: 1, onPressed: addNewBand, child: Icon(Icons.add)),
    );
  }

  Widget _bandTile(Band band) {
    final socketService = Provider.of<SocketService>(context, listen: false);

    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) =>
          socketService.socket.emit("delete-band", {'id': band.id}),
      background: Container(
          padding: const EdgeInsets.only(left: 8.0),
          color: Colors.red,
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Delete Band',
              style: TextStyle(color: Colors.white),
            ),
          )),
      child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Text(band.name.substring(0, 2)),
          ),
          title: Text(band.name),
          trailing: Text('${band.votes}', style: TextStyle(fontSize: 20)),
          onTap: () => socketService.socket.emit('vote-band', {'id': band.id})),
    );
  }

  addNewBand() {
    //Los final a diferencia de los CONST, se pueden instanciar en tiempo de ejecución
    final textController = TextEditingController();

    //Este IF ahora no me sirve porque estoy usando el chrome como emulador
    // if (Platform.isAndroid) {
    return showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('New band name: '),
              content: TextField(
                controller: textController,
              ),
              actions: <Widget>[
                MaterialButton(
                  elevation: 5,
                  textColor: Colors.blue,
                  child: const Text('Add'),
                  onPressed: () => addBandToList(textController.text),
                )
              ],
            ));
    // }

    //Esto es para IOS
    // showCupertinoDialog(
    //     context: context,
    //     builder: (_) => CupertinoAlertDialog(
    //           title: const Text('New band name: '),
    //           content: CupertinoTextField(
    //             controller: textController,
    //           ),
    //           actions: <Widget>[
    //             CupertinoDialogAction(
    //               isDefaultAction: true,
    //               child: const Text('Add'),
    //               onPressed: () => addBandToList(textController.text),
    //             ),
    //             CupertinoDialogAction(
    //               isDestructiveAction: true,
    //               child: const Text('Dismiss'),
    //               onPressed: () => Navigator.pop(context),
    //             )
    //           ],
    //         ));
  }

  void addBandToList(String name) {
    if (name.length > 1) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.socket.emit("add-band", {'name': name});
    }

    Navigator.pop(context);
  }

  Widget _showGraph() {
    Map<String, double> dataMap = new Map();
    bands.forEach((band) =>
        {dataMap.putIfAbsent(band.name, () => band.votes.toDouble())});

    //If i need colorList , can create this
    final List<Color> colorList = [
      Colors.blue[50] as Color,
      Colors.blue[200] as Color,
      Colors.yellow[50] as Color,
      Colors.yellow[200] as Color,
      Colors.pink[50] as Color,
      Colors.pink[200] as Color,
    ];

    return Container(
      padding: EdgeInsets.only(top: 10),
      width: double.infinity,
      height: 200,
      child: PieChart(
        dataMap: dataMap,
        animationDuration: Duration(milliseconds: 800),
        chartRadius: MediaQuery.of(context).size.width / 3.2,
        //colorList: colorList,
        chartType: ChartType.disc,
        decimalPlaces: 0,
        showLegends: true,
      ),
    );
  }
}
