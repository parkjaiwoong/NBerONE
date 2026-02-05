import 'package:http/http.dart' as http;

class UrlResolver {
  // Get the final destination URL after following redirects
  static Future<String?> getFinalDestination(String url) async {
    try {
      // Parse and validate URL
      final uri = Uri.parse(url);
      
      // Send HEAD request to follow redirects
      final response = await http.head(uri).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Timeout');
        },
      );
      
      // Return the final URL after redirects
      return response.request?.url.toString() ?? url;
    } catch (e) {
      // If error occurs, return original URL
      return url;
    }
  }

  // Normalize URL for comparison (remove trailing slashes, www, etc.)
  static String normalizeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      String host = uri.host.toLowerCase();
      
      // Remove www. prefix
      if (host.startsWith('www.')) {
        host = host.substring(4);
      }
      
      // Remove trailing slash from path
      String path = uri.path;
      if (path.endsWith('/') && path.length > 1) {
        path = path.substring(0, path.length - 1);
      }
      
      // Reconstruct normalized URL
      return '${uri.scheme}://$host$path';
    } catch (e) {
      return url.toLowerCase();
    }
  }

  // Compare if two URLs point to the same destination
  static Future<bool> isSameDestination(String url1, String url2) async {
    try {
      // Get final destinations
      final dest1 = await getFinalDestination(url1);
      final dest2 = await getFinalDestination(url2);
      
      if (dest1 == null || dest2 == null) {
        return false;
      }
      
      // Normalize and compare
      final normalized1 = normalizeUrl(dest1);
      final normalized2 = normalizeUrl(dest2);
      
      return normalized1 == normalized2;
    } catch (e) {
      return false;
    }
  }
}
