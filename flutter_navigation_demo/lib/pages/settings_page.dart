import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Pengaturan',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              background: Container(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Card(
                margin: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Notifikasi'),
                      subtitle: const Text('Aktifkan notifikasi push'),
                      value: true,
                      onChanged: (value) {},
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Tema Gelap'),
                      subtitle: const Text('Gunakan tema gelap'),
                      value: false,
                      onChanged: (value) {},
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Bahasa'),
                      subtitle: const Text('Indonesia'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Privasi & Keamanan'),
                      leading: Icon(
                        Icons.security,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Bantuan & Dukungan'),
                      leading: Icon(
                        Icons.help,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Tentang Aplikasi'),
                      leading: Icon(
                        Icons.info,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
