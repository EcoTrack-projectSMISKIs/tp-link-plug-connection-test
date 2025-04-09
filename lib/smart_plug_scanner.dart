import 'dart:async';
import 'package:flutter/material.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:wifi_iot/wifi_iot.dart';

class SmartPlugScanner extends StatefulWidget {
  @override
  _SmartPlugScannerState createState() => _SmartPlugScannerState();
}

class _SmartPlugScannerState extends State<SmartPlugScanner> {
  List<Map<String, dynamic>> foundDevices = [];
  bool scanning = false;

  Future<void> scanForPlugs() async {
    setState(() {
      scanning = true;
      foundDevices.clear();
    });

    final MDnsClient mdns = MDnsClient();
    await mdns.start();


    // Look for TP-Link Smart Plugs
    // Note: i'm not sure if tapo P110M plugs use the "_tplink-smarthome._tcp.local" service pero most likely??
    // change "_tplink-smarthome._tcp.local" if incorrect
  
    await for (final PtrResourceRecord ptr in mdns.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_tplink-smarthome._tcp.local'))) {
      await for (final SrvResourceRecord srv in mdns.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName))) {
        await for (final IPAddressResourceRecord ip in mdns.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target))) {
          setState(() {
            foundDevices.add({
              'ip': ip.address.address,
              'port': srv.port,
              'name': srv.name,
            });
          });
        }
      }
    }

    mdns.stop();
    setState(() => scanning = false);
  }

  @override
  void initState() {
    super.initState();
    checkWifiAndScan();
  }

  Future<void> checkWifiAndScan() async {
    bool isConnected = await WiFiForIoTPlugin.isConnected();
    if (isConnected) {
      await scanForPlugs();
    } else {
      setState(() {
        foundDevices = [
          {'ip': 'Not connected to Wi-Fi', 'port': '', 'name': ''}
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('TP-Link Smart Plug Scanner')),
      body: scanning
          ? Center(child: CircularProgressIndicator())
          : foundDevices.isEmpty
              ? Center(child: Text('No plugs found', style: TextStyle(fontSize: 18)))
              : ListView.builder(
                  itemCount: foundDevices.length,
                  itemBuilder: (context, index) {
                    final device = foundDevices[index];
                    return ListTile(
                      title: Text('${device['ip']}:${device['port']}'),
                      subtitle: Text(device['name'] ?? ''),
                      trailing: Icon(Icons.power),
                      onTap: () {
                        // You can add action to send a command or ping the plug here
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Selected ${device['ip']}')),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.refresh),
        onPressed: scanForPlugs,
      ),
    );
  }
}
