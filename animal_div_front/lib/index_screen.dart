import 'dart:io';
import 'package:animal_div_front/image_input.dart';
import 'package:flutter/material.dart';

class IndexScreen extends StatelessWidget {
  final File? pickedImage;

  const IndexScreen({super.key, this.pickedImage});

  void _selectImage(File pickedImage) {
    pickedImage = pickedImage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SEE ANIMAL'),
      ),
      body: ImageInput(_selectImage),
    );
  }
}