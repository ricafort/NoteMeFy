import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notemefy/presentation/widgets/throw_action_area.dart';
import 'package:notemefy/services/haptic_service.dart';
import 'package:notemefy/services/font_settings_service.dart';
import 'package:notemefy/services/geofence_service.dart';
import 'package:notemefy/presentation/screens/review_screen.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // TUTORIAL: The "Zero-UI" experience relies on the keyboard appearing the millisecond the app opens.
    // By requesting focus in the post-frame callback, we bypass typical Flutter route transition delays
    // and force the natively-backed keyboard to display instantly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
      ref.read(geofenceServiceProvider).initialize();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clearAndReset() {
    _textController.clear();
    FocusScope.of(context).requestFocus(_focusNode);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(fontSettingsProvider);
    return GestureDetector(
      // Allow swiping down to dismiss keyboard and go to Review Screen
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! > 300) {
          _focusNode.unfocus();
          ref.read(hapticServiceProvider).click();
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const ReviewScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, -1.0);
                const end = Offset.zero;
                const curve = Curves.easeOutCubic;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(position: animation.drive(tween), child: child);
              },
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black, // AMOLED Black
        body: SafeArea(
          child: Column(
            children: [
              // Subtle hint
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Swipe down to review',
                      style: TextStyle(
                        color: Colors.white54, 
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white54,
                      size: 16,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    maxLines: null, // Grows infinitely
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    autofocus: true, // Auto-focus on entry
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: settings.fontSize,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    cursorColor: Colors.blueAccent,
                    cursorWidth: 3,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Type an idea...',
                      hintStyle: TextStyle(
                        color: Colors.white24,
                        fontSize: settings.fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              // The interactive area right above the keyboard
              ThrowActionArea(
                textController: _textController,
                onThrowComplete: _clearAndReset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
