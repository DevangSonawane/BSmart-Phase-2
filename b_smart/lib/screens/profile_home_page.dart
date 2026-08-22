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
  static const String _missingText = 'Null';

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
    ], fallback: '');
    if (direct.isNotEmpty) return _titleCase(direct);
    final city = _stringValue(['city']);
    final state = _stringValue(['state', 'province']);
    final country = _stringValue(['country']);
    final parts = <String>[city, state, country]
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isNotEmpty) return parts.join(', ');
    return _missingText;
  }

  String _dateLine() {
    return _stringValue([
      'date_of_birth',
      'dob',
      'birth_date',
      'birthdate',
      'dateOfBirth',
    ], fallback: _missingText);
  }

  String _profession() {
    return _stringValue([
      'profession',
      'occupation',
      'job_title',
      'designation',
      'class',
      'grade',
      'account_type',
      'accountType',
      'role',
    ], fallback: _missingText);
  }

  String _aboutText() {
    final direct = bio?.trim().isNotEmpty == true
        ? bio!.trim()
        : _stringValue([
            'about_me',
            'aboutMe',
            'bio',
            'description',
            'intro',
          ], fallback: '');
    if (direct.isNotEmpty) return direct;
    return _missingText;
  }

  List<String> _hobbies() {
    return _listValue(
      ['hobbies', 'interests', 'tags', 'favoriteThings'],
      fallback: const [],
    );
  }

  int _likesFallback() {
    if (likesCount > 0) return likesCount;
    return 0;
  }

  bool _isFollowed() {
    final source = profile;
    if (source == null) return false;
    final value = source['is_followed_by_me'] ??
        source['isFollowing'] ??
        source['is_following'] ??
        source['followed_by_me'] ??
        source['followed'];
    if (value is bool) return value;
    if (value == null) return false;
    final text = value.toString().trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes' || text == 'followed';
  }

  String _profileSummary() {
    final direct = _stringValue([
      'tagline',
      'headline',
      'status',
      'bio',
      'about_me',
      'aboutMe',
    ], fallback: '');
    if (direct.isNotEmpty) return direct;
    return _missingText;
  }

  Widget _topIconButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.50),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Future<void> _showQuickActionsSheet(
    BuildContext buttonContext,
    List<String> hobbies,
  ) async {
    final buttonBox = buttonContext.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.of(buttonContext).context.findRenderObject() as RenderBox?;
    const menuWidth = 190.0;
    final position = buttonBox != null && overlayBox != null
        ? buttonBox.localToGlobal(Offset.zero, ancestor: overlayBox)
        : Offset.zero;
    final left = buttonBox != null && overlayBox != null
        ? (position.dx + buttonBox.size.width - menuWidth).clamp(
            12.0,
            overlayBox.size.width - menuWidth - 12.0,
          )
        : 12.0;
    final top = buttonBox != null
        ? position.dy + buttonBox.size.height + 8.0
        : MediaQuery.of(buttonContext).padding.top + 62;

    await showGeneralDialog<void>(
      context: buttonContext,
      barrierDismissible: true,
      barrierLabel: 'Quick actions',
      barrierColor: Colors.black.withValues(alpha: 0.20),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                child: Material(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: menuWidth,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _quickActionRow(
                          context: dialogContext,
                          icon: Icons.settings_rounded,
                          iconColor: _gold,
                          title: 'Settings',
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            onMenu?.call();
                          },
                        ),
                        const SizedBox(height: 8),
                        _quickActionRow(
                          context: dialogContext,
                          icon: Icons.favorite_rounded,
                          iconColor: _goldSoft,
                          title: 'Hobbies',
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            _showHobbiesSheet(buttonContext, hobbies);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.965, end: 1.0).animate(curved),
            alignment: Alignment.topRight,
            child: child,
          ),
        );
      },
    );
  }

  Widget _quickActionRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
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

  Widget _profileInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color iconColor = _gold,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFFF7D67A),
            Color(0xFFB88414),
            Color(0xFFFFE3A0),
            Color(0xFF7A5310),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.30, 0.68, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.14),
            blurRadius: 18,
            spreadRadius: 0.2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF201309),
                      Color(0xFF0C0C0C),
                      Color(0xFF130F0B),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -46,
              left: -28,
              child: Container(
                width: 142,
                height: 142,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFF1C7).withValues(alpha: 0.26),
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
                        Colors.white.withValues(alpha: 0.08),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              child: Row(
                children: [
                  for (var i = 0; i < statItems.length; i++) ...[
                    Expanded(
                      child: _StatTile(item: statItems[i]),
                    ),
                    if (i != statItems.length - 1)
                      Container(
                        width: 1,
                        height: 68,
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
    final isFollowed = _isFollowed();
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.98),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF6C453), Color(0xFFE0A91F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onFollow,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!isFollowed) ...[
                            const Icon(
                              LucideIcons.userPlus,
                              color: Colors.black,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            isFollowed ? 'Followed' : 'Follow',
                            style: TextStyle(
                              color: isFollowed ? Colors.black : Colors.black,
                              fontSize: 15,
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
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _gold.withValues(alpha: 0.85)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onMessage,
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.messageCircle,
                              color: _gold, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Message',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
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
            const SizedBox(width: 10),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onShare,
                  child: const Icon(
                    LucideIcons.send,
                    color: Colors.white,
                    size: 20,
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
    final hobbies = _hobbies();
    const showBadge = true;

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
                    height: 340,
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
                          top: topInset + 14,
                          left: 16,
                          child: _topIconButton(
                            context: context,
                            icon: LucideIcons.chevronLeft,
                            onTap: onBack,
                          ),
                        ),
                        Positioned(
                          top: topInset + 14,
                          right: 16,
                          child: Builder(
                            builder: (buttonContext) => _topIconButton(
                              context: buttonContext,
                              icon: Icons.more_horiz_rounded,
                              onTap: () => _showQuickActionsSheet(
                                buttonContext,
                                hobbies,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _goldSoft.withValues(alpha: 0.96),
                                      width: 2.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _gold.withValues(alpha: 0.24),
                                        blurRadius: 16,
                                        spreadRadius: 0.4,
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 53,
                                    backgroundColor: _panel,
                                    child: ClipOval(
                                      child: SizedBox(
                                        width: 106,
                                        height: 106,
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
                                if (showBadge)
                                  const Positioned(
                                    right: 4,
                                    bottom: 4,
                                    child: Icon(
                                      Icons.verified_rounded,
                                      color: _gold,
                                      size: 22,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    color: Colors.black,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
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
                          _profileSummary(),
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
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF101010),
                                Color(0xFF0E0E0E),
                                Color(0xFF090909),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.065),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _profileInfoTile(
                                          icon: LucideIcons.calendarDays,
                                          label: 'Date of Birth',
                                          value: _dateLine(),
                                        ),
                                        const SizedBox(height: 18),
                                        _profileInfoTile(
                                          icon: LucideIcons.mapPin,
                                          label: 'Location',
                                          value: _location(),
                                        ),
                                        const SizedBox(height: 18),
                                        _profileInfoTile(
                                          icon: LucideIcons.graduationCap,
                                          label: 'Class',
                                          value: _profession(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _profileInfoTile(
                                          icon: LucideIcons.heart,
                                          label: 'Hobbies',
                                          value: hobbies.isNotEmpty
                                              ? hobbies.join(', ')
                                              : _missingText,
                                          iconColor: const Color(0xFFF48FAF),
                                        ),
                                        const SizedBox(height: 18),
                                        _profileInfoTile(
                                          icon: LucideIcons.palette,
                                          label: 'Favorite Color',
                                          value: _stringValue(
                                            ['favorite_color', 'favoriteColor'],
                                            fallback: _missingText,
                                          ),
                                          iconColor: const Color(0xFFB68CFF),
                                        ),
                                        const SizedBox(height: 18),
                                        _profileInfoTile(
                                          icon: LucideIcons.bookOpen,
                                          label: 'Favorite Subject',
                                          value: _stringValue(
                                            [
                                              'favorite_subject',
                                              'favoriteSubject'
                                            ],
                                            fallback: _missingText,
                                          ),
                                          iconColor: const Color(0xFFB68CFF),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
                            if (hobbies.isEmpty)
                              Chip(
                                label: const Text(_missingText),
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
                              )
                            else
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
