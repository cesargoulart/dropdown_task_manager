import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_dropdown_screen.dart';

class DropdownManager extends StatefulWidget {
  @override
  _DropdownManagerState createState() => _DropdownManagerState();
}

class _DropdownManagerState extends State<DropdownManager> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> dropdown1Items = [];
  List<String> dropdown2Items = [];
  String? selectedDropdown1;
  String? selectedDropdown2;

  @override
  void initState() {
    super.initState();
    loadDropdownData();
  }

  Future<void> loadDropdownData() async {
    try {
      // Fetch dropdown1 items from Firestore
      final dropdown1Snapshot = await _firestore.collection('dropdown1').get();
      final dropdown2Snapshot = await _firestore.collection('dropdown2').get();

      setState(() {
        dropdown1Items = dropdown1Snapshot.docs
            .map((doc) => doc.data()['name'] as String)
            .toList(); // Collect all 'name' fields
        dropdown2Items = dropdown2Snapshot.docs
            .map((doc) => doc.data()['name'] as String)
            .toList(); // Collect all 'name' fields
      });
    } catch (e) {
      print('Error loading dropdown data: $e');
    }
  }

  Future<void> createTask() async {
    if (selectedDropdown1 == null || selectedDropdown2 == null) return;

    final taskName = 'Task ${DateTime.now().millisecondsSinceEpoch}';
    print('Attempting to create task: $taskName');

    try {
      await _firestore.collection('tasks').add({
        'dropdown1': selectedDropdown1,
        'dropdown2': selectedDropdown2,
        'taskName': taskName,
        'completed': false,
      });
      print('Task created successfully: $taskName');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task created: $taskName')),
      );
    } catch (e) {
      print('Error creating task: $e');
    }
  }

  Future<void> addSubtask(String taskId) async {
    final subtaskName = 'Subtask ${DateTime.now().millisecondsSinceEpoch}';
    try {
      await _firestore
          .collection('tasks')
          .doc(taskId)
          .collection('subtasks')
          .add({'name': subtaskName, 'completed': false});
      print('Subtask added: $subtaskName');
    } catch (e) {
      print('Error adding subtask: $e');
    }
  }

  Future<String?> showEditDialog(BuildContext context, String currentName) async {
    final TextEditingController controller = TextEditingController(text: currentName);

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Name'),
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
    return Column(
      children: [
        // Dropdowns at the top
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: DropdownButton<String>(
                value: selectedDropdown1,
                hint: Text('Dropdown 1'),
                isExpanded: true,
                items: dropdown1Items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDropdown1 = value;
                  });
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: DropdownButton<String>(
                value: selectedDropdown2,
                hint: Text('Dropdown 2'),
                isExpanded: true,
                items: dropdown2Items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDropdown2 = value;
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // "Create Task" button
        ElevatedButton(
          onPressed: () {
            if (selectedDropdown1 != null && selectedDropdown2 != null) {
              createTask();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please select both dropdown values')),
              );
            }
          },
          child: Text('Create Task'),
        ),

        // "Edit Dropdowns" buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditDropdownScreen(dropdownCollection: 'dropdown1'),
                  ),
                );
              },
              child: Text('Edit Dropdown 1'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditDropdownScreen(dropdownCollection: 'dropdown2'),
                  ),
                );
              },
              child: Text('Edit Dropdown 2'),
            ),
          ],
        ),

        // Task List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('tasks').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final taskDocs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['dropdown1'] == selectedDropdown1 &&
                    data['dropdown2'] == selectedDropdown2;
              }).toList();

              if (taskDocs.isEmpty) {
                return Center(child: Text('No tasks found for selected dropdowns'));
              }

              return ListView.builder(
                itemCount: taskDocs.length,
                itemBuilder: (context, index) {
                  final task = taskDocs[index].data() as Map<String, dynamic>;
                  final taskName = task['taskName'] ?? 'Unnamed Task';
                  final completed = task['completed'] ?? false;

                  return ExpansionTile(
                    title: Row(
                      children: [
                        Checkbox(
                          value: completed,
                          onChanged: (bool? value) async {
                            await _firestore
                                .collection('tasks')
                                .doc(taskDocs[index].id)
                                .update({'completed': value});
                          },
                        ),
                        Text(taskName),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            final newName =
                                await showEditDialog(context, taskName);
                            if (newName != null) {
                              await _firestore
                                  .collection('tasks')
                                  .doc(taskDocs[index].id)
                                  .update({'taskName': newName});
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _firestore
                                .collection('tasks')
                                .doc(taskDocs[index].id)
                                .delete();
                          },
                        ),
                      ],
                    ),
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('tasks')
                            .doc(taskDocs[index].id)
                            .collection('subtasks')
                            .snapshots(),
                        builder: (context, subtaskSnapshot) {
                          if (!subtaskSnapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }

                          final subtasks = subtaskSnapshot.data!.docs;

                          return Column(
                            children: [
                              ...subtasks.map((subtaskDoc) {
                                final subtask = subtaskDoc.data()
                                    as Map<String, dynamic>;
                                final subtaskName =
                                    subtask['name'] ?? 'Unnamed Subtask';
                                final subtaskCompleted =
                                    subtask['completed'] ?? false;

                                return Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: ListTile(
                                    leading: Checkbox(
                                      value: subtaskCompleted,
                                      onChanged: (bool? value) async {
                                        await _firestore
                                            .collection('tasks')
                                            .doc(taskDocs[index].id)
                                            .collection('subtasks')
                                            .doc(subtaskDoc.id)
                                            .update({'completed': value});
                                      },
                                    ),
                                    title: Text(subtaskName),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () async {
                                            final newName =
                                                await showEditDialog(
                                                    context, subtaskName);
                                            if (newName != null) {
                                              await _firestore
                                                  .collection('tasks')
                                                  .doc(taskDocs[index].id)
                                                  .collection('subtasks')
                                                  .doc(subtaskDoc.id)
                                                  .update({'name': newName});
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () async {
                                            await _firestore
                                                .collection('tasks')
                                                .doc(taskDocs[index].id)
                                                .collection('subtasks')
                                                .doc(subtaskDoc.id)
                                                .delete();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await addSubtask(taskDocs[index].id);
                                  },
                                  child: Text('Add Subtask'),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
