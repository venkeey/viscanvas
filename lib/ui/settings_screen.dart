import 'package:flutter/material.dart';
import '../services/canvas/canvas_service.dart';

class SettingsScreen extends StatefulWidget {
  final CanvasService service;

  const SettingsScreen({Key? key, required this.service}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Auto-save',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('Enable Auto-save'),
              subtitle: const Text('Automatically save your canvas periodically'),
              value: widget.service.isAutoSaveEnabled,
              onChanged: (value) {
                setState(() {
                  widget.service.setAutoSaveEnabled(value);
                });
              },
              secondary: const Icon(Icons.autorenew),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Save',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.save),
              title: const Text('Save Canvas'),
              subtitle: const Text('Save current canvas to a file'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showSaveDialog(context),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Panel',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.view_sidebar),
              title: const Text('Right Panel Width'),
              subtitle: const Text('Adjust default width of the right panel'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Canvas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.grid_on),
                  title: Text('Show Grid'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.color_lens_outlined),
                  title: Text('Theme'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSaveDialog(BuildContext context) async {
    final controller = TextEditingController(text: 'my_canvas');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Canvas'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'File name',
            hintText: 'Enter file name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await widget.service.saveCanvasToFile(fileName: result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved as: $result')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Save failed: $e')),
          );
        }
      }
    }
  }
}


