import 'package:flutter/material.dart';
import 'package:orland_sports/View/Screens/Users/History/history_matches_screen.dart';

/// Legacy wrapper — redirects to [HistoryMatchesScreen] with won filter.
class WinMatches extends StatelessWidget {
  const WinMatches({super.key});

  @override
  Widget build(BuildContext context) {
    return const HistoryMatchesScreen(filterType: HistoryFilterType.won);
  }
}
