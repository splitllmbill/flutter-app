import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/helpers.dart';

class ShareBillScreen extends ConsumerStatefulWidget {
  final String expenseType;
  const ShareBillScreen({super.key, required this.expenseType});

  @override
  ConsumerState<ShareBillScreen> createState() => _ShareBillScreenState();
}

class _ShareBillScreenState extends ConsumerState<ShareBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _splitType = 'equal';
  String _selectedCategory = 'General';
  final List<Map<String, dynamic>> _users = [];
  final Map<String, double> _customAmounts = {};
  final Map<String, double> _percentages = {};
  bool _isLoading = false;

  final _categories = [
    'General',
    'Food',
    'Transport',
    'Accommodation',
    'Shopping',
    'Entertainment',
    'Utilities',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add members to split with')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final totalAmount = double.parse(_amountController.text.trim());

      List<Map<String, dynamic>> shares;
      if (_splitType == 'equal') {
        final perPerson = totalAmount / _users.length;
        shares = _users.map((u) {
          return {
            'userId': u['id'] ?? u['_id'],
            'amount': perPerson,
          };
        }).toList();
      } else if (_splitType == 'percentage') {
        shares = _users.map((u) {
          final pct =
              _percentages[u['id']?.toString() ?? u['_id']?.toString()] ?? 0;
          return {
            'userId': u['id'] ?? u['_id'],
            'amount': totalAmount * pct / 100,
            'percentage': pct,
          };
        }).toList();
      } else {
        shares = _users.map((u) {
          final amt =
              _customAmounts[u['id']?.toString() ?? u['_id']?.toString()] ?? 0;
          return {'userId': u['id'] ?? u['_id'], 'amount': amt};
        }).toList();
      }

      await api.post('/db/expense', data: {
        'title': _titleController.text.trim(),
        'amount': totalAmount,
        'category': _selectedCategory,
        'shares': shares,
        'type': widget.expenseType,
        'date': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bill shared successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share bill')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Bill'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Bill Title',
                      prefixIcon: Icon(Icons.receipt),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Total Amount',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category),
                    ),
                    dropdownColor: AppTheme.cardColor,
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedCategory = v ?? 'General'),
                  ),
                  const SizedBox(height: 24),

                  // Split type selector
                  const Text('Split Type',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'equal',
                          label: Text('Equal'),
                          icon: Icon(Icons.balance)),
                      ButtonSegment(
                          value: 'percentage',
                          label: Text('Percentage'),
                          icon: Icon(Icons.percent)),
                      ButtonSegment(
                          value: 'custom',
                          label: Text('Custom'),
                          icon: Icon(Icons.tune)),
                    ],
                    selected: {_splitType},
                    onSelectionChanged: (val) =>
                        setState(() => _splitType = val.first),
                  ),
                  const SizedBox(height: 24),

                  // Members display
                  if (_users.isNotEmpty) ...[
                    const Text('Members',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ..._users.map((user) {
                      final userId = user['id']?.toString() ??
                          user['_id']?.toString() ??
                          '';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppTheme.primaryColor.withValues(alpha: 0.15),
                            child: Text(
                              AppUtils.getInitials(user['name'] ?? 'U'),
                              style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title:
                              Text(user['name'] ?? user['email'] ?? 'Unknown'),
                          trailing: _splitType != 'equal'
                              ? SizedBox(
                                  width: 100,
                                  child: TextFormField(
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: InputDecoration(
                                      suffixText: _splitType == 'percentage'
                                          ? '%'
                                          : '₹',
                                      isDense: true,
                                    ),
                                    onChanged: (v) {
                                      final val = double.tryParse(v) ?? 0;
                                      if (_splitType == 'percentage') {
                                        _percentages[userId] = val;
                                      } else {
                                        _customAmounts[userId] = val;
                                      }
                                    },
                                  ),
                                )
                              : null,
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Share Bill'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
