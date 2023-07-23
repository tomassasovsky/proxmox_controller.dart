import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:proxmox_controller/vm_list_parser.dart';

Future<Response> onRequest(RequestContext context) async {
  final proxmoxConnection = context.read<SSHClient>();
  final strVmIds = context.request.uri.queryParameters['vmIds'];
  final vmIds = strVmIds?.split(',').map(int.tryParse).toList() ?? [];

  if (vmIds.length != 2) {
    return Response(
      body: jsonEncode(
        {'error': 'vmIds is must be a comma separated list of two integers.'},
      ),
      headers: {'Content-Type': 'application/json'},
      statusCode: HttpStatus.badRequest,
    );
  }

  final vms = await proxmoxConnection.run('qm list --full', stderr: false);
  final parsedVms = VirtualMachine.parseData(utf8.decode(vms));

  final vmsToSwitch =
      parsedVms.where((element) => vmIds.contains(element.vmId));

  if (vmsToSwitch.isEmpty) {
    return Response(
      body: jsonEncode(
        {'error': 'No VMs found with ids $vmIds.'},
      ),
      headers: {'Content-Type': 'application/json'},
      statusCode: HttpStatus.notFound,
    );
  }

  final vmToStart = vmsToSwitch.firstWhereOrNull(
    (element) => element.status != 'running' && vmIds.contains(element.vmId),
  );

  final vmToStop = vmsToSwitch.firstWhereOrNull(
    (element) => element.status == 'running' && vmIds.contains(element.vmId),
  );

  if (vmToStart == null) {
    return Response(
      body: jsonEncode(
        {
          'error': 'No VMs found with ids $vmIds that are stopped.',
        },
      ),
      headers: {'Content-Type': 'application/json'},
      statusCode: HttpStatus.notFound,
    );
  }

  if (vmToStop != null) {
    final result = await proxmoxConnection.execute('qm stop ${vmToStop.vmId}');

    if (result.exitCode != 0) {
      return Response(
        body: jsonEncode(
          {
            'error': 'Failed to stop VM with id ${vmToStop.vmId}.',
            'stackTrace': result.stderr,
          },
        ),
        headers: {'Content-Type': 'application/json'},
        statusCode: HttpStatus.internalServerError,
      );
    }
  }

  final result = await proxmoxConnection.execute('qm start ${vmToStart.vmId}');
  if (result.exitCode != 0) {
    return Response(
      body: jsonEncode(
        {
          'error': 'Failed to start VM with id ${vmToStart.vmId}.',
          'stackTrace': result.stderr,
        },
      ),
      headers: {'Content-Type': 'application/json'},
      statusCode: HttpStatus.internalServerError,
    );
  }

  final vmsAfterSwitch = await proxmoxConnection.run('qm list --full');
  final parsedVmsAfterSwitch =
      VirtualMachine.parseData(utf8.decode(vmsAfterSwitch));

  return Response(
    body: jsonEncode(
      parsedVmsAfterSwitch.map((e) => e.toJson()).toList(),
    ),
    headers: {'Content-Type': 'application/json'},
  );
}
