import 'package:flutter_test/flutter_test.dart';
import 'package:skillswap/models/user_profile.dart';
import 'package:skillswap/utils/matcher.dart';

UserProfile u(String id, List<String> offers, List<String> wants) => UserProfile(
    uid: id, name: id, email: '', skillsOffered: offers, skillsWanted: wants, profileComplete: true);

void main() {
  final me = u('me', ['Flutter', 'Guitar'], ['Photoshop']);

  test('mutual match scores highest', () {
    final mutual = u('a', ['photoshop'], ['guitar']);
    final oneWay = u('b', ['Photoshop'], ['Cooking']);
    final r = computeMatches(me, [oneWay, mutual]);
    expect(r.first.user.uid, 'a');
    expect(r.first.isMutual, true);
    expect(r.first.score, 35);
    expect(r.last.score, 10);
  });

  test('no overlap -> excluded', () {
    expect(computeMatches(me, [u('c', ['Cooking'], ['Yoga'])]), isEmpty);
  });

  test('partial skill names overlap', () {
    final r = computeMatches(me, [u('d', ['Adobe Photoshop CC'], [])]);
    expect(r.length, 1);
  });
}
