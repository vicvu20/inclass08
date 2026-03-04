import 'package:flutter/material.dart';
import '../models/card.dart';
import '../models/folder.dart';
import '../repositories/card_repository.dart';
import 'edit_card_screen.dart';

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

  Future<void> _openEdit({PlayingCard? card}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditCardScreen(
          folder: widget.folder,
          existing: card,
        ),
      ),
    );
    await _loadCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folder.folderName),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEdit(card: null),
        child: const Icon(Icons.add),
      ),
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
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _openEdit(card: c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteCard(c),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}