import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/club_admin/controllers/club_admin_controller.dart';
import 'package:intl/intl.dart';
import 'package:orland_sports/models/match_model.dart';
import 'package:orland_sports/enums/match_status.dart';

class ClubAgendaScreen extends StatefulWidget {
  const ClubAgendaScreen({Key? key}) : super(key: key);

  @override
  State<ClubAgendaScreen> createState() => _ClubAgendaScreenState();
}

class _ClubAgendaScreenState extends State<ClubAgendaScreen> {
  final ClubAdminController controller = Get.find<ClubAdminController>();

  final List<String> hours = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30', '11:00', '11:30', '12:00', '12:30',
    '13:00', '13:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30', '17:00', '17:30',
    '18:00', '18:30', '19:00', '19:30', '20:00', '20:30', '21:00', '21:30', '22:00', '22:30',
    '23:00', '23:30'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Agenda Diaria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(color: Colors.black87),
      ),
      body: Column(
        children: [
          _buildDatePicker(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value || controller.isLoadingAgenda.value) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF6B4EFF)));
              }
              
              if (controller.myCourts.isEmpty) {
                return const Center(child: Text('No hay canchas registradas para mostrar agenda.'));
              }

              return _buildAgendaGrid();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        height: 70,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 14, // 14 días
          itemBuilder: (context, index) {
            final date = DateTime.now().add(Duration(days: index));
            
            return Obx(() {
              final selectedDate = controller.selectedAgendaDate.value;
              final isSelected = date.day == selectedDate.day && date.month == selectedDate.month;
              
              return GestureDetector(
                onTap: () {
                  controller.setAgendaDate(date);
                },
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6B4EFF) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF6B4EFF) : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE', 'es').format(date).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 18,
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  Widget _buildAgendaGrid() {
    final courts = controller.myCourts;
    const double timeColWidth = 60.0;
    const double courtColMinWidth = 90.0;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double minTotalWidth = timeColWidth + courts.length * courtColMinWidth;
    final double gridWidth = minTotalWidth < screenWidth ? screenWidth : minTotalWidth;

    // Outer: vertical scroll for all the time rows (32 rows × 60px ≈ 1920px)
    // Inner: horizontal scroll for multiple courts
    // Using a plain Column (not ListView) inside the horizontal scroll so there
    // is no shrinkWrap conflict with the bounded Expanded parent.
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: gridWidth,
          child: Column(
            children: [
              // ── Court header row ───────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(left: 60, top: 12, bottom: 12),
                child: Row(
                  children: courts.map((c) => Expanded(
                    child: Center(
                      child: Text(
                        c.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )).toList(),
                ),
              ),
              const Divider(height: 1),
              // ── Time slot rows (plain Column — no shrinkWrap needed) ───
              ...hours.map((time) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      // Time label
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: Center(
                          child: Text(
                            time,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      // Court cells
                      ...courts.map((court) {
                        final match = controller.dailyMatches.firstWhereOrNull((m) {
                          if (m.courtId != court.id) return false;
                          final rawTime = m.scheduledTime;
                          if (rawTime.isEmpty) return false;
                          try {
                            final base = DateTime(2000, 1, 1);
                            DateTime matchStart;

                            // Support both "2:00 PM" (AM/PM) and "14:00" (24h) formats
                            if (rawTime.contains('AM') || rawTime.contains('PM') ||
                                rawTime.contains('am') || rawTime.contains('pm')) {
                              final p = DateFormat('h:mm a').parse(rawTime);
                              matchStart = DateTime(base.year, base.month, base.day, p.hour, p.minute);
                            } else {
                              final p = DateFormat('HH:mm').parse(rawTime);
                              matchStart = DateTime(base.year, base.month, base.day, p.hour, p.minute);
                            }

                            DateTime matchEnd;
                            final rawEnd = m.scheduledEndTime;
                            if (rawEnd != null && rawEnd.isNotEmpty) {
                              DateTime endParsed;
                              if (rawEnd.contains('AM') || rawEnd.contains('PM') ||
                                  rawEnd.contains('am') || rawEnd.contains('pm')) {
                                final p = DateFormat('h:mm a').parse(rawEnd);
                                endParsed = DateTime(base.year, base.month, base.day, p.hour, p.minute);
                              } else {
                                final p = DateFormat('HH:mm').parse(rawEnd);
                                endParsed = DateTime(base.year, base.month, base.day, p.hour, p.minute);
                              }
                              matchEnd = endParsed;
                              if (matchEnd.isBefore(matchStart) || matchEnd.isAtSameMomentAs(matchStart)) {
                                matchEnd = matchEnd.add(const Duration(days: 1));
                              }
                            } else {
                              matchEnd = matchStart.add(const Duration(minutes: 60));
                            }

                            final cellP = DateFormat('HH:mm').parse(time);
                            final cellTime = DateTime(base.year, base.month, base.day, cellP.hour, cellP.minute);

                            return (cellTime.isAtSameMomentAs(matchStart) ||
                                    cellTime.isAfter(matchStart)) &&
                                cellTime.isBefore(matchEnd);
                          } catch (_) {
                            return false;
                          }
                        });

                        return Expanded(
                          child: Container(
                            height: 60,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border(left: BorderSide(color: Colors.grey.shade200)),
                            ),
                            child: match != null
                                ? _buildOccupiedSlot(match)
                                : _buildAvailableSlot(court.id, time),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOccupiedSlot(MatchModel match) {
    bool isBlocked = match.status == MatchStatus.blocked;
    bool isOfficialMatch = match.matchMode != MatchMode.manualReservation;

    Color bgColor = Colors.red.shade50;
    Color borderColor = Colors.red.shade200;
    Color textColor = Colors.red;
    String label = 'Ocupado';

    if (isBlocked) {
      bgColor = Colors.grey.shade800;
      borderColor = Colors.grey.shade900;
      textColor = Colors.white;
      label = 'Bloqueado';
    } else if (isOfficialMatch) {
      bgColor = const Color(0xFF6B4EFF);
      borderColor = const Color(0xFF5A3EE0);
      textColor = Colors.white;
      
      // Construir etiqueta descriptiva: "Deporte Tipo"
      String sportName = 'Pádel'; // Fallback estático para evitar error de casteo en CourtModel
      label = '$sportName ${match.matchType.displayName}';
    } else    label = match.matchMode.displayName;
  

    return GestureDetector(
      onTap: isBlocked 
          ? () => _showUnblockDialog(match) 
          : (isOfficialMatch ? () => _showMatchDetailsModal(match) : null),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
          boxShadow: isOfficialMatch ? [
            BoxShadow(
              color: const Color(0xFF6B4EFF).withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              label,
              style: TextStyle(
                color: textColor, 
                fontSize: 9, 
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  void _showMatchDetailsModal(MatchModel match) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detalles del Partido',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Confirmado',
                    style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow(Icons.sports_tennis, 'Deporte y Modalidad', 'Pádel ${match.matchType.displayName}'),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.access_time, 'Horario', '${match.scheduledTime} - ${match.scheduledEndTime ?? '90 min'}'),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.location_on, 'Cancha', match.court?.name ?? 'Cancha Principal'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4EFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cerrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6B4EFF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF6B4EFF), size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ],
    );
  }

  void _showUnblockDialog(MatchModel match) {
    Get.dialog(
      AlertDialog(
        title: const Text('Desbloquear Turno'),
        content: const Text('¿Deseas desbloquear este turno y volverlo a poner disponible?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.unblockCourt(match.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desbloquear', style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );
  }

  Widget _buildAvailableSlot(String courtId, String time) {
    return GestureDetector(
      onTap: () {
        _showBlockDialog(courtId, time);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF6B4EFF).withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF6B4EFF).withOpacity(0.2)),
        ),
        child: const Center(
          child: Text(
            'Disponible',
            style: TextStyle(color: Color(0xFF6B4EFF), fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _showBlockDialog(String courtId, String time) {
    Get.dialog(
      AlertDialog(
        title: const Text('Bloquear Horario'),
        content: Text('¿Estás seguro de bloquear esta cancha a las $time?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.blockCourtTime(courtId, time);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B4EFF)),
            child: const Text('Bloquear', style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );
  }
}
