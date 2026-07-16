import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/currencies.dart';
import '../../../core/providers.dart';
import '../../../core/utils/app_theme.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  Map<String, dynamic>? _account;
  bool _isLoading = true;
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _upiController = TextEditingController();
  String _defaultCurrency = Currencies.defaultCode;
  List<dynamic> _invitedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _loadAccount() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/db/user/account');
      final invitesResponse = await api.get('/db/user/invites');
      setState(() {
        _account = response.data;
        _invitedUsers = invitesResponse.data;
        _nameController.text = _account?['name'] ?? '';
        _upiController.text = _account?['upiId'] ?? _account?['upi_id'] ?? '';
        _defaultCurrency =
            _account?['defaultCurrency'] ?? Currencies.defaultCode;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load account details: $e')),
      );
    }
  }

  Future<void> _updateAccount() async {
    try {
      final newName = _nameController.text.trim();
      final newUpi = _upiController.text.trim();
      
      await ref.read(apiClientProvider).put('/db/user/account', data: {
        'name': newName,
        'upiId': newUpi,
        'defaultCurrency': _defaultCurrency,
      });
      
      // Also update Supabase metadata so the auth provider sees the new name
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: {'full_name': newName}),
        );
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        if (_account != null) {
          _account!['name'] = newName;
          _account!['upiId'] = newUpi;
          _account!['defaultCurrency'] = _defaultCurrency;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Account updated!'),
            backgroundColor: AppTheme.successColor),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update')),
      );
    }
  }

  Future<void> _changePassword() async {
    final newPasswordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Change')),
        ],
      ),
    );

    if (confirmed == true && newPasswordController.text.isNotEmpty) {
      try {
        final authService = ref.read(authServiceProvider);
        await authService.updatePassword(newPasswordController.text);
        // Also update backend
        await ref.read(apiClientProvider).put('/db/changePassword', data: {
          'password': newPasswordController.text,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Password changed!'),
                backgroundColor: AppTheme.successColor),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Failed to change password. You may need to re-login first.')),
          );
        }
      }
    }
    newPasswordController.dispose();
  }

  void _showQRCode() {
    final friendCode =
        _account?['friendCode'] ?? _account?['friend_code'] ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your Friend Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (friendCode.isNotEmpty)
              SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(
                  data: friendCode,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      friendCode,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: friendCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(apiClientProvider).post('/db/logout');
      } catch (_) {}
      await ref.read(authServiceProvider).signOut();
    }
  }

  Future<void> _submitIssue() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String issueType = 'feature_request';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Submit Feedback'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: issueType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(value: 'feature_request', child: Text('Feature Request')),
                        DropdownMenuItem(value: 'issue', child: Text('Issue / Bug')),
                      ],
                      onChanged: (v) => setState(() => issueType = v!),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Submit')),
              ],
            );
          }
        );
      },
    );

    if (confirmed == true && titleController.text.isNotEmpty) {
      try {
        await ref.read(apiClientProvider).post('/db/issues/', data: {
          'type': issueType,
          'title': titleController.text,
          'description': descriptionController.text,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Feedback submitted successfully!'),
                backgroundColor: AppTheme.successColor),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to submit feedback')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final firebaseUser = authState.whenOrNull(data: (user) => user);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      // Profile header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: AppTheme.cardGradient,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor:
                                  AppTheme.primaryColor.withValues(alpha: 0.2),
                              child: Text(
                                (firebaseUser?.displayName ??
                                        _account?['name'] ??
                                        'U')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              firebaseUser?.displayName ??
                                  _account?['name'] ??
                                  'User',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              firebaseUser?.email ?? _account?['email'] ?? '',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Edit fields
                      if (_isEditing) ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _upiController,
                          decoration: const InputDecoration(
                            labelText: 'UPI ID',
                            prefixIcon: Icon(Icons.account_balance),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _defaultCurrency,
                          decoration: const InputDecoration(
                            labelText: 'Default Currency',
                            prefixIcon: Icon(Icons.currency_exchange),
                          ),
                          items: Currencies.all
                              .map((c) => DropdownMenuItem(
                                    value: c.code,
                                    child: Text(
                                        '${c.symbol}  ${c.code} — ${c.name}'),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() =>
                              _defaultCurrency = v ?? Currencies.defaultCode),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    setState(() => _isEditing = false),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _updateAccount,
                                child: const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Invited Users
                      if (_invitedUsers.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Invited Users (${_invitedUsers.length})',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _invitedUsers.length,
                            separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.1)),
                            itemBuilder: (context, index) {
                              final user = _invitedUsers[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                                  child: Text((user['name'] ?? 'U')[0].toUpperCase()),
                                ),
                                title: Text(user['name'] ?? 'Unknown'),
                                subtitle: Text(user['email'] ?? ''),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Actions
                      _buildActionTile(
                        icon: Icons.qr_code,
                        title: 'Friend Code / QR',
                        subtitle: 'Share your code with friends',
                        onTap: _showQRCode,
                      ),
                      _buildActionTile(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        subtitle: 'Update your password',
                        onTap: _changePassword,
                      ),
                      _buildActionTile(
                        icon: Icons.currency_exchange,
                        title: 'Currency',
                        subtitle:
                            '${Currencies.byCode(_defaultCurrency).symbol} ${Currencies.byCode(_defaultCurrency).name} — used for totals across groups',
                        onTap: () => setState(() => _isEditing = true),
                      ),
                      _buildActionTile(
                        icon: Icons.account_balance,
                        title: 'UPI Settings',
                        subtitle: _upiController.text.isNotEmpty
                            ? _upiController.text
                            : 'Not configured',
                        onTap: () => setState(() => _isEditing = true),
                      ),
                      _buildActionTile(
                        icon: Icons.feedback_outlined,
                        title: 'Submit Feedback',
                        subtitle: 'Feature request or report an issue',
                        onTap: _submitIssue,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _signOut,
                          icon: const Icon(Icons.logout,
                              color: AppTheme.errorColor),
                          label: const Text('Sign Out',
                              style: TextStyle(color: AppTheme.errorColor)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.errorColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        trailing:
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      ),
    );
  }
}
