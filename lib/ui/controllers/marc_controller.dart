part of '../views/marc_view.dart';

abstract class MarcController extends State<MarcView> {
  String? marcData;
  String? formattedMarcData;
  bool isLoading = true;
  bool isError = false;
  final int screenSizeLimit = 800;

  @override
  void initState() {
    super.initState();
    loadMarcData(context);
  }

  Future<void> loadMarcData(BuildContext context) async {
    final biblioNumber = int.parse(widget.biblioNumber);
    try {
      marcData = await BibliosDetailsService.getBibliosMarcPlainText(
        biblioNumber,
      );
    } on TimeoutException catch (_) {
      //debugPrint('Error loading MARC data: $e');
      isError = true;

      //Snackbar notifying timeout
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.timeoutLoading)),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  static String? formatAltMarcStyle(String? marc) {
    if (marc == null) return null;

    final formattedMarc = StringBuffer();

    marc.split('\n').forEach((line) {
      if (line.startsWith(RegExp(r'^\d{3}(?!\d) '))) {
        // Check if the line starts with a three-digit tag followed by a space

        // Replace the first '_' after the tag with a pipe '|'
        line = line.replaceFirst('_', '|');

        // Add a space after each piped marc subfield code
        line = line.replaceFirstMapped(
          RegExp(
            r'\|([A-Za-z0-9])',
          ), // Checks for '|' followed by a single alphanumeric character
          (m) => '|${m[1]} ', // Adds a space after the piped subfield code
        );
      } else if (line.startsWith('   ')) {
        // Subfield line
        // Replace leading '_' with a pipe '|'
        line = line.replaceFirst('_', '|');

        /// Preserve indentation and add space after subfield code
        final indentMatch = RegExp(
          r'^\s+',
        ).firstMatch(line); // Checks if line starts with spaces
        final indent =
            indentMatch?.group(0) ?? ''; // Preserves original indentation
        final content = line.substring(
          indent.length,
        ); // Content after indentation
        if (content.length >= 2) {
          // Add space after subfield code
          final first2 = content.substring(0, 2);
          line = '$indent$first2 ${content.substring(2)}';
        } else {
          line = '$indent$content ';
        }
      }
      //debugPrint('Formatted line: $line');
      formattedMarc.writeln(line);
    });

    return formattedMarc.toString();
  }
}
