import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:proxmox_controller/vm_list_parser.dart';

Future<Response> onRequest(RequestContext context) async {
  final proxmoxConnection = context.read<SSHClient>();

  final strVmId = context.request.uri.queryParameters['vmId'];
  final vmId = int.tryParse(strVmId ?? '');

  if (vmId == null) {
    return Response(
      body: jsonEncode(
        {'error': 'vmId is required, and must be an integer.'},
      ),
      headers: {'Content-Type': 'application/json'},
      statusCode: HttpStatus.badRequest,
    );
  }

  final vms = await proxmoxConnection.run('qm list --full', stderr: false);
  final parsed = VirtualMachine.parseData(utf8.decode(vms));

  final vm = parsed.firstWhereOrNull((element) => element.vmId == vmId);

  if (vm == null) {
    return Response(
      body: jsonEncode(
        {'error': 'VM with id $vmId not found.'},
      ),
      headers: {'Content-Type': 'application/json'},
      statusCode: HttpStatus.notFound,
    );
  }

  if (vm.status == 'running') {
    return Response(
      body: jsonEncode(
        {'error': 'VM with id $vmId is already running.'},
      ),
      headers: {'Content-Type': 'application/json'},
      statusCode: HttpStatus.alreadyReported,
    );
  }

  // stop all VMs
  for (final vm in parsed) {
    if (vm.status == 'running') {
      final result = await proxmoxConnection.execute('qm stop ${vm.vmId}');

      if (result.exitCode != 0) {
        return Response(
          body: jsonEncode(
            {
              'error': 'Failed to stop VM with id ${vm.vmId}.',
              'stackTrace': result.stderr,
            },
          ),
          headers: {'Content-Type': 'application/json'},
          statusCode: HttpStatus.internalServerError,
        );
      }
    }
  }

  // start the VM
  final result = await proxmoxConnection.execute('qm start $vmId');

  if (result.exitCode != 0) {
    return Response(
      body: jsonEncode(
        {
          'error': 'Failed to start VM with id $vmId.',
          'stackTrace': result.stderr,
        },
      ),
      headers: {'Content-Type': 'application/json'},
      statusCode: HttpStatus.internalServerError,
    );
  }

  return Response(
    body: jsonEncode(
      {'message': 'VM with id $vmId started.'},
    ),
    headers: {'Content-Type': 'application/json'},
  );
}
