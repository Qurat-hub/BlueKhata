import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/services/supabase_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: ListView(
        children: [

          const SizedBox(height: 12),

          const _SectionTitle("Business"),

          _Tile(
            icon: Icons.store_rounded,
            title: "Business Profile",
            subtitle: "Manage your business information",
            onTap: () {
              context.push(AppRoutes.businessSelection);
            },
          ),

          _Tile(
            icon: Icons.people_alt_rounded,
            title: "Staff",
            subtitle: "Manage employees",
            onTap: () {
              context.push(AppRoutes.staffBook);
            },
          ),

          const Divider(),

          const _SectionTitle("Preferences"),

          _Tile(
            icon: Icons.language_rounded,
            title: "Language",
            subtitle: "English",
            onTap: () {},
          ),

          _Tile(
            icon: Icons.notifications_active_rounded,
            title: "Notifications",
            subtitle: "Manage notification settings",
            onTap: () {},
          ),

          _Tile(
            icon: Icons.dark_mode_rounded,
            title: "Theme",
            subtitle: "System Default",
            onTap: () {},
          ),

          const Divider(),

          const _SectionTitle("Security"),

          _Tile(
            icon: Icons.lock_outline_rounded,
            title: "Change Password",
            subtitle: "Update account password",
            onTap: () {},
          ),

          _Tile(
            icon: Icons.backup_rounded,
            title: "Backup Data",
            subtitle: "Backup your business records",
            onTap: () {},
          ),

          const Divider(),

          const _SectionTitle("Support"),

          _Tile(
            icon: Icons.help_outline_rounded,
            title: "Help Center",
            subtitle: "FAQs & Support",
            onTap: () {},
          ),

          _Tile(
            icon: Icons.info_outline,
            title: "About",
            subtitle: "BlueKhata v1.0",
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "BlueKhata",
                applicationVersion: "1.0.0",
              );
            },
          ),

          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 55),
              ),
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              onPressed: () async {

                await SupabaseService.client.auth.signOut();

                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Icon(icon),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}