import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Color palette for the marketing landing page. These intentionally differ
/// from [AppTheme] so the landing page can present a distinct, branded look
/// (deep navy background with a soft purple accent) independent of the in-app
/// Material theme.
class _Palette {
  _Palette._();

  static const background = Color(0xFF051424);
  static const onBackground = Color(0xFFD4E4FA);
  static const primary = Color(0xFFD7BAFF);
  static const primaryContainer = Color(0xFFB78AF7);
  static const onPrimaryContainer = Color(0xFF491984);
  static const tertiaryContainer = Color(0xFFB18BFF);
  static const onSurfaceVariant = Color(0xFFCDC3D3);
  static const surfaceContainer = Color(0xFF122131);
  static const surfaceContainerHigh = Color(0xFF1C2B3C);
  static const surfaceContainerLowest = Color(0xFF010F1F);
  static const surfaceBright = Color(0xFF2C3A4C);
  static const hairline = Color(0x14FFFFFF); // white @ ~8%
}

/// Layout constants shared across sections.
class _Layout {
  _Layout._();

  static const double maxContentWidth = 1200;
  static const double mobileBreakpoint = 860;
  static const double headerHeight = 72;

  static double horizontalPadding(double width) =>
      width >= mobileBreakpoint ? 64 : 16;
}

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      backgroundColor: _Palette.background,
      body: Stack(
        children: [
          // Scrollable page content, padded down to clear the fixed header.
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: _Layout.headerHeight),
                _HeroSection(),
                _TrustBar(),
                _FeatureGrid(),
                _FinalCtaSection(),
                _Footer(),
              ],
            ),
          ),
          // Fixed, blurred navigation bar overlaying the content.
          Align(
            alignment: Alignment.topCenter,
            child: _Header(),
          ),
        ],
      ),
    );
  }
}

