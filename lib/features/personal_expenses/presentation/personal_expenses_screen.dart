import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/models/expense_model.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/date_utils.dart';

class PersonalExpensesScreen extends ConsumerStatefulWidget {
  const PersonalExpensesScreen({super.key});

  @override
  ConsumerState<PersonalExpensesScreen> createState() => _PersonalExpensesScreenState();
}

class _PersonalExpensesScreenState extends ConsumerState<PersonalExpensesScreen> {
  List<ExpenseModel> _expenses = [];
  bool _isLoading = true;
  bool _isAddingViaChatbot = false;
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post('/db/expenses/personal', data: {});
      final data = response.data;
      final list = data is List ? data : (data['expenses'] ?? []);
      setState(() {
        _expenses = list.map<ExpenseModel>((e) => ExpenseModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendChatMessage() async {
    final message = _chatController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _chatMessages.add({'role': 'user', 'content': message});
      _chatController.clear();
    });

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post('/llm/expense', data: {
        'requestData': {'sentence': message},
      });

      setState(() {
        _chatMessages.add({
          'role': 'assistant',
          'content': 'Expense added: ${response.data['title'] ?? message}',
        });
      });
      _loadExpenses();
    } catch (e) {
      setState(() {
        _chatMessages.add({
          'role': 'assistant',
          'content': 'Sorry, I could not process that. Try again with a clearer description.',
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Expenses'),
        actions: [
          IconButton(
            icon: Icon(_isAddingViaChatbot ? Icons.list : Icons.chat_bubble_outline),
            onPressed: () => setState(() => _isAddingViaChatbot = !_isAddingViaChatbot),
            tooltip: _isAddingViaChatbot ? 'Show list' : 'AI Chat',
          ),
        ],
      ),
      body: _isAddingViaChatbot ? _buildChatbot() : _buildExpensesList(),
    );
  }

  Widget _buildExpensesList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 80, color: AppTheme.primaryColor.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('No personal expenses',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Use the AI chatbot to add expenses naturally',
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() => _isAddingViaChatbot = true),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Open AI Chat'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExpenses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _expenses.length,
        itemBuilder: (context, index) {
          final expense = _expenses[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                child: const Icon(Icons.receipt, color: AppTheme.primaryColor, size: 20),
              ),
              title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${expense.category ?? 'General'} • ${AppDateUtils.formatDateString(expense.date ?? '')}',
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

  Widget _buildChatbot() {
    return Column(
      children: [
        // Chat info
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tell me your expense naturally, e.g., "Spent 500 on dinner"',
                  style: TextStyle(color: AppTheme.primaryColor.withValues(alpha: 0.8), fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: _chatMessages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      const Text('Start a conversation',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _chatMessages[index];
                    final isUser = msg['role'] == 'user';

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isUser ? AppTheme.primaryColor : AppTheme.cardColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          msg['content'],
                          style: TextStyle(
                            color: isUser ? Colors.black : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Input
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: InputDecoration(
                    hintText: 'Type your expense...',
                    filled: true,
                    fillColor: AppTheme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _sendChatMessage(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _sendChatMessage,
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
