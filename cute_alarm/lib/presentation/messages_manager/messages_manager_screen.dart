import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/pastel_gradient_background.dart';
import '../../data/datasources/message_local_datasource.dart';
import '../../data/repositories/message_repository_impl.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/usecases/manage_messages_usecase.dart';

class MessagesManagerScreen extends StatefulWidget {
  const MessagesManagerScreen({super.key});

  @override
  State<MessagesManagerScreen> createState() => _MessagesManagerScreenState();
}

class _MessagesManagerScreenState extends State<MessagesManagerScreen> {
  late final ManageMessagesUseCase _useCase;
  List<MessageEntity> _messages = [];
  bool _loading = true;
  bool _showCustomOnly = true;

  @override
  void initState() {
    super.initState();
    _useCase = ManageMessagesUseCase(
      MessageRepositoryImpl(MessageLocalDataSource()),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await _useCase.getAll();
    setState(() {
      _messages = all;
      _loading = false;
    });
  }

  Future<void> _showEditorDialog({MessageEntity? existing}) async {
    final controller = TextEditingController(text: existing?.text ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.creamWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(existing == null ? 'New message' : 'Edit message'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Write something sweet...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    if (existing == null) {
      await _useCase.add(result);
    } else {
      await _useCase.edit(existing.id, result);
    }
    await _load();
  }

  Future<void> _delete(MessageEntity message) async {
    await _useCase.delete(message.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _showCustomOnly
        ? _messages.where((m) => m.isCustom).toList()
        : _messages;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Romantic Messages'),
      ),
      body: PastelGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _FilterChip(
                        label: 'My messages',
                        selected: _showCustomOnly,
                        onTap: () => setState(() => _showCustomOnly = true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FilterChip(
                        label: 'All 200+ messages',
                        selected: !_showCustomOnly,
                        onTap: () => setState(() => _showCustomOnly = false),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryPink,
                        ),
                      )
                    : visible.isEmpty
                        ? Center(
                            child: Text(
                              _showCustomOnly
                                  ? 'You haven\'t added any custom\nmessages yet. Tap + to add one!'
                                  : 'No messages found.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColors.textMuted),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                20, 16, 20, 100),
                            itemCount: visible.length,
                            itemBuilder: (context, index) {
                              final m = visible[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryPink
                                          .withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      m.isUsed
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: AppColors.primaryPink,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        m.text,
                                        style: const TextStyle(
                                          color: AppColors.textDark,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (m.isCustom) ...[
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined,
                                            size: 20,
                                            color: AppColors.textMuted),
                                        onPressed: () =>
                                            _showEditorDialog(existing: m),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.delete_outline,
                                            size: 20,
                                            color: AppColors.heartRed),
                                        onPressed: () => _delete(m),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditorDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryPink : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
