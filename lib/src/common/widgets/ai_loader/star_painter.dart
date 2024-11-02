// ignore_for_file: cascade_invocations

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// //Add this CustomPaint widget to the Widget Tree
// CustomPaint(
//     size: Size(WIDTH, (WIDTH*1).toDouble()), //You can Replace [WIDTH] with your desired width for Custom Paint and height will be calculated automatically
//     painter: AiLoaderPainter(),
// )

//Copy this CustomPainter code to the Bottom of the File
class AiLoaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path_0 = Path();
    path_0.moveTo(size.width * 0.9977563, size.height * 0.4958076);
    path_0.cubicTo(
      size.width * 0.9294874,
      size.height * 0.4958076,
      size.width * 0.8664118,
      size.height * 0.4828798,
      size.width * 0.8063966,
      size.height * 0.4573950,
    );
    path_0.cubicTo(
      size.width * 0.7463462,
      size.height * 0.4310714,
      size.width * 0.6933723,
      size.height * 0.3951975,
      size.width * 0.6489613,
      size.height * 0.3507824,
    );
    path_0.cubicTo(
      size.width * 0.6045462,
      size.height * 0.3063664,
      size.width * 0.5686723,
      size.height * 0.2533975,
      size.width * 0.5423546,
      size.height * 0.1933521,
    );
    path_0.cubicTo(
      size.width * 0.5168588,
      size.height * 0.1333176,
      size.width * 0.5039370,
      size.height * 0.07023815,
      size.width * 0.5039370,
      size.height * 0.001961202,
    );
    path_0.cubicTo(
      size.width * 0.5039370,
      size.height * 0.0008770924,
      size.width * 0.5030597,
      0,
      size.width * 0.5019756,
      0,
    );
    path_0.cubicTo(
      size.width * 0.5008916,
      0,
      size.width * 0.5000143,
      size.height * 0.0008770924,
      size.width * 0.5000143,
      size.height * 0.001961202,
    );
    path_0.cubicTo(
      size.width * 0.5000143,
      size.height * 0.07022723,
      size.width * 0.4866723,
      size.height * 0.1332958,
      size.width * 0.4603546,
      size.height * 0.1933521,
    );
    path_0.cubicTo(
      size.width * 0.4348538,
      size.height * 0.2533975,
      size.width * 0.3994050,
      size.height * 0.3063664,
      size.width * 0.3549891,
      size.height * 0.3507824,
    );
    path_0.cubicTo(
      size.width * 0.3105840,
      size.height * 0.3951975,
      size.width * 0.2576101,
      size.height * 0.4310664,
      size.width * 0.1975706,
      size.height * 0.4573840,
    );
    path_0.cubicTo(
      size.width * 0.1375303,
      size.height * 0.4828798,
      size.width * 0.07443975,
      size.height * 0.4958126,
      size.width * 0.006162874,
      size.height * 0.4958126,
    );
    path_0.cubicTo(
      size.width * 0.005078773,
      size.height * 0.4958126,
      size.width * 0.004201681,
      size.height * 0.4966899,
      size.width * 0.004201681,
      size.height * 0.4977739,
    );
    path_0.cubicTo(
      size.width * 0.004201681,
      size.height * 0.4988580,
      size.width * 0.005078773,
      size.height * 0.4997353,
      size.width * 0.006162874,
      size.height * 0.4997353,
    );
    path_0.cubicTo(
      size.width * 0.07442345,
      size.height * 0.4997353,
      size.width * 0.1375143,
      size.height * 0.5130765,
      size.width * 0.1975706,
      size.height * 0.5394008,
    );
    path_0.cubicTo(
      size.width * 0.2576210,
      size.height * 0.5649126,
      size.width * 0.3105899,
      size.height * 0.6003613,
      size.width * 0.3549891,
      size.height * 0.6447605,
    );
    path_0.cubicTo(
      size.width * 0.3994050,
      size.height * 0.6891866,
      size.width * 0.4348588,
      size.height * 0.7421504,
      size.width * 0.4603597,
      size.height * 0.8022118,
    );
    path_0.cubicTo(
      size.width * 0.4866723,
      size.height * 0.8622353,
      size.width * 0.5000143,
      size.height * 0.9252857,
      size.width * 0.5000143,
      size.height * 0.9935462,
    );
    path_0.cubicTo(
      size.width * 0.5000143,
      size.height * 0.9946303,
      size.width * 0.5008916,
      size.height * 0.9955126,
      size.width * 0.5019756,
      size.height * 0.9955126,
    );
    path_0.cubicTo(
      size.width * 0.5030597,
      size.height * 0.9955126,
      size.width * 0.5039370,
      size.height * 0.9946303,
      size.width * 0.5039370,
      size.height * 0.9935462,
    );
    path_0.cubicTo(
      size.width * 0.5039370,
      size.height * 0.9252689,
      size.width * 0.5168588,
      size.height * 0.8622185,
      size.width * 0.5423487,
      size.height * 0.8022118,
    );
    path_0.cubicTo(
      size.width * 0.5686723,
      size.height * 0.7421504,
      size.width * 0.6045403,
      size.height * 0.6891765,
      size.width * 0.6489613,
      size.height * 0.6447605,
    );
    path_0.cubicTo(
      size.width * 0.6933613,
      size.height * 0.6003504,
      size.width * 0.7463244,
      size.height * 0.5649017,
      size.width * 0.8063966,
      size.height * 0.5393950,
    );
    path_0.cubicTo(
      size.width * 0.8664286,
      size.height * 0.5130824,
      size.width * 0.9294958,
      size.height * 0.4997353,
      size.width * 0.9977563,
      size.height * 0.4997353,
    );
    path_0.cubicTo(
      size.width * 0.9988403,
      size.height * 0.4997353,
      size.width * 0.9997143,
      size.height * 0.4988580,
      size.width * 0.9997143,
      size.height * 0.4977739,
    );
    path_0.cubicTo(
      size.width * 0.9997143,
      size.height * 0.4966899,
      size.width * 0.9988403,
      size.height * 0.4958076,
      size.width * 0.9977563,
      size.height * 0.4958076,
    );
    path_0.close();

    final paint0Fill = Paint()..style = PaintingStyle.fill;
    paint0Fill.shader = ui.Gradient.linear(
        Offset(size.width * 0.3140294, size.height * 0.6434849),
        Offset(size.width * 0.7643630, size.height * 0.2638034), [
      const Color(0xff217BFE).withOpacity(1),
      const Color(0xff078EFB).withOpacity(1),
      const Color(0xffA190FF).withOpacity(1),
      const Color(0xffBD99FE).withOpacity(1),
    ], [
      0,
      0.27,
      0.776981,
      1,
    ]);
    canvas.drawPath(path_0, paint0Fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
