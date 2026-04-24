import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

class FoundItemService {
  final _fs = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // Android emulator
  static const String baseUrl = 'http://10.0.2.2:8000';

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

  Future<Map<String, dynamic>> searchMatches({
    required String docId,
    required String collection,
    int topK = 5,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/search'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'docId': docId,
        'collection': collection,
        'top_k': topK,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Search failed: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid search response');
    }

    return decoded;
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
      'aiColor': aiColor ?? '',
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
      return docRef.id;
    }

    try {
      final searchResponse = await searchMatches(
        docId: docRef.id,
        collection: 'foundItems',
      );

      final List<dynamic> rawResults =
      (searchResponse['results'] as List<dynamic>? ?? []);

      final topMatches = rawResults.map((e) {
        final item = Map<String, dynamic>.from(e as Map);
        return {
          'docId': item['docId'] ?? '',
          'collection': item['collection'] ?? '',
          'imageUrl': item['imageUrl'] ?? '',
          'similarity': item['similarity'] ?? 0.0,
          'match_label': item['match_label'] ?? '',
          'type': item['type'] ?? '',
          'color': item['color'] ?? '',
          'location': item['location'] ?? '',
          'status': item['status'] ?? '',
        };
      }).toList();

      final hasPotentialMatch = topMatches.any((m) {
        final label = (m['match_label'] ?? '').toString();
        return label == 'strong_match' || label == 'potential_match';
      });

      final bestMatch = topMatches.isNotEmpty ? topMatches.first : null;

      await docRef.update({
        'topMatches': topMatches,
        'potentialMatchesCount': searchResponse['potential_matches_count'] ?? 0,
        'candidatePoolSize': searchResponse['candidate_pool_size'] ?? 0,
        'searchedIn': searchResponse['searched_in'] ?? 'lostItems',
        'topScore': searchResponse['top_score'],
        'avgTop5Score': searchResponse['avg_top5_score'],
        'searchTimeMs': searchResponse['search_time_ms'],
        'hasPotentialMatches': hasPotentialMatch,
        'bestMatchedLostReportId': bestMatch?['docId'],
        'bestMatchedLostImageUrl': bestMatch?['imageUrl'],
        'bestMatchedLostType': bestMatch?['type'],
        'bestMatchedLostColor': bestMatch?['color'],
        'bestMatchedLostLocation': bestMatch?['location'],
        'bestMatchedLostSimilarity': bestMatch?['similarity'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      await docRef.update({
        'topMatches': [],
        'potentialMatchesCount': 0,
        'candidatePoolSize': 0,
        'searchedIn': 'lostItems',
        'topScore': null,
        'avgTop5Score': null,
        'searchTimeMs': null,
        'hasPotentialMatches': false,
        'searchError': e.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    return docRef.id;
  }
}