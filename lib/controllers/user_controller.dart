import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserController with ChangeNotifier {
  final List<UserModel> _users = [
    UserModel(
      id: '1',
      name: 'Irma',
      username: 'irma123',
      email: 'irma@example.com',
      role: 'Admin',
      password: 'password123',
      profileImage: 'assets/images/profile1.png',
    ),
    UserModel(
      id: '2',
      name: 'Sindy',
      username: 'sindy456',
      email: 'sindy@example.com',
      role: 'User',
      password: 'password456',
      profileImage: 'assets/images/profile2.png',
    ),
    UserModel(
      id: '3',
      name: 'Wily',
      username: 'wily789',
      email: 'wily@example.com',
      role: 'User',
      password: 'password789',
      profileImage: 'assets/images/profile3.png',
    ),
  ];

  List<UserModel> get users => [..._users];

  void addUser(UserModel user) {
    _users.add(user);
    notifyListeners();
  }

  void updateUser(String id, UserModel updatedUser) {
    final index = _users.indexWhere((user) => user.id == id);
    if (index != -1) {
      _users[index] = updatedUser;
      notifyListeners();
    }
  }

  void deleteUser(String id) {
    _users.removeWhere((user) => user.id == id);
    notifyListeners();
  }
}
