import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/helpers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Map<String, dynamic>? _summary;
  List<dynamic>? _chartData;
  bool _isLoading = true;
  String _selectedPeriod = 'This Month';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1).toIso8601String();
      final endDate = now.toIso8601String();

      final summaryRes = await apiClient.post('/db/dashboard/summary', data: {
        'startDate': startDate,
        'endDate': endDate,
      });

      final chartRes = await apiClient.post('/db/dashboard/chart', data: {
        'startDate': startDate,
        'endDate': endDate,
      });

      setState(() {
        _summary = summaryRes.data;
        _chartData = chartRes.data is List ? chartRes.data : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load dashboard data';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          _buildPeriodDropdown(),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: _buildContent(),
                  ),
                ),
    );
  }

  Widget _buildPeriodDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          dropdownColor: AppTheme.cardColor,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          items: ['This Week', 'This Month', 'This Year', 'All Time']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedPeriod = val);
              _loadData();
            }
          },
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary cards
        if (isWide)
          Row(children: _buildSummaryCards().map((c) => Expanded(child: c)).toList())
        else
          ..._buildSummaryCards(),
        const SizedBox(height: 24),

        // Chart section
        _buildChartSection(),
        const SizedBox(height: 24),

        // Quick actions
        _buildQuickActions(),
      ],
    );
  }

  List<Widget> _buildSummaryCards() {
    final totalOwed = (_summary?['totalOwed'] ?? 0).toDouble();
    final totalOwe = (_summary?['totalOwe'] ?? 0).toDouble();
    final totalExpense = (_summary?['totalExpense'] ?? 0).toDouble();

    return [
      _SummaryCard(
        title: 'Total Expenses',
        amount: totalExpense,
        icon: Icons.account_balance_wallet_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4A42D9)],
        ),
      ),
      _SummaryCard(
        title: 'You Are Owed',
        amount: totalOwed,
        icon: Icons.arrow_downward_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF009624)],
        ),
      ),
      _SummaryCard(
        title: 'You Owe',
        amount: totalOwe,
        icon: Icons.arrow_upward_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
        ),
      ),
    ];
  }

  Widget _buildChartSection() {
    if (_chartData == null || _chartData!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No expense data for this period',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expenses by Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: _buildChartSections(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: _buildLegend(),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections() {
    final colors = [
      const Color(0xFFBB86FC),
      const Color(0xFF03DAC6),
      const Color(0xFFFF6B6B),
      const Color(0xFFFFD93D),
      const Color(0xFF6BCB77),
      const Color(0xFF4D96FF),
      const Color(0xFFFF8C32),
    ];

    return _chartData!.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      final amount = (item['amount'] ?? item['total'] ?? 0).toDouble();
      return PieChartSectionData(
        value: amount,
        color: colors[i % colors.length],
        radius: 35,
        showTitle: false,
      );
    }).toList();
  }

  List<Widget> _buildLegend() {
    final colors = [
      const Color(0xFFBB86FC),
      const Color(0xFF03DAC6),
      const Color(0xFFFF6B6B),
      const Color(0xFFFFD93D),
      const Color(0xFF6BCB77),
      const Color(0xFF4D96FF),
      const Color(0xFFFF8C32),
    ];

    return _chartData!.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      final label = item['category'] ?? item['name'] ?? 'Other';
      final amount = (item['amount'] ?? item['total'] ?? 0).toDouble();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: colors[i % colors.length],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text('$label (${AppUtils.formatCurrency(amount)})',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      );
    }).toList();
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.add_circle_outline,
                label: 'New Event',
                onTap: () => context.push('/create-event'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.person_add_outlined,
                label: 'Add Friend',
                onTap: () => context.push('/friends'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.receipt_long_outlined,
                label: 'Add Expense',
                onTap: () => context.push('/personal-expenses'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final LinearGradient gradient;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, right: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppUtils.formatCurrency(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
