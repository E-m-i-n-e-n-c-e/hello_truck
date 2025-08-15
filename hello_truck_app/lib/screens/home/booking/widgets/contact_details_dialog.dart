import 'package:flutter/material.dart';

class ContactDetailsDialog extends StatefulWidget {
  final String addressName;
  final String? initialContactName;
  final String? initialContactPhone;
  final String? initialNoteToDriver;

  const ContactDetailsDialog({
    super.key,
    required this.addressName,
    this.initialContactName,
    this.initialContactPhone,
    this.initialNoteToDriver,
  });

  @override
  State<ContactDetailsDialog> createState() => _ContactDetailsDialogState();
}

class _ContactDetailsDialogState extends State<ContactDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _contactNameController;
  late final TextEditingController _contactPhoneController;
  late final TextEditingController _noteToDriverController;

  @override
  void initState() {
    super.initState();
    _contactNameController = TextEditingController(text: widget.initialContactName ?? '');
    _contactPhoneController = TextEditingController(text: widget.initialContactPhone ?? '');
    _noteToDriverController = TextEditingController(text: widget.initialNoteToDriver ?? '');
  }

  @override
  void dispose() {
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _noteToDriverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact Details',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'For ${widget.addressName}',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),

              // Contact Name
              TextFormField(
                controller: _contactNameController,
                decoration: InputDecoration(
                  labelText: 'Contact Name *',
                  hintText: 'Enter contact person name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Contact name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Contact Phone
              TextFormField(
                controller: _contactPhoneController,
                decoration: InputDecoration(
                  labelText: 'Contact Phone *',
                  hintText: 'Enter phone number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Contact phone is required';
                  }
                  if (value.trim().length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Note to Driver
              TextFormField(
                controller: _noteToDriverController,
                decoration: InputDecoration(
                  labelText: 'Note to Driver (Optional)',
                  hintText: 'Any special instructions...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveContactDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveContactDetails() {
    if (_formKey.currentState!.validate()) {
      final contactDetails = {
        'contactName': _contactNameController.text.trim(),
        'contactPhone': _contactPhoneController.text.trim(),
        'noteToDriver': _noteToDriverController.text.trim(),
      };
      Navigator.pop(context, contactDetails);
    }
  }
}