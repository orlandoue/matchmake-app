import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/club_admin/controllers/club_wallet_controller.dart';

class ClubWalletScreen extends StatelessWidget {
  const ClubWalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lazy-find so it works whether registered in nav or here
    final controller = Get.find<ClubWalletController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        title: const Text(
          'Billetera del Club',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0A0A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Obx(() => IconButton(
                icon: controller.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF6B4EFF),
                        ),
                      )
                    : const Icon(Icons.refresh, color: Colors.white70),
                onPressed:
                    controller.isLoading.value ? null : controller.loadWalletData,
              )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6B4EFF)),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFF6B4EFF),
          backgroundColor: const Color(0xFF1A1A2E),
          onRefresh: controller.loadWalletData,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Hero Balance Card ───────────────────────────────────────
              _HeroBalanceCard(controller: controller),
              const SizedBox(height: 20),
              // ── KPI Row ─────────────────────────────────────────────────
              _KpiRow(controller: controller),
              const SizedBox(height: 28),
              // ── Withdrawal Button ───────────────────────────────────────
              _WithdrawalButton(controller: controller),
              const SizedBox(height: 32),
              // ── Transaction History ─────────────────────────────────────
              _HistorySection(controller: controller),
            ],
          ),
        );
      }),
    );
  }
}

// ── Hero Balance Card ──────────────────────────────────────────────────────────

class _HeroBalanceCard extends StatelessWidget {
  final ClubWalletController controller;

  const _HeroBalanceCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B4EFF), Color(0xFF9B59F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4EFF).withOpacity(0.45),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              const Text(
                'Saldo Neto a Liquidar',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() => Text(
                controller.formatClp(controller.netBalance.value),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              )),
          const SizedBox(height: 6),
          const Text(
            'CLP · Acumulado total',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── KPI Row ────────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final ClubWalletController controller;

  const _KpiRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Partidos\nCompletados',
                value: controller.completedMatchesTotal.value.toString(),
                icon: Icons.sports_tennis_rounded,
                color: const Color(0xFF00C48C),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'Ingresos\neste Mes',
                value: controller.formatClp(controller.monthEarnings.value),
                icon: Icons.trending_up_rounded,
                color: const Color(0xFFFFBB00),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'Partidos\neste Mes',
                value: controller.completedMatchesMonth.value.toString(),
                icon: Icons.calendar_today_rounded,
                color: const Color(0xFF6B4EFF),
              ),
            ),
          ],
        ));
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141428),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Withdrawal Button ──────────────────────────────────────────────────────────

class _WithdrawalButton extends StatelessWidget {
  final ClubWalletController controller;

  const _WithdrawalButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasBalance = controller.netBalance.value > 0;

      return SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: controller.isLoading.value
              ? null
              : controller.requestWithdrawal,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                hasBalance ? const Color(0xFF12B76A) : Colors.grey.shade800,
            disabledBackgroundColor: Colors.grey.shade800,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: hasBalance ? 4 : 0,
            shadowColor: const Color(0xFF12B76A).withOpacity(0.4),
          ),
          icon: Icon(
            hasBalance
                ? Icons.upload_rounded
                : Icons.lock_outline_rounded,
            color: Colors.white,
            size: 20,
          ),
          label: Text(
            hasBalance
                ? 'Solicitar Retiro de ${controller.formatClp(controller.netBalance.value)}'
                : 'Sin saldo disponible',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      );
    });
  }
}

// ── Transaction History ────────────────────────────────────────────────────────

class _HistorySection extends StatelessWidget {
  final ClubWalletController controller;

  const _HistorySection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final entries = controller.entries;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Historial de Ingresos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B4EFF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Obx(() => Text(
                      '${controller.completedMatchesTotal.value} partidos',
                      style: const TextStyle(
                        color: Color(0xFF9B7FFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            _EmptyHistory()
          else
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _HistoryTile(
                  entry: entry,
                  controller: controller,
                );
              },
            ),
        ],
      );
    });
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF141428),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 52,
            color: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin transacciones aún',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Los ingresos aparecerán aquí una vez\nque se completen partidos en tu recinto.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white30,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final WalletEntry entry;
  final ClubWalletController controller;

  const _HistoryTile({required this.entry, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141428),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6B4EFF).withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          // Sport icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF6B4EFF).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sports_tennis_rounded,
              color: Color(0xFF9B7FFF),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.sportName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${entry.courtName} · ${controller.formatDate(entry.scheduledDate)}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                controller.formatClp(entry.amount),
                style: const TextStyle(
                  color: Color(0xFF12B76A),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'CLP',
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
