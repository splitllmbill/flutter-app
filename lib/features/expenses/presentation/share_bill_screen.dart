import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/currencies.dart';
import '../../../core/providers.dart';
import '../../../core/services/receipt_scanner.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/helpers.dart';

class ShareBillScreen extends ConsumerStatefulWidget {
  /// Split context: 'event' (group expense) or 'friend'. Null = ad-hoc split
  /// with people added by email.
  final String? contextType;
  final String? contextId;
  const ShareBillScreen({super.key, this.contextType, this.contextId});

  @override
  ConsumerState<ShareBillScreen> createState() => _ShareBillScreenState();
}

class _ShareBillScreenState extends ConsumerState<ShareBillScreen> {
  /// Backend expense type: an event context is a "group" expense; everything
  /// else settles between friends.
  String get _expenseType => widget.contextType == 'event' ? 'group' : 'friend';

  String _idOf(Map<String, dynamic> u) =>
      (u['id'] ?? u['_id'])?.toString() ?? '';

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _splitType = 'equal';
  String _selectedCategory = 'General';
  String _currency = Currencies.defaultCode;
  String? _date;
  Map<String, dynamic>? _me;
  final List<Map<String, dynamic>> _users = [];
  final Map<String, double> _customAmounts = {};
  final Map<String, double> _percentages = {};
  bool _isLoading = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadAccount();
    if (widget.contextType != null && widget.contextId != null) {
      await _loadContextUsers();
    }
  }

  Future<void> _loadAccount() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/db/user/account');
      if (mounted) {
        setState(() {
          _me = Map<String, dynamic>.from(response.data);
          _currency = _me?['defaultCurrency'] ?? Currencies.defaultCode;
          // The payer splits the bill with the members, so they're part of it
          if (!_users.any((u) => _idOf(u) == _me?['id'])) {
            _users.insert(0, _me!);
          }
        });
      }
    } catch (_) {}
  }

  /// Preload the members of the event/friend context so the split starts with
  /// the right people instead of an empty list.
  Future<void> _loadContextUsers() async {
    try {
      final api = ref.read(apiClientProvider);
      final res =
          await api.get('/db/${widget.contextType}/${widget.contextId}/users');
      final data = res.data;
      if (data is List && mounted) {
        setState(() {
          for (final u in data) {
            final m = Map<String, dynamic>.from(u as Map);
            final id = _idOf(m);
            if (id.isEmpty) continue;
            if (!_users.any((x) => _idOf(x) == id)) {
              _users.add(m);
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _scanReceipt() async {
    setState(() => _isScanning = true);
    try {
      final receipt = await pickAndScanReceipt(ref);
      if (receipt == null) return;
      setState(() {
        if (receipt.name != null) _titleController.text = receipt.name!;
        if (receipt.amount != null) {
          _amountController.text = receipt.amount.toString();
        }
        if (receipt.currency != null &&
            Currencies.all.any((c) => c.code == receipt.currency)) {
          _currency = receipt.currency!;
        }
        if (receipt.date != null) _date = receipt.date;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not read receipt: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

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

    final totalAmount = double.parse(_amountController.text.trim());

    // Shares must reconcile with the total or the backend rejects the expense
    // with a generic error; validate up front with a clear message.
    if (_splitType == 'percentage') {
      final sumPct = _users.fold<double>(
          0, (a, u) => a + (_percentages[_idOf(u)] ?? 0));
      if ((sumPct - 100).abs() > 0.5) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Percentages must add up to 100% (currently ${sumPct.toStringAsFixed(0)}%)')));
        return;
      }
    } else if (_splitType == 'custom') {
      final sumAmt = _users.fold<double>(
          0, (a, u) => a + (_customAmounts[_idOf(u)] ?? 0));
      if ((sumAmt - totalAmount).abs() > 1) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Split amounts must add up to the total (${Currencies.symbolFor(_currency)}${totalAmount.toStringAsFixed(2)})')));
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final eventId =
          widget.contextType == 'event' ? widget.contextId : null;

      List<Map<String, dynamic>> shares;
      if (_splitType == 'equal') {
        final perPerson = totalAmount / _users.length;
        shares = _users.map((u) {
          return {'userId': _idOf(u), 'amount': perPerson};
        }).toList();
      } else if (_splitType == 'percentage') {
        shares = _users.map((u) {
          final pct = _percentages[_idOf(u)] ?? 0;
          return {
            'userId': _idOf(u),
            'amount': totalAmount * pct / 100,
            'percentage': pct,
          };
        }).toList();
      } else {
        shares = _users.map((u) {
          final amt = _customAmounts[_idOf(u)] ?? 0;
          return {'userId': _idOf(u), 'amount': amt};
        }).toList();
      }

      if (eventId != null) {
        for (final s in shares) {
          s['eventId'] = eventId;
        }
      }

      // The current user pays the bill; shares define who owes what
      final myId = _me?['id']?.toString();
      await api.post('/db/expense', data: {
        'expenseName': _titleController.text.trim(),
        'amount': totalAmount,
        'category': _selectedCategory,
        'currency': _currency,
        'shares': shares,
        if (myId != null)
          'payShares': [
            {'userId': myId, 'amount': totalAmount}
          ],
        'type': _expenseType,
        if (eventId != null) 'eventId': eventId,
        'date': _date ?? DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bill shared successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.pop(true);
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

  Future<void> _addMemberByEmail() async {
    final emailController = TextEditingController();
    final nameController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email Address'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name (Optional)'),
            ),
            const SizedBox(height: 16),
            const Text(
              'If this person is not registered, they will be invited. You can still share this expense with them.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );

    if (confirm == true && emailController.text.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final api = ref.read(apiClientProvider);
        final res = await api.post('/db/user/phantom', data: {
          'email': emailController.text.trim(),
          'name': nameController.text.trim(),
        });
        
        final user = res.data;
        if (!_users.any((u) => (u['id'] ?? u['_id']) == (user['id'] ?? user['_id']))) {
          setState(() {
            _users.add(user);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Member added!'), backgroundColor: AppTheme.successColor),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add member')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
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
                  OutlinedButton.icon(
                    onPressed: _isScanning ? null : _scanReceipt,
                    icon: _isScanning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.document_scanner_outlined),
                    label: Text(
                        _isScanning ? 'Reading receipt…' : 'Scan a receipt'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Total Amount',
                            prefixIcon: const Icon(Icons.payments),
                            prefixText:
                                '${Currencies.symbolFor(_currency)} ',
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (double.tryParse(v) == null) {
                              return 'Invalid amount';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _currency,
                          decoration:
                              const InputDecoration(labelText: 'Currency'),
                          dropdownColor: AppTheme.cardColor,
                          items: Currencies.all
                              .map((c) => DropdownMenuItem(
                                    value: c.code,
                                    child: Text('${c.symbol} ${c.code}'),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(
                              () => _currency = v ?? Currencies.defaultCode),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
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
                                          : Currencies.symbolFor(_currency),
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

                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _addMemberByEmail,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Member by Email'),
                  ),

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
