import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditDropdownScreen extends StatefulWidget {
  final String dropdownCollection;

  const EditDropdownScreen({Key? key, required this.dropdownCollection})
      : super(key: key);

  @override
  _EditDropdownScreenState createState() => _EditDropdownScreenState();
}

class _EditDropdownScreenState extends State<EditDropdownScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();
  List<DocumentSnapshot> dropdownItems = [];

  @override
  void initState() {
    super.initState();
    loadDropdownItems();
  }

  Future<void> loadDropdownItems() async {
    try {
      final snapshot =
          await _firestore.collection(widget.dropdownCollection).get();
      setState(() {
        dropdownItems = snapshot.docs;
      });
      print('Dropdown items reloaded');
    } catch (e) {
      print('Error loading dropdown items: $e');
    }
  }

  Future<void> addOption(String name) async {
    if (name.isEmpty) return;
    try {
      await _firestore
          .collection(widget.dropdownCollection)
          .add({'name': name});
      _controller.clear();
      loadDropdownItems(); // Reload items after adding
    } catch (e) {
      print('Error adding option: $e');
    }
  }

  Future<void> editOption(String docId, String newName) async {
    if (newName.isEmpty) return;
    try {
      print('Editing document $docId with new name: $newName');
      await _firestore
          .collection(widget.dropdownCollection)
          .doc(docId)
          .update({'name': newName});
      print('Document updated successfully');
      loadDropdownItems(); // Reload items after editing
    } catch (e) {
      print('Error editing option: $e');
    }
  }

  Future<void> deleteOption(String docId) async {
    try {
      await _firestore
          .collection(widget.dropdownCollection)
          .doc(docId)
          .delete();
      loadDropdownItems(); // Reload items after deleting
    } catch (e) {
      print('Error deleting option: $e');
    }
  }

  Future<String?> showEditDialog(
      BuildContext context, String currentName) async {
    final TextEditingController controller =
        TextEditingController(text: currentName);

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Dropdown Item'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: 'Enter new name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Cancel
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text); // Save
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
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
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Add new option',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => addOption(_controller.text),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: dropdownItems.length,
              itemBuilder: (context, index) {
                final doc = dropdownItems[index];
                final name = doc['name'] ?? 'Unnamed';

                return ListTile(
                  title: Text(name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final newName = await showEditDialog(context, name);
                          if (newName != null) {
                            await editOption(doc.id, newName);
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteOption(doc.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
