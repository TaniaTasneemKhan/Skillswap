import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skillswap/widgets/skill_chip_input.dart';
import 'package:skillswap/widgets/star_rating.dart';

void main() {
  testWidgets('SkillChipInput adds a skill and ignores duplicates',
      (WidgetTester tester) async {
    var skills = <String>[];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => SkillChipInput(
            label: 'Skills',
            hint: 'e.g. Flutter',
            values: skills,
            onChanged: (v) => setState(() => skills = v),
          ),
        ),
      ),
    ));

    await tester.enterText(find.byType(TextField), 'Flutter');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(skills, ['Flutter']);

    await tester.enterText(find.byType(TextField), 'flutter');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(skills.length, 1);
  });

  testWidgets('StarPicker reports the tapped star', (WidgetTester tester) async {
    var value = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => StarPicker(
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.star_border).at(3)); // 4th star
    await tester.pump();
    expect(value, 4);
    expect(find.byIcon(Icons.star), findsNWidgets(4));
  });
}
