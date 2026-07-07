/// User type enum matching the database user_type enum
enum UserType {
  owner('OWNER'),
  manager('MANAGER'),
  staff('STAFF');

  final String value;
  const UserType(this.value);

  /// Get UserType from string value
  static UserType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'OWNER':
        return UserType.owner;
      case 'MANAGER':
        return UserType.manager;
      case 'STAFF':
        return UserType.staff;
      default:
        throw ArgumentError('Invalid user type: $value');
    }
  }

  /// Get display name for the user type
  String get displayName {
    switch (this) {
      case UserType.owner: 
        return 'Owner';
      case UserType.manager:
        return 'Manager';
      case UserType.staff:
        return 'Staff';
    }
  }

  /// Check if user has owner privileges
  bool get isOwner => this == UserType.owner;

  /// Check if user has manager or owner privileges
  bool get hasManagerAccess =>
      this == UserType.owner || this == UserType.manager;

  @override
  String toString() => value;
}
