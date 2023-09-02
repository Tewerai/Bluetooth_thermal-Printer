// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:offline/Screens/printerenum.dart';

class SecondPage extends StatefulWidget {
  const SecondPage({Key? key}) : super(key: key);

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _device;
  bool _connected = false;
  bool _pressed = false;
  late String errormsg;
  late bool error, showprogress;
  late String username, password;
  late String sum = '0';
  late String shopName;
  late List printName = ['Colgate','Bread','Biscuits'];
  late List printQuantity = [1,2,3];
  late List printPrices = [0.50,1,2];

  late List products;
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Print Receipt'),
        ),
        body: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'Device:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  DropdownButton<BluetoothDevice>(
                    items: _getDeviceItems(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _device = value);
                      }
                      _connect();
                    },
                    value: _device,
                  ),
                  ElevatedButton(
                    onPressed: _pressed
                        ? null
                        : _connected
                            ? _disconnect
                            : _connect,
                    child: Text(_connected ? 'Disconnect' : 'Connect'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 10),
              child: ElevatedButton(
                onPressed: () {
                  initPlatformState();
                },
                child: const Text('Refresh'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 10),
              child: ElevatedButton(
                onPressed: _connected ? _tesPrint : null,
                child: const Text('Print Receipt'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> initPlatformState() async {

    //
    var __pricesToPrint = [];

    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
    } on PlatformException {}
    bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
          setState(() {
            _connected = true;
            _pressed = false;
          });

          break;
        case BlueThermalPrinter.DISCONNECTED:
          setState(() {
            _connected = false;
            _pressed = false;
          });
          break;
        default:
          print(state);
          break;
      }
    });

    if (!mounted) return;
    setState(() {
      _devices = devices;
    });
  }

  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devices.isEmpty) {
      items.add(const DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      for (var device in _devices) {
        items.add(DropdownMenuItem(
          child: Text(device.name!),
          value: device,
        ));
      }
    }
    return items;
  }

  void _connect() async {
    if (_device == null) {
      show('No device selected.');
    } else {
      bluetooth.isConnected.then((isConnected) {
        bluetooth.connect(_device!).catchError((error) {
          setState(() => _pressed = false);
        });
        setState(() => _pressed = true);
      });
    }
  }

  void _disconnect() {
    bluetooth.disconnect();
    setState(() => _pressed = true);
  }

  void _tesPrint() async {
    // get filtered products
    final prefs = await SharedPreferences.getInstance();

    //get all products without filtering
    var _products = prefs.getString('currentOrder');
    var _prices = prefs.getString('currentOrderPrices');
    var _total = prefs.getString('currentTotal');
    var shopName = prefs.getString('shopName');
    List __products = _products!.split(",");
    List __prices = _prices!.split(",");
    // get time
    var dt = DateTime.now();
    var hour = dt.hour.toString();
    var minute = dt.minute.toString();

    bluetooth.isConnected.then((isConnected) {
      if (isConnected != null) {
        bluetooth.printNewLine();
        /* PRINT SHOP NAME*/
        bluetooth.printCustom('Our Shop', 3, 1);
        bluetooth.printNewLine();

        bluetooth.printCustom(
            '------------------------------------------', 0, 0);
        bluetooth.printCustom(
            '------------------------------------------', 0, 0);

        bluetooth.printNewLine();

        //bluetooth.printImageBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
        bluetooth.printLeftRight(
            dt.day.toString() +
                '/' +
                dt.month.toString() +
                '/' +
                dt.year.toString(),
            "Cash",
            1);
        bluetooth.printCustom(
            '------------------------------------------', 0, 0);

        bluetooth.printNewLine();
        bluetooth.printNewLine();

        /* COLUMNS DETAILS*/
        bluetooth.print3Column('No', "Product", 'Subtotal', Size.bold.val);
        bluetooth.printCustom(
            '------------------------------------------', 0, 0);
        bluetooth.printCustom(
            '------------------------------------------', 0, 0);

        /* PRINT PRODUCTS */

        for (var i = 0; i < printName.length; i++) {
          var itemId = i + 1;
          var subtotal =
              double.parse(printPrices[i]) * double.parse(printQuantity[i]);
          // bluetooth.print3Column( itemId.toString()+ '. ' + __products[i],'','', Size.bold.val);
          bluetooth.printCustom(itemId.toString() + '. ' + printName[i], 0, 0);
          bluetooth.print3Column('\$' + printPrices[i] + 'x' + printQuantity[i],
              '', '\$' + subtotal.toString(), Size.bold.val);

          bluetooth.printNewLine();
        }
        /* TEST PRINT*/

        bluetooth.printNewLine();
        bluetooth.printCustom(
            '------------------------------------------', 0, 0);
        bluetooth.printCustom(
            '------------------------------------------', 0, 0);

        /*END OF PRINT PRODUCTS*/

        /* PRINT TOTAL*/
        bluetooth.printLeftRight("TOTAL", '\$' + _total! + '0', Size.bold.val,
            format: "%-15s %15s %n");
        bluetooth.printNewLine();
        /*PRINT TIME*/
        bluetooth.printCustom(hour + ' : ' + minute, 2, 1);
        bluetooth.printNewLine();
        bluetooth.printCustom(
            '------------------------------------------', 0, 0);
        bluetooth.printCustom(
            '------------------------------------------', 0, 0);

        /*PRINT THANK YOU*/
        bluetooth.printCustom("Thank You", 2, 1);
        // bluetooth.printCustom("Powered By Blue Ichor", 2, 1);
        /*    bluetooth.printQRcode(
            'Corner Shop Receipt' +
                ' date' +
                dt.day.toString() +
                ' ' +
                dt.month.toString(),
            200,
            200,
            1);
        //bluetooth.printNewLine();
        */
        bluetooth.paperCut();
      }
    });
  }


  Future show(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        duration: duration,
      ),
    );
  }
}
