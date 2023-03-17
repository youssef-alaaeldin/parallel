import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Histogram",
      home: HistogramEqualization(),
    );
  }
}

class HistogramEqualization extends StatefulWidget {
  const HistogramEqualization({super.key});

  @override
  _HistogramEqualizationState createState() => _HistogramEqualizationState();
}

class _HistogramEqualizationState extends State<HistogramEqualization> {
  final String apiUrl = "http://192.168.100.11:5000";
  String? newImage;
  List<dynamic>? newHistogram;
  File? _image;
  double? finalResponse;
  String? message = "";

  final picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  uploadImage() async {
    final request = http.MultipartRequest(
        "POST", Uri.parse("http://192.168.100.11:5000/upload_image"));

    final headers = {"Content-type": "multipart/form-data"};

    request.files.add(http.MultipartFile(
        'image', _image!.readAsBytes().asStream(), _image!.lengthSync(),
        filename: _image!.path.split("/").last));

    request.headers.addAll(headers);

    final response = await request.send();

    http.Response res = await http.Response.fromStream(response);
    final resJson = jsonDecode(res.body);
    message = resJson['message'];
    setState(() {});
  }

  Future<String> getImageUrl(String filename) async {
    var response = await http
        .get(Uri.parse('http://192.168.100.11:5000/get_image/$filename'));
    if (response.statusCode == 200) {
      return 'http://your-flask-server-url/get_image/$filename';
    } else {
      throw Exception('Failed to load image');
    }
  }

  @override
  void initState() {
    super.initState();
    // getNewImage();
    // getNewHistogram();
  }

  bool flag = false;
  @override
  Widget build(BuildContext context) {
    String url;
    var data;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histogram Equalization'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: _image == null
                  ? const Text('No image selected.')
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: SizedBox(
                            height: 250,
                            width: 250,
                            child: Image.file(_image!),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            uploadImage();
                          },
                          child: const Text('Enhance Image'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            url = 'http://192.168.100.11:5000/get_image';
                            data = await getData(url);
                            var decodedData = jsonDecode(data);
                            setState(() {
                              finalResponse = decodedData['time'];
                              flag = true;
                            });
                          },
                          child: const Text('Show time'),
                        ),
                        Visibility(
                          visible: flag,
                          child: Text(
                            finalResponse.toString(),
                          ),
                        ),
                        Center(
                          child: ,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Pick Image',
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
