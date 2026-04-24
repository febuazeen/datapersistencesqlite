import '../models/todo.dart';
import 'category_screen.dart';
import 'todo_form_screen.dart';
import '../models/category.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _isLoading = true;
  String _filter = 'all';
  String _searchKeyword = '';
  int? _selectedCategoryId;
  // checkbox urut berdasarkan deadline
  bool _sortByDeadline = false;

  final TextEditingController _searchController = TextEditingController();

  Set<int> _selectedIds = {};

  List<Map<String, dynamic>> _todos = [];
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  // ================= LOAD =================

  Future<void> _loadTodos() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final todos = await _dbHelper.getTodosWithCategory(
        keyword: _searchKeyword,
        filter: _filter,
        categoryId: _selectedCategoryId,
        sortByDeadline: _sortByDeadline,
      );

      final categories = await _dbHelper.getAllCategories();

      setState(() {
        _todos = todos;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("ERROR LOAD TODO: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ================= ACTION =================

  Future<void> _toggleTodo(Todo todo) async {
    await _dbHelper.toggleTodoStatus(todo.id!, !todo.isDone);
    _loadTodos();
  }

  Future<void> _deleteTodo(int id) async {
    await _dbHelper.deleteTodo(id);
    _loadTodos();
  }

  Future<void> _deleteSelected() async {
    for (int id in _selectedIds) {
      await _dbHelper.deleteTodo(id);
    }

    setState(() {
      _selectedIds.clear();
    });

    _loadTodos();
  }

  Future<void> _navigateToEditForm(Todo todo) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TodoFormScreen(todo: todo)),
    );

    _loadTodos();
  }

  Future<void> _navigateToAddForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TodoFormScreen()),
    );

    _loadTodos();
  }

  // ================= FILTER DIALOG =================
  void _openFilterDialog() {
    String tempFilter = _filter;
    int tempCategory = _selectedCategoryId ?? 0;
    bool tempSortDeadline = _sortByDeadline;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Filter",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ================= STATUS =================
                    const Text(
                      "Status",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      value: tempFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text("Semua")),
                        DropdownMenuItem(value: 'done', child: Text("Selesai")),
                        DropdownMenuItem(value: 'undone', child: Text("Belum")),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          tempFilter = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // ================= KATEGORI =================
                    const Text(
                      "Kategori",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<int>(
                      value: tempCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: 0,
                          child: Text("Semua Kategori"),
                        ),

                        ..._categories.map(
                          (c) => DropdownMenuItem<int>(
                            value: c.id!,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          tempCategory = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // ================= CHECKBOX SORT DEADLINE =================
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Urutkan berdasarkan deadline"),
                      value: tempSortDeadline,
                      onChanged: (value) {
                        setModalState(() {
                          tempSortDeadline = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // ================= BUTTON =================
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _filter = tempFilter;
                            _selectedCategoryId = tempCategory == 0
                                ? null
                                : tempCategory;
                            _sortByDeadline = tempSortDeadline;
                          });

                          Navigator.pop(context);
                          _loadTodos();
                        },
                        child: const Text("Terapkan"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= HELPER =================

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return '${date.day}/${date.month}/${date.year}';
  }

  void _onLongPress(Todo todo) {
    setState(() {
      if (_selectedIds.contains(todo.id)) {
        _selectedIds.remove(todo.id);
      } else {
        _selectedIds.add(todo.id!);
      }
    });
  }

  void _onTap(Todo todo) {
    if (_selectedIds.isNotEmpty) {
      _onLongPress(todo);
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final bool isSelecting = _selectedIds.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSelecting ? '${_selectedIds.length} dipilih' : 'To-Do List',
        ),
        actions: [
          if (!isSelecting)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _openFilterDialog,
            ),

          if (isSelecting)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelected,
            ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ================= SEARCH =================
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari judul...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _searchKeyword = value;
                _loadTodos();
              },
            ),

            const SizedBox(height: 10),

            // ================= LIST =================
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _todos.isEmpty
                  ? const Center(child: Text('Tidak ada data'))
                  : ListView.builder(
                      itemCount: _todos.length,
                      itemBuilder: (context, index) {
                        final map = _todos[index];
                        final todo = Todo.fromMap(map);
                        final categoryName = map['categoryName'];

                        final bool isSelected = _selectedIds.contains(todo.id);

                        return Card(
                          color: isSelected
                              ? Colors.blue.withOpacity(0.2)
                              : null,
                          child: ListTile(
                            onLongPress: () => _onLongPress(todo),
                            onTap: () => _onTap(todo),

                            leading: isSelecting
                                ? Checkbox(
                                    value: isSelected,
                                    onChanged: (_) => _onLongPress(todo),
                                  )
                                : Checkbox(
                                    value: todo.isDone,
                                    onChanged: (_) => _toggleTodo(todo),
                                  ),

                            title: Text(
                              todo.title,
                              style: TextStyle(
                                decoration: todo.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),

                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (todo.description.isNotEmpty)
                                  Text(todo.description),

                                Text(
                                  'Dibuat: ${_formatDate(todo.createdAt)}',
                                  style: const TextStyle(fontSize: 11),
                                ),

                                if (todo.deadline != null)
                                  Text(
                                    'Deadline: ${_formatDate(todo.deadline!)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.red,
                                    ),
                                  ),

                                if (categoryName != null)
                                  Text(
                                    'Kategori: $categoryName',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue,
                                    ),
                                  ),
                              ],
                            ),

                            isThreeLine: true,

                            trailing: isSelecting
                                ? null
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () =>
                                            _navigateToEditForm(todo),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _deleteTodo(todo.id!),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // ================= FLOATING BUTTON =================
      floatingActionButton: isSelecting
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "category",
                  mini: true,
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CategoryScreen()),
                    );

                    _loadTodos();
                  },
                  child: const Icon(Icons.category),
                ),

                const SizedBox(height: 10),

                FloatingActionButton(
                  heroTag: "add",
                  onPressed: _navigateToAddForm,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
    );
  }
}
