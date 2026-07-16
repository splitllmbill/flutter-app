import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/providers.dart';
import '../../../core/utils/app_theme.dart';

/// Import a Splitwise group export (CSV) as a new SplitLLM event.
///
/// Flow: pick file -> preview (members/rows parsed by the backend) ->
/// map each CSV member to yourself, a friend, or an invite-by-email ->
/// import.
class ImportSplitwiseScreen extends ConsumerStatefulWidget {
  const ImportSplitwiseScreen({super.key});

  @override
  ConsumerState<ImportSplitwiseScreen> createState() =>
      _ImportSplitwiseScreenState();
}

class _MemberMapping {
  String mode = 'email'; // 'me' | 'friend' | 'email'
  String? friendId;
  final TextEditingController emailController = TextEditingController();

  void dispose() => emailController.dispose();
}

class _ImportSplitwiseScreenState extends ConsumerState<ImportSplitwiseScreen> {
  PlatformFile? _file;
  Map<String, dynamic>? _preview;
  Map<String, dynamic>? _account;
  List<dynamic> _friends = [];
  final Map<String, _MemberMapping> _mappings = {};
  final _eventNameController = TextEditingController();
  String _currency = Currencies.defaultCode;
  bool _isBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    for (final m in _mappings.values) {
      m.dispose();
    }
    super.dispose();
  }

  Future<void> _loadContext() async {
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait([
        api.get('/db/user/account'),
        api.get('/db/user/friends'),
      ]);
      if (!mounted) return;
      setState(() {
        _account = Map<String, dynamic>.from(results[0].data);
        final friendsData = results[1].data;
        _friends = friendsData is Map
            ? (friendsData['friendsList'] ?? [])
            : (friendsData is List ? friendsData : []);
      });
    } catch (_) {}
  }

  Future<void> _pickAndPreview() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post(
        '/db/import/splitwise/preview',
        jsonBody: false,
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
        }),
      );
      final preview = Map<String, dynamic>.from(response.data);
      setState(() {
        _file = file;
        _preview = preview;
        _eventNameController.text = preview['suggestedEventName'] ?? '';
        final currencies = List<String>.from(preview['currencies'] ?? []);
        if (currencies.isNotEmpty &&
            Currencies.all.any((c) => c.code == currencies.first)) {
          _currency = currencies.first;
        }
        for (final m in _mappings.values) {
          m.dispose();
        }
        _mappings.clear();
        final myName = (_account?['name'] ?? '').toString().toLowerCase();
        for (final member in List<String>.from(preview['members'] ?? [])) {
          final mapping = _MemberMapping();
          final memberLower = member.toLowerCase();
          // Best-effort auto match: me by name, then friends by name
          if (myName.isNotEmpty &&
              (memberLower.contains(myName) || myName.contains(memberLower))) {
            mapping.mode = 'me';
          } else {
            final friend = _friends.cast<Map?>().firstWhere(
                  (f) =>
                      (f?['name'] ?? '').toString().toLowerCase() ==
                      memberLower,
                  orElse: () => null,
                );
            if (friend != null) {
              mapping.mode = 'friend';
              mapping.friendId = friend['id']?.toString();
            }
          }
          _mappings[member] = mapping;
        }
      });
    } catch (e) {
      setState(() => _error = 'Could not read that file: $e');
    } finally {
      setState(() => _isBusy = false);
    }
  }

  String? _validateMappings() {
    if (_eventNameController.text.trim().isEmpty) {
      return 'Give the imported group a name';
    }
    var meCount = 0;
    for (final entry in _mappings.entries) {
      final m = entry.value;
      if (m.mode == 'me') meCount++;
      if (m.mode == 'friend' && m.friendId == null) {
        return 'Pick a friend for "${entry.key}"';
      }
      if (m.mode == 'email' &&
          !m.emailController.text.trim().contains('@')) {
        return 'Enter an email for "${entry.key}"';
      }
    }
    if (meCount != 1) return 'Map exactly one member to yourself';
    return null;
  }

  Future<void> _import() async {
    final validationError = _validateMappings();
    if (validationError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final mapping = <String, Map<String, String>>{};
      _mappings.forEach((member, m) {
        if (m.mode == 'me') {
          mapping[member] = {'userId': _account!['id'].toString()};
        } else if (m.mode == 'friend') {
          mapping[member] = {'userId': m.friendId!};
        } else {
          mapping[member] = {
            'email': m.emailController.text.trim(),
            'name': member,
          };
        }
      });

      final api = ref.read(apiClientProvider);
      final response = await api.post(
        '/db/import/splitwise',
        jsonBody: false,
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(_file!.bytes!,
              filename: _file!.name),
          'eventName': _eventNameController.text.trim(),
          'currency': _currency,
          'mapping': jsonEncode(mapping),
        }),
      );

      final data = Map<String, dynamic>.from(response.data);
      if (!mounted) return;
      final skipped = (data['skipped'] as List?)?.length ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Imported ${data['imported']} expenses${skipped > 0 ? ' ($skipped skipped)' : ''}!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.go('/event/${data['eventId']}');
    } catch (e) {
      setState(() => _error = 'Import failed: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import from Splitwise'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: _preview == null ? _buildPickStep() : _buildMappingStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildPickStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.upload_file_rounded,
            size: 72, color: AppTheme.primaryColor),
        const SizedBox(height: 20),
        const Text(
          'Bring your groups over',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'In Splitwise, open a group and choose "Export as spreadsheet". '
          'Upload the CSV here and the whole history — expenses, payments, '
          'currencies and balances — becomes a SplitLLM group.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isBusy ? null : _pickAndPreview,
            icon: _isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.folder_open),
            label: Text(_isBusy ? 'Reading…' : 'Choose CSV file'),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.errorColor)),
        ],
      ],
    );
  }

  Widget _buildMappingStep() {
    final preview = _preview!;
    final members = List<String>.from(preview['members'] ?? []);
    final dateRange = preview['dateRange'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_file?.name ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                '${preview['rowCount']} expenses'
                '${(preview['paymentRows'] ?? 0) > 0 ? ' (incl. ${preview['paymentRows']} payments)' : ''}'
                ' • ${dateRange['from'] ?? '?'} → ${dateRange['to'] ?? '?'}'
                ' • ${(preview['currencies'] as List?)?.join(', ') ?? ''}',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _eventNameController,
          decoration: const InputDecoration(
            labelText: 'Group name',
            prefixIcon: Icon(Icons.event),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _currency,
          decoration: const InputDecoration(
            labelText: 'Group currency',
            prefixIcon: Icon(Icons.currency_exchange),
          ),
          dropdownColor: AppTheme.cardColor,
          items: Currencies.all
              .map((c) => DropdownMenuItem(
                    value: c.code,
                    child: Text('${c.symbol}  ${c.code} — ${c.name}'),
                  ))
              .toList(),
          onChanged: (v) =>
              setState(() => _currency = v ?? Currencies.defaultCode),
        ),
        const SizedBox(height: 24),
        const Text('Who is who?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text(
          'Match each Splitwise member to yourself, a friend, or invite them '
          'by email — their balances come along automatically.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        ...members.map(_buildMemberCard),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: AppTheme.errorColor)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isBusy ? null : _import,
            icon: _isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_done),
            label: Text(_isBusy ? 'Importing…' : 'Import group'),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _isBusy
              ? null
              : () => setState(() {
                    _preview = null;
                    _file = null;
                    _error = null;
                  }),
          child: const Text('Choose a different file'),
        ),
      ],
    );
  }

  Widget _buildMemberCard(String member) {
    final mapping = _mappings[member]!;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'me', label: Text('Me'), icon: Icon(Icons.person)),
                ButtonSegment(
                    value: 'friend',
                    label: Text('Friend'),
                    icon: Icon(Icons.group)),
                ButtonSegment(
                    value: 'email',
                    label: Text('Invite'),
                    icon: Icon(Icons.mail_outline)),
              ],
              selected: {mapping.mode},
              onSelectionChanged: (val) =>
                  setState(() => mapping.mode = val.first),
            ),
            const SizedBox(height: 10),
            if (mapping.mode == 'friend')
              DropdownButtonFormField<String>(
                value: mapping.friendId,
                decoration: const InputDecoration(
                  labelText: 'Select friend',
                  isDense: true,
                ),
                dropdownColor: AppTheme.cardColor,
                items: _friends
                    .map<DropdownMenuItem<String>>(
                        (f) => DropdownMenuItem(
                              value: f['id']?.toString(),
                              child: Text(f['name'] ?? f['email'] ?? '?'),
                            ))
                    .toList(),
                onChanged: (v) => setState(() => mapping.friendId = v),
              ),
            if (mapping.mode == 'email')
              TextFormField(
                controller: mapping.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  hintText: 'They get an invite; balances link on signup',
                  isDense: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
