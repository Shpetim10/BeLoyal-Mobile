import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A slide-to-confirm widget for high-stakes actions.
class SlideToConfirmWidget extends StatefulWidget {
  const SlideToConfirmWidget({
    super.key,
    required this.onConfirmed,
    this.label = 'Slide to confirm',
    this.height = 60,
    this.isLoading = false,
  });

  final VoidCallback onConfirmed;
  final String label;
  final double height;
  final bool isLoading;

  @override
  State<SlideToConfirmWidget> createState() => SlideToConfirmWidgetState();
}

class SlideToConfirmWidgetState extends State<SlideToConfirmWidget>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0;
  double _maxDrag = 0;
  bool _confirmed = false;

  late final AnimationController _resetController;
  late Animation<double> _resetAnim;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    if (_confirmed || widget.isLoading) return;
    _resetController.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_confirmed || widget.isLoading) return;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0, _maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_confirmed || widget.isLoading) return;

    if (_dragPosition / _maxDrag >= 0.85) {
      // Confirmed!
      setState(() {
        _confirmed = true;
        _dragPosition = _maxDrag;
      });
      widget.onConfirmed();
    } else {
      // Snap back.
      _resetAnim =
          Tween<double>(begin: _dragPosition, end: 0).animate(
            CurvedAnimation(parent: _resetController, curve: Curves.easeOut),
          )..addListener(() {
            setState(() => _dragPosition = _resetAnim.value);
          });
      _resetController.forward(from: 0);
    }
  }

  /// Reset the widget (e.g. after submission error).
  void reset() {
    setState(() {
      _confirmed = false;
      _dragPosition = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final thumbSize = widget.height - 8;
        _maxDrag = constraints.maxWidth - thumbSize - 8;

        final progress = _maxDrag > 0 ? _dragPosition / _maxDrag : 0.0;

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: _confirmed
                ? AppColors.secondary.withValues(alpha: 0.15)
                : AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(widget.height / 2),
            border: Border.all(
              color: _confirmed
                  ? AppColors.secondary.withValues(alpha: 0.3)
                  : AppColors.glassBorder,
            ),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // ── Progress fill ──
              AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                width: _dragPosition + thumbSize + 8,
                height: widget.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(widget.height / 2),
                ),
              ),

              // ── Label ──
              Center(
                child: AnimatedOpacity(
                  opacity: progress < 0.5 ? 1.0 : 1.0 - (progress - 0.5) * 2,
                  duration: const Duration(milliseconds: 50),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 60), // space for thumb
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.textMuted.withValues(alpha: 0.4),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Draggable thumb ──
              Positioned(
                left: _dragPosition + 4,
                child: GestureDetector(
                  onHorizontalDragStart: _onDragStart,
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      gradient: _confirmed
                          ? const LinearGradient(
                              colors: [
                                AppColors.secondary,
                                AppColors.secondaryLight,
                              ],
                            )
                          : AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_confirmed
                                      ? AppColors.secondary
                                      : AppColors.primary)
                                  .withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: widget.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _confirmed
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
