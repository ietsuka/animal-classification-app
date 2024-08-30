import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;


class ImageInput extends StatefulWidget {
  final Function onSelectImage;

  const ImageInput(this.onSelectImage);

  @override
  _ImageInputState createState() => _ImageInputState();
}

class GPTResponse {
  GPTResponse({
    required this.percentage,
    required this.label,
  });

  double percentage;
  String label;

  factory GPTResponse.fromJson(Map<String, dynamic> json) => GPTResponse(
        percentage: (json["percentage"] as num).toDouble(),
        label: json["label"] as String,
      );

  Map<String, dynamic> toJson() => {
        "percentage": percentage,
        "label": label,
      };
}

class _ImageInputState extends State<ImageInput> {
  File? _storedImage;
  final picker = ImagePicker();
  String resultText = '';
  bool isAnimal = false;
  bool isPredicted = false;
  String label = '';
  double confidence = 0.0;

  Future<void> _takePicture() async {
    final imageFile = await picker.pickImage(source: ImageSource.camera,);
    if (imageFile == null) {
      return;
    }
    setState(() {
      _storedImage = File(imageFile.path);
    });
    predict();
  }


  Future<void> _getImageFromGallery() async {
    final imageFile = await picker.pickImage(source: ImageSource.gallery,);
    if(imageFile == null) {
      return;
    }
    setState(() {
      _storedImage = File(imageFile.path);
    });
    predict();
  }

  Future<void> _clearState() async {
    setState(() {
      isPredicted = false;
      isAnimal = false;
      resultText = "";
      _storedImage = null;
      label = "";
      confidence = 0.0;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  void predict() async {
    List<int> bytes = _storedImage!.readAsBytesSync();
    String base64Image =  base64Encode(bytes);
    Uri url = Uri.parse("http://192.168.2.103:8080/images/");
    
    Map<String, String> headers = {
      'content-type': 'application/json',
    };
    final body = json.encode({'image': base64Image});
    final response = await http.post(url, body: body, headers: headers);
    if (response.statusCode == 200) {
      print("Image uploaded successfully");
    } else {
      print("Failed to upload image: ${response.body}");
    }
    final responseJson = GPTResponse.fromJson(json.decode(response.body));
    double percentage = responseJson.percentage;

    if (percentage > 0.7) {
      setState(() {
        isPredicted = true;
        isAnimal = true;
        resultText = "Animal";
        label = responseJson.label;
        confidence = percentage;
      });
    } else {
      setState(() {
        isPredicted = true;
        isAnimal = false;
        resultText = "Not Animal";
        confidence = percentage;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: size.width,
              height: 480,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(width: 1, color: Colors.grey)
              ),
              child: _storedImage == null 
              ? const Text(
                "No Image Taken",
                textAlign: TextAlign.center,
              )
              : Image.file(
                _storedImage!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            isPredicted 
            ? Stack(
              children: [
                Container(
                  color: isAnimal ? Colors.green : Colors.red,
                  height: 80,
                  padding: const EdgeInsets.all(10),
                  alignment: Alignment.topCenter,
                  child: Text(
                    label,
                    style: GoogleFonts.bungeeInline(
                      textStyle: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  height: 120,
                  alignment: Alignment.bottomCenter,
                  child: CircleAvatar(
                    maxRadius: 35,
                    backgroundColor: isAnimal ? Colors.green : Colors.red,
                    child: Icon(
                      isAnimal ? Icons.check : Icons.question_mark,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            )
            : Container(),
          ],
        ),
        isPredicted
        ? Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.clear), 
              label: const Text('クリア'),
              onPressed: _clearState,
            ),
          ],
        )
        : Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_camera), 
              label: const Text('カメラ'),
              onPressed: _takePicture,
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_library), 
              label: const Text('ギャラリー'),
              onPressed: _getImageFromGallery,
            ),
          ],
        )
        
      ],
    );
  }
}