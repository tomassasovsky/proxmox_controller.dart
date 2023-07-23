import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:proxmox_controller/vm_list_parser.dart';

Future<Response> onRequest(RequestContext context) async {
  final proxmoxConnection = context.read<SSHClient>();

  final vms = await proxmoxConnection.run('qm list --full', stderr: false);
  final parsed = VirtualMachine.parseData(utf8.decode(vms));

  return Response(
    body: jsonEncode(
      parsed.map((e) => e.toJson()).toList(),
    ),
    headers: {'Content-Type': 'application/json'},
  );
}
