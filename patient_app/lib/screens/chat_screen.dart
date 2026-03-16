import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/message_model.dart';
import '../services/gemini_service.dart';
import '../services/firebase_service.dart';
import '../widgets/text_message.dart';
import '../widgets/action_buttons.dart';
import '../widgets/checklist_widget.dart';
import '../widgets/pharmacy_selector.dart';
import 'appointment_booking_screen.dart';
import 'pharmacy_screen.dart';
import 'lab_test_screen.dart';
import 'chat_history_screen.dart';

class ChatScreen extends StatefulWidget {
  final String? prefilledSpecialist;
  final String? prefilledMedicines;
  final String? appointmentId;
  final String? existingSessionId; // ← for continuing old chat

  const ChatScreen({
    super.key,
    this.prefilledSpecialist,
    this.prefilledMedicines,
    this.appointmentId,
    this.existingSessionId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _geminiService = GeminiService();
  final _firebaseService = FirebaseService();
  final _uuid = const Uuid();
  final List<ChatMessage> _messages = [];

  late final String _sessionId;
  bool _isLoading = false;
  bool _loadingHistory = false;
  String _currentSpecialist = '';
  int _questionCount = 0;
  bool _sessionSaved = false;

  static const Color _primary = Color(0xFF00C896);
  static const Color _bg = Color(0xFF0D1117);
  static const Color _card = Color(0xFF161B27);
  static const Color _inputBg = Color(0xFF1E2535);
  static const Color _text2 = Color(0xFF8B9EC7);

  @override
  void initState() {
    super.initState();
    // Use existing session or create new one
    _sessionId = widget.existingSessionId ??
        DateTime.now().millisecondsSinceEpoch.toString();

    if (widget.existingSessionId != null) {
      // Load existing chat history from Firebase
      _loadExistingHistory();
    } else {
      if (widget.prefilledSpecialist != null) {
        _currentSpecialist = widget.prefilledSpecialist!;
      }
      _addWelcomeMessage();
    }
  }

  Future<void> _loadExistingHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final snap = await _firebaseService
          .listenToChatMessages(_sessionId)
          .first;

      for (final doc in snap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final sender = d['sender'] == 'user'
            ? SenderType.user
            : SenderType.bot;
        setState(() {
          _messages.add(ChatMessage(
            id: doc.id,
            text: d['text'] ?? '',
            sender: sender,
            type: MessageType.text,
            timestamp: (d['timestamp'] as dynamic)?.toDate() ??
                DateTime.now(),
          ));
        });
      }
      _scrollToBottom();
    } catch (e) {
      print('Load history error: $e');
    }
    setState(() => _loadingHistory = false);
  }

  void _addWelcomeMessage() {
    if (widget.prefilledSpecialist != null) {
      _addBotMessage(
        '👨‍⚕️ Your doctor has recommended a ${widget.prefilledSpecialist} specialist.\n\n'
        '${widget.prefilledMedicines != null ? '💊 Prescribed: ${widget.prefilledMedicines}\n\n' : ''}'
        'I have pre-filled the details for you. Tap the buttons below to book your appointment or order medicines.',
      );
      _showActionButtons({
        'show_appointment': true,
        'show_medicine': widget.prefilledMedicines != null,
        'show_lab_test': true,
        'checklist':
            _getChecklistForSpecialty(widget.prefilledSpecialist!),
        'precautions': [
          'Follow doctor\'s instructions',
          'Take medicines on time'
        ],
      });
    } else {
      _addBotMessage(
        'Hello! I am MediBot 👋\n\n'
        'I am here to help you understand your symptoms and guide you to the right medical care.\n\n'
        'Please describe how you are feeling today.',
      );
    }
  }

