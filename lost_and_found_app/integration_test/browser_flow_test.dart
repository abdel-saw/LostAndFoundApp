// This suite deliberately runs only in a real Web browser.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lost_and_found_app/main.dart' as app;

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 45));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}

Future<void> press(WidgetTester tester, Finder finder) async {
  await waitFor(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('signup, photo report, comments, live delivery and sign-out',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await app.main();
    await waitFor(tester, find.byKey(const Key('auth-email')));
    final email = 'browser-${DateTime.now().microsecondsSinceEpoch}@example.test';
    const password = 'local-browser-fixture-password';
    await press(tester, find.text("Don't have an account? Sign Up"));
    await tester.enterText(find.byKey(const Key('auth-email')), email);
    await tester.enterText(find.byKey(const Key('auth-password')), password);
    await press(tester, find.byKey(const Key('auth-submit')));
    await waitFor(tester, find.byKey(const Key('item-search')));

    await press(tester, find.byKey(const Key('new-report')));
    await tester.enterText(find.byKey(const Key('report-name')), 'Browser fixture keys');
    await tester.enterText(find.byKey(const Key('report-description')), 'Fictional test item');
    await tester.enterText(find.byKey(const Key('report-location')), 'Demo campus');
    await press(tester, find.byKey(const Key('pick-photo')));
    final input = html.document.querySelector('#report-photo-input') as html.FileUploadInputElement;
    final photo = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGMwLl8FAAI1AVVMCQ50AAAAAElFTkSuQmCC');
    final transfer = html.DataTransfer();
    transfer.items!.add(html.File([photo], 'fixture.png', {'type': 'image/png'}));
    input.files = transfer.files;
    input.dispatchEvent(html.Event('change'));
    await waitFor(tester, find.byKey(const Key('photo-preview')));
    await press(tester, find.byKey(const Key('submit-report')));
    await waitFor(tester, find.text('Browser fixture keys (Lost)'));

    final client = Supabase.instance.client;
    final item = await client.from('items').select().eq('name', 'Browser fixture keys').single();
    final id = item['id'];
    expect(item['photo_url'], endsWith('.png'));
    final photoFinder = find.byKey(ValueKey('photo-$id'));
    await waitFor(tester, photoFinder);
    expect(tester.widget<Image>(photoFinder).image, isA<NetworkImage>());
    await press(tester, find.text('Browser fixture keys (Lost)'));
    await waitFor(tester, find.text('No comments yet.'));
    await tester.ensureVisible(find.byKey(ValueKey('comment-$id')));
    await tester.enterText(find.byKey(ValueKey('comment-$id')), 'Comment from browser UI');
    await press(tester, find.byKey(ValueKey('post-comment-$id')));
    await waitFor(tester, find.text('Comment from browser UI'));

    // Another authenticated client changes the database while this UI stays open.
    final remote = SupabaseClient(
      const String.fromEnvironment('SUPABASE_URL'),
      const String.fromEnvironment('SUPABASE_ANON_KEY'),
      authOptions: const AuthClientOptions(autoRefreshToken: false));
    try {
      await remote.auth.signUp(email: 'remote-${DateTime.now().microsecondsSinceEpoch}@example.test',
        password: password);
      await remote.from('comments').insert({
        'item_id': id, 'user_id': remote.auth.currentUser!.id,
        'text': 'Live comment from another user',
      });
      await waitFor(tester, find.text('Live comment from another user'));
      await tester.enterText(find.byKey(const Key('item-search')), 'Browser');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byKey(const Key('item-search')), '');
      await tester.pump(const Duration(milliseconds: 300));
      await remote.rpc('report_item', params: {'payload': {
        'name': 'Live remote wallet', 'type': 'found', 'category': 'Personal',
      }});
      await waitFor(tester, find.text('Live remote wallet (Found)'));
    } finally {
      await remote.dispose();
    }

    // Sign out from the report route, then sign in again through the form.
    await press(tester, find.byKey(const Key('new-report')));
    await press(tester, find.byKey(const Key('sign-out')).last);
    await waitFor(tester, find.byKey(const Key('auth-email')));
    await tester.enterText(find.byKey(const Key('auth-email')), email);
    await tester.enterText(find.byKey(const Key('auth-password')), password);
    await press(tester, find.byKey(const Key('auth-submit')));
    await waitFor(tester, find.byKey(const Key('item-search')));
    expect(client.auth.currentUser!.email, email);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
