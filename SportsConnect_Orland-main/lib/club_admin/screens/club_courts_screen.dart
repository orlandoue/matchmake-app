import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/club_admin/controllers/club_admin_controller.dart';
import 'package:orland_sports/models/sport_model.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:orland_sports/const/google_maps_config.dart';

class ClubCourtsScreen extends StatefulWidget {
  const ClubCourtsScreen({Key? key}) : super(key: key);

  @override
  State<ClubCourtsScreen> createState() => _ClubCourtsScreenState();
}

class _ClubCourtsScreenState extends State<ClubCourtsScreen> {
  final ClubAdminController controller = Get.find<ClubAdminController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Obx(() => Text(
              controller.currentClub.value?.name ?? 'Dashboard',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            )),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(color: Colors.black87),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6B4EFF)));
        }

        if (!controller.hasClub) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          color: const Color(0xFF6B4EFF),
          onRefresh: controller.loadDashboardData,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              _buildMetricsInfo(),
              const SizedBox(height: 24),
              const Text(
                'Tus Canchas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildCourtsList(),
            ],
          ),
        );
      }),
      floatingActionButton: Obx(() => controller.hasClub
          ? FloatingActionButton(
              onPressed: () => _showAddCourtBottomSheet(context),
              backgroundColor: const Color(0xFF6B4EFF),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : const SizedBox.shrink()),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6B4EFF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront, size: 64, color: Color(0xFF6B4EFF)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Bienvenido a Matchmake',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Registra tu recinto deportivo para comenzar a gestionar tus canchas y agenda.',
              style: TextStyle(fontSize: 15, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _showCreateClubBottomSheet(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4EFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Crear mi Club', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateClubBottomSheet(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    double currentLat = 0.0;
    double currentLng = 0.0;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registrar Club',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Club',
                  prefixIcon: const Icon(Icons.store),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Teléfono de Contacto',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              GooglePlaceAutoCompleteTextField(
                textEditingController: addressController,
                googleAPIKey: GoogleMapsConfig.apiKey,
                inputDecoration: InputDecoration(
                  labelText: 'Dirección del Recinto',
                  prefixIcon: const Icon(Icons.map),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                debounceTime: 600,
                countries: const ["cl"],
                isLatLngRequired: true,
                getPlaceDetailWithLatLng: (Prediction prediction) {
                  if (prediction.lat != null && prediction.lng != null) {
                    currentLat = double.tryParse(prediction.lat!) ?? 0.0;
                    currentLng = double.tryParse(prediction.lng!) ?? 0.0;
                  }
                },
                itemClick: (Prediction prediction) {
                  addressController.text = prediction.description ?? "";
                  addressController.selection = TextSelection.fromPosition(
                      TextPosition(offset: addressController.text.length));
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(() {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B4EFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: controller.isCreatingClub.value
                        ? null
                        : () {
                            controller.createClub(
                              nameController.text, 
                              phoneController.text,
                              addressController.text,
                              currentLat,
                              currentLng
                            );
                          },
                    child: controller.isCreatingClub.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Guardar y Continuar',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildMetricsInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Centro de Control B2B',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Hoy',
                value: controller.todayReservations.value.toString(),
                subtitle: 'Reservas',
                icon: Icons.today,
                color: const Color(0xFF6B4EFF),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                title: 'Semana',
                value: controller.weekReservations.value.toString(),
                subtitle: 'Reservas',
                icon: Icons.date_range,
                color: const Color(0xFF00C48C),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                title: 'Mensual',
                value: controller.monthReservations.value.toString(),
                subtitle: 'Reservas',
                icon: Icons.calendar_month,
                color: const Color(0xFFFFBB00),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCourtsList() {
    final courts = controller.myCourts;

    if (courts.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text('No tienes canchas registradas.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: courts.length,
      itemBuilder: (context, index) {
        final court = courts[index];
        final sportName = court.sports != null && court.sports!.isNotEmpty 
           ? court.sports!.first.name 
           : 'Desconocido';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF6B4EFF).withOpacity(0.1),
              child: const Icon(Icons.sports, color: Color(0xFF6B4EFF)),
            ),
            title: Text(court.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Deporte: $sportName'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: court.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                court.isActive ? 'Activa' : 'Inactiva',
                style: TextStyle(
                  color: court.isActive ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddCourtBottomSheet(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    SportModel? selectedSport;

    Get.bottomSheet(
      StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nueva Cancha',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de la cancha',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<SportModel>(
                  decoration: InputDecoration(
                    labelText: 'Deporte',
                    prefixIcon: const Icon(Icons.sports_basketball),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  initialValue: selectedSport,
                  items: controller.sports.map((SportModel sport) {
                    return DropdownMenuItem<SportModel>(
                      value: sport,
                      child: Text(sport.name),
                    );
                  }).toList(),
                  onChanged: (SportModel? value) {
                    setState(() {
                      selectedSport = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Obx(() {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4EFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: controller.isCreatingCourt.value
                          ? null
                          : () {
                              if (selectedSport != null) {
                                controller.createCourt(
                                    nameController.text, selectedSport!.id);
                              } else {
                                Get.snackbar('Error', 'Selecciona un deporte',
                                    backgroundColor: Colors.red.withOpacity(0.9),
                                    colorText: Colors.white);
                              }
                            },
                      child: controller.isCreatingCourt.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'GUARDAR',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      }),
      isScrollControlled: true,
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
          ),
        ],
      ),
    );
  }
}
