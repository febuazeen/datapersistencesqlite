import '../models/todo.dart';
import '../models/category.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class TodoFormScreen extends StatefulWidget {
  final Todo? todo;
  const TodoFormScreen({super.key, this.todo});

  @override
  State<TodoFormScreen> createState() => _TodoFormScreenState();
}

class _TodoFormScreenState extends State<TodoFormScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  DateTime? _selectedDeadline;

  List<Category> _categories = [];
  int? _selectedCategoryId;

  bool get _isEditMode => widget.todo != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();

    if (_isEditMode) {
      _titleController.text = widget.todo!.title;
      _descController.text = widget.todo!.description;
      _selectedCategoryId = widget.todo!.categoryId;

      if (widget.todo!.deadline != null) {
        _selectedDeadline = DateTime.parse(widget.todo!.deadline!);
      }
    }
  }

  Future<void> _loadCategories() async {
    final data = await _dbHelper.getAllCategories();
    setState(() => _categories = data);
  }

  Future<void> _saveTodo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (_isEditMode) {
        final updatedTodo = Todo(
          id: widget.todo!.id,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          createdAt: widget.todo!.createdAt,
          deadline: _selectedDeadline?.toIso8601String(),
          categoryId: _selectedCategoryId,
          isDone: widget.todo!.isDone,
        );
        await _dbHelper.updateTodo(updatedTodo);
      } else {
        final newTodo = Todo(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          createdAt: DateTime.now().toIso8601String(),
          deadline: _selectedDeadline?.toIso8601String(),
          categoryId: _selectedCategoryId,
        );
        await _dbHelper.insertTodo(newTodo);
      }

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Tugas' : 'Tambah Tugas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int?>(
                value: _selectedCategoryId,
                hint: const Text('Pilih Kategori'),
                items: _categories
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedCategoryId = value);
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDeadline == null
                          ? 'Belum ada deadline'
                          : 'Deadline: ${_formatDate(_selectedDeadline!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDeadline ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _selectedDeadline = picked);
                      }
                    },
                    child: const Text('Pilih'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSaving ? null : _saveTodo,
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : Text(_isEditMode ? 'Update' : 'Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
