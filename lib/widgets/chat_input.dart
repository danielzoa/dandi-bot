import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class ChatInput extends StatefulWidget {
  const ChatInput({super.key, required this.onSend, this.enabled = true});

  final ValueChanged<String> onSend;
  final bool enabled;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final value = _controller.text.trim();
    if (value.isEmpty || !widget.enabled) return;
    widget.onSend(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter, control: true):
            _SendChatIntent(),
      },
      child: Actions(
        actions: {
          _SendChatIntent: CallbackAction<_SendChatIntent>(
            onInvoke: (intent) {
              _send();
              return null;
            },
          ),
        },
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Faça uma pergunta...',
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 10),
            Tooltip(
              message: 'Enviar mensagem (Ctrl+Enter)',
              child: FilledButton(
                onPressed: widget.enabled ? _send : null,
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: AppColors.blue,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(52, 52),
                ),
                child: const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendChatIntent extends Intent {
  const _SendChatIntent();
}
