import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/utils/app_theme.dart';

class AddFriendScreen extends ConsumerStatefulWidget {
  final String friendCode;
  const AddFriendScreen({super.key, required this.friendCode});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  bool _isLoading = false;
  bool _added = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _addFriend();
  }

  Future<void> _addFriend() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(apiClientProvider).post('/db/addFriend', data: {
        'friendCode': widget.friendCode,
      });
      setState(() {
        _added = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to add friend';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Friend')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _added
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.successColor, size: 64),
                      const SizedBox(height: 16),
                      const Text('Friend added successfully!',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go('/friends'),
                        child: const Text('Go to Friends'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 64),
                      const SizedBox(height: 16),
                      Text(_error ?? 'Something went wrong',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _addFriend,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
      ),
    );
  }
}
