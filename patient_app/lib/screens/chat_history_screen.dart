import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'chat_screen.dart';

class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key});

  static const Color _primary = Color(0xFF00C896);
  static const Color _bg = Color(0xFF0D1117);
  static const Color _card = Color(0xFF161B27);
  static const Color _border = Color(0xFF1E2A42);
  static const Color _text2 = Color(0xFF8B9EC7);

  @override
  Widget build(BuildContext context) {
    final svc = FirebaseService();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_outlined,
                color: _primary, size: 18),
          ),
          const SizedBox(width: 10),
          Text('MediBot Chats',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ]),
        actions: [
          // New chat button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => _startNewChat(context),
              icon: const Icon(Icons.add_rounded,
                  color: Colors.white, size: 16),
              label: Text('New Chat',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: svc.listenToChatSessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _primary));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded,
                        color: _primary, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text('No chats yet',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Start a new chat with MediBot',
                      style: GoogleFonts.poppins(
                          color: _text2, fontSize: 13)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _startNewChat(context),
                    icon: const Icon(Icons.add_rounded,
                        color: Colors.white),
                    label: Text('Start New Chat',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }

          // Sort by updatedAt client-side
          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final at = (a.data() as Map)['updatedAt'];
              final bt = (b.data() as Map)['updatedAt'];
              if (at == null) return 1;
              if (bt == null) return -1;
              return (bt as Timestamp).compareTo(at as Timestamp);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final sessionId = d['sessionId'] ?? docs[i].id;
              final title = d['title'] ?? 'Chat Session';
              final lastMessage = d['lastMessage'] ?? '';
              final updatedAt = d['updatedAt'] as Timestamp?;

              return Dismissible(
                key: Key(sessionId),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4757).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFFF4757).withOpacity(0.3)),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFFF4757)),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: _card,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: Text('Delete Chat?',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      content: Text(
                          'This will permanently delete this chat session.',
                          style: GoogleFonts.poppins(
                              color: _text2, fontSize: 13)),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, false),
                          child: Text('Cancel',
                              style: GoogleFonts.poppins(
                                  color: _text2)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4757),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                          ),
                          onPressed: () =>
                              Navigator.pop(context, true),
                          child: Text('Delete',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) => svc.deleteChatSession(sessionId),
                child: GestureDetector(
                  onTap: () => _continueChat(context, sessionId, title),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border),
                    ),
                    child: Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: _primary,
                            size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Text(lastMessage,
                                style: GoogleFonts.poppins(
                                    color: _text2, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatDate(updatedAt),
                            style: GoogleFonts.poppins(
                                color: _text2, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          const Icon(Icons.chevron_right_rounded,
                              color: Color(0xFF4A5568), size: 18),
                        ],
                      ),
                    ]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  void _startNewChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  void _continueChat(
      BuildContext context, String sessionId, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(existingSessionId: sessionId),
      ),
    );
  }
}