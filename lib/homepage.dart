import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  String? result = "";

  final ImagePicker _picker = ImagePicker();
  Future<void> _getImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await uploadImage(_image!);
    }
  }

  Future<void> _getImageFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await uploadImage(_image!);
    }
  }

  Future<void> uploadImage(File image) async {
    final uri = Uri.parse(
      "https://novascan.onrender.com/analyze",
    ); // Replace with your IP
    final request = http.MultipartRequest("POST", uri);
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await http.Response.fromStream(response);
      final Map<String, dynamic> jsonResponse = json.decode(responseData.body);
      setState(() {
        result = jsonResponse.toString();
      });
      print("Server Response: $jsonResponse");
    } else {
      setState(() {
        result = "Failed to analyze image.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("NovaScan"),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 151, 232, 244),
        foregroundColor: const Color.fromARGB(255, 66, 66, 66),
        elevation: 50,
      ),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Recents'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.import_contacts_outlined),
              title: Text('About US'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image != null)
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromARGB(255, 199, 255, 151),
                  ),
                ),
                child: Image.file(_image!, fit: BoxFit.cover),
              )
            else
              Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(color: Color.fromARGB(9, 133, 119, 109)),
                    ],
                    // // border: Border.all(
                    // //   // color: const Color.fromRGBO(11, 254, 137, 0.175),
                    // // ),
                    // borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  child: const Center(child: Text("No Image Selected")),
                ),
              ),
            const SizedBox(height: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (result != null)
                  Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Text(
                      result!,
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton.icon(
                          onPressed: _getImageFromGallery,
                          icon: Icon(Icons.photo_library),
                          label: const Text("Upload"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: const Color.fromARGB(
                              255,
                              255,
                              255,
                              255,
                            ),
                            shadowColor: Colors.black45,
                            elevation: 6,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton.icon(
                          onPressed: _getImageFromCamera,
                          icon: Icon(Icons.camera_alt),
                          label: const Text("Camera"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: const Color.fromARGB(
                              255,
                              255,
                              255,
                              255,
                            ),
                            shadowColor: Colors.black45,
                            elevation: 6,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
