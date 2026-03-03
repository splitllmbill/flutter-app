import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/utils/app_theme.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  final String? eventId;
  const CreateEventScreen({super.key, this.eventId});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _memberEmailController = TextEditingController();
  final List<String> _memberEmails = [];
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.eventId != null;
    if (_isEditing) _loadEvent();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _memberEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadEvent() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/db/event/${widget.eventId}');
      final data = response.data;
      setState(() {
        _titleController.text = data['title'] ?? data['name'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        if (data['members'] != null) {
          _memberEmails.addAll(List<String>.from(data['members']));
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _addMember() {
    final email = _memberEmailController.text.trim();
    if (email.isNotEmpty && email.contains('@') && !_memberEmails.contains(email)) {
      setState(() {
        _memberEmails.add(email);
        _memberEmailController.clear();
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'members': _memberEmails,
      };

      if (_isEditing) {
        data['id'] = widget.eventId!;
        await api.put('/db/event', data: data);
      } else {
        await api.post('/db/event', data: data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Event updated!' : 'Event created!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.go('/events');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${_isEditing ? 'update' : 'create'} event')),
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
        title: Text(_isEditing ? 'Edit Event' : 'Create Event'),
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
                            labelText: 'Event Name',
                            prefixIcon: Icon(Icons.event),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Event name is required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description (optional)',
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Members',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _memberEmailController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter member email',
                                  prefixIcon: Icon(Icons.person_add),
                                ),
                                onFieldSubmitted: (_) => _addMember(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _addMember,
                              icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
                              iconSize: 36,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _memberEmails
                              .map((email) => Chip(
                                    label: Text(email, style: const TextStyle(fontSize: 13)),
                                    deleteIcon: const Icon(Icons.close, size: 18),
                                    onDeleted: () => setState(() => _memberEmails.remove(email)),
                                  ))
                              .toList(),
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
                                : Text(_isEditing ? 'Update Event' : 'Create Event'),
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
