import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/models/expense_model.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/date_utils.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _event;
  List<ExpenseModel> _expenses = [];
  Map<String, dynamic>? _dues;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait([
        api.get('/db/event/${widget.eventId}'),
        api.get('/db/event/${widget.eventId}/expenses'),
        api.get('/db/user/event/${widget.eventId}/dues'),
      ]);

      setState(() {
        _event = results[0].data;
        final expList = results[1].data is List
            ? results[1].data
            : (results[1].data['expenses'] ?? []);
        _expenses = expList.map<ExpenseModel>((e) => ExpenseModel.fromJson(e)).toList();
        _dues = results[2].data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(apiClientProvider).delete('/db/event/${widget.eventId}');
        if (mounted) context.go('/events');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete event')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_event?['title'] ?? _event?['name'] ?? 'Event'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/events'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/event/${widget.eventId}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteEvent,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Balances'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/createExpense/event/${widget.eventId}'),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildExpensesList(),
                _buildBalances(),
              ],
            ),
    );
  }

  Widget _buildExpensesList() {
    if (_expenses.isEmpty) {
      return const Center(
        child: Text('No expenses yet', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _expenses.length,
        itemBuilder: (context, index) {
          final expense = _expenses[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              onTap: () => context.push('/expense/${expense.id}'),
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                child: Icon(
                  _getCategoryIcon(expense.category),
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${expense.paidByName ?? 'Unknown'} • ${AppDateUtils.formatDateString(expense.date ?? '')}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              trailing: Text(
                AppUtils.formatCurrency(expense.amount),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalances() {
    if (_dues == null) {
      return const Center(child: Text('No balance data'));
    }

    final balances = _dues!['balances'] ?? _dues!['dues'] ?? [];
    if (balances is! List || balances.isEmpty) {
      return const Center(
        child: Text('All settled up!', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: balances.length,
      itemBuilder: (context, index) {
        final item = balances[index];
        final amount = (item['amount'] ?? 0).toDouble();
        final isPositive = amount >= 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (isPositive ? AppTheme.successColor : AppTheme.errorColor)
                  .withOpacity(0.15),
              child: Icon(
                isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                color: isPositive ? AppTheme.successColor : AppTheme.errorColor,
                size: 20,
              ),
            ),
            title: Text(item['name'] ?? item['userName'] ?? 'Unknown'),
            subtitle: Text(
              isPositive ? 'owes you' : 'you owe',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            trailing: Text(
              AppUtils.formatCurrency(amount.abs()),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPositive ? AppTheme.successColor : AppTheme.errorColor,
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'accommodation':
        return Icons.hotel;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      default:
        return Icons.receipt;
    }
  }
}
