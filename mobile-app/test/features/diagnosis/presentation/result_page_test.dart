import 'package:flutter_test/flutter_test.dart';

import '../../../helpers.dart';

void main() {
  Future<void> open(WidgetTester t, String id) async {
    await pumpApp(t);
    await pushRoute(t, '/diagnosis/$id');
  }

  testWidgets('S3-A late blight', (t) async {
    await open(t, 'd-0912');
    expect(find.text('Late blight'), findsNWidgets(2)); // chip + title
    expect(
      find.textContaining('Phytophthora infestans', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('76.5%'), findsOneWidget);
    expect(find.text('Above the 50% threshold'), findsOneWidget);
    expect(find.text('18.9%'), findsOneWidget);
    expect(find.text('4.6%'), findsOneWidget);
    expect(find.text('On-device · 1.9 ms · Model v1'), findsOneWidget);
    expect(find.text('What this means'), findsOneWidget);
    expect(find.text('Get advice'), findsOneWidget);
    expect(find.text('Ask the server for a second opinion'), findsOneWidget);
    await expectAccessible(t);
    await expectScreen(t, 's3_a_result_late_blight');
  });

  testWidgets('S3-B healthy', (t) async {
    await open(t, 'd-1640');
    expect(find.text('98.1%'), findsOneWidget);
    expect(find.text('Potato · no disease found'), findsOneWidget);
    await expectScreen(t, 's3_b_result_healthy');
  });

  testWidgets('S3-C early blight', (t) async {
    await open(t, 'd-1105');
    expect(find.text('88.4%'), findsOneWidget);
    expect(
      find.textContaining('Alternaria solani', findRichText: true),
      findsOneWidget,
    );
    await expectScreen(t, 's3_c_result_early_blight');
  });

  testWidgets('S3-D not sure: best guess, all classes, retake', (t) async {
    await open(t, 'd-0910');
    expect(find.text('Not sure'), findsNWidgets(2));
    expect(find.text('Best guess'), findsOneWidget);
    expect(find.text('Below the 50% threshold'), findsOneWidget);
    expect(find.text('31.4%'), findsOneWidget);
    expect(find.text('29.7%'), findsOneWidget);
    expect(find.text('Try again with'), findsOneWidget);
    expect(find.text('Retake photo'), findsOneWidget);
    expect(find.text('What this means'), findsNothing);
    await expectScreen(t, 's3_d_result_not_sure_1');
  });

  testWidgets('S3-E second opinion', (t) async {
    await open(t, 'd-0912');
    await t.tap(find.text('Ask the server for a second opinion'));
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Second opinion'), findsOneWidget);
    expect(find.text('81.2%'), findsOneWidget);
    expect(find.text('312 ms over Wi-Fi'), findsOneWidget);
    expect(find.text('Both agree'), findsOneWidget);
    expect(find.text('Ask the server for a second opinion'), findsNothing);
    await expectScreen(t, 's3_e_result_second_opinion');
  });

  testWidgets('S5-D rejected sync banner', (t) async {
    await open(t, 'd-1051');
    expect(find.text("Couldn't sync this diagnosis"), findsOneWidget);
    expect(find.textContaining("The phone's clock was ahead"), findsOneWidget);
    await expectScreen(t, 's5_d_result_sync_rejected_1');
  });

  testWidgets('delete asks first, then removes and goes back', (t) async {
    await open(t, 'd-0912');
    await t.tap(find.byTooltip('Delete'));
    await t.pumpAndSettle();
    expect(find.text('Delete this diagnosis?'), findsOneWidget);
    await t.tap(find.text('Delete').last);
    await t.pumpAndSettle();
    expect(find.text('Today, 09:12 · 76.5%'), findsNothing);
    expect(find.text('Check a potato leaf'), findsOneWidget);
  });
}
