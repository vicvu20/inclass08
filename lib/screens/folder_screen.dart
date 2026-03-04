import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../repositories/card_repository.dart';
import '../repositories/folder_repository.dart';
import 'cards_screen.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final FolderRepository _folderRepo = FolderRepository();
  final CardRepository _cardRepo = CardRepository();

  List<Folder> _folders = [];
  final Map<int, int> _counts = {};
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
      _counts
        ..clear()
        ..addAll(counts);
      _loading = false;
    });
  }

  Future<void> _deleteFolder(Folder folder) async {
    final id = folder.id;
    if (id == null) return;

    final cardCount = _counts[id] ?? 0;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Delete Folder?'),
        content: Text(
          'Delete "${folder.folderName}"?\n\n'
          'This will also delete $cardCount cards in this folder (CASCADE).',
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
      await _folderRepo.deleteFolder(id);
      await _loadFolders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${folder.folderName}')),
      );
    }
  }

  IconData _getSuitIcon(String suitName) {
    switch (suitName) {
      case 'Hearts':
        return Icons.favorite;
      case 'Diamonds':
        return Icons.diamond;
      case 'Clubs':
        return Icons.local_florist;
      case 'Spades':
        return Icons.spade;
      default:
        return Icons.folder;
    }
  }

  Color? _getSuitColor(String suitName) {
    switch (suitName) {
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
                childAspectRatio: 1.15,
              ),
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                final folder = _folders[index];
                final id = folder.id ?? -1;
                final count = _counts[id] ?? 0;

                return Card(
                  elevation: 2,
                  child: InkWell(
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getSuitIcon(folder.folderName),
                            size: 56,
                            color: _getSuitColor(folder.folderName),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            folder.folderName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('$count cards'),
                          const SizedBox(height: 6),
                          IconButton(
                            onPressed: () => _deleteFolder(folder),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}