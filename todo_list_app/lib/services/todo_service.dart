import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';

class TodoService {
  static const String _todoKey = 'todos';

  Future<List<Todo>> getTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? todosJson = prefs.getString(_todoKey);

      if (todosJson == null || todosJson.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(todosJson);
      return jsonList
          .map((j) => Todo.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveTodos(List<Todo> todos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String combinedJson =
          json.encode(todos.map((t) => t.toJson()).toList());
      await prefs.setString(_todoKey, combinedJson);
    } catch (e) {
      // Handle error silently in production
    }
  }

  Future<void> addTodo(Todo todo) async {
    final List<Todo> todos = await getTodos();
    todos.add(todo);
    await saveTodos(todos);
  }

  Future<void> updateTodo(Todo updatedTodo) async {
    final List<Todo> todos = await getTodos();
    final int index = todos.indexWhere((todo) => todo.id == updatedTodo.id);
    if (index != -1) {
      todos[index] = updatedTodo;
      await saveTodos(todos);
    }
  }

  Future<void> deleteTodo(String id) async {
    final List<Todo> todos = await getTodos();
    todos.removeWhere((todo) => todo.id == id);
    await saveTodos(todos);
  }

  Future<void> toggleTodo(String id) async {
    final List<Todo> todos = await getTodos();
    final int index = todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final updatedTodo = todos[index].copyWith(
        isCompleted: !todos[index].isCompleted,
        updatedAt: DateTime.now(),
      );
      todos[index] = updatedTodo;
      await saveTodos(todos);
    }
  }
}
