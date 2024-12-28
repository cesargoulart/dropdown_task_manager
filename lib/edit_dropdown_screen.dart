import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditDropdownScreen extends StatefulWidget {
  final String dropdownCollection;

  const EditDropdownScreen({required this.dropdownCollection, Key? key})
      : super(key: key);

  @override
  _EditDropdownScreenState createState() => _EditDropdownScreenState();
}

class _EditDropdownScreenState extends State<EditDropdownScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();

  Future<void> addOption(String name) async {
    if (name.isEmpty) return;
    print('Attempting to add: $name');
    try {
      await _firestore
          .collection(widget.dropdownCollection)
          .add({'name': name});
      print('Successfully added: $name');
      _controller.clear();
    } catch (e) {
      print('Error adding option: $e');
    }
  }

  Future<void> deleteOption(String docId) async {
    await _firestore.collection(widget.dropdownCollection).doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.dropdownCollection}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Add Option',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => addOption(_controller.text),
                  child: Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore.collection(widget.dropdownCollection).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return ListTile(
                      title: Text(doc['name']),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteOption(doc.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
