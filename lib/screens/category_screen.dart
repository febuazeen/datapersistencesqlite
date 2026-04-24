import '../models/category.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _controller = TextEditingController();

  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // ================= LOAD DATA =================
  Future<void> _loadCategories() async {
    try {
      setState(() => _isLoading = true);

      final data = await _dbHelper.getAllCategories();

      setState(() {
        _categories = data;
        _isLoading = false;
      });
    } catch (e) {
      print("ERROR LOAD CATEGORY: $e");

      setState(() => _isLoading = false);
    }
  }

  // ================= TAMBAH =================
  Future<void> _addCategory() async {
    final text = _controller.text.trim();

    if (text.isEmpty) return;

    try {
      await _dbHelper.insertCategory(Category(name: text));

      _controller.clear();

      await _loadCategories(); // 🔥 WAJIB await
    } catch (e) {
      print("ERROR ADD CATEGORY: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal tambah kategori")));
    }
  }

  // ================= HAPUS =================
  Future<void> _deleteCategory(int id) async {
    await _dbHelper.deleteCategory(id);
    _loadCategories();
  }

  // ================= EDIT =================
  Future<void> _editCategory(Category category) async {
    final controller = TextEditingController(text: category.name);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Kategori'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              await _dbHelper.updateCategory(
                Category(id: category.id, name: newName),
              );

              Navigator.pop(context);
              _loadCategories();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Kategori')),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // INPUT + BUTTON
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Nama kategori...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addCategory,
                  child: const Text('Tambah'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // LIST
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _categories.isEmpty
                  ? const Center(child: Text('Belum ada kategori'))
                  : ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];

                        return Card(
                          child: ListTile(
                            title: Text(category.name),

                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editCategory(category),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      _deleteCategory(category.id!),
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
    );
  }
}
