// lib/AI_services/found_item_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FoundItemService {
  final _fs = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<String> uploadImage(File image) async {
    final name = 'found_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('found_items/$name');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<void> saveFoundItem({
    required String type,
    required String color,
    required String description,
    required String foundLocation,
    required DateTime foundAt,
    required String storageLocation,
    required String imageUrl,
    List<String>? aiTypes,
    String? aiColor,
  }) async {
    await _fs.collection('found_items').add({
      'type': type,
      'color': color,
      'description': description,
      'foundLocation': foundLocation,
      'foundAt': Timestamp.fromDate(foundAt),
      'storageLocation': storageLocation,
      'imageUrl': imageUrl,
      'status': 'pending',
      'aiTypes': aiTypes ?? [],
      'aiColor': aiColor,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
