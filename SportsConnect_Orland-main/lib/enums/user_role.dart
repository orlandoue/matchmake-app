/// User role enum for the sports app
/// Currently supports player, with referee to be added in future
enum UserRole {
  player('player'),
  referee('referee'),
  clubAdmin('club_admin');

  final String value;
  const UserRole(this.value);

  /// Get UserRole from string value
  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'player':
        return UserRole.player;
      case 'referee':
        return UserRole.referee;
      case 'admin':
      case 'club_admin':
        return UserRole.clubAdmin;
      default:
        return UserRole.player; // Default to player
    }
  }

  /// Get display name for the user role
  String get displayName {
    switch (this) {
      case UserRole.player:
        return 'Player';
      case UserRole.referee:
        return 'Referee';
      case UserRole.clubAdmin:
        return 'Club Admin';
    }
  }

  /// Check if user is a player
  bool get isPlayer => this == UserRole.player;

  /// Check if user is a referee
  bool get isReferee => this == UserRole.referee;

  /// Check if user is a club admin
  bool get isClubAdmin => this == UserRole.clubAdmin;

  @override
  String toString() => value;
}
