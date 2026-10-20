import 'package:flutter_test/flutter_test.dart';
import 'package:skillswap/models/user_profile.dart';

void main() {
  test('average rating comes from sum and count', () {
    final p = UserProfile.fromMap('u1', {'name': 'A', 'ratingSum': 9, 'ratingCount': 2});
    expect(p.ratingCount, 2);
    expect(p.rating, 4.5);
  });

  test('a member with no reviews has rating 0 and count 0', () {
    final p = UserProfile.fromMap('u2', {'name': 'B'});
    expect(p.ratingCount, 0);
    expect(p.rating, 0);
  });

  test('numeric fields stored as doubles still parse', () {
    final p = UserProfile.fromMap('u3', {'ratingSum': 10.0, 'ratingCount': 2.0});
    expect(p.rating, 5);
  });
}
