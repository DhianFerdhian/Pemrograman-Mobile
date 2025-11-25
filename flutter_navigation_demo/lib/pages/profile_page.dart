import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text('Dhian Kurnia Ferdiansyah Irawan',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Web Developer',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.email,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('Email'),
                      subtitle: const Text('dhiankurniaf99@gmail.com'),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.phone,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('Telepon'),
                      subtitle: const Text('+62 822-8140-0772'),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.location_on,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('Lokasi'),
                      subtitle: const Text('Jambi, Indonesia'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
