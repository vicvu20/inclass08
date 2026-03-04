import 'package:flutter/material.dart';

import 'database/database_helper.dart';
import 'repositories/folder_repository.dart';
import 'repositories/card_repository.dart';
import 'models/folder.dart';
import 'models/card.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Organizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const FoldersScreen(),
    );
  }
}

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final FolderRepository _folderRepo = FolderRepository();
  final CardRepository _cardRepo = CardRepository();

  List<Folder> _folders = [];
  final Map<int, int> _cardCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() => _loading = true);

    final folders = await _folderRepo.getAllFolders();
    final Map<int, int> counts = {};

    for (final f in folders) {
      if (f.id == null) continue;
      counts[f.id!] = await _cardRepo.getCardCountByFolder(f.id!);
    }

    setState(() {
      _folders = folders;
      _cardCounts
        ..clear()
        ..addAll(counts);
      _loading = false;
    });
  }

  IconData _getSuitIcon(String suit) {
    switch (suit) {
      case 'Hearts':
        return Icons.favorite;
      case 'Diamonds':
        return Icons.diamond;
      case 'Clubs':
        return Icons.local_florist;
      case 'Spades':
        return Icons.change_history; // ✅ no Icons.spade in Flutter
      default:
        return Icons.folder;
    }
  }

  Color? _getSuitColor(String suit) {
    switch (suit) {
      case 'Hearts':
      case 'Diamonds':
        return Colors.red;
      case 'Clubs':
      case 'Spades':
        return Colors.black;
      default:
        return null;
    }
  }

  Future<void> _deleteFolder(Folder folder) async {
    if (folder.id == null) return;

    final count = _cardCounts[folder.id!] ?? 0;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Delete Folder?'),
        content: Text(
          'Delete "${folder.folderName}"?\n\n'
          'This will also delete $count cards in this folder (CASCADE).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _folderRepo.deleteFolder(folder.id!);
      await _loadFolders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${folder.folderName}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Organizer'),
        actions: [
          IconButton(
            onPressed: _loadFolders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95, // ✅ taller so it fits better
              ),
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                final folder = _folders[index];
                final count =
                    (folder.id == null) ? 0 : (_cardCounts[folder.id!] ?? 0);

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CardsScreen(folder: folder),
                        ),
                      );
                      await _loadFolders();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      // ✅ Fix overflow: allow scroll + keep centered when it fits
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getSuitIcon(folder.folderName),
                                    size: 44, // ✅ smaller
                                    color: _getSuitColor(folder.folderName),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    folder.folderName,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16, // ✅ smaller
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$count cards',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  IconButton(
                                    onPressed: () => _deleteFolder(folder),
                                    icon: const Icon(Icons.delete_outline),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    tooltip: 'Delete folder',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class CardsScreen extends StatefulWidget {
  final Folder folder;
  const CardsScreen({super.key, required this.folder});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final CardRepository _cardRepo = CardRepository();
  List<PlayingCard> _cards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _loading = true);
    final folderId = widget.folder.id!;
    final cards = await _cardRepo.getCardsByFolderId(folderId);
    setState(() {
      _cards = cards;
      _loading = false;
    });
  }

  Future<void> _deleteCard(PlayingCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Delete Card?'),
        content: Text('Delete "${card.cardName}" from ${card.suit}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cardRepo.deleteCard(card.id!);
      await _loadCards();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${card.cardName}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.folder.folderName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _cards.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final c = _cards[index];
                return Card(
                  child: ListTile(
                    leading: SizedBox(
                      width: 56,
                      height: 56,
                      child: (c.imageUrl == null || c.imageUrl!.isEmpty)
                          ? const Icon(Icons.image_not_supported)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                c.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image),
                              ),
                            ),
                    ),
                    title: Text(c.cardName),
                    subtitle: Text(c.suit),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteCard(c),
                    ),
                  ),
                );
              },
            ),
    );
  }
}