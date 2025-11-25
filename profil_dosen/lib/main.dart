import 'package:flutter/material.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profil Dosen',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Daftar Dosen'),
          backgroundColor: Colors.blue,
        ),
        body: ListView(
          children: const [
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Dr. Ahmad Fauzi, M.Kom'),
              subtitle: Text('Kecerdasan Buatan'),
              trailing: Icon(Icons.arrow_forward),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Prof. Dr. Siti Rahmawati, M.T.'),
              subtitle: Text('Rekayasa Perangkat lunak'),
              trailing: Icon(Icons.arrow_forward),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Ir. Budi santoso, M.Sc'),
              subtitle: Text('jaringan Komputer'),
              trailing: Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
    );
  }
}
