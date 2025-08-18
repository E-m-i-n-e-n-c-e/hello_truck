import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:hello_truck_app/widgets/snackbars.dart';

class DocumentViewer extends ConsumerWidget {
  final String documentType;
  final String title;
  final String? documentUrl;

  const DocumentViewer({
    super.key,
    required this.documentType,
    required this.title,
    this.documentUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _buildDocumentContent(context, ref),
      ),
    );
  }

  Widget _buildDocumentContent(BuildContext context, WidgetRef ref) {
    // If documentUrl is provided, use it directly
    if (documentUrl != null && documentUrl!.isNotEmpty) {
      final bool isPdf = documentUrl!.toLowerCase().contains('.pdf');
      return isPdf
          ? _buildPdfViewer(context, ref, documentUrl!)
          : _buildImageViewer(context, ref, documentUrl!);
    }

    // Otherwise, show error state
    return _buildErrorState(
      context,
      ref,
      'Document not found',
      'The document URL is not available.',
    );
  }

  Widget _buildPdfViewer(BuildContext context, WidgetRef ref, String url) {
    return SfPdfViewer.network(
      url,
      enableDoubleTapZooming: true,
      enableTextSelection: true,
      canShowPaginationDialog: true,
      canShowScrollHead: true,
      canShowScrollStatus: true,
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        // Handle PDF load failure
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.of(context).pop();
            SnackBars.retry(context, 'Failed to load PDF: ${details.description}', () {
              // Refresh the viewer
              Navigator.of(context).pop();
              showDocumentViewer(
                context,
                documentType: documentType,
                title: title,
                documentUrl: documentUrl,
              );
            });
          }
        });
      },
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        debugPrint('PDF loaded successfully: ${details.document.pages.count} pages');
      },
    );
  }

  Widget _buildImageViewer(BuildContext context, WidgetRef ref, String url) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      child: Center(
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Loading image...'),
                ],
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorState(
              context,
              ref,
              'Failed to load document',
              'The document could not be loaded. Please check your internet connection and try again.\n\nError: $error',
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    String title,
    String message,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Retry by closing and reopening
              Navigator.of(context).pop();
              showDocumentViewer(
                context,
                documentType: documentType,
                title: title,
                documentUrl: documentUrl,
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Show document viewer dialog
void showDocumentViewer(
  BuildContext context, {
  required String documentType,
  required String title,
  String? documentUrl,
}) {
  showDialog(
    context: context,
    builder: (context) => DocumentViewer(
      documentType: documentType,
      title: title,
      documentUrl: documentUrl,
    ),
  );
}
