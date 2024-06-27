// account.dart
class Account {
  final int id;
  final String name;
  final String username;
  final double average;
  final int totalPlay;
  final int totalScore;

  Account({
    required this.id,
    required this.name,
    required this.username,
    this.average = 0,
    this.totalPlay = 0,
    this.totalScore = 0,
  });
}
