// lib/main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'native_share.dart';

// Theme mode controller
final themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

// Monochrome ColorSchemes
final ColorScheme lightMono = const ColorScheme(
  brightness: Brightness.light,
  primary: Colors.black,
  onPrimary: Colors.white,
  secondary: Color(0xFF1A1A1A),
  onSecondary: Colors.white,
  error: Color(0xFFB00020),
  onError: Colors.white,
  background: Colors.white,
  onBackground: Colors.black,
  surface: Colors.white,
  onSurface: Colors.black,
);

final ColorScheme darkMono = const ColorScheme(
  brightness: Brightness.dark,
  primary: Colors.white,
  onPrimary: Colors.black,
  secondary: Color(0xFFE0E0E0),
  onSecondary: Colors.black,
  error: Color(0xFFFF6B6B),
  onError: Colors.black,
  background: Color(0xFF121212),
  onBackground: Colors.white,
  surface: Color(0xFF121212),
  onSurface: Colors.white,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GroceryApp());
}

class GroceryApp extends StatelessWidget {
  const GroceryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Grocery List',
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightMono,
            scaffoldBackgroundColor: lightMono.background,
            visualDensity: VisualDensity.compact,
            appBarTheme: AppBarTheme(
              backgroundColor: lightMono.background,
              foregroundColor: lightMono.onBackground,
              elevation: 0.5,
              surfaceTintColor: Colors.transparent,
            ),
            bottomAppBarTheme: const BottomAppBarThemeData(
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 8,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            listTileTheme: const ListTileThemeData(
              dense: true,
              visualDensity: VisualDensity(horizontal: -2, vertical: -2),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkMono,
            scaffoldBackgroundColor: darkMono.background,
            visualDensity: VisualDensity.compact,
            appBarTheme: AppBarTheme(
              backgroundColor: darkMono.background,
              foregroundColor: darkMono.onBackground,
              elevation: 0.5,
              surfaceTintColor: Colors.transparent,
            ),
            bottomAppBarTheme: const BottomAppBarThemeData(
              color: Color(0xFF0E0E0E),
              surfaceTintColor: Colors.transparent,
              elevation: 8,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            listTileTheme: const ListTileThemeData(
              dense: true,
              visualDensity: VisualDensity(horizontal: -2, vertical: -2),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          home: const HomeScreen(),
        );
      },
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
    _loadList();
  }

  Future<void> _loadList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString('shopping_list');
    if (jsonData != null) {
      final decoded = Map<String, dynamic>.from(json.decode(jsonData));
      setState(() {
        shoppingList = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      });
    }
  }

