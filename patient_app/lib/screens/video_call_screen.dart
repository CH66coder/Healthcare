import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import '../services/firebase_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String roomName;
  final String displayName;
  final String appointmentId;
  final bool isDoctor;

  const VideoCallScreen({
    super.key,
    required this.roomName,
    required this.displayName,
    required this.appointmentId,
    required this.isDoctor,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final _jitsi = JitsiMeet();
  bool _joining = true;
  String _statusMsg = 'Connecting to call...';

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  Future<void> _startCall() async {
    try {
      var options = JitsiMeetConferenceOptions(
        serverURL: 'https://meet.jit.si',
        room: widget.roomName,
        userInfo: JitsiMeetUserInfo(
          displayName: widget.displayName,
          email: '',
        ),
        featureFlags: {
          // Clean UI - hide unnecessary features
          'add-people.enabled': false,
          'calendar.enabled': false,
          'call-integration.enabled': false,
          'car-mode.enabled': false,
          'close-captions.enabled': false,
          'help.enabled': false,
          'invite.enabled': false,
          'kick-out.enabled': !widget.isDoctor,
          'live-streaming.enabled': false,
          'meeting-name.enabled': true,
          'meeting-password.enabled': false,
          'notifications.enabled': false,
          'overflow-menu.enabled': true,
          'pip.enabled': true,
          'raise-hand.enabled': true,
          'recording.enabled': false,
          'server-url-change.enabled': false,
          'settings.enabled': true,
          'share-conference.enabled': false,
          'tile-view.enabled': true,
          'toolbox.alwaysVisible': false,
          'video-mute.enabled': true,
          'video-share.enabled': false,
          'welcomepage.enabled': false,
        },
        configOverrides: {
          'startWithAudioMuted': false,
          'startWithVideoMuted': false,
          'subject': widget.isDoctor
              ? '🩺 Doctor Consultation'
              : '👤 Patient Consultation',
          'prejoinPageEnabled': false,
          'disableDeepLinking': true,
        },
      );

      await _jitsi.join(options, JitsiMeetEventListener(
        conferenceJoined: (url) {
          setState(() {
            _joining = false;
            _statusMsg = 'In call';
          });
          // Update Firestore status → 'active'
          FirebaseFirestore_updateCallStatus(widget.appointmentId, 'active');
        },
        conferenceTerminated: (url, error) {
          // Update Firestore status → 'ended'
          FirebaseFirestore_updateCallStatus(widget.appointmentId, 'ended');
          if (mounted) Navigator.of(context).pop();
        },
        conferenceWillJoin: (url) {
          setState(() => _statusMsg = 'Joining room...');
        },
        participantJoined: (email, name, role, participantId) {
          setState(() => _statusMsg = '$name joined');
        },
        participantLeft: (participantId) {},
        audioMutedChanged: (muted) {},
        videoMutedChanged: (muted) {},
      ));
    } catch (e) {
      setState(() {
        _joining = false;
        _statusMsg = 'Failed to join call: $e';
      });
    }
  }

  void FirebaseFirestore_updateCallStatus(
      String appointmentId, String status) async {
    try {
      await FirebaseService()
          .endVideoCall(appointmentId)
          .catchError((_) {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _jitsi.hangUp();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Jitsi renders on top of this — this is just a loading screen
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.video_call_rounded,
                  color: Color(0xFF6C63FF), size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              widget.isDoctor ? 'Doctor Consultation' : 'Patient Consultation',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Room: ${widget.roomName.substring(0, widget.roomName.length > 20 ? 20 : widget.roomName.length)}...',
              style: GoogleFonts.poppins(
                  color: const Color(0xFF8B9EC7), fontSize: 12),
            ),
            const SizedBox(height: 32),
            if (_joining)
              const CircularProgressIndicator(color: Color(0xFF6C63FF)),
            const SizedBox(height: 16),
            Text(
              _statusMsg,
              style: GoogleFonts.poppins(
                  color: const Color(0xFF8B9EC7), fontSize: 14),
            ),
            const SizedBox(height: 48),
            TextButton.icon(
              onPressed: () {
                _jitsi.hangUp();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.call_end_rounded,
                  color: Color(0xFFFF4757)),
              label: Text('Leave Call',
                  style: GoogleFonts.poppins(color: const Color(0xFFFF4757))),
            ),
          ],
        ),
      ),
    );
  }
}
