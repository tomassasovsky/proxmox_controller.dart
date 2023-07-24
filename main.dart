import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dartssh2/dartssh2.dart';
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
  final sshSocket = await SSHSocket.connect(environment.proxmoxIPAddress, 22);
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
