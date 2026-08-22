import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../utils/url_helper.dart';
import '../widgets/safe_network_image.dart';

class ProfileHomePage extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final String username;
  final String? fullName;
  final String? bio;
  final String? avatarUrl;
  final Map<String, String>? avatarHeaders;
  final int postsCount;
  final int followers;
  final int following;
  final int likesCount;
  final bool isMe;
  final bool isValidated;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;
  final VoidCallback? onFollow;
  final VoidCallback? onMessage;
  final VoidCallback? onShare;

  const ProfileHomePage({
    super.key,
    required this.profile,
    required this.username,
    required this.fullName,
    required this.bio,
    required this.avatarUrl,
    required this.avatarHeaders,
    required this.postsCount,
    required this.followers,
    required this.following,
    required this.likesCount,
    required this.isMe,
    required this.isValidated,
    required this.onBack,
    required this.onMenu,
    required this.onFollow,
    required this.onMessage,
    required this.onShare,
  });

  static const Color _gold = Color(0xFFD4AF37);
  static const Color _goldSoft = Color(0xFFFFD77A);
  static const Color _panel = Color(0xFF101010);

  String _stringValue(List<String> keys, {String fallback = ''}) {
    final source = profile;
    if (source == null) return fallback;
    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  List<String> _listValue(List<String> keys, {required List<String> fallback}) {
    final source = profile;
    if (source == null) return fallback;
    for (final key in keys) {
      final value = source[key];
      if (value is List) {
        final items =
            value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty);
        final result = items.toList();
        if (result.isNotEmpty) return result;
      } else if (value is String && value.trim().isNotEmpty) {
        final result = value
            .split(RegExp(r'[,|/]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (result.isNotEmpty) return result;
      }
    }
    return fallback;
  }

  String _titleCase(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return cleaned;
    return cleaned
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) {
      if (part.length <= 1) return part.toUpperCase();
      return part[0].toUpperCase() + part.substring(1).toLowerCase();
    }).join(' ');
  }

  String _location() {
    final direct = _stringValue([
      'location',
      'city',
      'hometown',
      'address',
      'place',
    ]);
    if (direct.isNotEmpty) return _titleCase(direct);
    final city = _stringValue(['city']);
    final state = _stringValue(['state', 'province']);
    final country = _stringValue(['country']);
    final parts = <String>[city, state, country]
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isNotEmpty) return parts.join(', ');
    return 'Jaipur, Rajasthan';
  }

  String _dateLine() {
    return _stringValue([
      'date_of_birth',
      'dob',
      'birth_date',
      'birthdate',
      'dateOfBirth',
    ], fallback: '23 March 2016');
  }

  String _profession() {
    return _stringValue([
      'profession',
      'occupation',
      'job_title',
      'designation',
      'class',
      'grade',
    ], fallback: '3rd Grade');
  }

  String _aboutText() {
    final direct = _stringValue([
      'about_me',
      'aboutMe',
      'bio',
      'description',
      'intro',
    ]);
    if (direct.isNotEmpty) return direct;
    return 'Hi! I’m ${fullName?.trim().isNotEmpty == true ? fullName!.trim() : username.trim()}, a curious little creator who loves learning, exploring, and making every day feel a bit brighter.';
  }

  List<String> _hobbies() {
    return _listValue(
      ['hobbies', 'interests', 'tags', 'favoriteThings'],
      fallback: const ['Drawing', 'Reading', 'Dancing', 'Exploring'],
    );
  }

  int _likesFallback() {
    if (likesCount > 0) return likesCount;
    return 512;
  }

  Widget _topIconButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.50),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Future<void> _showQuickActionsSheet(
    BuildContext context,
    List<String> hobbies,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.settings_rounded,
                    color: _gold,
                  ),
                  title: const Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Open profile settings',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onMenu?.call();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.favorite_rounded,
                    color: _goldSoft,
                  ),
                  title: const Text(
                    'Hobbies',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'View hobbies and interests',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showHobbiesSheet(context, hobbies);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showHobbiesSheet(
    BuildContext context,
    List<String> hobbies,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Hobbies & Interests',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final hobby in hobbies)
                      Chip(
                        label: Text(hobby),
                        backgroundColor: Colors.white.withValues(alpha: 0.04),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        const Icon(LucideIcons.user, size: 16, color: _gold),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _gold,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _goldChip({
    required IconData icon,
    required String label,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: _gold),
          SizedBox(width: compact ? 6 : 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                color: Colors.white70,
                fontSize: compact ? 12.0 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailTile({
    required IconData icon,
    required String label,
    required String value,
    Color iconColor = _gold,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsCard(BuildContext context) {
    final statItems = <_StatItem>[
      _StatItem('Posts', postsCount.toString(), LucideIcons.grid2x2),
      _StatItem('Followers', _formatCompact(followers), LucideIcons.users),
      _StatItem('Following', _formatCompact(following), LucideIcons.userRound),
      _StatItem('Likes', _formatCompact(_likesFallback()), LucideIcons.heart),
    ];

    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFFFFD56A),
            Color(0xFFE8A928),
            Color(0xFFFFF0C2),
            Color(0xFFC88A12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.33, 0.66, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.32),
            blurRadius: 34,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF2A1B0A),
                      Color(0xFF0E0B08),
                      Color(0xFF201409),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -50,
              left: -28,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFF0C2).withValues(alpha: 0.36),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -28,
              bottom: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.transparent,
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              child: Row(
                children: [
                  for (var i = 0; i < statItems.length; i++) ...[
                    Expanded(
                      child: _StatTile(item: statItems[i]),
                    ),
                    if (i != statItems.length - 1)
                      Container(
                        width: 1,
                        height: 72,
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCompact(int value) {
    if (value >= 1000000) {
      final n = value / 1000000;
      return '${n.toStringAsFixed(n >= 10 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      final n = value / 1000;
      return '${n.toStringAsFixed(n >= 10 ? 0 : 1)}K';
    }
    return value.toString();
  }

  Widget _stickyActions(BuildContext context) {
    if (isMe) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF6C453), Color(0xFFE0A91F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: onFollow,
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.userPlus, color: Colors.black),
                          SizedBox(width: 10),
                          Text(
                            'Follow',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _gold.withValues(alpha: 0.85)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: onMessage,
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.messageCircle, color: _gold),
                          SizedBox(width: 10),
                          Text(
                            'Message',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: onShare,
                  child: const Icon(
                    LucideIcons.send,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final heroUrl = (avatarUrl ?? '').trim();
    final hasHero = heroUrl.isNotEmpty;
    final shouldAttachAuth =
        hasHero && UrlHelper.shouldAttachAuthHeader(heroUrl);
    final heroHeaders = shouldAttachAuth ? avatarHeaders : null;
    final displayName = fullName?.trim().isNotEmpty == true
        ? fullName!.trim()
        : username.trim();
    const tagline = <String>['Dreamer', 'Learner', 'Little Explorer'];
    final hobbies = _hobbies();
    final showBadge = isValidated;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black, Colors.black],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 380,
                    width: double.infinity,
                    child: Stack(
                      clipBehavior: Clip.none,
                      fit: StackFit.expand,
                      children: [
                        if (hasHero)
                          SafeNetworkImage(
                            url: heroUrl,
                            headers: heroHeaders,
                            fit: BoxFit.cover,
                            placeholder: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF2B2B2B),
                                    Color(0xFF0F0F0F)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                            errorWidget: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF2B2B2B),
                                    Color(0xFF0F0F0F)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF2B2B2B), Color(0xFF0F0F0F)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        const Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0x00000000),
                                  Color(0x00000000),
                                  Color(0x66000000),
                                  Color(0xE6000000),
                                ],
                                stops: [0.0, 0.72, 0.90, 1.0],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: topInset + 20,
                          left: 16,
                          child: _topIconButton(
                            context: context,
                            icon: LucideIcons.chevronLeft,
                            onTap: onBack,
                          ),
                        ),
                        Positioned(
                          top: topInset + 20,
                          right: 16,
                          child: _topIconButton(
                            context: context,
                            icon: Icons.more_horiz_rounded,
                            onTap: () =>
                                _showQuickActionsSheet(context, hobbies),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: -28,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _goldSoft.withValues(alpha: 0.85),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _gold.withValues(alpha: 0.35),
                                    blurRadius: 22,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 58,
                                backgroundColor: _panel,
                                child: ClipOval(
                                  child: SizedBox(
                                    width: 116,
                                    height: 116,
                                    child: hasHero
                                        ? SafeNetworkImage(
                                            url: heroUrl,
                                            headers: heroHeaders,
                                            fit: BoxFit.cover,
                                            placeholder: const ColoredBox(
                                              color: Color(0xFF222222),
                                            ),
                                            errorWidget: const ColoredBox(
                                              color: Color(0xFF222222),
                                            ),
                                          )
                                        : const ColoredBox(
                                            color: Color(0xFF222222),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (showBadge)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: -46,
                            child: Center(
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: _gold,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _gold.withValues(alpha: 0.4),
                                      blurRadius: 18,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.verified_rounded,
                                  color: Colors.black,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    color: Colors.black,
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 14),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              displayName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                              ),
                            ),
                            if (showBadge) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.verified_rounded,
                                color: _gold,
                                size: 22,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tagline.join('  •  '),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _goldChip(
                                icon: LucideIcons.mapPin,
                                label: _location(),
                                compact: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _goldChip(
                                icon: LucideIcons.calendarDays,
                                label: _dateLine(),
                                compact: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _goldChip(
                                icon: LucideIcons.graduationCap,
                                label: _profession(),
                                compact: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _statsCard(context),
                        const SizedBox(height: 28),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _sectionTitle('About Me'),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _aboutText(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: _panel.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _detailTile(
                                        icon: LucideIcons.calendarDays,
                                        label: 'Date of Birth',
                                        value: _dateLine(),
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 74,
                                      color:
                                          Colors.white.withValues(alpha: 0.08),
                                    ),
                                    Expanded(
                                      child: _detailTile(
                                        icon: LucideIcons.heart,
                                        label: 'Hobbies',
                                        value: hobbies.take(3).join(', '),
                                        iconColor: const Color(0xFFF99BC1),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _detailTile(
                                        icon: LucideIcons.mapPin,
                                        label: 'Location',
                                        value: _location(),
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 74,
                                      color:
                                          Colors.white.withValues(alpha: 0.08),
                                    ),
                                    Expanded(
                                      child: _detailTile(
                                        icon: LucideIcons.bookOpen,
                                        label: 'Favorite Subject',
                                        value: _stringValue(
                                          [
                                            'favorite_subject',
                                            'favoriteSubject'
                                          ],
                                          fallback: 'Art',
                                        ),
                                        iconColor: const Color(0xFFBA8CFF),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _detailTile(
                                        icon: LucideIcons.graduationCap,
                                        label: 'Class',
                                        value: _profession(),
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 74,
                                      color:
                                          Colors.white.withValues(alpha: 0.08),
                                    ),
                                    Expanded(
                                      child: _detailTile(
                                        icon: LucideIcons.palette,
                                        label: 'Favorite Color',
                                        value: _stringValue(
                                          ['favorite_color', 'favoriteColor'],
                                          fallback: 'Pink',
                                        ),
                                        iconColor: const Color(0xFFF99BC1),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _sectionTitle('Hobbies & Interests'),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final hobby in hobbies.take(6))
                              Chip(
                                label: Text(hobby),
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.03),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                                labelStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: _stickyActions(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem(this.label, this.value, this.icon);
}

class _StatTile extends StatelessWidget {
  final _StatItem item;

  const _StatTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, color: ProfileHomePage._goldSoft, size: 22),
        const SizedBox(height: 10),
        Text(
          item.value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 29,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.68),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
