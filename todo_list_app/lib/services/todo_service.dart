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

      // Simple JSON parsing approach
      final List<Todo> todos = [];
      final String cleanJson =
          todosJson.replaceAll('[', '').replaceAll(']', '');
      final List<String> todoStrings = cleanJson.split('},');

      for (String todoString in todoStrings) {
        try {
          if (!todoString.contains('{')) continue;

          todoString = todoString.trim();
          if (!todoString.endsWith('}')) {
            todoString = '$todoString}';
          }

          final todo = _parseTodoFromString(todoString);
          if (todo != null) {
            todos.add(todo);
          }
        } catch (e) {
          continue;
        }
      }

      return todos;
    } catch (e) {
      return [];
    }
  }

  Todo? _parseTodoFromString(String todoString) {
    try {
      final Map<String, dynamic> json = {};

      // Remove braces
      String content = todoString.replaceAll('{', '').replaceAll('}', '');

      // Split by commas but handle nested structures
      final List<String> pairs = [];
      String currentPair = '';
      bool inQuotes = false;

      for (int i = 0; i < content.length; i++) {
        final char = content[i];
        if (char == '"') inQuotes = !inQuotes;
        if (char == ',' && !inQuotes) {
          pairs.add(currentPair.trim());
          currentPair = '';
        } else {
          currentPair += char;
        }
      }
      if (currentPair.isNotEmpty) {
        pairs.add(currentPair.trim());
      }

      // Parse each key-value pair
      for (final pair in pairs) {
        final colonIndex = pair.indexOf(':');
        if (colonIndex != -1) {
          String key = pair.substring(0, colonIndex).trim().replaceAll('"', '');
          String value =
              pair.substring(colonIndex + 1).trim().replaceAll('"', '');

          if (key == 'isCompleted') {
            json[key] = value.toLowerCase() == 'true';
          } else if (key == 'id' || key == 'title' || key == 'description') {
            json[key] = value;
          } else if (key == 'createdAt' || key == 'updatedAt') {
            try {
              json[key] = DateTime.parse(value);
            } catch (e) {
              json[key] = DateTime.now();
            }
          }
        }
      }

      if (json.containsKey('id') && json.containsKey('title')) {
        return Todo.fromJson(json);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> saveTodos(List<Todo> todos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (todos.isEmpty) {
        await prefs.setString(_todoKey, '[]');
        return;
      }

      final List<String> todoJsonList = [];
      for (final todo in todos) {
        final json = todo.toJson();
        final jsonString = '{'
            '"id":"${json['id']}",'
            '"title":"${json['title']}",'
            '"description":"${json['description']}",'
            '"isCompleted":${json['isCompleted']},'
            '"createdAt":"${json['createdAt']}",'
            '"updatedAt":"${json['updatedAt']}"'
            '}';
        todoJsonList.add(jsonString);
      }

      final String combinedJson = '[${todoJsonList.join(',')}]';
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
