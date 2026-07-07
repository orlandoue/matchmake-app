import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/ticket_controller.dart';
import 'package:orland_sports/generated/assets.dart';

class BuyTicketsScreen extends StatelessWidget {
  const BuyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TicketController>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kwhite,
        appBar: simpleAppBar2(
          title: 'Tienda',
          haveBackButton: true,
          centerTitle: false,
        ),
        body: Column(
          children: [
            // Elegant TabBar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0A192F), // Cyber Navy
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: const Color(0xFF00FF85), // Cyber Neon
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: const Color(0xFF0A192F),
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: 'Pases Únicos'),
                  Tab(text: 'Suscripciones VIP'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPasesUnicosTab(controller),
                  _buildVIPTab(controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasesUnicosTab(TicketController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toggle Singles / Dobles
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Obx(() {
            final isSingles = controller.purchasingTicketType.value == 'singles';
            return Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.purchasingTicketType.value = 'singles',
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSingles ? kpurple1 : kgrey2.withValues(alpha: 0.5),
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                      ),
                      alignment: Alignment.center,
                      child: MyText(
                        text: 'Singles',
                        color: isSingles ? kwhite : kgrey1,
                        weight: isSingles ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.purchasingTicketType.value = 'doubles',
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !isSingles ? kpurple1 : kgrey2.withValues(alpha: 0.5),
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                      ),
                      alignment: Alignment.center,
                      child: MyText(
                        text: 'Dobles',
                        color: !isSingles ? kwhite : kgrey1,
                        weight: !isSingles ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 10),
              // Current balance card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kpurple1, kpurple2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      Assets.imagesTicket,
                      width: 48,
                      height: 48,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(() => MyText(
                                text: controller.purchasingTicketType.value == 'singles' ? 'Tus Pases (Singles)' : 'Tus Pases (Dobles)',
                                size: 14,
                                color: kwhite.withValues(alpha: 0.8),
                              )),
                          const SizedBox(height: 4),
                          Obx(() => MyText(
                                text: '${controller.purchasingTicketType.value == 'singles' ? controller.singlesBalance.value : controller.doublesBalance.value}',
                                size: 32,
                                weight: FontWeight.bold,
                                color: kwhite,
                              )),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.confirmation_number_outlined,
                      color: kwhite.withValues(alpha: 0.3),
                      size: 64,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Ticket card
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kpurple1),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(11)),
                      child: Image.asset(
                        Assets.imagesTicket2,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const Divider(color: kpurple1, height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Obx(() => MyText(
                            text: controller.purchasingTicketType.value == 'singles' ? 'Pase Singles (1v1)' : 'Pase Dobles (2v2)',
                            size: 16,
                            weight: FontWeight.w600,
                            color: kpurple1,
                          )),
                          Obx(() => MyText(
                            text:
                                '\$${controller.priceForType(controller.purchasingTicketType.value).toStringAsFixed(0)} ${TicketController.currency}',
                            size: 16,
                            weight: FontWeight.bold,
                            color: kpurple1,
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quantity selector
              Center(
                child: MyText(
                  text: 'quantity'.tr,
                  size: 16,
                  weight: FontWeight.bold,
                  color: kblack2,
                  paddingBottom: 16,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _QuantityButton(
                    icon: Icons.remove,
                    onTap: controller.decrementQuantity,
                  ),
                  const SizedBox(width: 24),
                  Obx(() => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                        decoration: BoxDecoration(
                          color: kgrey2,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: MyText(
                          text: '${controller.selectedQuantity.value}',
                          size: 20,
                          weight: FontWeight.bold,
                          color: kblack2,
                        ),
                      )),
                  const SizedBox(width: 24),
                  _QuantityButton(
                    icon: Icons.add,
                    onTap: controller.incrementQuantity,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Order summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kpurple1.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kpurple1.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MyText(
                          text: 'total'.tr,
                          size: 18,
                          weight: FontWeight.bold,
                          color: kblack2,
                        ),
                        Obx(() => MyText(
                              text:
                                  '\$${controller.totalPrice.toStringAsFixed(0)} ${TicketController.currency}',
                              size: 18,
                              weight: FontWeight.bold,
                              color: kpurple1,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),

        // Buy button section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kwhite,
            boxShadow: [
              BoxShadow(
                color: kblack2.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Obx(() => controller.isPurchasing.value
                ? const Center(
                    child: CircularProgressIndicator(color: kpurple1))
                : MyButton(
                    width: double.infinity, // Full width button
                    onTap: () => controller.purchaseTickets(),
                    buttonText:
                        '${'pay_amount'.tr} \$${controller.totalPrice.toStringAsFixed(0)} ${TicketController.currency}',
                  )),
          ),
        ),
      ],
    );
  }

  Widget _buildVIPTab(TicketController controller) {
    return Container(
      color: const Color(0xFF0A192F), // Cyber Navy background for VIP tab
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        physics: const BouncingScrollPhysics(),
        children: [
          MyText(
            text: 'Desata tu verdadero potencial.',
            color: Colors.white70,
            size: 14,
            textAlign: TextAlign.center,
            paddingBottom: 20,
          ),
          _buildVipCard(
            controller: controller,
            title: 'BÁSICO',
            price: 4000,
            description: '4 Pases Mensuales + Radar VIP.',
            isGold: false,
          ),
          _buildVipCard(
            controller: controller,
            title: 'PRO',
            price: 8000,
            description: '8 Pases Mensuales + Radar VIP.',
            isGold: false,
          ),
          _buildVipCard(
            controller: controller,
            title: 'ÉLITE',
            price: 12000,
            description: '12 Pases Mensuales + Radar VIP.',
            isGold: false,
          ),
          const SizedBox(height: 10),
          _buildVipCard(
            controller: controller,
            title: 'LEYENDA PADELERO',
            price: 79990,
            description: 'Pases Ilimitados + Radar VIP + Estatus Leyenda.',
            isGold: true,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildVipCard({
    required TicketController controller,
    required String title,
    required double price,
    required String description,
    required bool isGold,
  }) {
    final cyberNeon = const Color(0xFF00FF85);
    final goldColor = const Color(0xFFFFD700);
    final mainColor = isGold ? goldColor : cyberNeon;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mainColor.withValues(alpha: 0.5), width: isGold ? 2 : 1),
        boxShadow: isGold
            ? [BoxShadow(color: goldColor.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 2)]
            : [],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText(text: title, size: 20, weight: FontWeight.bold, color: mainColor),
              MyText(text: '\$${price.toStringAsFixed(0)}', size: 22, weight: FontWeight.bold, color: Colors.white),
            ],
          ),
          const SizedBox(height: 10),
          MyText(text: description, size: 14, color: Colors.white70),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isGold ? goldColor.withValues(alpha: 0.1) : cyberNeon.withValues(alpha: 0.1),
                side: BorderSide(color: mainColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => controller.subscribeToPlan(title, price),
              child: MyText(
                text: 'Suscribirse',
                color: mainColor,
                weight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: kpurple1.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kpurple1),
        ),
        child: Icon(icon, color: kpurple1),
      ),
    );
  }
}
