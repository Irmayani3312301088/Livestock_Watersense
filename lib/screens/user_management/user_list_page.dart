import 'package:flutter/material.dart';
import 'user_add_page.dart';
import 'user_edit_page.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({Key? key}) : super(key: key);

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<Map<String, String>> users = [
    {'name': 'Irma', 'imageUrl': 'assets/profile.png'},
    {'name': 'Sindy', 'imageUrl': 'assets/profile.png'},
    {'name': 'Wily', 'imageUrl': 'assets/profile.png'},
  ];

  String searchText = '';

  void _addUser() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserAddPage()),
    );
    if (result != null) {
      setState(() {
        users.add(result);
      });
    }
  }

  void _editUser(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserEditPage(user: users[index])),
    );
    if (result != null) {
      setState(() {
        users[index] = result;
      });
    }
  }

  void _deleteUser(int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: Text('Yakin ingin menghapus ${users[index]['name']}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    users.removeAt(index);
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User berhasil dihapus!'),
                      backgroundColor: Colors.redAccent,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  List<Map<String, String>> get filteredUsers {
    if (searchText.isEmpty) return users;
    return users.where((user) {
      return user['name']!.toLowerCase().contains(searchText.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6FF),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.02),
              // Custom AppBar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Manajemen User',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const CircleAvatar(
                    backgroundImage: AssetImage('assets/profile.png'),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),
              // Search dan Tambah
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari user...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchText = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  ElevatedButton(
                    onPressed: _addUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.015,
                      ),
                    ),
                    child: const Text('Tambah'),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.03),
              // List User
              Expanded(
                child:
                    filteredUsers.isEmpty
                        ? const Center(child: Text('User tidak ditemukan'))
                        : ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: screenHeight * 0.02,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.04,
                                    vertical: screenHeight * 0.015,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundImage: AssetImage(
                                      user['imageUrl']!,
                                    ),
                                    radius: 26,
                                  ),
                                  title: Text(
                                    user['name']!,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: screenWidth * 0.045,
                                    ),
                                  ),
                                  trailing: SizedBox(
                                    width: screenWidth * 0.3,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton(
                                          onPressed:
                                              () => _editUser(
                                                users.indexOf(user),
                                              ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            minimumSize: const Size(50, 36),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 0,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Edit',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        ElevatedButton(
                                          onPressed:
                                              () => _deleteUser(
                                                users.indexOf(user),
                                              ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            minimumSize: const Size(50, 36),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 0,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Hapus',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
