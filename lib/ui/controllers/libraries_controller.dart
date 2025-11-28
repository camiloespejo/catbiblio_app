part of '../views/libraries_view.dart';

abstract class LibrariesController extends State<LibrariesView> {
  final List<String> regionsList = regions.values.toList();
  final int screenSizeLimit = 800;

  /// Opens a URL in the default external application.
  /// If the URL cannot be opened, shows a SnackBar with an error message.
  ///
  /// Parameters:
  /// - [url]: The URL to open as a string.
  Future<void> openLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace: $url')),
        );
      }
    }
  }
}
