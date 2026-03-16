import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/message_model.dart';

class TextMessageWidget extends StatelessWidget {
  final ChatMessage message;
  const TextMessageWidget({super.key, required this.message});

  static const Color _primary = Color(0xFF00C896);
  static const Color _userBubble = Color(0xFF00C896);
  static const Color _botBubble = Color(0xFF161B27);
  static const Color _botBorder = Color(0xFF1E2A42);

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == SenderType.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: _primary, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? _userBubble : _botBubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(color: _botBorder, width: 1),
              ),
              child: Text(
                message.text,
                style: GoogleFonts.poppins(
                  color: isUser ? Colors.white : Colors.white,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline,
                  color: _primary, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}
