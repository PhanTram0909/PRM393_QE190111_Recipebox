import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_box/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RecipeBoxApp());
  });
}
