import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/helpers.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String paymentId;
  const PaymentScreen({super.key, required this.paymentId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  Map<String, dynamic>? _paymentData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPayment();
  }

  Future<void> _loadPayment() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/db/payment/${widget.paymentId}');
      setState(() {
        _paymentData = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Payment page not found';
        _isLoading = false;
      });
    }
  }

  Future<void> _openUPILink() async {
    final upiLink = _paymentData?['upiLink'] ?? _paymentData?['upi_link'];
    if (upiLink != null) {
      final uri = Uri.parse(upiLink);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF121212)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
                          const SizedBox(height: 16),
                          Text(_error!, style: const TextStyle(fontSize: 18)),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            children: [
                              const SizedBox(height: 24),
                              // Header
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.receipt_long, color: Colors.white, size: 36),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Payment Request',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 32),

                              // Amount card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.cardGradient,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      _paymentData?['name'] ?? 'Payment',
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      AppUtils.formatCurrency(
                                        (_paymentData?['amount'] ?? 0).toDouble(),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    if (_paymentData?['note'] != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        _paymentData!['note'],
                                        style: const TextStyle(color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // QR Code
                              if (_paymentData?['qrData'] != null || _paymentData?['qr_data'] != null)
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: QrImageView(
                                    data: _paymentData?['qrData'] ?? _paymentData?['qr_data'] ?? '',
                                    size: 220,
                                  ),
                                ),
                              const SizedBox(height: 24),

                              // Pay button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _openUPILink,
                                  icon: const Icon(Icons.account_balance),
                                  label: const Text('Pay via UPI'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}
