import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/ticket_controller.dart';

/// Premium metallic accents allowed ONLY on the VIP tab (design rule).
/// Base palette stays 100% Pádel (kpurple*).
const _bronze = Color(0xFFCD7F32);
const _silver = Color(0xFFB9C2CC);
const _gold = Color(0xFFFFD54A);

/// A VIP subscription plan (simulation data).
class _VipPlan {
  final String id;
  final String? tagline;
  final double price;
  final List<String> benefits;
  final Color accent;
  final bool highlighted;

  const _VipPlan({
    required this.id,
    this.tagline,
    required this.price,
    required this.benefits,
    required this.accent,
    this.highlighted = false,
  });
}

const List<_VipPlan> _vipPlans = [
  _VipPlan(
    id: 'Bronce',
    price: 4000,
    benefits: ['4 pases mensuales', 'VIP Radar'],
    accent: _bronze,
  ),
  _VipPlan(
    id: 'Plata',
    price: 8000,
    benefits: ['8 pases mensuales', 'VIP Radar'],
    accent: _silver,
  ),
  _VipPlan(
    id: 'Oro',
    price: 12000,
    benefits: ['12 pases mensuales', 'VIP Radar'],
    accent: _gold,
  ),
  _VipPlan(
    id: 'Ultra VIP',
    tagline: 'Leyenda',
    price: 79990,
    benefits: ['Pases ilimitados', 'VIP Radar', 'Prioridad Leyenda'],
    accent: _gold,
    highlighted: true,
  ),
];

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
            // Pádel-branded TabBar (no Cyber theme)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: kgrey2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: kpurple1,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: ktransparent,
                labelColor: kwhite,
                unselectedLabelColor: kgrey1,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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

  // ==================== PASES ÚNICOS ====================

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
                    onTap: () =>
                        controller.purchasingTicketType.value = 'singles',
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSingles
                            ? kpurple1
                            : kgrey2.withValues(alpha: 0.5),
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(8)),
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
                    onTap: () =>
                        controller.purchasingTicketType.value = 'doubles',
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !isSingles
                            ? kpurple1
                            : kgrey2.withValues(alpha: 0.5),
                        borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(8)),
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
                  gradient: const LinearGradient(
                    colors: [kpurple1, kpurple2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: kwhite.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.sports_tennis_rounded,
                          color: kwhite, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(() => MyText(
                                text: controller.purchasingTicketType.value ==
                                        'singles'
                                    ? 'Tus Pases (Singles)'
                                    : 'Tus Pases (Dobles)',
                                size: 14,
                                color: kwhite.withValues(alpha: 0.8),
                              )),
                          const SizedBox(height: 4),
                          Obx(() => MyText(
                                text:
                                    '${controller.purchasingTicketType.value == 'singles' ? controller.singlesBalance.value : controller.doublesBalance.value}',
                                size: 32,
                                weight: FontWeight.bold,
                                color: kwhite,
                              )),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.sports_tennis_rounded,
                      color: kwhite.withValues(alpha: 0.25),
                      size: 64,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Pase card (no ticket imagery)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kpurple1),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      height: 92,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kpurple1, kpurple2],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.badge_rounded,
                            color: kwhite, size: 44),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Obx(() => MyText(
                                text: controller.purchasingTicketType.value ==
                                        'singles'
                                    ? 'Pase Singles (1v1)'
                                    : 'Pase Dobles (2v2)',
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
                child: Row(
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
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),

        // Buy button section (Mercado Pago via Edge Function)
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
                    width: double.infinity,
                    onTap: () => controller.purchaseTickets(),
                    buttonText:
                        '${'pay_amount'.tr} \$${controller.totalPrice.toStringAsFixed(0)} ${TicketController.currency}',
                  )),
          ),
        ),
      ],
    );
  }

  // ==================== SUSCRIPCIONES VIP ====================

  Widget _buildVIPTab(TicketController controller) {
    return Container(
      // Premium on-brand backdrop (deep Pádel purple), not the Cyber theme.
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kpurple2, kpurple1],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        physics: const BouncingScrollPhysics(),
        children: [
          MyText(
            text: 'Desata tu verdadero potencial.',
            color: kwhite.withValues(alpha: 0.75),
            size: 14,
            textAlign: TextAlign.center,
            paddingBottom: 20,
          ),
          for (final plan in _vipPlans)
            _VipPlanCard(plan: plan, controller: controller),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _VipPlanCard extends StatelessWidget {
  final _VipPlan plan;
  final TicketController controller;

  const _VipPlanCard({required this.plan, required this.controller});

  @override
  Widget build(BuildContext context) {
    final bool gold = plan.highlighted;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kwhite.withValues(alpha: gold ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: plan.accent.withValues(alpha: gold ? 0.9 : 0.45),
          width: gold ? 2 : 1,
        ),
        boxShadow: gold
            ? [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.28),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (gold) ...[
                          const Icon(Icons.workspace_premium_rounded,
                              color: _gold, size: 22),
                          const SizedBox(width: 6),
                        ],
                        MyText(
                          text: plan.id,
                          size: 20,
                          weight: FontWeight.bold,
                          color: plan.accent,
                        ),
                      ],
                    ),
                    if (plan.tagline != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: plan.accent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: MyText(
                            text: plan.tagline!.toUpperCase(),
                            size: 10,
                            weight: FontWeight.bold,
                            color: plan.accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MyText(
                    text: '\$${plan.price.toStringAsFixed(0)}',
                    size: 22,
                    weight: FontWeight.bold,
                    color: kwhite,
                  ),
                  MyText(
                    text: TicketController.currency,
                    size: 11,
                    color: kwhite.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final benefit in plan.benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: plan.accent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MyText(
                      text: benefit,
                      size: 13,
                      color: kwhite.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Obx(() {
              final busy = controller.subscribingPlanId.value == plan.id;
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      gold ? plan.accent : plan.accent.withValues(alpha: 0.12),
                  side: BorderSide(color: plan.accent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: gold ? 4 : 0,
                ),
                onPressed:
                    busy ? null : () => controller.subscribeToPlan(plan.id, plan.price),
                child: busy
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: gold ? kpurple1 : plan.accent,
                        ),
                      )
                    : MyText(
                        text: 'Suscribirse',
                        color: gold ? kpurple1 : plan.accent,
                        weight: FontWeight.bold,
                      ),
              );
            }),
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
