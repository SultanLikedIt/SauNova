import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class FireService {
  static final _storage = FirebaseStorage.instance;

  static Future<String?> uploadImage(File imageFile, String uid) async {
    try {
      // Compress the image to 85% quality
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        quality: 85,
      );

      if (compressedBytes == null) return null;

      final storageRef = _storage.ref();
      final imagesRef = storageRef.child('images/$uid.jpg');

      final uploadTask = imagesRef.putData(compressedBytes);

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  static Future<void> deleteImage(String uid) async {
    try {
      final storageRef = _storage.ref();
      final imageRef = storageRef.child('images/$uid.jpg');

      await imageRef.delete();
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }
}
