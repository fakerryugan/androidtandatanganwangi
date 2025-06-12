import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:android/api/token.dart';

class QrOverlay extends StatefulWidget {
  final String data;
  final bool locked;
  final VoidCallback onLock;
  final Function(Offset) onDragEnd;
  final Function(double)? onResize;
  final double initialSize;

  const QrOverlay({
    super.key,
    required this.data,
    required this.locked,
    required this.onLock,
    required this.onDragEnd,
    this.onResize,
    this.initialSize = 100,
  });

  @override
  State<QrOverlay> createState() => _QrOverlayState();
}

class _QrOverlayState extends State<QrOverlay> {
  late double _size;

  @override
  void initState() {
    super.initState();
    _size = widget.initialSize;
  }

  void _updateSize(double delta) {
    setState(() {
      _size += delta;
      _size = _size.clamp(60, 300);
    });

    if (widget.onResize != null) {
      widget.onResize!(_size);
    }
  }

  Widget qrBox() {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        color: Colors.white,
      ),
      child: QrImageView(
        data: '$baseUrl/signature/view-from-payload?payload=${widget.data}',
        version: QrVersions.auto,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.locked) {
      return qrBox();
    }

    return Draggable(
      feedback: qrBox(),
      childWhenDragging: const SizedBox(),
      onDraggableCanceled: (_, offset) => widget.onDragEnd(offset),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          qrBox(),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: widget.onLock,
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.red,
                child: Icon(Icons.check, size: 16, color: Colors.white),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onPanUpdate: (details) => _updateSize(details.delta.dx),
              child: const Icon(Icons.open_in_full, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
