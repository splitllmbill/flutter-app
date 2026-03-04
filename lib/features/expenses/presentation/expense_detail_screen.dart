import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/models/expense_model.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/date_utils.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final String expenseId;
  const ExpenseDetailScreen({super.key, required this.expenseId});

  @override
  ConsumerState<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  ExpenseModel? _expense;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpense();
  }

  Future<void> _loadExpense() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/db/expense/${widget.expenseId}');
      setState(() {
        _expense = ExpenseModel.fromJson(response.data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteExpense() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
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
        await ref.read(apiClientProvider).delete('/db/expense/${widget.expenseId}');
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete expense')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/expense/${widget.expenseId}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteExpense,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expense == null
              ? const Center(child: Text('Expense not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: AppTheme.cardGradient,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _expense!.category ?? 'General',
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      AppDateUtils.formatDateString(_expense!.date ?? ''),
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary, fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _expense!.title,
                                  style: const TextStyle(
                                      fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppUtils.formatCurrency(_expense!.amount),
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                if (_expense!.description != null &&
                                    _expense!.description!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _expense!.description!,
                                    style: const TextStyle(color: AppTheme.textSecondary),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Paid by
                          _buildInfoRow('Paid by', _expense!.paidByName ?? 'Unknown'),
                          const Divider(height: 24),

                          // Shares
                          if (_expense!.shares != null && _expense!.shares!.isNotEmpty) ...[
                            const Text(
                              'Split Details',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            ...(_expense!.shares!.map((share) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                                      child: Text(
                                        AppUtils.getInitials(share.userName ?? 'U'),
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    title: Text(share.userName ?? 'Unknown'),
                                    trailing: Text(
                                      AppUtils.formatCurrency(share.amount ?? 0),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ))),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
