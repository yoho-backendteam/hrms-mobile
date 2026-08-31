import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

class SlideActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color baseColor;
  final Color activeColor;
  final Color textColor;
  final VoidCallback onSlideComplete;
  final double height;
  final bool isCompleted;

  const SlideActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onSlideComplete,
    this.baseColor = AppColors.primary,
    this.activeColor = AppColors.primaryDark,
    this.textColor = Colors.white,
    this.height = 54.0,
    this.isCompleted = false,
  });

  @override
  State<SlideActionButton> createState() => _SlideActionButtonState();
}

class _SlideActionButtonState extends State<SlideActionButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _submitted = false;
  late AnimationController _animController;
  late Animation<double> _resetAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_submitted) return;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, double maxDrag) {
    if (_submitted) return;
    if (_dragPosition >= maxDrag * 0.75) {
      // Completed!
      setState(() {
        _dragPosition = maxDrag;
        _submitted = true;
      });
      widget.onSlideComplete();
      // Reset after a brief pause so it can be used again
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _resetSlider();
        }
      });
    } else {
      // Snap back
      _resetAnim = Tween<double>(begin: _dragPosition, end: 0.0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut),
      )..addListener(() {
          setState(() {
            _dragPosition = _resetAnim.value;
          });
        });
      _animController.forward(from: 0.0);
    }
  }

  void _resetSlider() {
    setState(() {
      _dragPosition = 0.0;
      _submitted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final thumbSize = widget.height - 8;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - thumbSize - 8;
        final progress = maxDrag > 0 ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.baseColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: widget.baseColor.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // 1. Progress Fill
              Container(
                width: _dragPosition + thumbSize + 4,
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.baseColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),

              // 2. Sliding Label (fades out as thumb moves right)
              Center(
                child: Opacity(
                  opacity: (1.0 - (progress * 1.3)).clamp(0.0, 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.label,
                        style: AppTextStyles.bodyBold.copyWith(
                          color: widget.baseColor,
                          fontSize: 13.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.double_arrow_rounded,
                        size: 16,
                        color: widget.baseColor.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Draggable Thumb
              Positioned(
                left: _dragPosition + 4,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) =>
                      _onHorizontalDragUpdate(details, maxDrag),
                  onHorizontalDragEnd: (details) =>
                      _onHorizontalDragEnd(details, maxDrag),
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: widget.baseColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.baseColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 20,
                      ),
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
