import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/club_admin/controllers/club_admin_controller.dart';
import 'package:orland_sports/controllers/auth_controller.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:orland_sports/const/google_maps_config.dart';

class ClubProfileScreen extends StatefulWidget {
  const ClubProfileScreen({Key? key}) : super(key: key);

  @override
  State<ClubProfileScreen> createState() => _ClubProfileScreenState();
}

class _ClubProfileScreenState extends State<ClubProfileScreen> {
  final ClubAdminController controller = Get.find<ClubAdminController>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  // SII Info
  final TextEditingController razonSocialController = TextEditingController();
  final TextEditingController rutController = TextEditingController();
  final TextEditingController giroController = TextEditingController();

  // Banking Info
  final TextEditingController bankController = TextEditingController();
  final TextEditingController accNumberController = TextEditingController();
  final TextEditingController emailPagosController = TextEditingController();
  String? selectedAccType;
  
  double currentLat = 0.0;
  double currentLng = 0.0;
  
  TimeOfDay? openingTime;
  TimeOfDay? closingTime;

  @override
  void initState() {
    super.initState();
    _loadClubData();
  }

  void _loadClubData() {
    final club = controller.currentClub.value;
    if (club != null) {
      nameController.text = club.name;
      phoneController.text = club.phone ?? '';
      addressController.text = club.address ?? '';
      currentLat = club.lat;
      currentLng = club.lng;
      
      razonSocialController.text = club.razonSocial ?? '';
      rutController.text = club.rutEmpresa ?? '';
      giroController.text = club.giro ?? '';
      bankController.text = club.banco ?? '';
      accNumberController.text = club.numeroCuenta ?? '';
      emailPagosController.text = club.emailPagos ?? '';
      selectedAccType = club.tipoCuenta;
      // If we had opening/closing time in db we'd load it here too.
    }
  }

  Future<void> _selectTime(BuildContext context, bool isOpening) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6B4EFF),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isOpening) {
          openingTime = picked;
        } else {
          closingTime = picked;
        }
      });
    }
  }

  void _saveProfile() {
    final data = <String, dynamic>{
      'name': nameController.text.trim(),
      'contact_phone': phoneController.text.trim(),
      'address': addressController.text.trim(),
      'latitude': currentLat,
      'longitude': currentLng,
      'razon_social': razonSocialController.text.trim(),
      'rut_empresa': rutController.text.trim(),
      'giro': giroController.text.trim(),
      'banco': bankController.text.trim(),
      'tipo_cuenta': selectedAccType,
      'numero_cuenta': accNumberController.text.trim(),
      'email_pagos': emailPagosController.text.trim(),
    };

    controller.updateProfile(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Perfil del Club', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
          return const Center(child: Text("Debes registrar un club primero."));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF6B4EFF).withOpacity(0.1),
                  child: const Icon(Icons.storefront, size: 50, color: Color(0xFF6B4EFF)),
                ),
              ),
              const SizedBox(height: 24),
              
              const Text('Información General', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildTextField(nameController, 'Nombre del Club', Icons.store),
              const SizedBox(height: 12),
              _buildTextField(phoneController, 'Teléfono', Icons.phone, inputType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildAddressField(),
              
              const SizedBox(height: 24),
              const Text('Horarios de Operación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTimePickerField('Apertura', openingTime, () => _selectTime(context, true)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimePickerField('Cierre', closingTime, () => _selectTime(context, false)),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('Información Tributaria (SII)', Icons.business),
              const SizedBox(height: 16),
              _buildTextField(razonSocialController, 'Razón Social', Icons.assignment),
              const SizedBox(height: 12),
              _buildTextField(rutController, 'RUT Empresa', Icons.badge),
              const SizedBox(height: 12),
              _buildTextField(giroController, 'Giro Comercial', Icons.work),

              const SizedBox(height: 32),
              _buildSectionTitle('Datos Bancarios (Recepción de Pagos)', Icons.account_balance),
              const SizedBox(height: 16),
              _buildTextField(bankController, 'Banco', Icons.account_balance),
              const SizedBox(height: 12),
              _buildDropdownField('Tipo de Cuenta', ['Corriente', 'Vista/RUT'], selectedAccType, (val) => setState(() => selectedAccType = val)),
              const SizedBox(height: 12),
              _buildTextField(accNumberController, 'Número de Cuenta', Icons.numbers, inputType: TextInputType.number),
              const SizedBox(height: 12),
              _buildTextField(emailPagosController, 'Email de Comprobante', Icons.alternate_email, inputType: TextInputType.emailAddress),

              const SizedBox(height: 40),
              
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4EFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Guardar Cambios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextButton.icon(
                onPressed: () {
                  AuthController.instance.signOut();
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAddressField() {
    return GooglePlaceAutoCompleteTextField(
      textEditingController: addressController,
      googleAPIKey: GoogleMapsConfig.apiKey,
      inputDecoration: InputDecoration(
        labelText: 'Buscar Dirección del Club',
        prefixIcon: const Icon(Icons.map, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      debounceTime: 600,
      countries: const ["cl"], // Ajustado para Chile
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
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData? icon, {TextInputType? inputType}) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF6B4EFF)) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6B4EFF), width: 2),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6B4EFF), size: 22),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> options, String? value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.merge_type, color: Color(0xFF6B4EFF)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildTimePickerField(String label, TimeOfDay? time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              time != null ? time.format(context) : label,
              style: TextStyle(
                color: time != null ? Colors.black87 : Colors.grey.shade600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
