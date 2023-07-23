import 'dart:developer';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:network_tools/network_tools.dart';
import 'package:proxmox_controller/environment.dart';

Future<HttpServer> run(
  Handler handler,
  InternetAddress ip,
  int port,
) async {
  final environment = Environment.fromDotEnv();

  stdout
    ..writeln('Starting server on $ip:$port')
    ..writeln('Using proxmox username: ${environment.proxmoxUsername}');

  final proxmoxConnection = await connectToProxmox(environment);

  return serve(
    handler.use(provider<SSHClient>((context) => proxmoxConnection)),
    ip,
    port,
  );
}

Future<SSHClient> connectToProxmox(Environment environment) async {
  final stopwatch = Stopwatch()..start();
  final devices = await NetworkInterface.list(
    includeLinkLocal: true,
    type: InternetAddressType.IPv4,
  );

  final ip = devices.first.addresses.first.address;
  final subnet = ip.substring(0, ip.lastIndexOf('.'));

  final streamController = HostScanner.getAllPingableDevices(subnet);
  final activeHostList = <ActiveHost>[];

  await for (final ActiveHost activeHost in streamController) {
    try {
      final isSSH = (await PortScanner.isOpen(
        activeHost.address,
        22,
      ))
          ?.openPorts
          .contains(OpenPort(22));

      if (isSSH ?? false) {
        activeHostList
          ..add(activeHost)
          ..sort((a, b) {
            final aIp = int.parse(
              a.internetAddress.address
                  .substring(a.internetAddress.address.lastIndexOf('.') + 1),
            );
            final bIp = int.parse(
              b.internetAddress.address
                  .substring(b.internetAddress.address.lastIndexOf('.') + 1),
            );
            return aIp.compareTo(bIp);
          });
      }
    } catch (e) {
      log(e.toString());
    }
  }

  final sshSocket =
      await SSHSocket.connect(activeHostList.first.internetAddress.address, 22);

  stopwatch.stop();
  stdout.writeln(
    'Connected to Proxmox server in ${stopwatch.elapsed.inMilliseconds}ms',
  );

  return SSHClient(
    sshSocket,
    username: environment.proxmoxUsername,
    onPasswordRequest: () => environment.proxmoxPassword,
  );
}
