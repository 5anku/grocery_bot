import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'native_share.dart';

void main() {
  runApp(const GroceryApp());
}

class GroceryApp extends StatelessWidget {
  const GroceryApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Grocery List',
      theme: ThemeData(
        fontFamily: 'Poppins',
        primarySwatch: Colors.green,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, String> shoppingList = {};

  @override
  void initState() {
    super.initState();
    loadList();
  }

  Future<void> loadList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString('shopping_list');
    if (jsonData != null) {
      setState(() {
        shoppingList = Map<String, String>.from(json.decode(jsonData));
      });
    } else {
      setState(() => shoppingList = {});
    }
  }

  Future<void> saveList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shopping_list', json.encode(shoppingList));
  }

  void deleteItem(String key) {
    setState(() {
      shoppingList.remove(key);
    });
    saveList();
  }

  void showAddItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddItemSheet(
        shoppingList: shoppingList,
        onUpdate: loadList,
      ),
    );
  }

  void showEditList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditListSheet(
        shoppingList: shoppingList,
        onUpdate: loadList,
      ),
    );
  }

  void shareList() async {
    if (shoppingList.isEmpty) return;
    final content = shoppingList.entries
        .map((e) => "${e.key} | ${e.value}")
        .join("\n");
    await NativeShare.shareText(content);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 60),
        color: const Color(0xFFEDF2F4),
        child: Column(
          children: [
            const Text(
              "Shopping List",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: shoppingList.isEmpty
                  ? const Center(child: Text("Your list is empty", style: TextStyle(fontSize: 18)))
                  : ListView.separated(
                itemCount: shoppingList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final key = shoppingList.keys.elementAt(index);
                  final value = shoppingList[key]!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: Text(key, style: const TextStyle(fontSize: 18)),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteItem(key),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text("Edit List"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
              onPressed: showEditList,
            ),
            ElevatedButton(
              onPressed: showAddItemSheet,
              style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: Colors.greenAccent,
                  padding: const EdgeInsets.all(20)),
              child: const Icon(Icons.add, size: 32, color: Colors.white),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text("Share List"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
              onPressed: shareList,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Add Item Sheet ----------------
class AddItemSheet extends StatefulWidget {
  final Map<String, String> shoppingList;
  final VoidCallback onUpdate;
  const AddItemSheet({super.key, required this.shoppingList, required this.onUpdate});

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final TextEditingController _controller = TextEditingController();

  Future<void> saveList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shopping_list', json.encode(widget.shoppingList));
  }

  Future<void> addItems(String input) async {
    final items = input.split(RegExp(r',|\n')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    for (final item in items) {
      final parts = item.split(RegExp(r'\s+'));
      final key = parts[0].toLowerCase();
      final value = (parts.length > 1) ? parts.sublist(1).join(" ") : "";
      // duplicates behavior left as-is (overwrite)
      widget.shoppingList[key] = value;
    }

    await saveList();
    widget.onUpdate();
    _controller.clear();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 16, right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
                hintText: "Enter items (Name Qty) separated by comma or newline",
                border: OutlineInputBorder()),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => addItems(_controller.text),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text("Add Items"),
          ),
        ],
      ),
    );
  }
}

// ---------------- Edit List Sheet ----------------
class EditListSheet extends StatefulWidget {
  final Map<String, String> shoppingList;
  final VoidCallback onUpdate;
  const EditListSheet({super.key, required this.shoppingList, required this.onUpdate});

  @override
  State<EditListSheet> createState() => _EditListSheetState();
}

class _EditListSheetState extends State<EditListSheet> {
  late Map<String, TextEditingController> controllers;

  @override
  void initState() {
    super.initState();
    controllers = {for (final e in widget.shoppingList.entries) e.key: TextEditingController(text: e.value)};
  }

  Future<void> saveList() async {
    final Map<String, String> newMap = {};
    controllers.forEach((key, controller) {
      newMap[key] = controller.text;
    });
    widget.shoppingList
      ..clear()
      ..addAll(newMap);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shopping_list', json.encode(widget.shoppingList));
    widget.onUpdate();
  }

  Future<void> deleteItemFromSheet(String key) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Item?"),
        content: Text("Are you sure you want to delete '$key'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        controllers.remove(key);
        widget.shoppingList.remove(key);
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('shopping_list', json.encode(widget.shoppingList));
      widget.onUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = controllers.entries.toList();
    return Container(
      height: 500,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text("Edit Shopping List", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final key = entries[index].key;
                final controller = entries[index].value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(flex: 4, child: Text(key, style: const TextStyle(fontSize: 18))),
                      Expanded(
                        flex: 4,
                        child: TextField(controller: controller, decoration: const InputDecoration(border: OutlineInputBorder())),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteItemFromSheet(key),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: saveList,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            ),
            child: const Text("Save Changes"),
          )
        ],
      ),
    );
  }
}
