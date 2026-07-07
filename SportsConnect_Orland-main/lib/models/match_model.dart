import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/models/court_model.dart';
import 'package:orland_sports/models/user_model.dart';

/// Match model representing a match in the database
class MatchModel {
  final String id;
  final String? courtId;  // Nullable: asignado por el admin del club en el nuevo flujo geográfico
  final List<String> preferredClubIds; // Clubs preferidos (nuevo flujo geo)
  final String? sportId;
  final String? matchCategory;
  final String player1Id;
  final String? player2Id;
  final String? invitedPlayer2Id; // For 2v2 partner invites
  final String? player3Id; // For 2v2
  final String? player4Id; // For 2v2
  final String? refereeId;
  final MatchType matchType;
  final MatchMode matchMode;
  final MatchStatus status;
  final DateTime scheduledDate;
  final String scheduledTime;
  final String? scheduledEndTime;
  final String? inviteCode;
  final String? winnerId;
  final Map<String, dynamic>? scoreData;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool player1CheckedIn;
  final bool player2CheckedIn;
  final bool player3CheckedIn;
  final bool player4CheckedIn;

  // Financial field: hourly_rate of the assigned court (populated from JOIN)
  final double? courtPrice;

  // Related models (populated from joins)
  final CourtModel? court;
  final UserModel? player1;
  final UserModel? player2;
  final UserModel? player3;
  final UserModel? player4;
  final UserModel? referee;

  MatchModel({
    required this.id,
    this.courtId,
    this.preferredClubIds = const [],
    this.sportId,
    this.matchCategory,
    required this.player1Id,
    this.player2Id,
    this.invitedPlayer2Id,
    this.player3Id,
    this.player4Id,
    this.refereeId,
    required this.matchType,
    required this.matchMode,
    required this.status,
    required this.scheduledDate,
    required this.scheduledTime,
    this.scheduledEndTime,
    this.inviteCode,
    this.winnerId,
    this.scoreData,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.court,
    this.player1,
    this.player2,
    this.player3,
    this.player4,
    this.referee,
    this.player1CheckedIn = false,
    this.player2CheckedIn = false,
    this.player3CheckedIn = false,
    this.player4CheckedIn = false,
    this.courtPrice,
  });

