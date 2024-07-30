import 'package:flutter/material.dart';

class TextUtil extends StatelessWidget {
  final String text;
  final Color? color;
  final double? size;
  final bool? weight;
  final String? family;

  const TextUtil({
    Key? key,
    required this.text,
    this.size,
    this.color,
    this.weight,
    this.family,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color ?? Colors.white,
        fontSize: size ?? 16,
        fontWeight: weight == null || weight == false ? FontWeight.w600 : FontWeight.w700,
        fontFamily: family ?? 'Times New Roman',
      ),
    );
  }
}
