import 'package:flutter/material.dart';
import '../data/dosen_data.dart';
import 'dosen_detail_page.dart';

class DosenListPage extends StatelessWidget {
  const DosenListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dosenList = DosenData.getDosenList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Dosen',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: ListView.builder(
          itemCount: dosenList.length,
          itemBuilder: (context, index) {
            final dosen = dosenList[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue[100],
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.blue[700],
                      size: 30,
                    ),
                  ),
                  title: Text(
                    dosen.nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        dosen.jabatan,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        dosen.bidang,
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DosenDetailPage(dosen: dosen),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
