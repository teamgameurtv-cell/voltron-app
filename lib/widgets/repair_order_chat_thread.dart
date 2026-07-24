import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/repair_order_message.dart';
import '../providers/repair_order_detail_provider.dart';
import '../theme/voltron_theme.dart';

/// Fil de discussion d'un dossier de réparation, utilisé côté client et côté
/// admin (seul [myRole] change selon qui l'affiche) — indépendant du système
/// de support client général.
class RepairOrderChatThread extends ConsumerStatefulWidget {
  final String orderId;
  final RepairMessageSenderRole myRole;

  const RepairOrderChatThread({
    super.key,
    required this.orderId,
    required this.myRole,
  });

  @override
  ConsumerState<RepairOrderChatThread> createState() =>
      _RepairOrderChatThreadState();
}

class _RepairOrderChatThreadState extends ConsumerState<RepairOrderChatThread> {
  final _bodyController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(repairOrderDetailActionsProvider)
          .markMessagesRead(widget.orderId, widget.myRole);
    });
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendText() async {
    final text = _bodyController.text.trim();
    if (text.isEmpty) return;
    _bodyController.clear();
    await ref
        .read(repairOrderDetailActionsProvider)
        .sendMessage(
          orderId: widget.orderId,
          senderRole: widget.myRole,
          body: text,
        );
    _scrollToBottom();
  }

  Future<void> _attach() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.media,
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file?.bytes == null) return;
    setState(() => _isSending = true);
    try {
      final (url, type) = await ref
          .read(repairOrderDetailActionsProvider)
          .uploadMessageAttachment(widget.orderId, file!.bytes!, file.name);
      await ref
          .read(repairOrderDetailActionsProvider)
          .sendMessage(
            orderId: widget.orderId,
            senderRole: widget.myRole,
            body: '',
            attachmentUrl: url,
            attachmentType: type,
          );
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Échec de l\'envoi : $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(
      repairOrderMessagesProvider(widget.orderId),
    );

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: VoltronColors.electricYellow,
              ),
            ),
            error: (err, _) => Center(
              child: Text(
                'Erreur : $err',
                style: const TextStyle(color: VoltronColors.greyText),
              ),
            ),
            data: (messages) {
              if (messages.isNotEmpty) _scrollToBottom();
              if (messages.isEmpty) {
                return const Center(
                  child: Text(
                    'Aucun message pour ce dossier.',
                    style: TextStyle(color: VoltronColors.greyText),
                  ),
                );
              }
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) => _MessageBubble(
                  message: messages[index],
                  isMine: messages[index].senderRole == widget.myRole,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IconButton(
                onPressed: _isSending ? null : _attach,
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: VoltronColors.electricYellow,
                        ),
                      )
                    : const Icon(
                        Icons.attach_file_rounded,
                        color: VoltronColors.greyText,
                      ),
              ),
              Expanded(
                child: TextField(
                  controller: _bodyController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Écris ton message...',
                    hintStyle: TextStyle(color: VoltronColors.greyText),
                  ),
                  onSubmitted: (_) => _sendText(),
                ),
              ),
              IconButton(
                onPressed: _sendText,
                icon: const Icon(
                  Icons.send_rounded,
                  color: VoltronColors.electricYellow,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final RepairOrderMessage message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: isMine
              ? VoltronColors.electricYellow
              : VoltronColors.cardBlack,
          borderRadius: BorderRadius.circular(VoltronRadii.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isImage && message.attachmentUrl != null)
              GestureDetector(
                onTap: () =>
                    _openFullscreenImage(context, message.attachmentUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(VoltronRadii.sm),
                  child: Image.network(
                    message.attachmentUrl!,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else if (message.isVideo && message.attachmentUrl != null)
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(message.attachmentUrl!),
                  mode: LaunchMode.externalApplication,
                ),
                child: Container(
                  width: 200,
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: VoltronColors.deepBlack,
                    borderRadius: BorderRadius.circular(VoltronRadii.sm),
                  ),
                  child: const Icon(
                    Icons.play_circle_fill_rounded,
                    size: 40,
                    color: VoltronColors.electricYellow,
                  ),
                ),
              ),
            if (message.body.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  message.body,
                  style: TextStyle(
                    color: isMine ? VoltronColors.deepBlack : Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void _openFullscreenImage(BuildContext context, String url) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (context, _, __) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5,
                child: Image.network(url),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
