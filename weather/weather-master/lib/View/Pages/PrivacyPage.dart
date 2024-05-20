import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PrivacyPage extends StatelessWidget {
  void _downloadFile(BuildContext context) async {
    final Dio dio = Dio();

    try {
      // Get the external storage directory
      Directory? directory = await getApplicationDocumentsDirectory();
      if (directory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get the download directory')),
        );
        return;
      }

      String filePath = '${directory.path}/privacy_policy.pdf';
      String fileUrl = 'https://www.example.com/privacy_policy.pdf'; // URL of the file to download

      await dio.download(fileUrl, filePath);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File downloaded to $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Privacy',style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff060720),
      ),
      backgroundColor: const Color(0xff060720),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy Information',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              'This is some information about the privacy policy...',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _downloadFile(context),
              child: Text('Download File'),
            ),
          ],
        ),
      ),
    );
  }
}
