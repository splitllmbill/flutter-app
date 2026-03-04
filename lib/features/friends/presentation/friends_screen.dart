import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/helpers.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  List<dynamic> _friends = [];
  bool _isLoading = true;
  String? _error;
  final _friendCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _friendCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/db/user/friends');
      final data = response.data;
      setState(() {
        _friends = data is List ? data : (data['friends'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load friends';
        _isLoading = false;
      });
    }
  }

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Friend'),
        content: TextField(
          controller: _friendCodeController,
          decoration: const InputDecoration(
            hintText: 'Enter friend code',
            prefixIcon: Icon(Icons.person_add),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final code = _friendCodeController.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ref
                    .read(apiClientProvider)
                    .post('/db/addFriend', data: {'friendCode': code});
                _friendCodeController.clear();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Friend added!'),
                      backgroundColor: AppTheme.successColor),
                );
                _loadFriends();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to add friend')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFriend(String friendCode) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Friend'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(apiClientProvider)
            .delete('/db/deleteFriend', data: {'friendCode': friendCode});
        _loadFriends();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to remove friend')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFriendDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Friend'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!,
                          style:
                              const TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _loadFriends, child: const Text('Retry')),
                    ],
                  ),
                )
              : _friends.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadFriends,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          final friend = _friends[index];
                          final friendId = friend['id']?.toString() ??
                              friend['_id']?.toString() ??
                              '';
                          final name =
                              friend['name'] ?? friend['email'] ?? 'Unknown';
                          final balance = (friend['balance'] ?? 0).toDouble();
                          final friendCode = friend['friendCode'] ??
                              friend['friend_code'] ??
                              '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              onTap: () => context.push('/friend/$friendId'),
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryColor
                                    .withValues(alpha: 0.15),
                                child: Text(
                                  AppUtils.getInitials(name),
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                balance == 0
                                    ? 'Settled up'
                                    : balance > 0
                                        ? 'owes you ${AppUtils.formatCurrency(balance)}'
                                        : 'you owe ${AppUtils.formatCurrency(balance.abs())}',
                                style: TextStyle(
                                  color: balance == 0
                                      ? AppTheme.textSecondary
                                      : balance > 0
                                          ? AppTheme.successColor
                                          : AppTheme.errorColor,
                                  fontSize: 13,
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (val) {
                                  if (val == 'delete') {
                                    _deleteFriend(friendCode);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                      value: 'delete', child: Text('Remove')),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
              size: 80, color: AppTheme.primaryColor.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('No friends yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Add friends to start splitting bills',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddFriendDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Add Friend'),
          ),
        ],
      ),
    );
  }
}
