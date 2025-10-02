import 'package:flutter/material.dart';

// Menambahkan extension clamp untuk Offset agar bisa digunakan di mana saja
extension OffsetClamp on Offset {
  Offset clamp(Offset min, Offset max) {
    return Offset(dx.clamp(min.dx, max.dx), dy.clamp(min.dy, max.dy));
  }
}