  /// Create MatchModel from JSON map
  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as String? ?? '',
      courtId: json['court_id'] as String?,
      preferredClubIds: json['preferred_club_ids'] != null
          ? List<String>.from(json['preferred_club_ids'] as List)
          : const [],
      sportId: json['sport_id'] as String?,
      matchCategory: json['match_category'] as String?,
      player1Id: json['player1_id'] as String? ?? '',
      player2Id: json['player2_id'] as String?,
      invitedPlayer2Id: json['invited_player2_id'] as String?,
      player3Id: json['player3_id'] as String?,
      player4Id: json['player4_id'] as String?,
      refereeId: json['referee_id'] as String?,
      matchType: MatchType.fromString(json['match_type'] as String? ?? '1v1'),
      matchMode:
          MatchMode.fromString(json['match_mode'] as String? ?? 'random'),
      status: MatchStatus.fromString(json['status'] as String? ?? 'pending'),
      scheduledDate: DateTime.parse(
          json['scheduled_date'] as String? ?? DateTime.now().toIso8601String()),
      scheduledTime: json['scheduled_time'] as String? ?? '--:--',
      scheduledEndTime: json['scheduled_end_time'] as String?,
      inviteCode: json['invite_code'] as String?,
      winnerId: json['winner_id'] as String?,
      scoreData: json['score_data'] as Map<String, dynamic>?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      court: json['courts'] != null
          ? CourtModel.fromJson(json['courts'] as Map<String, dynamic>)
          : null,
      player1: json['player1'] != null
          ? UserModel.fromJson(json['player1'] as Map<String, dynamic>)
          : null,
      player2: json['player2'] != null
          ? UserModel.fromJson(json['player2'] as Map<String, dynamic>)
          : null,
      player3: json['player3'] != null
          ? UserModel.fromJson(json['player3'] as Map<String, dynamic>)
          : null,
      player4: json['player4'] != null
          ? UserModel.fromJson(json['player4'] as Map<String, dynamic>)
          : null,
      referee: json['referee'] != null
          ? UserModel.fromJson(json['referee'] as Map<String, dynamic>)
          : null,
      player1CheckedIn: json['player1_checked_in'] as bool? ?? false,
      player2CheckedIn: json['player2_checked_in'] as bool? ?? false,
      player3CheckedIn: json['player3_checked_in'] as bool? ?? false,
      player4CheckedIn: json['player4_checked_in'] as bool? ?? false,
      // Pull hourly_rate from joined courts row when present
      courtPrice: json['courts'] != null
          ? (json['courts']['hourly_rate'] as num?)?.toDouble()
          : null,
    );
  }

  /// Convert MatchModel to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'court_id': courtId,
      'preferred_club_ids': preferredClubIds,
      'sport_id': sportId,
      'match_category': matchCategory,
      'player1_id': player1Id,
      'player2_id': player2Id,
      'invited_player2_id': invitedPlayer2Id,
      'player3_id': player3Id,
      'player4_id': player4Id,
      'referee_id': refereeId,
      'match_type': matchType.value,
      'match_mode': matchMode.value,
      'status': status.value,
      'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
      'scheduled_time': scheduledTime,
      'scheduled_end_time': scheduledEndTime,
      'invite_code': inviteCode,
      'winner_id': winnerId,
      'score_data': scoreData,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'player1_checked_in': player1CheckedIn,
      'player2_checked_in': player2CheckedIn,
      'player3_checked_in': player3CheckedIn,
      'player4_checked_in': player4CheckedIn,
    };
  }

  /// Create insert data map (without id for auto-generation)
  Map<String, dynamic> toInsertJson() {
    return {
      'court_id': courtId,  // null when using geo-flow (admin assigns court later)
      'preferred_club_ids': preferredClubIds.isNotEmpty ? preferredClubIds : null,
      'sport_id': sportId,
      'match_category': matchCategory,
      'player1_id': player1Id,
      'player2_id': player2Id,
      'invited_player2_id': invitedPlayer2Id,
      'player3_id': player3Id,
      'player4_id': player4Id,
      'referee_id': refereeId,
      'match_type': matchType.value,
      'match_mode': matchMode.value,
      'status': status.value,
      'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
      'scheduled_time': scheduledTime,
      'scheduled_end_time': scheduledEndTime,
      'invite_code': inviteCode,
      'winner_id': winnerId,
      'score_data': scoreData,
      'notes': notes,
    };
  }

  /// Create a copy of MatchModel with updated fields
  MatchModel copyWith({
    String? id,
    String? courtId,
    List<String>? preferredClubIds,
    String? sportId,
    String? matchCategory,
    String? player1Id,
    String? player2Id,
    String? invitedPlayer2Id,
    String? player3Id,
    String? player4Id,
    String? refereeId,
    MatchType? matchType,
    MatchMode? matchMode,
    MatchStatus? status,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? scheduledEndTime,
    String? inviteCode,
    String? winnerId,
    Map<String, dynamic>? scoreData,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    CourtModel? court,
    UserModel? player1,
    UserModel? player2,
    UserModel? player3,
    UserModel? player4,
    UserModel? referee,
    bool? player1CheckedIn,
    bool? player2CheckedIn,
    bool? player3CheckedIn,
    bool? player4CheckedIn,
    double? courtPrice,
  }) {
    return MatchModel(
      id: id ?? this.id,
      courtId: courtId ?? this.courtId,
      preferredClubIds: preferredClubIds ?? this.preferredClubIds,
      sportId: sportId ?? this.sportId,
      matchCategory: matchCategory ?? this.matchCategory,
      player1Id: player1Id ?? this.player1Id,
      player2Id: player2Id ?? this.player2Id,
      invitedPlayer2Id: invitedPlayer2Id ?? this.invitedPlayer2Id,
      player3Id: player3Id ?? this.player3Id,
      player4Id: player4Id ?? this.player4Id,
      refereeId: refereeId ?? this.refereeId,
      matchType: matchType ?? this.matchType,
      matchMode: matchMode ?? this.matchMode,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      scheduledEndTime: scheduledEndTime ?? this.scheduledEndTime,
      inviteCode: inviteCode ?? this.inviteCode,
      winnerId: winnerId ?? this.winnerId,
      scoreData: scoreData ?? this.scoreData,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      court: court ?? this.court,
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      player3: player3 ?? this.player3,
      player4: player4 ?? this.player4,
      referee: referee ?? this.referee,
      player1CheckedIn: player1CheckedIn ?? this.player1CheckedIn,
      player2CheckedIn: player2CheckedIn ?? this.player2CheckedIn,
      player3CheckedIn: player3CheckedIn ?? this.player3CheckedIn,
      player4CheckedIn: player4CheckedIn ?? this.player4CheckedIn,
      courtPrice: courtPrice ?? this.courtPrice,
    );
  }

  /// Get all player IDs as a list
  List<String> get allPlayerIds {
    final ids = <String>[player1Id];
    if (player2Id != null) ids.add(player2Id!);
    if (player3Id != null) ids.add(player3Id!);
    if (player4Id != null) ids.add(player4Id!);
    return ids;
  }

  /// Check if a player is part of this match
  bool hasPlayer(String playerId) {
    return player1Id == playerId ||
        player2Id == playerId ||
        player3Id == playerId ||
        player4Id == playerId;
  }

  /// Check if all players have checked in based on match type
  bool get areAllPlayersCheckedIn {
    if (matchType == MatchType.oneVsOne) {
      return player1CheckedIn && player2CheckedIn;
    } else {
      return player1CheckedIn && 
             player2CheckedIn && 
             player3CheckedIn && 
             player4CheckedIn;
    }
  }

  /// Get count of checked-in players
  int get checkedInCount {
    int count = 0;
    if (player1CheckedIn) count++;
    if (player2CheckedIn) count++;
    if (player3CheckedIn) count++;
    if (player4CheckedIn) count++;
    return count;
  }

  /// Check if match is full
  bool get isFull {
    if (matchType == MatchType.oneVsOne) {
      return player1Id.isNotEmpty && player2Id != null;
    } else {
      return player1Id.isNotEmpty &&
          player2Id != null &&
          player3Id != null &&
          player4Id != null;
    }
  }

  /// Get team 1 player IDs
  List<String> get team1PlayerIds {
    final ids = <String>[player1Id];
    if (matchType == MatchType.twoVsTwo && player2Id != null) {
      ids.add(player2Id!);
    }
    return ids;
  }

  /// Get team 2 player IDs
  List<String> get team2PlayerIds {
    final ids = <String>[];
    if (matchType == MatchType.oneVsOne && player2Id != null) {
      ids.add(player2Id!);
    } else if (matchType == MatchType.twoVsTwo) {
      if (player3Id != null) ids.add(player3Id!);
      if (player4Id != null) ids.add(player4Id!);
    }
    return ids;
  }

  /// Get player 1 display name
  String get player1Name => player1?.name ?? 'Player 1';

  /// Get player 2 display name
  String get player2Name => player2?.name ?? 'Waiting...';

  /// Get player 3 display name (2v2)
  String get player3Name => player3?.name ?? 'Waiting...';

  /// Get player 4 display name (2v2)
  String get player4Name => player4?.name ?? 'Waiting...';

  /// Team 1 display name for 2v2
  String get team1DisplayName {
    if (matchType == MatchType.twoVsTwo) {
      final p1 = player1?.name ?? 'Player 1';
      final p2 = player2?.name;
      return p2 != null ? '$p1 & $p2' : p1;
    }
    return player1Name;
  }

  /// Team 2 display name for 2v2
  String get team2DisplayName {
    if (matchType == MatchType.twoVsTwo) {
      final p3 = player3?.name;
      final p4 = player4?.name;
      if (p3 != null && p4 != null) return '$p3 & $p4';
      if (p3 != null) return p3;
      return 'Waiting...';
    }
    return player2Name;
  }

  /// Check if the winner is Team 1 (player1 + player2)
  bool get isTeam1Winner {
    if (winnerId == null) return false;
    return winnerId == player1Id || winnerId == player2Id;
  }

  /// Check if the winner is Team 2 (player3 + player4)
  bool get isTeam2Winner {
    if (winnerId == null) return false;
    return winnerId == player3Id || winnerId == player4Id;
  }

  /// Winner display name (handles 2v2 teams)
  String get winnerDisplayName {
    if (winnerId == null) return '';
    if (matchType == MatchType.twoVsTwo) {
      return isTeam1Winner ? team1DisplayName : team2DisplayName;
    }
    return winnerId == player1Id ? player1Name : player2Name;
  }

  /// How many player slots are filled
  int get filledSlots {
    int count = 1; // player1 is always filled
    if (player2Id != null) count++;
    if (player3Id != null) count++;
    if (player4Id != null) count++;
    return count;
  }

  /// Total required slots
  int get totalSlots => matchType == MatchType.twoVsTwo ? 4 : 2;

  /// Get display string for scheduled time range
  String get timeRangeDisplay {
    if (scheduledEndTime != null && scheduledEndTime!.isNotEmpty) {
      return '$scheduledTime - $scheduledEndTime';
    }
    return scheduledTime;
  }

  /// Get formatted scheduled date
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final matchDay =
        DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);

    if (matchDay == today) {
      return 'Today';
    } else if (matchDay == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}';
    }
  }

  /// Get simplified formatted date (e.g. 05/04)
  String get formattedShortDate {
    return '${scheduledDate.day.toString().padLeft(2, '0')}/${scheduledDate.month.toString().padLeft(2, '0')}';
  }

  /// Whether match is scheduled for a future date (after today)
  bool get isScheduledForFuture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final matchDay =
        DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
    return matchDay.isAfter(today);
  }

  /// Whether match is scheduled in the past (before today)
  bool get isPastMatch {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final matchDay =
        DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
    return matchDay.isBefore(today);
  }

  /// Whether match is today or in the future
  bool get isTodayOrFuture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final matchDay =
        DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
    return !matchDay.isBefore(today);
  }

  /// Referee-contextual display status
  /// Shows "Scheduled" for confirmed matches with future dates
  String get refereeDisplayStatus {
    if (status == MatchStatus.confirmed && isScheduledForFuture) {
      return 'Scheduled';
    }
    return status.displayName;
  }

  @override
  String toString() {
    return 'MatchModel(id: $id, status: $status, type: $matchType, players: ${allPlayerIds.length})';
  }
}
