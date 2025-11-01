import 'package:flutter/material.dart';
import '../models/templates/template_variable.dart';
import '../models/templates/document_template.dart';

class TemplateVariableDialog extends StatefulWidget {
  final DocumentTemplate template;
  final Map<String, String>? initialValues;

  const TemplateVariableDialog({
    Key? key,
    required this.template,
    this.initialValues,
  }) : super(key: key);

  @override
  State<TemplateVariableDialog> createState() => _TemplateVariableDialogState();
}

class _TemplateVariableDialogState extends State<TemplateVariableDialog> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _values = {};
  final Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  void _initializeValues() {
    // Set default values
    for (final variable in widget.template.variables) {
      _values[variable.name] = widget.initialValues?[variable.name] ?? 
                              variable.defaultValue ?? '';
      _controllers[variable.name] = TextEditingController(
        text: _values[variable.name],
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context),
            
            // Content
            Expanded(
              child: _buildContent(context),
            ),
            
            // Actions
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.description_outlined,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configure Template Variables',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.template.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (widget.template.variables.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('This template has no variables to configure.'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: widget.template.variables.map((variable) {
        return _buildVariableField(context, variable);
      }).toList(),
    );
  }

  Widget _buildVariableField(BuildContext context, TemplateVariable variable) {
    final hasError = _errors.containsKey(variable.name);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Row(
            children: [
              Text(
                variable.displayName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (variable.required) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          
          // Input field
          if (variable.type == VariableType.select && variable.options != null)
            _buildSelectField(context, variable)
          else if (variable.type == VariableType.date)
            _buildDateField(context, variable)
          else
            _buildTextField(context, variable),
          
          // Error message
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _errors[variable.name]!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
          
          // Description
          if (variable.description != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                variable.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context, TemplateVariable variable) {
    final controller = _controllers[variable.name]!;
    final hasError = _errors.containsKey(variable.name);
    
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: variable.placeholder ?? variable.displayName,
        errorText: hasError ? _errors[variable.name] : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: _getKeyboardType(variable.type),
      onChanged: (value) {
        setState(() {
          _values[variable.name] = value;
          _errors.remove(variable.name);
        });
      },
    );
  }

  Widget _buildSelectField(BuildContext context, TemplateVariable variable) {
    final value = _values[variable.name] ?? '';
    
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      decoration: InputDecoration(
        hintText: variable.placeholder ?? 'Select ${variable.displayName}',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: variable.options!.map((option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _values[variable.name] = newValue ?? '';
          _errors.remove(variable.name);
        });
      },
    );
  }

  Widget _buildDateField(BuildContext context, TemplateVariable variable) {
    final controller = _controllers[variable.name]!;
    final value = _values[variable.name] ?? '';
    
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value.isNotEmpty 
            ? DateTime.tryParse(value) ?? DateTime.now()
            : DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        
        if (date != null) {
          setState(() {
            _values[variable.name] = date.toIso8601String().split('T')[0];
            controller.text = _values[variable.name]!;
            _errors.remove(variable.name);
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: variable.placeholder ?? 'Select date',
          suffixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        child: Text(
          value.isNotEmpty 
            ? DateTime.tryParse(value)?.toString().split(' ')[0] ?? value
            : '',
          style: value.isEmpty 
            ? TextStyle(color: Colors.grey[400])
            : null,
        ),
      ),
    );
  }

  TextInputType _getKeyboardType(VariableType type) {
    switch (type) {
      case VariableType.number:
        return TextInputType.number;
      case VariableType.email:
        return TextInputType.emailAddress;
      case VariableType.url:
        return TextInputType.url;
      default:
        return TextInputType.text;
    }
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _validateAndSubmit,
            child: const Text('Use Template'),
          ),
        ],
      ),
    );
  }

  void _validateAndSubmit() {
    _errors.clear();
    bool isValid = true;

    for (final variable in widget.template.variables) {
      final value = _values[variable.name] ?? '';
      
      if (variable.required && value.isEmpty) {
        _errors[variable.name] = '${variable.displayName} is required';
        isValid = false;
        continue;
      }
      
      if (value.isNotEmpty) {
        // Type-specific validation
        switch (variable.type) {
          case VariableType.email:
            if (!value.contains('@') || !value.contains('.')) {
              _errors[variable.name] = 'Please enter a valid email address';
              isValid = false;
            }
            break;
          case VariableType.url:
            if (!value.startsWith('http://') && !value.startsWith('https://')) {
              _errors[variable.name] = 'Please enter a valid URL';
              isValid = false;
            }
            break;
          case VariableType.number:
            if (double.tryParse(value) == null) {
              _errors[variable.name] = 'Please enter a valid number';
              isValid = false;
            }
            break;
          default:
            break;
        }
      }
    }

    if (isValid) {
      Navigator.of(context).pop(_values);
    } else {
      setState(() {});
    }
  }
}

