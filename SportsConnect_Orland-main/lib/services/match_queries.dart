/// Shared PostgREST select query for matches with all related rows.
///
/// Used by [MatchService] (CRUD) and [MatchmakingService] (search) so the
/// shape of a fetched match — courts, players and referee joins — stays
/// identical across every read path.
const String kMatchSelectQuery = '''
  *,
  courts(*, sports(*)),
  player1:users!matches_player1_id_fkey(*),
  player2:users!matches_player2_id_fkey(*),
  player3:users!matches_player3_id_fkey(*),
  player4:users!matches_player4_id_fkey(*),
  referee:users!matches_referee_id_fkey(*)
''';
