import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';

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
  List<Map<String, dynamic>> _possibleUsers = [];
  bool _isLoading = false;
  bool _isEditing = false;

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
    } else if (widget.type != null && widget.contextId != null) {
      _loadPossibleUsers();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadExpense() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/db/expense/${widget.expenseId}');
      final data = response.data;
      setState(() {
        _titleController.text = data['title'] ?? '';
        _amountController.text = (data['amount'] ?? '').toString();
        _descriptionController.text = data['description'] ?? '';
        _selectedCategory = data['category'] ?? 'General';
        _selectedPaidBy = data['paidBy'] ?? data['paid_by'];
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final data = {
        'title': _titleController.text.trim(),
        'amount': double.parse(_amountController.text.trim()),
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        if (_selectedPaidBy != null) 'paidBy': _selectedPaidBy,
        if (widget.type == 'event') 'eventId': widget.contextId,
        if (widget.type == 'friend') 'friendId': widget.contextId,
        'date': DateTime.now().toIso8601String(),
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
        context.pop();
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
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            prefixIcon: Icon(Icons.currency_rupee),
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
                        const SizedBox(height: 16),

                        // Category dropdown
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
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
                            initialValue: _selectedPaidBy,
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