/// Centers its [child] within a max-width container with responsive
/// horizontal padding, matching the design's content gutters.
class _ContentContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _ContentContainer({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _Layout.maxContentWidth),
        child: Padding(
          padding: padding ??
              EdgeInsets.symmetric(
                  horizontal: _Layout.horizontalPadding(width)),
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header / Navigation
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Tiered breakpoints: full nav only when there's room for it, the "Log In"
    // button on tablets and up, the logo + "Get Started" always.
    final showNav = width >= 1024;
    final showLogIn = width >= 600;

    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLogIn) ...[
          _OutlineButton(
            label: 'Log In',
            onPressed: () => context.go('/login'),
          ),
          const SizedBox(width: 16),
        ],
        _PrimaryButton(
          label: 'Get Started',
          onPressed: () => context.go('/login'),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ],
    );

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: _Layout.headerHeight,
          decoration: const BoxDecoration(
            color: Color(0xCC051424), // background @ 80%
            border: Border(
              bottom: BorderSide(color: _Palette.hairline),
            ),
          ),
          child: _ContentContainer(
            padding: EdgeInsets.symmetric(
              horizontal: _Layout.horizontalPadding(width),
            ),
            child: showNav
                // Wide: logo (left) · centered nav · buttons (right).
                ? Row(
                    children: [
                      const _Logo(),
                      const Expanded(
                        child: Center(
                          // FittedBox(scaleDown) keeps the nav from overflowing
                          // its slot at tighter widths; it stays unscaled when
                          // there is room.
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _NavLink('Features', active: true),
                                SizedBox(width: 32),
                                _NavLink('How it Works'),
                                SizedBox(width: 32),
                                _NavLink('Pricing'),
                                SizedBox(width: 32),
                                _NavLink('Community'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      buttons,
                    ],
                  )
                // Tablet / mobile: logo (left) · buttons (right). The logo is
                // shrink-safe via FittedBox so the header never overflows.
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _Logo(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      buttons,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _Palette.primaryContainer,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: _Palette.primaryContainer.withValues(alpha: 0.4),
                blurRadius: 15,
              ),
            ],
          ),
          child: const Icon(
            Icons.receipt_long,
            size: 20,
            color: _Palette.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'SplitLLM',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _Palette.primary,
          ),
        ),
      ],
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final bool active;

  const _NavLink(this.label, {this.active = false});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.active || _hovering;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Container(
        padding: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: widget.active ? _Palette.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          widget.label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: widget.active ? FontWeight.w700 : FontWeight.w400,
            color: highlighted ? _Palette.primary : _Palette.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared buttons
// ---------------------------------------------------------------------------

class _PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    this.fontSize = 14,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _hovering
                ? _Palette.tertiaryContainer
                : _Palette.primaryContainer,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: _Palette.primaryContainer
                    .withValues(alpha: _hovering ? 0.4 : 0.2),
                blurRadius: _hovering ? 25 : 15,
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w600,
              color: _Palette.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const _OutlineButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _hovering
                  ? _Palette.primary.withValues(alpha: 0.5)
                  : _Palette.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20, color: _Palette.primary),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _Palette.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _Layout.mobileBreakpoint;

    return _ContentContainer(
      padding: EdgeInsets.fromLTRB(
        _Layout.horizontalPadding(width),
        isDesktop ? 96 : 64,
        _Layout.horizontalPadding(width),
        96,
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Soft background glow behind the hero copy. A RadialGradient fading
          // to transparent reads as a genuine glow (a solid circle + shadow
          // renders as a hard-edged disc in Flutter).
          const Positioned(
            top: 40,
            child: IgnorePointer(
              child: SizedBox(
                width: 620,
                height: 620,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0x33D7BAFF), // primary @ ~20% center
                        Color(0x00D7BAFF), // transparent edge
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Slow-drifting gradient orbs give the hero depth behind the copy.
          const Positioned(
            top: 140,
            left: 20,
            child: _FloatingOrb(
              size: 180,
              color: Color(0x2200E5C9),
              duration: Duration(seconds: 7),
            ),
          ),
          const Positioned(
            top: 60,
            right: 40,
            child: _FloatingOrb(
              size: 140,
              color: Color(0x33B78AF7),
              duration: Duration(seconds: 9),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Badge(),
              const SizedBox(height: 32),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Text(
                  'Just another expense\nsplitting app.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isDesktop ? 60 : 38,
                    height: 1.08,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.2,
                    color: _Palette.onBackground,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Text(
                  'Except this one reads your receipts, speaks 31 currencies, '
                  'imports your Splitwise history, and settles the math before '
                  'the conversation gets awkward.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isDesktop ? 18 : 16,
                    height: 1.55,
                    fontWeight: FontWeight.w400,
                    color: _Palette.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _HeroActions(isDesktop: isDesktop),
              SizedBox(height: isDesktop ? 96 : 64),
              // Perspective-tilted product shot that reacts to the pointer.
              const _Tilt3D(child: _DashboardPreview()),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroActions extends StatelessWidget {
  final bool isDesktop;
  const _HeroActions({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final getStarted = _PrimaryButton(
      label: 'Get Started',
      fontSize: 16,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      onPressed: () => context.go('/login'),
    );
    final viewDemo = _OutlineButton(
      label: 'View Demo',
      icon: Icons.play_circle_outline,
      onPressed: () => context.go('/login'),
    );

    if (isDesktop) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [getStarted, const SizedBox(width: 16), viewDemo],
      );
    }
    return Column(
      children: [getStarted, const SizedBox(height: 16), viewDemo],
    );
  }
}

class _Badge extends StatefulWidget {
  const _Badge();

  @override
  State<_Badge> createState() => _BadgeState();
}

class _BadgeState extends State<_Badge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _Palette.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _Palette.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller),
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _Palette.primaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'SPLITLLM.COM — NOW WITH RECEIPT VISION',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: _Palette.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A soft radial orb that drifts slowly up and down, adding depth behind the
/// hero content. Purely decorative.
class _FloatingOrb extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const _FloatingOrb({
    required this.size,
    required this.color,
    required this.duration,
  });

  @override
  State<_FloatingOrb> createState() => _FloatingOrbState();
}

class _FloatingOrbState extends State<_FloatingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 24 * (_controller.value - 0.5)),
          child: child,
        ),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [widget.color, widget.color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps [child] in a 3D perspective tilt that follows the pointer on
/// desktop/web, giving the product shot a "floating card" feel. On touch it
/// rests at a subtle static tilt.
class _Tilt3D extends StatefulWidget {
  final Widget child;
  const _Tilt3D({required this.child});

  @override
  State<_Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<_Tilt3D> {
  // Tilt angles in radians, driven by the pointer's position over the card.
  double _rx = 0.04;
  double _ry = 0;

  void _updateTilt(PointerEvent event, Size size) {
    final dx = (event.localPosition.dx / size.width) - 0.5; // -0.5 .. 0.5
    final dy = (event.localPosition.dy / size.height) - 0.5;
    setState(() {
      _ry = dx * 0.10;
      _rx = 0.04 - dy * 0.10;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => MouseRegion(
        onHover: (e) => _updateTilt(
            e, Size(constraints.maxWidth, constraints.maxHeight)),
        onExit: (_) => setState(() {
          _rx = 0.04;
          _ry = 0;
        }),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 120),
          builder: (context, _, __) => Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012) // perspective
              ..rotateX(_rx)
              ..rotateY(_ry),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// A stylized mock of the in-app dashboard, shown as the hero's product
/// preview. Recreated natively (rather than a remote image) so it renders
/// offline and stays on-brand.
class _DashboardPreview extends StatelessWidget {
  const _DashboardPreview();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _Palette.hairline),
          gradient: const LinearGradient(
            colors: [Color(0xFFB78AF7), Color(0xFF1DB0A6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x80000000), blurRadius: 50),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 32),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF051424),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              'SplitLLM',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0B0B14),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Intelligent Expense Sharing & Splitting',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xCC0B0B14),
              ),
            ),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PreviewRow(Icons.smart_toy, 'AI-Powered Splitting'),
                  SizedBox(height: 12),
                  _PreviewRow(
                      Icons.account_balance_wallet, 'Seamless Group Expenses'),
                  SizedBox(height: 12),
                  _PreviewRow(Icons.share, 'Invite Friends & Share'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PreviewRow(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xCC0B0B14)),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xCC0B0B14),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Trust bar
// ---------------------------------------------------------------------------

class _TrustBar extends StatelessWidget {
  const _TrustBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0x80010F1F), // surface-container-lowest @ 50%
        border: Border.symmetric(
          horizontal: BorderSide(color: _Palette.hairline),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: _ContentContainer(
        child: Column(
          children: [
            Text(
              'TRUSTED BY DIGITAL NOMADS AND FRIEND GROUPS WORLDWIDE',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: _Palette.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            const Opacity(
              opacity: 0.5,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 48,
                runSpacing: 24,
                children: [
                  _FauxLogo('AcmeCorp'),
                  _FauxLogo('WanderLust', italic: true),
                  _FauxLogo('Splitters'),
                  _FauxLogo('NEXUS', letterSpacing: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FauxLogo extends StatelessWidget {
  final String name;
  final bool italic;
  final double letterSpacing;

  const _FauxLogo(this.name, {this.italic = false, this.letterSpacing = 0});

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        letterSpacing: letterSpacing,
        color: const Color(0xFFBFC9D6),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feature grid
// ---------------------------------------------------------------------------

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  static const _features = [
    (
      icon: Icons.document_scanner,
      title: 'Receipts That Read Themselves',
      body:
          'Snap a receipt and a vision model extracts the merchant, items, '
              'taxes, total, and even the currency — ready to split.',
    ),
    (
      icon: Icons.currency_exchange,
      title: 'Any Currency, One Balance',
      body:
          'Set a currency per group, per expense, or globally. Everything is '
              'auto-converted so trips abroad still add up at home.',
    ),
    (
      icon: Icons.move_down,
      title: 'Leave Splitwise in Minutes',
      body:
          'Import a Splitwise CSV export and your whole group history — '
              'expenses, payments, and balances — comes with you.',
    ),
    (
      icon: Icons.account_balance_wallet,
      title: 'Groups That Stay Organized',
      body:
          'Trips, flats, dinners — keep every shared expense in its place '
              'with running balances for each member.',
    ),
    (
      icon: Icons.share,
      title: 'Settle With a Link',
      body:
          'Send a payment link with the exact amount. No app download '
              'required for them to pay you back.',
    ),
    (
      icon: Icons.mark_email_read,
      title: 'Everyone Stays in the Loop',
      body:
          'New expenses, settle-ups, and invites land in your group\'s inbox '
              'automatically — no more "wait, what do I owe?"',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _Layout.mobileBreakpoint;

    return _ContentContainer(
      padding: EdgeInsets.symmetric(
        horizontal: _Layout.horizontalPadding(width),
        vertical: isDesktop ? 128 : 80,
      ),
      child: Column(
        children: [
          Text(
            'Effortless Control',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: _Palette.onBackground,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              'Experience a frictionless environment where managing shared '
              'finances feels like a premium digital tool.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                height: 1.5,
                color: _Palette.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 64),
          if (isDesktop)
            // Rows of three. IntrinsicHeight bounds each Row's height to its
            // tallest child so CrossAxisAlignment.stretch yields equal-height
            // cards. Without it, stretch inside the unbounded-height scroll
            // view forces infinity.
            Column(
              children: [
                for (var row = 0; row < _features.length; row += 3) ...[
                  if (row > 0) const SizedBox(height: 24),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = row;
                            i < row + 3 && i < _features.length;
                            i++) ...[
                          if (i > row) const SizedBox(width: 24),
                          Expanded(
                            child: _FeatureCard(
                              icon: _features[i].icon,
                              title: _features[i].title,
                              body: _features[i].body,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            )
          else
            Column(
              children: [
                for (var i = 0; i < _features.length; i++) ...[
                  if (i > 0) const SizedBox(height: 24),
                  _FeatureCard(
                    icon: _features[i].icon,
                    title: _features[i].title,
                    body: _features[i].body,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String body;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _Palette.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovering
                ? _Palette.primary.withValues(alpha: 0.3)
                : _Palette.hairline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedScale(
              scale: _hovering ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _Palette.surfaceBright,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, size: 24, color: _Palette.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _Palette.onBackground,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.body,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.55,
                color: _Palette.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Final CTA
// ---------------------------------------------------------------------------

class _FinalCtaSection extends StatelessWidget {
  const _FinalCtaSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _Layout.mobileBreakpoint;

    return _ContentContainer(
      padding: EdgeInsets.symmetric(
        horizontal: _Layout.horizontalPadding(width),
        vertical: isDesktop ? 96 : 64,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _Palette.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _Palette.hairline),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 48 : 24,
            vertical: 56,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Text(
                  'Ready to balance your life?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isDesktop ? 32 : 26,
                    fontWeight: FontWeight.w700,
                    color: _Palette.onBackground,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  'Join thousands of users who are already experiencing the '
                  'future of shared expenses.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    height: 1.5,
                    color: _Palette.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _PrimaryButton(
                label: 'Create Your Free Account',
                fontSize: 16,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer
// ---------------------------------------------------------------------------

class _Footer extends StatelessWidget {
  const _Footer();

  static const _links = [
    'Privacy Policy',
    'Terms of Service',
    'Security',
    'Status',
    'Contact Us',
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _Layout.mobileBreakpoint;

    final logo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.receipt_long, size: 20, color: _Palette.primary),
        const SizedBox(width: 8),
        Text(
          'SplitLLM',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _Palette.primary,
          ),
        ),
      ],
    );

    final links = Wrap(
      alignment: WrapAlignment.center,
      spacing: 24,
      runSpacing: 12,
      children: [for (final l in _links) _FooterLink(l)],
    );

    final copyright = Text(
      '© 2026 SplitLLM. All rights reserved. Developed and maintained by '
      'siv19.dev',
      textAlign: isDesktop ? TextAlign.right : TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 12,
        color: _Palette.onSurfaceVariant,
      ),
    );

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _Palette.surfaceContainerLowest,
        border: Border(top: BorderSide(color: _Palette.hairline)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: _Layout.horizontalPadding(width),
        vertical: 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: _Layout.maxContentWidth),
          child: isDesktop
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    logo,
                    Flexible(child: links),
                    Flexible(child: copyright),
                  ],
                )
              : Column(
                  children: [
                    logo,
                    const SizedBox(height: 24),
                    links,
                    const SizedBox(height: 24),
                    copyright,
                  ],
                ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String label;
  const _FooterLink(this.label);

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Text(
        widget.label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _hovering
              ? _Palette.tertiaryContainer
              : _Palette.onSurfaceVariant,
        ),
      ),
    );
  }
}
