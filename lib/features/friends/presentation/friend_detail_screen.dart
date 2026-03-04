import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/models/expense_model.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/date_utils.dart';

class FriendDetailScreen extends ConsumerStatefulWidget {
  final String friendId;
  const FriendDetailScreen({super.key, required this.friendId});

  @override
  ConsumerState<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends ConsumerState<FriendDetailScreen> {
  Map<String, dynamic>? _friendData;
  List<ExpenseModel> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response =
          await api.get('/db/user/expense/friend/${widget.friendId}');
      final data = response.data;
      setState(() {
        _friendData = data;
        final expList = data['expenses'] ?? [];
        _expenses = (expList as List)
            .map<ExpenseModel>((e) => ExpenseModel.fromJson(e))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _settleUp() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settle Up'),
        content: const Text('Mark all expenses with this friend as settled?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Settle'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(apiClientProvider).post(
              '/db/user/expense/friend/${widget.friendId}/settleup',
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Settled up!'),
              backgroundColor: AppTheme.successColor),
        );
        _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to settle')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = (_friendData?['balance'] ?? 0).toDouble();
    final friendName =
        _friendData?['name'] ?? _friendData?['friendName'] ?? 'Friend';

    return Scaffold(
      appBar: AppBar(
        title: Text(friendName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/friends'),
        ),
        actions: [
          if (balance != 0)
            TextButton.icon(
              onPressed: _settleUp,
              icon: const Icon(Icons.handshake, size: 18),
              label: const Text('Settle'),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            context.push('/createExpense/friend/${widget.friendId}'),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Balance card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: balance == 0
                          ? AppTheme.cardGradient
                          : balance > 0
                              ? const LinearGradient(colors: [
                                  Color(0xFF1B5E20),
                                  Color(0xFF2E7D32)
                                ])
                              : const LinearGradient(colors: [
                                  Color(0xFFB71C1C),
                                  Color(0xFFC62828)
                                ]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          balance == 0
                              ? 'All Settled Up!'
                              : balance > 0
                                  ? '$friendName owes you'
                                  : 'You owe $friendName',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppUtils.formatCurrency(balance.abs()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Shared expenses
                  const Text(
                    'Shared Expenses',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (_expenses.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No shared expenses yet',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                    )
                  else
                    ..._expenses.map((expense) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () => context.push('/expense/${expense.id}'),
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppTheme.primaryColor.withValues(alpha: 0.15),
                              child: const Icon(Icons.receipt,
                                  color: AppTheme.primaryColor, size: 20),
                            ),
                            title: Text(expense.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              AppDateUtils.formatDateString(expense.date ?? ''),
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12),
                            ),
                            trailing: Text(
                              AppUtils.formatCurrency(expense.amount),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
