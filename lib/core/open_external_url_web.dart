import 'package:universal_html/html.dart' as html;

void openExternalUrlInNewTab(String url) {
  html.window.open(url, '_blank');
}
