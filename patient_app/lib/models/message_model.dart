enum SenderType { user, bot }

enum MessageType {
  text,
  quickReply,
  actionButtons,
  checklist,
  pharmacySelector,
  navigateButton, // NEW: button that navigates to a screen
}

class ChatMessage {
  final String id;
  final String text;
  final SenderType sender;
  final MessageType type;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.type,
    this.data,
    required this.timestamp,
  });
}
