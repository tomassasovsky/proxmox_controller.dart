import 'package:dotenv/dotenv.dart';

class Environment {
  const Environment({
    required this.proxmoxUsername,
    required this.proxmoxPassword,
  });

  factory Environment.fromDotEnv() {
    final env = DotEnv()..load();
    final proxmoxPassword = env['PROXMOX_PASSWORD']!;
    final proxmoxUsername = env['PROXMOX_USERNAME']!;

    return Environment(
      proxmoxUsername: proxmoxUsername,
      proxmoxPassword: proxmoxPassword,
    );
  }

  final String proxmoxUsername;
  final String proxmoxPassword;
}
