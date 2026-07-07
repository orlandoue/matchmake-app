/// Match status enum for tracking match lifecycle
enum MatchStatus {
  pending('pending'),
  waitingForOpponent('waiting_for_opponent'),
  matched('matched'),
  confirmed('confirmed'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled'),
  blocked('blocked');

  final String value;
  const MatchStatus(this.value);

  /// Get MatchStatus from string value
  static MatchStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return MatchStatus.pending;
      case 'waiting_for_opponent':
        return MatchStatus.waitingForOpponent;
      case 'matched':
        return MatchStatus.matched;
      case 'confirmed':
        return MatchStatus.confirmed;
      case 'in_progress':
        return MatchStatus.inProgress;
      case 'completed':
      case 'finished': // backward compat
        return MatchStatus.completed;
      case 'cancelled':
        return MatchStatus.cancelled;
      case 'blocked':
        return MatchStatus.blocked;
      default:
        return MatchStatus.pending;
    }
  }

  /// Get display name for the match status
  String get displayName {
    switch (this) {
      case MatchStatus.pending:
        return 'Pending';
      case MatchStatus.waitingForOpponent:
        return 'Waiting for Opponent';
      case MatchStatus.matched:
        return 'Matched';
      case MatchStatus.confirmed:
        return 'Confirmed';
      case MatchStatus.inProgress:
        return 'En Curso';
      case MatchStatus.completed:
        return 'Finalizado';
      case MatchStatus.cancelled:
        return 'Cancelado';
      case MatchStatus.blocked:
        return 'Bloqueado';
    }
  }

  /// Get status color name for UI styling
  String get colorName {
    switch (this) {
      case MatchStatus.pending:
      case MatchStatus.waitingForOpponent:
        return 'orange';
      case MatchStatus.matched:
      case MatchStatus.confirmed:
        return 'blue';
      case MatchStatus.inProgress:
        return 'green';
      case MatchStatus.completed:
        return 'purple';
      case MatchStatus.cancelled:
        return 'red';
      case MatchStatus.blocked:
        return 'grey';
    }
  }

  /// Check if match can be cancelled
  bool get canBeCancelled =>
      this == MatchStatus.pending ||
      this == MatchStatus.waitingForOpponent ||
      this == MatchStatus.matched;

  /// Check if match can be started
  bool get canBeStarted => this == MatchStatus.confirmed;

  /// Check if match is active
  bool get isActive =>
      this == MatchStatus.pending ||
      this == MatchStatus.waitingForOpponent ||
      this == MatchStatus.matched ||
      this == MatchStatus.confirmed ||
      this == MatchStatus.inProgress;

  @override
  String toString() => value;
}

/// Match type enum for different match formats
enum MatchType {
  oneVsOne('1v1'),
  twoVsTwo('2v2');

  final String value;
  const MatchType(this.value);

  static MatchType fromString(String value) {
    switch (value.toLowerCase()) {
      case '1v1':
      case '1x1':
        return MatchType.oneVsOne;
      case '2v2':
      case '2x2':
        return MatchType.twoVsTwo;
      default:
        return MatchType.oneVsOne;
    }
  }

  String get displayName {
    switch (this) {
      case MatchType.oneVsOne:
        return '1v1';
      case MatchType.twoVsTwo:
        return '2v2';
    }
  }

  int get playersPerTeam {
    switch (this) {
      case MatchType.oneVsOne:
        return 1;
      case MatchType.twoVsTwo:
        return 2;
    }
  }

  @override
  String toString() => value;
}

/// Match mode enum for different matchmaking modes
enum MatchMode {
  competitive('competitive'),
  friendly('friendly'),
  manualReservation('manual_reservation');

  final String value;
  const MatchMode(this.value);

  static MatchMode fromString(String value) {
    switch (value.toLowerCase()) {
      case 'competitive':
      case 'random': // backward compat
        return MatchMode.competitive;
      case 'friendly':
      case 'private': // backward compat
        return MatchMode.friendly;
      case 'manual_reservation':
      case 'manual':
        return MatchMode.manualReservation;
      default:
        return MatchMode.competitive;
    }
  }

  String get displayName {
    switch (this) {
      case MatchMode.competitive:
        return 'Competitive';
      case MatchMode.friendly:
        return 'Friendly';
      case MatchMode.manualReservation:
        return 'Manual';
    }
  }

  String get description {
    switch (this) {
      case MatchMode.competitive:
        return 'Ranked match with a referee assigned by the system';
      case MatchMode.friendly:
        return 'Casual match visible in Find a Match, no referee required';
      case MatchMode.manualReservation:
        return 'Manual court block by admin';
    }
  }

  /// Whether this mode requires a referee
  bool get requiresReferee => this == MatchMode.competitive;

  @override
  String toString() => value;
}
