import 'dart:async';
import 'package:flutter/material.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:wifi_iot/wifi_iot.dart';

class SmartTVScanner extends StatefulWidget {
  @override
  _SmartTVScannerState createState() => _SmartTVScannerState();
}

class _SmartTVScannerState extends State<SmartTVScanner> {
  List<Map<String, dynamic>> foundDevices = [];
  bool scanning = false;

  // Modify this method to look for Smart TVs or Android TVs via mDNS
  Future<void> scanForTVs() async {
    setState(() {
      scanning = true;
      foundDevices.clear();
    });

    final MDnsClient mdns = MDnsClient();
    await mdns.start();

    // Look for Google Cast-enabled devices (Chromecast, Google TV, etc.)
    await for (final PtrResourceRecord ptr in mdns.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_googlecast._tcp.local'))) {
      await for (final SrvResourceRecord srv in mdns.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName))) {
        await for (final IPAddressResourceRecord ip
            in mdns.lookup<IPAddressResourceRecord>(
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

    // Look for Apple AirPlay-enabled devices (Apple TV)
    await for (final PtrResourceRecord ptr in mdns.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_airplay._tcp.local'))) {
      await for (final SrvResourceRecord srv in mdns.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName))) {
        await for (final IPAddressResourceRecord ip
            in mdns.lookup<IPAddressResourceRecord>(
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
      await scanForTVs();
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
      appBar: AppBar(title: Text('Smart TV / Android TV Scanner')),
      body: scanning
          ? Center(child: CircularProgressIndicator())
          : foundDevices.isEmpty
              ? Center(child: Text('No Smart TVs found'))
              : ListView.builder(
                  itemCount: foundDevices.length,
                  itemBuilder: (context, index) {
                    final device = foundDevices[index];
                    return ListTile(
                      title: Text('${device['ip']}:${device['port']}'),
                      subtitle: Text(device['name'] ?? ''),
                      trailing: Icon(Icons.tv),
                      onTap: () {
                        // Add your action here (e.g., show more details or connect to the TV)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Selected ${device['ip']}')),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.refresh),
        onPressed: scanForTVs,
      ),
    );
  }
}
