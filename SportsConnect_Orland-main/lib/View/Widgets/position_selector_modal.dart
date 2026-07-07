import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';

class PositionSelectorModal {
  static void show({required Function(String position) onPositionSelected}) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: kwhite,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText(
                text: 'Elige tu Lado',
                size: 20,
                weight: FontWeight.bold,
                color: kblack2,
                paddingBottom: 8,
              ),
              MyText(
                text: 'Selecciona la posición en la que prefieres jugar.',
                size: 14,
                color: kgrey1,
                textAlign: TextAlign.center,
                paddingBottom: 24,
              ),
              _buildOption('Drive', 'Derecha', Icons.arrow_forward, onPositionSelected),
              const SizedBox(height: 12),
              _buildOption('Revés', 'Izquierda', Icons.arrow_back, onPositionSelected),
              const SizedBox(height: 12),
              _buildOption('Ambos', 'Cualquier lado', Icons.swap_horiz, onPositionSelected),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Get.back(),
                child: MyText(text: 'Cancelar', color: kgrey1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildOption(String title, String subtitle, IconData icon, Function(String) onSelected) {
    return GestureDetector(
      onTap: () {
        Get.back(); // close dialog
        onSelected(title);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: kpurple1.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kpurple1.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kpurple1.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: kpurple1, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(text: title, size: 16, weight: FontWeight.bold, color: kpurple1),
                  MyText(text: subtitle, size: 12, color: kgrey1),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kpurple1),
          ],
        ),
      ),
    );
  }
}

// Utility function to get position badge
Widget getPositionBadge(String? position) {
  if (position == null || position.isEmpty) return const SizedBox.shrink();
  
  String short = '';
  Color color = kpurple1;
  
  if (position.toLowerCase() == 'drive') {
    short = 'DRV';
    color = Colors.blue;
  } else if (position.toLowerCase() == 'revés' || position.toLowerCase() == 'reves') {
    short = 'REV';
    color = Colors.orange;
  } else if (position.toLowerCase() == 'ambos') {
    short = 'AMB';
    color = Colors.green;
  } else {
    short = position.substring(0, 3).toUpperCase();
  }

  return Container(
    margin: const EdgeInsets.only(left: 8),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Text(
      short,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    ),
  );
}
