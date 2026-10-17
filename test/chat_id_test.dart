import 'package:flutter_test/flutter_test.dart';
import 'package:skillswap/services/chat_service.dart';
import 'package:skillswap/utils/format.dart';

void main() {
  test('chat id is identical for both users', () {
    expect(ChatService.chatIdFor('alice', 'bob'), ChatService.chatIdFor('bob', 'alice'));
    expect(ChatService.chatIdFor('b', 'a'), 'a_b');
  });

  test('timeAgo formats short durations', () {
    expect(timeAgo(null), '');
    expect(timeAgo(DateTime.now()), 'now');
    expect(timeAgo(DateTime.now().subtract(const Duration(minutes: 5))), '5m');
    expect(timeAgo(DateTime.now().subtract(const Duration(hours: 3))), '3h');
  });
}
