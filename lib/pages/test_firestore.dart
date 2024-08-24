import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestFirestorePage extends StatelessWidget {
  final CollectionReference courts = FirebaseFirestore.instance.collection('Courts');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firestore Test Page'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: courts.get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.done) {
            List<DocumentSnapshot> documents = snapshot.data!.docs;
            return ListView(
              children: documents.map((doc) => ListTile(title: Text(doc['Name']))).toList(),
            );
          }

          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}