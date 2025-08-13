import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  String? _desease;
  String? _description;
  bool _isLoading = false;
  final _picker = ImagePicker();
  final API_URL = '${dotenv.env['API_URL']}/upload-image';

  // choix d'image
  Future<void> _pickImage(ImageSource source) async {
    // choix de l'image par gallery ou par camera
    try {
      final PickedFile = await _picker.pickImage(
        source: source,
        maxHeight: 1080,
        maxWidth: 1920,
        imageQuality: 85
      );
      
      if (PickedFile != null) {
        setState(() {
          _image = File(PickedFile.path);
        });
        await _analyseImage();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> sendImage(File image) async {
    final url = Uri.parse(API_URL);

    try {
      final request = http.MultipartRequest('POST', url);
      
      // Ajoute le fichier image
      request.files.add(await http.MultipartFile.fromPath(
        'file',        // le nom du champ attendu par ton API
        image.path,
      ));
      
      // Envoie la requête
      final streamedResponse = await request.send();
      
      // Récupère la réponse
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        print(response.body);
        final data = jsonDecode(response.body);

          setState(() {
            // recuperation du nom de la maladie
            _desease = data['translation'];
            // recuperation des conseils pour traiter la maladie
            _description = data['description'];
          });
      } else {
          throw Exception("Impossible de charger les donnees");
      }
    }  catch (e) {
      _desease = 'Error: $e';
    }
  }


  // fonction d'appel a de l'API
  Future<void> fetchData() async {
    try {
      final response = await http.post(Uri.parse(API_URL));
      
      if (response.statusCode == 200) {
        // recuperation du nom de la maladie
        setState(() {
          _desease = jsonDecode(response.body)['translation'];
        });
        // recuperation des conseils pour traiter la maladie
        setState(() {
          _description = jsonDecode(response.body)['description'];
        });
      }
      else {
        throw Exception("Impossible de charger les donnees");
      }
    } catch (e) {
      _desease = 'Error: $e';
    }
  }

  Future<void> _analyseImage() async {
    if (_image == null) return; 
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await sendImage(_image!);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print(e);

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.green.shade700,
      title: const Text(
        "AI Plant Diseases",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Zone d'affichage de l'image
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: _image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      _image!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : const Center(
                    child: Text(
                      "Aucune image sélectionnée",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
          ),

          const SizedBox(height: 24),

          // Bouton de capture
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text("Prendre une photo"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Zone de résultat
          if (_isLoading)
            Center(
              child: Lottie.asset(
                'assets/animations/plant_scanning.json',
                repeat: true,
                reverse: true,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            )
          else if (_desease != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Maladie détectée :",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    _desease!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                if (_description != null) ...[
                  Text(
                    "Conseil de traitement :",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.brown.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.brown.shade200),
                    ),
                    child: Text(
                      _description!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    ),
  );
}

}