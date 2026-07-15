import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/currencies.dart';
import '../../../core/providers.dart';
import '../../../core/services/receipt_scanner.dart';

import '../../../core/utils/app_theme.dart';

class CreateExpenseScreen extends ConsumerStatefulWidget {
  final String? type;
  final String? contextId;
  final String? expenseId;

  const CreateExpenseScreen({
    super.key,
    this.type,
    this.contextId,
    this.expenseId,
  });

  @override
  ConsumerState<CreateExpenseScreen> createState() =>
      _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends ConsumerState<CreateExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'General';
  String? _selectedPaidBy;
  String _currency = Currencies.defaultCode;
  String? _date;
  List<Map<String, dynamic>> _possibleUsers = [];
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isScanning = false;

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
  void initState() {
    super.initState();
    _isEditing = widget.expenseId != null;
    if (_isEditing) {
      _loadExpense();
    } else {
      _loadDefaultCurrency();
      if (widget.type != null && widget.contextId != null) {
        _loadPossibleUsers();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultCurrency() async {
    try {
      final api = ref.read(apiClientProvider);
      // Expense currency defaults to the context: event currency for group
      // expenses, otherwise the user's default currency.
      if (widget.type == 'event' && widget.contextId != null) {
        final response = await api.get('/db/event/${widget.contextId}');
        if (mounted) {
          setState(() => _currency =
              response.data['currency'] ?? Currencies.defaultCode);
        }
      } else {
        final response = await api.get('/db/user/account');
        if (mounted) {
          setState(() => _currency =
              response.data['defaultCurrency'] ?? Currencies.defaultCode);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadExpense() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/db/expense/${widget.expenseId}');
      final data = response.data;
      setState(() {
        _titleController.text = data['expenseName'] ?? data['title'] ?? '';
        _amountController.text = (data['amount'] ?? '').toString();
        _descriptionController.text = data['description'] ?? '';
        _selectedCategory = data['category'] ?? 'General';
        _selectedPaidBy = data['paidBy'] ?? data['paid_by'];
        _currency = data['currency'] ?? Currencies.defaultCode;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPossibleUsers() async {
    try {
      final api = ref.read(apiClientProvider);
      final response =
          await api.get('/db/${widget.type}/${widget.contextId}/users');
      final data = response.data;
      setState(() {
        _possibleUsers = data is List
            ? data
                .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
      });
    } catch (_) {}
  }

  /// Pick a receipt photo, send it to the vision model, prefill the form.
  Future<void> _scanReceipt() async {
    setState(() => _isScanning = true);
    try {
      final receipt = await pickAndScanReceipt(ref);
      if (receipt == null) return; // cancelled

      setState(() {
        if (receipt.name != null) _titleController.text = receipt.name!;
        if (receipt.amount != null) {
          _amountController.text = receipt.amount.toString();
        }
        if (receipt.currency != null &&
            Currencies.all.any((c) => c.code == receipt.currency)) {
          _currency = receipt.currency!;
        }
        if (receipt.category != null) {
          _selectedCategory = _mapScannedCategory(receipt.category!);
        }
        if (receipt.date != null) _date = receipt.date;
        if (receipt.items.isNotEmpty) {
          _descriptionController.text = receipt.itemsSummary;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Receipt scanned! Review the details below.'),
              backgroundColor: AppTheme.successColor),
        );
      }
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

  String _mapScannedCategory(String scanned) {
    const mapping = {
      'Dining out': 'Food',
      'Groceries': 'Food',
      'Taxi': 'Transport',
      'Travel': 'Transport',
      'Shopping': 'Shopping',
      'Entertainment': 'Entertainment',
      'Utilities': 'Utilities',
      'Health': 'Other',
      'General': 'General',
    };
    if (_categories.contains(scanned)) return scanned;
    return mapping[scanned] ?? 'General';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final data = {
        'expenseName': _titleController.text.trim(),
        'amount': double.parse(_amountController.text.trim()),
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'currency': _currency,
        if (_selectedPaidBy != null) 'paidBy': _selectedPaidBy,
        if (widget.type == 'event') 'eventId': widget.contextId,
        if (widget.type == 'friend') 'friendId': widget.contextId,
        'date': _date ?? DateTime.now().toIso8601String(),
      };

      if (_isEditing) {
        data['id'] = widget.expenseId!;
        await api.put('/db/expense/${widget.expenseId}', data: data);
      } else {
        await api.post('/db/expense', data: data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Expense updated!' : 'Expense created!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save expense')),
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
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading && _isEditing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_isEditing) ...[
                          OutlinedButton.icon(
                            onPressed: _isScanning ? null : _scanReceipt,
                            icon: _isScanning
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.document_scanner_outlined),
                            label: Text(_isScanning
                                ? 'Reading receipt…'
                                : 'Scan a receipt'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Expense Title',
                            prefixIcon: Icon(Icons.receipt),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Title is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Amount',
                                  prefixIcon: const Icon(Icons.payments),
                                  prefixText:
                                      '${Currencies.symbolFor(_currency)} ',
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Amount is required';
                                  }
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
                                decoration: const InputDecoration(
                                  labelText: 'Currency',
                                ),
                                dropdownColor: AppTheme.cardColor,
                                items: Currencies.all
                                    .map((c) => DropdownMenuItem(
                                          value: c.code,
                                          child:
                                              Text('${c.symbol} ${c.code}'),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(() =>
                                    _currency = v ?? Currencies.defaultCode),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Category dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category),
                          ),
                          dropdownColor: AppTheme.cardColor,
                          items: _categories
                              .map((c) =>
                                  DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) => setState(
                              () => _selectedCategory = v ?? 'General'),
                        ),
                        const SizedBox(height: 16),

                        // Paid by dropdown (if applicable)
                        if (_possibleUsers.isNotEmpty) ...[
                          DropdownButtonFormField<String>(
                            value: _selectedPaidBy,
                            decoration: const InputDecoration(
                              labelText: 'Paid By',
                              prefixIcon: Icon(Icons.person),
                            ),
                            dropdownColor: AppTheme.cardColor,
                            items: _possibleUsers
                                .map((u) => DropdownMenuItem(
                                      value: u['id']?.toString() ??
                                          u['_id']?.toString(),
                                      child: Text(
                                          u['name'] ?? u['email'] ?? 'Unknown'),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedPaidBy = v),
                          ),
                          const SizedBox(height: 16),
                        ],

                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description (optional)',
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 3,
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
                                : Text(_isEditing
                                    ? 'Update Expense'
                                    : 'Add Expense'),
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
