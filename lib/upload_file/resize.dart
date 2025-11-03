import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../api/token.dart';

class ResizableQrCode extends StatefulWidget {
  final Map<String, dynamic> qrData;
  final BoxConstraints constraints;
  final Function(Offset) onDragUpdate;
  final Function(double) onResizeUpdate;
  final VoidCallback onDragEnd;

  const ResizableQrCode({
    super.key,
    required this.qrData,
    required this.constraints,
    required this.onDragUpdate,
    required this.onResizeUpdate,
    required this.onDragEnd,
  });

  @override
  _ResizableQrCodeState createState() => _ResizableQrCodeState();
}

class _ResizableQrCodeState extends State<ResizableQrCode> {
  late double _size;
  late Offset _position;

  @override
  void initState() {
    super.initState();
    _size = widget.qrData['size'];
    _position = widget.qrData['position'];
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final newPosition = _position + details.delta;
            _position = Offset(
              newPosition.dx.clamp(0, widget.constraints.maxWidth - _size),
              newPosition.dy.clamp(0, widget.constraints.maxHeight - _size),
            );
            widget.onDragUpdate(_position);
          });
        },
        onPanEnd: (_) => widget.onDragEnd(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: QrImageView(
                data: "$baseUrl/view/${widget.qrData['sign_token']}",
                size: _size,
              ),
            ),
            Positioned(
              right: -10,
              bottom: -10,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final newSize =
                        _size + (details.delta.dx + details.delta.dy) / 2;
                    _size = newSize.clamp(50.0, 300.0);
                    _position = Offset(
                      _position.dx.clamp(
                        0,
                        widget.constraints.maxWidth - _size,
                      ),
                      _position.dy.clamp(
                        0,
                        widget.constraints.maxHeight - _size,
                      ),
                    );
                    widget.onResizeUpdate(_size);
                  });
                },
                onPanEnd: (_) => widget.onDragEnd(),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.zoom_out_map,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
