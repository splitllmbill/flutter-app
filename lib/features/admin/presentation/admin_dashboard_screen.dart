import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/utils/app_theme.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<dynamic> _users = [];
  List<dynamic> _issues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> _availableModels = [];
  
  // Update state variables parsing from /db/admin/models response
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final usersRes = await api.get('/db/admin/users');
      final issuesRes = await api.get('/db/admin/issues');
      final modelsRes = await api.get('/db/admin/models');
      
      setState(() {
        _users = usersRes.data;
        _issues = issuesRes.data;
        _availableModels = modelsRes.data['availableModels'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load admin data: $e')),
      );
    }
  }

  Future<void> _deleteUser(String uid) async {
    try {
      await ref.read(apiClientProvider).delete('/db/admin/users/$uid');
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete user')),
      );
    }
  }

  Future<void> _resetPassword(String uid) async {
    try {
      await ref.read(apiClientProvider).post('/db/admin/users/$uid/reset-password');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset email sent'), backgroundColor: AppTheme.successColor),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send reset email')),
      );
    }
  }

  Future<void> _setActiveModel(String model) async {
    try {
      await ref.read(apiClientProvider).put('/db/admin/models/active', data: {'activeModel': model});
      // Reload so the ACTIVE badge (driven by model['isActive']) reflects the change.
      _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Active model updated'), backgroundColor: AppTheme.successColor),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update model')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.model_training), text: 'Models'),
            Tab(icon: Icon(Icons.report_problem), text: 'Issues'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(),
                _buildModelsTab(),
                _buildIssuesTab(),
              ],
            ),
    );
  }

  Widget _buildUsersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(user['name'] ?? 'Unknown'),
            subtitle: Text('${user['email']} • Role: ${user['role']}'),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'reset', child: Text('Reset Password')),
                const PopupMenuItem(value: 'delete', child: Text('Delete User')),
              ],
              onSelected: (val) {
                if (val == 'reset') _resetPassword(user['firebaseUid']);
                if (val == 'delete') _deleteUser(user['firebaseUid']);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildModelsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableModels.length,
      itemBuilder: (context, index) {
        final model = _availableModels[index];
        final isActive = model['isActive'] == true;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isActive ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.05),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(model['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('ACTIVE', style: TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Provider: ${model['provider']}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatBadge('Requests', '${model['totalRequests'] ?? 0}'),
                          const SizedBox(width: 8),
                          _buildStatBadge('Tokens', '${model['totalTokens'] ?? 0}'),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isActive)
                  ElevatedButton(
                    onPressed: () => _setActiveModel(model['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(color: AppTheme.primaryColor),
                    ),
                    child: const Text('Set Active'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _updateIssueStatus(String issueId, String newStatus) async {
    try {
      await ref.read(apiClientProvider).put('/db/admin/issues/$issueId', data: {'status': newStatus});
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus'), backgroundColor: AppTheme.successColor),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status')),
      );
    }
  }

  Widget _buildIssuesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _issues.length,
      itemBuilder: (context, index) {
        final issue = _issues[index];
        final type = (issue['type'] ?? 'issue').toString().toLowerCase();
        final status = (issue['status'] ?? 'pending').toString().toLowerCase();
        
        final isFeature = type == 'feature';
        
        Color statusColor = Colors.grey;
        if (status == 'resolved' || status == 'added') statusColor = AppTheme.successColor;
        else if (status == 'cancelled') statusColor = AppTheme.errorColor;
        else if (status == 'future') statusColor = Colors.blue;

        List<PopupMenuEntry<String>> menuItems = [];
        if (isFeature) {
          menuItems = [
            const PopupMenuItem(value: 'pending', child: Text('Mark Pending')),
            const PopupMenuItem(value: 'added', child: Text('Mark Added')),
            const PopupMenuItem(value: 'future', child: Text('Mark Future')),
          ];
        } else {
          menuItems = [
            const PopupMenuItem(value: 'pending', child: Text('Mark Pending')),
            const PopupMenuItem(value: 'resolved', child: Text('Mark Resolved')),
            const PopupMenuItem(value: 'cancelled', child: Text('Mark Cancelled')),
          ];
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isFeature ? Colors.purple.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isFeature ? Colors.purple : Colors.orange).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(isFeature ? Icons.lightbulb_outline : Icons.bug_report, 
                             color: isFeature ? Colors.purple : Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(issue['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(issue['description'] ?? '', style: const TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),
                      Text('By: ${issue['userEmail'] ?? 'Unknown'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (val) => _updateIssueStatus(issue['_id'] ?? issue['id'], val),
                  itemBuilder: (context) => menuItems,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
