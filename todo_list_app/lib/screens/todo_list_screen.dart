import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';
import '../widgets/todo_dialog.dart';

enum FilterType { all, completed, pending }

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final TodoService _todoService = TodoService();
  List<Todo> _todos = [];
  List<Todo> _filteredTodos = [];
  FilterType _currentFilter = FilterType.all;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final todos = await _todoService.getTodos();
    setState(() {
      _todos = todos;
      _applyFilter();
    });
  }

  void _applyFilter() {
    switch (_currentFilter) {
      case FilterType.all:
        _filteredTodos = _todos;
        break;
      case FilterType.completed:
        _filteredTodos = _todos.where((todo) => todo.isCompleted).toList();
        break;
      case FilterType.pending:
        _filteredTodos = _todos.where((todo) => !todo.isCompleted).toList();
        break;
    }
    // Sort by updatedAt descending (newest first)
    _filteredTodos.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> _addTodo() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const TodoDialog(),
    );

    if (result != null &&
        result['title'] != null &&
        result['title']!.isNotEmpty) {
      final newTodo = Todo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: result['title']!,
        description: result['description'] ?? '',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _todoService.addTodo(newTodo);
      _loadTodos();

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todo berhasil ditambahkan!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _editTodo(Todo todo) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => TodoDialog(
        initialTitle: todo.title,
        initialDescription: todo.description,
        isEditing: true,
      ),
    );

    if (result != null &&
        result['title'] != null &&
        result['title']!.isNotEmpty) {
      final updatedTodo = todo.copyWith(
        title: result['title']!,
        description: result['description'] ?? '',
        updatedAt: DateTime.now(),
      );

      await _todoService.updateTodo(updatedTodo);
      _loadTodos();

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todo berhasil diupdate!'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _toggleTodo(Todo todo) async {
    await _todoService.toggleTodo(todo.id);
    _loadTodos();

    // Show status message
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          todo.isCompleted
              ? 'Todo ditandai sebagai belum selesai'
              : 'Todo ditandai sebagai selesai',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _deleteTodo(String id) async {
    await _todoService.deleteTodo(id);
    _loadTodos();

    // Show success message
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todo berhasil dihapus!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showDeleteConfirmation(Todo todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Todo'),
        content: Text('Yakin ingin menghapus "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              _deleteTodo(todo.id);
              Navigator.of(context).pop();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getFilterText() {
    switch (_currentFilter) {
      case FilterType.all:
        return 'Semua';
      case FilterType.completed:
        return 'Selesai';
      case FilterType.pending:
        return 'Belum Selesai';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List App'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Text(
                  'Filter: ${_getFilterText()}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<FilterType>(
                  onSelected: (FilterType result) {
                    setState(() {
                      _currentFilter = result;
                      _applyFilter();
                    });
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<FilterType>>[
                        const PopupMenuItem<FilterType>(
                          value: FilterType.all,
                          child: Row(
                            children: [
                              Icon(Icons.list, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Semua'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<FilterType>(
                          value: FilterType.completed,
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Selesai'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<FilterType>(
                          value: FilterType.pending,
                          child: Row(
                            children: [
                              Icon(
                                Icons.radio_button_unchecked,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 8),
                              Text('Belum Selesai'),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
          ),
        ],
      ),
      body: _filteredTodos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checklist, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _todos.isEmpty
                        ? 'Tidak ada todo'
                        : 'Tidak ada todo dengan filter "${_getFilterText()}"',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  if (_todos.isNotEmpty && _currentFilter != FilterType.all)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _currentFilter = FilterType.all;
                          _applyFilter();
                        });
                      },
                      child: const Text('Tampilkan Semua Todo'),
                    ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _filteredTodos.length,
              itemBuilder: (context, index) {
                final todo = _filteredTodos[index];
                return Dismissible(
                  key: Key(todo.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.blue,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      _showDeleteConfirmation(todo);
                      return false;
                    } else {
                      _editTodo(todo);
                      return false;
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    color: todo.isCompleted ? Colors.grey[100] : null,
                    child: ListTile(
                      leading: Checkbox(
                        value: todo.isCompleted,
                        onChanged: (bool? value) {
                          _toggleTodo(todo);
                        },
                      ),
                      title: Text(
                        todo.title,
                        style: TextStyle(
                          decoration: todo.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: todo.isCompleted ? Colors.grey : Colors.black,
                          fontWeight: todo.isCompleted
                              ? FontWeight.normal
                              : FontWeight.w500,
                        ),
                      ),
                      subtitle: todo.description.isNotEmpty
                          ? Text(
                              todo.description,
                              style: TextStyle(
                                decoration: todo.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: todo.isCompleted
                                    ? Colors.grey
                                    : Colors.black54,
                              ),
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editTodo(todo),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmation(todo),
                          ),
                        ],
                      ),
                      onTap: () => _toggleTodo(todo),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodo,
        tooltip: 'Tambah Todo Baru',
        child: const Icon(Icons.add),
      ),
    );
  }
}