  Future<void> _saveList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shopping_list', json.encode(shoppingList));
  }

  void _deleteItem(String key) {
    setState(() => shoppingList.remove(key));
    _saveList();
  }

  Future<void> _clearList() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Clear List?"),
        content: const Text("Are you sure you want to clear the entire shopping list?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => shoppingList.clear());
      await _saveList();
    }
  }

  void _showAddItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SingleChildScrollView(
        child: AddItemSheet(
          shoppingList: shoppingList,
          onUpdate: _loadList,
        ),
      ),
    );
  }

  void _showEditList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EditListSheet(
        shoppingList: shoppingList,
        onUpdate: _loadList,
      ),
    );
  }

  Future<void> _shareList() async {
    if (shoppingList.isEmpty) return;
    final content = shoppingList.entries.map((e) => "${e.key} | ${e.value}").join("\n");
    await NativeShare.shareText(content);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF7F7F7);
    final errorColor = Theme.of(context).colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery List'),
        actions: [
          IconButton(
            tooltip: 'Clear all',
            icon: const Icon(Icons.clear, color: Colors.red),
            onPressed: _clearList,
          ),
          // Sun/Moon theme switch
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeMode,
              builder: (context, mode, _) {
                final isDark = mode == ThemeMode.dark;
                return Row(
                  children: [
                    const Icon(Icons.light_mode, size: 18),
                    Switch.adaptive(
                      value: isDark,
                      onChanged: (v) => themeMode.value = v ? ThemeMode.dark : ThemeMode.light,
                      thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                        final dark = isDark;
                        return Icon(dark ? Icons.dark_mode : Icons.light_mode, size: 16);
                      }),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const Icon(Icons.dark_mode, size: 18),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isVeryNarrow = constraints.maxWidth < 360;
            final horizontalPad = isVeryNarrow ? 8.0 : 16.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                  child: shoppingList.isEmpty
                      ? const Center(child: Text('Your list is empty'))
                      : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: shoppingList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final key = shoppingList.keys.elementAt(i);
                      final value = shoppingList[key] ?? '';
                      return Material(
                        color: containerColor,
                        elevation: 0,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          dense: true,
                          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          title: Text(key, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: value.isNotEmpty
                              ? Text(value, maxLines: 1, overflow: TextOverflow.ellipsis)
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: errorColor,
                            onPressed: () => _deleteItem(key),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemSheet,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 64,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              overflowAlignment: OverflowBarAlignment.end,
              spacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _showEditList,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _shareList,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- Add Item Sheet ----------------

class AddItemSheet extends StatefulWidget {
  final Map<String, String> shoppingList;
  final VoidCallback onUpdate;
  const AddItemSheet({
    super.key,
    required this.shoppingList,
    required this.onUpdate,
  });

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shopping_list', json.encode(widget.shoppingList));
  }

  // No-RegExp parser: keep leading-number brands intact,
  // only extract trailing numeric quantity segments with known units.
  MapEntry<String, String> splitNameAndQty(String raw) {
    final s = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (s.isEmpty) return const MapEntry('', '');

    final units = <String>{
      // weights
      'kg','g','gm','gram','grams','mg',
      // volumes
      'l','ml','ltr','litre','litres',
      // pack/grouping
      'pack','packs','packet','packets','pkt',
      'pc','pcs','piece','pieces','dozen',
      'bottle','bottles','can','cans','box','boxes','roll','rolls','bar','bars','sachet',
      // spoons/cups
      'tsp','teaspoon','teaspoons','tbsp','tablespoon','tablespoons',
      'cup','cups','scoop','scoops',
      // pinches/dashes
      'pinch','pinches','dash','dashes',
      // handful variants
      'handful','handfuls','handfull','handfulls','handsful',
    };

    final words = s.split(' ');
    int startOfQty = words.length; // assume no qty
    bool seenNumber = false;

    // Scan from the end to find a trailing numeric segment with units
    for (int i = words.length - 1; i >= 0; i--) {
      final w = words[i];
      final hasNum = w.runes.any((c) => c >= 48 && c <= 57); // 0–9
      final lower = w.toLowerCase();
      final isUnit = units.contains(lower) || lower.startsWith('x') && lower.length > 1 && lower.substring(1).runes.every((c) => c >= 48 && c <= 57);

      if (!seenNumber && (hasNum || isUnit)) {
        startOfQty = i;
        if (hasNum) seenNumber = true;
        continue;
      }
      if (seenNumber && (hasNum || isUnit)) {
        startOfQty = i;
        continue;
      } else if (seenNumber) {
        break;
      }
    }

    if (seenNumber && startOfQty < words.length) {
      final name = words.take(startOfQty).join(' ').trim();
      final qty  = words.skip(startOfQty).join(' ').trim();
      if (name.isNotEmpty) return MapEntry(name, qty);
    }
    // No trailing numeric+unit segment: entire string is the name.
    return MapEntry(s, '');
  }

  Future<void> addItems(String input) async {
    final items = input
        .split(RegExp(r',|\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (final item in items) {
      final parsed = splitNameAndQty(item);
      final key = parsed.key;
      final value = parsed.value;
      widget.shoppingList[key] = value; // overwrite duplicates
    }

    await _save();
    widget.onUpdate();
    _controller.clear();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomPadding =
        MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom + 16;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding, top: 24, left: 16, right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: "Enter items (Name Qty) separated by comma or newline",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ElevatedButton(
          onPressed: () => addItems(_controller.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
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
  const EditListSheet({
    super.key,
    required this.shoppingList,
    required this.onUpdate,
  });

  @override
  State<EditListSheet> createState() => _EditListSheetState();
}

class _EditListSheetState extends State<EditListSheet> {
  final List<Map<String, TextEditingController>> itemControllers = [];
  final List<Map<String, FocusNode>> focusNodes = [];
  final List<GlobalKey> rowKeys = [];
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.shoppingList.forEach((name, value) {
      itemControllers.add({
        "name": TextEditingController(text: name),
        "value": TextEditingController(text: value),
      });
      focusNodes.add({"name": FocusNode(), "value": FocusNode()});
      rowKeys.add(GlobalKey());
    });

    for (int i = 0; i < focusNodes.length; i++) {
      focusNodes[i]["name"]!.addListener(() => _scrollToFocused(i));
      focusNodes[i]["value"]!.addListener(() => _scrollToFocused(i));
    }
  }

  void _scrollToFocused(int index) {
    final nameFocused = focusNodes[index]["name"]!.hasFocus;
    final valueFocused = focusNodes[index]["value"]!.hasFocus;
    if (nameFocused || valueFocused) {
      final contextRow = rowKeys[index].currentContext;
      if (contextRow != null) {
        Scrollable.ensureVisible(
          contextRow,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.3,
        );
      }
    }
  }

  Future<void> saveList() async {
    final Map<String, String> updated = {};
    for (var pair in itemControllers) {
      final name = pair["name"]!.text.trim();
      final value = pair["value"]!.text.trim();
      if (name.isNotEmpty) updated[name] = value;
    }
    widget.shoppingList
      ..clear()
      ..addAll(updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shopping_list', json.encode(widget.shoppingList));
    widget.onUpdate();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes saved successfully!')));
    }
  }

  void deleteItemFromSheet(int index) {
    setState(() {
      itemControllers.removeAt(index);
      focusNodes.removeAt(index);
      rowKeys.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (var nodes in focusNodes) {
      nodes["name"]!.dispose();
      nodes["value"]!.dispose();
    }
    for (var controllers in itemControllers) {
      controllers["name"]!.dispose();
      controllers["value"]!.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom + 16;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Edit Shopping List", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (int i = 0; i < itemControllers.length; i++)
            Padding(
              key: rowKeys[i],
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: TextField(
                      focusNode: focusNodes[i]["name"],
                      controller: itemControllers[i]["name"],
                      decoration: const InputDecoration(
                        labelText: "Item",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: TextField(
                      focusNode: focusNodes[i]["value"],
                      controller: itemControllers[i]["value"],
                      decoration: const InputDecoration(
                        labelText: "Quantity",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteItemFromSheet(i),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: saveList,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                elevation: 0,
              ),
              child: const Text("Save Changes"),
            ),
          ),
        ],
      ),
    );
  }
}
