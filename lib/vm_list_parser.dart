import 'dart:developer';

import 'package:equatable/equatable.dart';

class VirtualMachine extends Equatable {
  const VirtualMachine({
    required this.vmId,
    required this.name,
    required this.status,
    required this.memoryInMB,
    required this.bootDiskInGB,
    required this.pid,
  });

  final int vmId;
  final String name;
  final String status;
  final int memoryInMB;
  final double bootDiskInGB;
  final int pid;

  @override
  String toString() {
    return 'VMID: $vmId, NAME: $name, STATUS: $status, MEM(MB): $memoryInMB, '
        'BOOTDISK(GB): $bootDiskInGB, PID: $pid';
  }

  Map<String, dynamic> toJson() {
    return {
      'vmid': vmId,
      'name': name,
      'status': status,
      'memoryInMB': memoryInMB,
      'bootDiskInGB': bootDiskInGB,
      'processId': pid,
    };
  }

  static List<VirtualMachine> parseData(String data) {
    final result = <VirtualMachine>[];
    var lines = data.trim().split('\n');

    // Assuming the first line is the header and the column names.
    final headerLine = lines.first;
    final columnNames = headerLine
        .split(RegExp(r'\s+'))
        .where((col) => col.isNotEmpty)
        .toList();

    // Removing the header line from the lines list.
    lines = lines.sublist(1);

    for (final line in lines) {
      final values = line
          .trim()
          .split(RegExp(r'\s+'))
          .where((val) => val.isNotEmpty)
          .toList();

      // Check if the number of values is the same as the number of columns.
      if (values.length == columnNames.length) {
        final vmId = int.parse(values[0]);
        final name = values[1];
        final status = values[2];
        final memoryInMB = int.parse(values[3]);
        final bootDiskInGB = double.parse(values[4]);
        final pid = int.parse(values[5]);

        final vm = VirtualMachine(
          vmId: vmId,
          name: name,
          status: status,
          memoryInMB: memoryInMB,
          bootDiskInGB: bootDiskInGB,
          pid: pid,
        );

        result.add(vm);
      } else {
        // In case the line doesn't match the expected format.
        log('Skipping line: $line');
      }
    }

    return result;
  }

  @override
  List<Object?> get props => [
        vmId,
        name,
        status,
        memoryInMB,
        bootDiskInGB,
        pid,
      ];
}