  List<String> _getChecklistForSpecialty(String specialty) {
    final checklistMap = {
      'dermatologist': [
        'Note when the skin issue first appeared',
        'Check if rash has changed in size or color',
        'Avoid applying creams before visit',
        'Take photos of affected area',
        'List any new soaps or foods tried recently',
      ],
      'gastroenterologist': [
        'Note stool color (brown=normal, black/red=alert)',
        'Check urine color',
        'Fast for 8 hours if endoscopy is likely',
        'List all current medications',
        'Note bowel movement frequency',
      ],
      'cardiologist': [
        'Check your resting heart rate',
        'Note any chest pain or breathlessness',
        'Bring previous ECG or echo reports',
        'List all heart medications',
        'Avoid caffeine 2 hours before visit',
      ],
    };
    return checklistMap[specialty.toLowerCase()] ??
        [
          'List all your current symptoms',
          'Bring previous medical records',
          'Note duration of each symptom',
          'List all medicines you currently take',
          'Write down questions for the doctor',
        ];
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        text: text,
        sender: SenderType.bot,
        type: MessageType.text,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        text: text,
        sender: SenderType.user,
        type: MessageType.text,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _saveSession(String firstMessage, String lastBotMessage) async {
    // Save session metadata — title = first user message (truncated)
    final title = firstMessage.length > 40
        ? '${firstMessage.substring(0, 40)}...'
        : firstMessage;

    if (!_sessionSaved) {
      await _firebaseService.saveChatSession(
        sessionId: _sessionId,
        title: title,
        lastMessage: lastBotMessage,
      );
      _sessionSaved = true;
    } else {
      await _firebaseService.updateChatSession(
        sessionId: _sessionId,
        lastMessage: lastBotMessage,
      );
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _addUserMessage(text);
    _controller.clear();
    _firebaseService.saveChatMessage(_sessionId, text, 'user');
    setState(() => _isLoading = true);

    final response = await _geminiService.sendMessage(text);
    setState(() => _isLoading = false);

    final botMessage = response['message'] ?? '';
    _addBotMessage(botMessage);
    _firebaseService.saveChatMessage(_sessionId, botMessage, 'bot');

    // Save/update session in Firebase
    await _saveSession(text, botMessage);

    if (response['specialist'] != null &&
        response['specialist'].toString().isNotEmpty) {
      _currentSpecialist = response['specialist'];
    }

    if (response['followup_question'] != null &&
        response['followup_question'].toString().isNotEmpty) {
      _questionCount++;
    }

    if (_questionCount >= 3) {
      response['is_final'] = true;
      response['show_appointment'] = true;
      response['show_medicine'] = true;
      response['show_lab_test'] = true;
      _questionCount = 0;

      if ((response['checklist'] as List?)?.isEmpty ?? true) {
        response['checklist'] =
            _getChecklistForSpecialty(_currentSpecialist);
      }
      if ((response['precautions'] as List?)?.isEmpty ?? true) {
        response['precautions'] = [
          'Avoid self medication',
          'Stay hydrated',
          'Rest well',
        ];
      }
    }

    if (response['is_final'] == true) _showActionButtons(response);
    if ((response['checklist'] as List?)?.isNotEmpty ?? false) {
      _showChecklist(response);
    }
    if ((response['quick_replies'] as List?)?.isNotEmpty ?? false &&
        response['is_final'] != true) {
      _showQuickReplies(response);
    }
  }

  void _showActionButtons(Map<String, dynamic> response) {
    setState(() {
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        text: '',
        sender: SenderType.bot,
        type: MessageType.actionButtons,
        data: response,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _showChecklist(Map<String, dynamic> response) {
    setState(() {
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        text: '',
        sender: SenderType.bot,
        type: MessageType.checklist,
        data: response,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _showQuickReplies(Map<String, dynamic> response) {
    setState(() {
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        text: response['followup_question'] ?? '',
        sender: SenderType.bot,
        type: MessageType.quickReply,
        data: response,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _showPharmacySelector() {
    setState(() {
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        text: '',
        sender: SenderType.bot,
        type: MessageType.pharmacySelector,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _handleAppointmentBooking() async {
    _addBotMessage(
        '🔍 Finding available $_currentSpecialist near you...');
    final doctors = await _firebaseService
        .getDoctorsBySpecialty(_currentSpecialist);

    if (doctors.isEmpty) {
      _addBotMessage(
          'Sorry, no $_currentSpecialist found right now. Please try again later.');
      return;
    }

    String doctorList = '✅ Available Doctors:\n\n';
    for (var doctor in doctors) {
      doctorList +=
          '👨‍⚕️ ${doctor['name']}\n📍 ${doctor['bangalore_location']}\n⭐ ${doctor['rating']} rating\n💰 ₹${doctor['consultation_fee']} consultation\n🎓 ${doctor['experience_years']} yrs exp\n\n';
    }
    _addBotMessage(doctorList);

    setState(() {
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        text: '',
        sender: SenderType.bot,
        type: MessageType.navigateButton,
        data: {
          'label': '📅 Book Appointment',
          'color': 0xFF00C896,
          'screen': 'appointment',
          'doctors': doctors,
          'specialist': _currentSpecialist,
        },
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _handleMedicineOrder() {
    _addBotMessage('Please choose your preferred pharmacy:');
    _showPharmacySelector();
  }

  void _handleLabTest() {
    _addBotMessage('Redirecting you to book a lab test. 🧪');
    setState(() {
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        text: '',
        sender: SenderType.bot,
        type: MessageType.navigateButton,
        data: {
          'label': '🧪 Book Lab Test',
          'color': 0xFFFFB347,
          'screen': 'lab',
        },
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _handlePharmacySelected(String pharmacyName) async {
    _addUserMessage('Selected: $pharmacyName');
    final orderId = await _firebaseService.orderMedicine(
        'Prescribed medicines', pharmacyName, _sessionId);

    if (orderId.isNotEmpty) {
      _addBotMessage(
          '✅ Order confirmed at $pharmacyName!\n\nOrder ID: $orderId\nYour medicines will be delivered soon.\nTrack in Orders section.');
    } else {
      _addBotMessage(
          '✅ Order placed at $pharmacyName!\nYour medicines will be delivered soon.');
    }
  }

  void _resetChat() {
    _geminiService.resetChat();
    setState(() {
      _messages.clear();
      _questionCount = 0;
      _currentSpecialist = '';
      _sessionSaved = false;
    });
    _addWelcomeMessage();
  }

  Widget _buildMessage(ChatMessage message) {
    switch (message.type) {
      case MessageType.text:
        return TextMessageWidget(message: message);

      case MessageType.quickReply:
        return Column(children: [
          TextMessageWidget(message: message),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Wrap(
              spacing: 8,
              children:
                  (message.data?['quick_replies'] as List? ?? [])
                      .map<Widget>((reply) => ActionChip(
                            label: Text(reply.toString(),
                                style:
                                    GoogleFonts.poppins(fontSize: 12)),
                            onPressed: () =>
                                _sendMessage(reply.toString()),
                            backgroundColor: const Color(0xFF1E2535),
                            side: const BorderSide(
                                color: Color(0xFF00C896)),
                            labelStyle: const TextStyle(
                                color: Color(0xFF00C896)),
                          ))
                      .toList(),
            ),
          ),
        ]);

      case MessageType.actionButtons:
        return ActionButtonsWidget(
          showAppointment: message.data?['show_appointment'] ?? false,
          showMedicine: message.data?['show_medicine'] ?? false,
          showLabTest: message.data?['show_lab_test'] ?? false,
          specialist: _currentSpecialist,
          onAppointmentTap: _handleAppointmentBooking,
          onMedicineTap: _handleMedicineOrder,
          onLabTestTap: _handleLabTest,
        );

      case MessageType.checklist:
        return ChecklistWidget(
          items: List<String>.from(message.data?['checklist'] ?? []),
          precautions:
              List<String>.from(message.data?['precautions'] ?? []),
        );

      case MessageType.pharmacySelector:
        return PharmacySelectorWidget(
            onPharmacySelected: _handlePharmacySelected);

      case MessageType.navigateButton:
        final label = message.data?['label'] ?? 'Open';
        final screen = message.data?['screen'] ?? '';
        final color = Color(message.data?['color'] ?? 0xFF00C896);
        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 20),
            ),
            onPressed: () {
              if (screen == 'appointment') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AppointmentBookingScreen(
                      specialist: message.data?['specialist'] ?? '',
                      doctors: List<Map<String, dynamic>>.from(
                          message.data?['doctors'] ?? []),
                    ),
                  ),
                );
              } else if (screen == 'lab') {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LabTestScreen()));
              } else if (screen == 'pharmacy') {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PharmacyScreen()));
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.white),
              ],
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        leading: IconButton(
          icon: const Icon(Icons.history_rounded,
              color: Color(0xFF8B9EC7)),
          tooltip: 'Chat History',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ChatHistoryScreen()),
          ),
        ),
        title: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_outlined,
                color: _primary, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MediBot',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              Text('Healthcare Assistant',
                  style: GoogleFonts.poppins(
                      color: _text2, fontSize: 11)),
            ],
          ),
        ]),
        actions: [
          // New chat button
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: Color(0xFF8B9EC7)),
            tooltip: 'New Chat',
            onPressed: () {
              // Navigate to fresh chat
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const ChatScreen()),
              );
            },
          ),
          // Reset current chat
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Color(0xFF8B9EC7)),
            tooltip: 'Clear Chat',
            onPressed: _resetChat,
          ),
        ],
      ),
      body: Column(children: [
        // Loading history indicator
        if (_loadingHistory)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _primary),
                ),
                const SizedBox(width: 8),
                Text('Loading chat history...',
                    style: GoogleFonts.poppins(
                        color: _text2, fontSize: 12)),
              ],
            ),
          ),

        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: _messages.length,
            itemBuilder: (context, i) =>
                _buildMessage(_messages[i]),
          ),
        ),

        if (_isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Row(children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _primary),
              ),
              const SizedBox(width: 10),
              Text('MediBot is thinking...',
                  style: GoogleFonts.poppins(
                      color: _text2, fontSize: 13)),
            ]),
          ),

        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(
            color: Color(0xFF161B27),
            border: Border(
                top: BorderSide(
                    color: Color(0xFF1E2A42), width: 1)),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Describe your symptoms...',
                  filled: true,
                  fillColor: _inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                maxLines: null,
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(_controller.text),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}