import 'dart:io';

import 'package:dotenv/dotenv.dart';

class Environment {
  const Environment({
    required this.proxmoxUsername,
    required this.proxmoxPassword,
    required this.proxmoxIPAddress,
  });

  factory Environment.fromDotEnv() {
    final env = DotEnv()..load();
    final proxmoxPassword =
        env['PROXMOX_PASSWORD'] ?? Platform.environment['PROXMOX_PASSWORD'];
    final proxmoxUsername =
        env['PROXMOX_USERNAME'] ?? Platform.environment['PROXMOX_USERNAME'];
    final proxmoxIPAddress =
        env['PROXMOX_IP_ADDRESS'] ?? Platform.environment['PROXMOX_IP_ADDRESS'];

    return Environment(
      proxmoxUsername: String.fromEnvironment(
        'PROXMOX_USERNAME',
        defaultValue: proxmoxUsername ?? '',
      ),
      proxmoxPassword: String.fromEnvironment(
        'PROXMOX_PASSWORD',
        defaultValue: proxmoxPassword ?? '',
      ),
      proxmoxIPAddress: String.fromEnvironment(
        'PROXMOX_IP_ADDRESS',
        defaultValue: proxmoxIPAddress ?? '',
      ),
    );
  }

  final String proxmoxUsername;
  final String proxmoxPassword;
  final String proxmoxIPAddress;
}
