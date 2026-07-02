import 'package:flutter/material.dart';

import '../../core/utils/card_brand_detector.dart';

class CardBrandLogo extends StatelessWidget {
  const CardBrandLogo({
    required this.brand,
    this.height = 28,
    super.key,
  });

  final CardBrand brand;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (brand == CardBrand.unknown) {
      return SizedBox(height: height);
    }

    return SizedBox(
      height: height,
      child: switch (brand) {
        CardBrand.visa => _VisaLogo(height: height),
        CardBrand.mastercard => _MastercardLogo(height: height),
        CardBrand.unknown => const SizedBox.shrink(),
      },
    );
  }
}

class _VisaLogo extends StatelessWidget {
  const _VisaLogo({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: height * 0.35),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F71),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        'VISA',
        style: TextStyle(
          color: Colors.white,
          fontSize: height * 0.45,
          fontWeight: FontWeight.w800,
          fontStyle: FontStyle.italic,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _MastercardLogo extends StatelessWidget {
  const _MastercardLogo({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final circle = height * 0.62;
    return SizedBox(
      height: height,
      width: height * 1.45,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: circle,
              height: circle,
              decoration: const BoxDecoration(
                color: Color(0xFFEB001B),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              width: circle,
              height: circle,
              decoration: const BoxDecoration(
                color: Color(0xFFF79E1B),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
