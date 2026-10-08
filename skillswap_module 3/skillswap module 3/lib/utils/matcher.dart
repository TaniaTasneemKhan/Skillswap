import '../models/user_profile.dart';

/// A suggested learning partner.
class Match {
  final UserProfile user;
  final List<String> theyCanTeachYou; // their offered ∩ my wanted
  final List<String> youCanTeachThem; // my offered ∩ their wanted
  final int score;

  const Match(this.user, this.theyCanTeachYou, this.youCanTeachThem, this.score);

  bool get isMutual => theyCanTeachYou.isNotEmpty && youCanTeachThem.isNotEmpty;
}

String _norm(String s) => s.trim().toLowerCase();

/// Two skills overlap if equal, or if one contains the other (min 3 chars),
/// so "flutter" matches "flutter development".
bool _skillsOverlap(String a, String b) {
  final x = _norm(a), y = _norm(b);
  if (x.isEmpty || y.isEmpty) return false;
  if (x == y) return true;
  if (x.length < 3 || y.length < 3) return false;
  return x.contains(y) || y.contains(x);
}

List<String> _intersect(List<String> mine, List<String> theirs) => [
      for (final t in theirs)
        if (mine.any((m) => _skillsOverlap(m, t))) t
    ];

/// Scoring: 10 pts per skill they can teach me, 10 per skill I can teach
/// them, +15 bonus when the exchange is mutual. Sorted best-first.
List<Match> computeMatches(UserProfile me, List<UserProfile> others) {
  final results = <Match>[];
  for (final o in others) {
    final learn = _intersect(me.skillsWanted, o.skillsOffered);
    final teach = _intersect(o.skillsWanted, me.skillsOffered);
    if (learn.isEmpty && teach.isEmpty) continue;
    var score = (learn.length + teach.length) * 10;
    if (learn.isNotEmpty && teach.isNotEmpty) score += 15;
    results.add(Match(o, learn, teach, score));
  }
  results.sort((a, b) => b.score.compareTo(a.score));
  return results;
}
