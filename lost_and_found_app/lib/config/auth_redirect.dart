/// Returns to the web app's directory, preserving deployments below a subpath.
/// Hash routes and callback query parameters must not become redirect targets.
/// Native clients keep their existing Supabase redirect behavior.
String? signupRedirectUrl({required bool isWeb, required Uri appUrl}) {
  return isWeb ? appUrl.resolve('.').toString() : null;
}
