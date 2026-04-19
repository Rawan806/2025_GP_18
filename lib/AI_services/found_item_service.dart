// lib/AI_services/found_item_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

class FoundItemService {
  final _fs = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // عدلي هذا حسب جهازك/السيرفر
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<String> uploadImage(File image) async {
    final name = 'found_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('found_items/$name');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<void> triggerIndexing({
    required String docId,
    required String collection,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/index-item'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'docId': docId,
        'collection': collection,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Indexing failed: ${response.body}');
    }
  }

  Future<String> saveFoundItem({
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
    final now = Timestamp.now();

    final docRef = await _fs.collection('foundItems').add({
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
      'createdAt': now,
      'updatedAt': now,
      'docId': '',
      'id': '',
      'itemCategory': 'found',
      'isIndexed': false,
      'indexStatus': 'pending',
      'indexError': '',
    });

    await docRef.update({
      'docId': docRef.id,
      'id': docRef.id,
    });

    try {
      await triggerIndexing(
        docId: docRef.id,
        collection: 'foundItems',
      );
    } catch (e) {
      await docRef.update({
        'isIndexed': false,
        'indexStatus': 'failed',
        'indexError': e.toString(),
      });
    }

    return docRef.id;
  }
}