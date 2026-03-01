import 'dart:math';
import 'package:flutter/material.dart';

class VolumeIndicator extends StatefulWidget {
  final bool isStreaming;
  final bool isMuted;

  const VolumeIndicator({
    super.key,
    required this.isStreaming,
    required this.isMuted,
  });

  @override
  State<VolumeIndicator> createState() => _VolumeIndicatorState();
}

class _VolumeIndicatorState extends State<VolumeIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  List<double> _levels = List.generate(5, (_) => 0.2);

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 150),
        )..addListener(() {
          if (widget.isStreaming && !widget.isMuted) {
            setState(() {
              _levels = List.generate(
                5,
                (_) => _random.nextDouble() * 0.8 + 0.2,
              );
            });
          }
        });

    if (widget.isStreaming && !widget.isMuted) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(VolumeIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isStreaming && !widget.isMuted) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
        setState(() {
          _levels = List.generate(5, (_) => 0.2);
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.isMuted ? Icons.mic_off : Icons.mic,
            color: widget.isMuted ? Colors.redAccent : Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                5,
                (index) => Container(
                  width: 3,
                  height: widget.isMuted ? 3 : 16 * _levels[index],
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: widget.isMuted
                        ? Colors.redAccent
                        : Colors.greenAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
