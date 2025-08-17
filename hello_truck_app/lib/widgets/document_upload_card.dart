import 'package:flutter/material.dart';
import 'dart:io';
import 'package:hello_truck_app/widgets/document_viewer.dart';

class DocumentUploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final File? selectedFile;
  final String? uploadedUrl;
  final bool isUploading;
  final VoidCallback onUpload;
  final bool isRequired;

  const DocumentUploadCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selectedFile,
    required this.uploadedUrl,
    required this.isUploading,
    required this.onUpload,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isUploaded = (uploadedUrl != null && uploadedUrl!.trim().isNotEmpty);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isUploaded
              ? colorScheme.secondary
              : colorScheme.outline.withValues(alpha: 0.3),
          width: isUploaded ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(icon, color: colorScheme.secondary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (isRequired)
                            Text(
                              ' *',
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Supports: JPG, PNG, PDF (Max 10MB)',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.secondary.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUploaded)
                  Icon(
                    Icons.check_circle_rounded,
                    color: colorScheme.secondary.withValues(alpha: 0.85),
                    size: 24,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // View/Upload Actions
            Row(
              children: [
                // View Document Button (only show if uploaded)
                if (isUploaded) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showDocumentViewer(
                        context,
                        documentType: title.toLowerCase().replaceAll(' ', '_'),
                        title: title,
                        documentUrl: uploadedUrl,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      label: Text(
                        'View',
                        style: TextStyle(color: colorScheme.secondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Upload/Re-upload Document Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isUploading ? null : onUpload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.secondary.withValues(alpha: 0.85),
                      foregroundColor: colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: isUploading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                colorScheme.onSecondary,
                              ),
                            ),
                          )
                        : Icon(
                            isUploaded
                                ? Icons.upload_file_rounded
                                : Icons.upload_file_rounded,
                            size: 18,
                          ),
                    label: Text(
                      isUploading
                          ? 'Uploading...'
                          : isUploaded
                          ? 'Re-upload'
                          : 'Choose File',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),

            // File info of uploading document
            if (isUploading && selectedFile != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.description_rounded,
                      size: 18,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selected: ${selectedFile?.path.split('/').last}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
