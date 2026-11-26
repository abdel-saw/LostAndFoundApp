import 'package:flutter_test/flutter_test.dart';
import 'package:lost_and_found_app/config/auth_redirect.dart';

void main() {
  test('confirmation returns to the GitHub Pages project rather than the origin', () {
    expect(
      signupRedirectUrl(
        isWeb: true,
        appUrl: Uri.parse('https://abdel-saw.github.io/LostAndFoundApp/'),
      ),
      'https://abdel-saw.github.io/LostAndFoundApp/',
    );
  });

  test('hash routes and callback parameters are excluded from the return URL', () {
    expect(
      signupRedirectUrl(
        isWeb: true,
        appUrl: Uri.parse(
          'https://abdel-saw.github.io/LostAndFoundApp/?code=fixture#/report',
        ),
      ),
      'https://abdel-saw.github.io/LostAndFoundApp/',
    );
  });

  test('root deployments and localhost keep their own directory and port', () {
    for (final url in [
      'https://demo.example/',
      'http://localhost:8080/',
      'http://localhost:8080/preview/',
    ]) {
      expect(
        signupRedirectUrl(isWeb: true, appUrl: Uri.parse('${url}#/report')),
        url,
      );
    }
  });

  test('native signup keeps the provider redirect behavior', () {
    expect(
      signupRedirectUrl(isWeb: false, appUrl: Uri.parse('file:///app/')),
      isNull,
    );
  });
}
