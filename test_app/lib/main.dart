import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Histogram Equalization',
      home: UploadImageScreen(),
      debugShowCheckedModeBanner: false,
      
    );
  }
}

class UploadImageScreen extends StatefulWidget {
  const UploadImageScreen({super.key});

  @override
  _UploadImageScreenState createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  File? _image;
  String? imageUrl;

  Future<void> _getImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      _image = File(pickedFile!.path);
    });
  }

  Future<void> _uploadImage(BuildContext context) async {
    if (_image == null) {
      return;
    }
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.100.11:5000/upload_image'),
    );
    request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
    var response = await request.send();
    if (response.statusCode == 200) {
      var filename = basename(_image!.path);
      var imageUrl = await getImageUrl(filename);
      print(imageUrl);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImageScreen(imageUrl: imageUrl),
        ),
      );
    } else {
      print('Image upload failed');
    }
  }

  Future<String> getImageUrl(String filename) async {
    var response = await http
        .get(Uri.parse('http://192.168.100.11:5000/get_image/$filename'));
    print(filename);
    if (response.statusCode == 200) {
      return 'http://192.168.100.11:5000/get_image/$filename';
    } else {
      throw Exception('Failed to load image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Histogram Equalization'),
      ),
      body: Center(
        child: _image != null
            ? Column(
               mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.file(_image!),
                  ElevatedButton(
                    onPressed: () {
                      _uploadImage(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    child: const Text('Enhance Image')
                  ),
                ],
              )
            : const Text("No Image Selected"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getImage,
        tooltip: 'Pick Image',
        backgroundColor: Colors.black,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

class ImageScreen extends StatelessWidget {
  final String imageUrl;

  const ImageScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Enhanced Image'),
      ),
      body: Center(
        child: SizedBox(
          height: 200,
          width: 200,
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}
