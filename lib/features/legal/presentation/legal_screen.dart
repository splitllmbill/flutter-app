import 'package:flutter/material.dart';

import '../../../core/utils/app_theme.dart';

/// A titled section of a legal document.
class LegalSection {
  final String heading;
  final String body;

  const LegalSection(this.heading, this.body);
}

/// Renders a legal document (privacy policy / terms). Public route: also the
/// hosted policy URL required by the app stores when served from the web app.
class LegalScreen extends StatelessWidget {
  final String title;
  final String effectiveDate;
  final List<LegalSection> sections;

  const LegalScreen.privacy({super.key})
      : title = 'Privacy Policy',
        effectiveDate = _privacyEffectiveDate,
        sections = _privacySections;

  const LegalScreen.terms({super.key})
      : title = 'Terms of Service',
        effectiveDate = _termsEffectiveDate,
        sections = _termsSections;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false, // AppBar owns the top inset
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Effective date: $effectiveDate',
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                  for (final section in sections) ...[
                    const SizedBox(height: 24),
                    Text(
                      section.heading,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      section.body,
                      style: textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const String _privacyEffectiveDate = '16 July 2026';

const List<LegalSection> _privacySections = [
  LegalSection(
    'Who we are',
    'SplitLLM ("we", "us") is an expense-splitting service that helps you '
        'track shared and personal expenses. This policy explains what data '
        'we collect, why, and the choices you have. For anything unclear, '
        'contact us at support@splitllm.com.',
  ),
  LegalSection(
    'Data we collect',
    '• Account data: your name, email address, and a password (held by our '
        'authentication provider; we never see or store your password).\n'
        '• Expense data you enter: descriptions, amounts, currencies, dates, '
        'categories, and who participated in each expense.\n'
        '• Receipt images: photos you choose to scan for automatic expense '
        'entry.\n'
        '• Text you send to the expense assistant for parsing.\n'
        '• Connections: friends you add via invite codes and the groups you '
        'join.\n'
        '• Technical data: basic logs (timestamps, request status) needed to '
        'operate and secure the service.',
  ),
  LegalSection(
    'How we use your data',
    'To run the product: compute balances and settlements, show your history, '
        'send transactional emails (invitations, password resets), parse '
        'receipts and expense text you submit, and provide support. We do '
        'not sell your data and we do not show ads.',
  ),
  LegalSection(
    'AI processing',
    'Receipt images and expense text that you submit are processed by large '
        'language models hosted on Zoho Catalyst (QuickML) solely to extract '
        'expense details (amount, date, merchant, items). The output is shown '
        'to you for confirmation before anything is saved. Your data is not '
        'used to train these models.',
  ),
  LegalSection(
    'Service providers',
    'We use a small number of processors to operate SplitLLM: Supabase '
        '(authentication), Zoho Catalyst (application hosting and AI, India '
        'data centre), MongoDB Atlas (database), and Zoho ZeptoMail '
        '(transactional email). On the web, font files may be served from the '
        'Google Fonts CDN. Each provider processes data only to provide their '
        'service to us.',
  ),
  LegalSection(
    'Payments',
    'Settle-up links and QR codes deep-link into the UPI payment app of your '
        'choice. Payments happen entirely between you, your payment app, and '
        'your bank — we are not a payment processor and never receive or '
        'store payment credentials.',
  ),
  LegalSection(
    'What others can see',
    'People who share an expense, group, or friendship with you can see your '
        'display name and the expenses you share with them (amounts, shares, '
        'and settlement status). Your email is visible to friends who added '
        'you by email.',
  ),
  LegalSection(
    'Retention and deletion',
    'We keep your data while your account is active. You can delete your '
        'account any time from Account → Delete account: your profile is '
        'erased and your personal data removed, while records of expenses '
        'you shared with others are anonymised (shown as a deleted user) so '
        'their balances stay correct. You can also email '
        'support@splitllm.com to request deletion.',
  ),
  LegalSection(
    'Security',
    'Data is encrypted in transit (TLS) and protected by access controls at '
        'our providers. No method of storage or transmission is 100% secure, '
        'but we work to protect your information and will notify you of any '
        'breach as required by law.',
  ),
  LegalSection(
    'Children',
    'SplitLLM is not directed at children under 13, and we do not knowingly '
        'collect data from them. If you believe a child has created an '
        'account, contact us and we will delete it.',
  ),
  LegalSection(
    'Changes to this policy',
    'If we make material changes we will update the effective date above and '
        'notify you in the app or by email. Continued use after a change '
        'means you accept the updated policy.',
  ),
  LegalSection(
    'Contact',
    'Questions or requests about your data: support@splitllm.com.',
  ),
];

const String _termsEffectiveDate = '16 July 2026';

const List<LegalSection> _termsSections = [
  LegalSection(
    'What SplitLLM is',
    'SplitLLM is a tool for tracking and splitting expenses with friends. It '
        'is an informal record-keeping aid — not a bank, wallet, payment '
        'processor, or source of financial, legal, or tax advice. By creating '
        'an account or using the service you agree to these terms.',
  ),
  LegalSection(
    'Your account',
    'You must be at least 13 years old, provide accurate information, and '
        'keep your credentials confidential. You are responsible for '
        'activity on your account. Invite codes are for people you know and '
        'trust.',
  ),
  LegalSection(
    'Acceptable use',
    'Do not misuse the service: no unlawful content, no harassment, no '
        'attempts to break, overload, scrape, or reverse-engineer the '
        'service or access other users\' data. We may suspend or terminate '
        'accounts that do.',
  ),
  LegalSection(
    'Your content',
    'You own the content you add (expenses, receipts, messages). You grant '
        'us the licence needed to store and process it to operate the '
        'service — including AI parsing of receipts and text you submit. We '
        'do not use your content to train AI models.',
  ),
  LegalSection(
    'AI-generated results',
    'Amounts, dates, and details extracted by AI can be wrong. Review parsed '
        'expenses before saving, and treat balances as helpful bookkeeping '
        'between friends — they are not evidence of legal debt.',
  ),
  LegalSection(
    'Payments between users',
    'UPI links and QR codes only hand you over to your own payment app. Any '
        'payment is solely between you and the other person; we are not a '
        'party to it and are not responsible for failed, wrong, or disputed '
        'transfers.',
  ),
  LegalSection(
    'Termination',
    'You can stop using SplitLLM and delete your account at any time from '
        'the Account screen. We may suspend or close accounts that violate '
        'these terms or put the service or other users at risk.',
  ),
  LegalSection(
    'Disclaimers and liability',
    'The service is provided "as is" without warranties of any kind. To the '
        'maximum extent permitted by law, we are not liable for indirect or '
        'consequential losses, or for disputes between users about money '
        'owed. Our total liability for any claim is limited to the amount '
        'you paid us to use the service (currently nothing).',
  ),
  LegalSection(
    'Governing law',
    'These terms are governed by the laws of India. Disputes are subject to '
        'the exclusive jurisdiction of the courts of Chennai, Tamil Nadu.',
  ),
  LegalSection(
    'Changes and contact',
    'We may update these terms; material changes will be announced in the '
        'app or by email, and the effective date above updated. Questions: '
        'support@splitllm.com.',
  ),
];
