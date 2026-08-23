import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';

import '../api/posts_api.dart';
import '../api/upload_api.dart';
import '../models/location_place.dart';
import '../models/media_model.dart';
import '../services/create_service.dart';
import '../utils/url_helper.dart';
import 'edit_video_screen.dart';
import 'location_search_screen.dart';
import 'tag_people_screen.dart';

class _PromoteDraftMedia {
  final String path;
  final bool isVideo;
  final double aspectRatio;
  final Duration? trimStart;
  final Duration? trimEnd;
  final Duration? duration;

  const _PromoteDraftMedia({
    required this.path,
    required this.isVideo,
    required this.aspectRatio,
    this.trimStart,
    this.trimEnd,
    this.duration,
  });

  _PromoteDraftMedia copyWith({
    String? path,
    bool? isVideo,
    double? aspectRatio,
    Duration? trimStart,
    Duration? trimEnd,
    Duration? duration,
  }) {
    return _PromoteDraftMedia(
      path: path ?? this.path,
      isVideo: isVideo ?? this.isVideo,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
      duration: duration ?? this.duration,
    );
  }
}

class _PromoteDraftProduct {
  final String name;
  final String description;
  final String price;
  final String discountAmount;
  final String visitLink;
  final String? imagePath;

  const _PromoteDraftProduct({
    required this.name,
    required this.description,
    required this.price,
    required this.discountAmount,
    required this.visitLink,
    this.imagePath,
  });

  _PromoteDraftProduct copyWith({
    String? name,
    String? description,
    String? price,
    String? discountAmount,
    String? visitLink,
    String? imagePath,
  }) {
    return _PromoteDraftProduct(
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discountAmount: discountAmount ?? this.discountAmount,
      visitLink: visitLink ?? this.visitLink,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

class PromoteComposerScreen extends StatefulWidget {
  const PromoteComposerScreen({super.key});

  @override
  State<PromoteComposerScreen> createState() => _PromoteComposerScreenState();
}

class _PromoteComposerScreenState extends State<PromoteComposerScreen> {
  final CreateService _createService = CreateService();
  final UploadApi _uploadApi = UploadApi();
  final PostsApi _postsApi = PostsApi();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _captionCtl = TextEditingController();
  final TextEditingController _tagCtl = TextEditingController();
  final TextEditingController _locationCtl = TextEditingController();

  final List<_PromoteDraftMedia> _media = [];
  final List<_PromoteDraftProduct> _products = [];
  final List<String> _hashtags = [];
  final List<Map<String, dynamic>> _peopleTags = [];

  LocationPlace? _location;
  bool _hideLikes = false;
  bool _turnOffCommenting = false;
  bool _isSubmitting = false;
  int _step = 0;

  static const _stepTitles = <String>[
    'Media',
    'Products',
    'Details',
    'Review',
  ];

  @override
  void dispose() {
    _captionCtl.dispose();
    _tagCtl.dispose();
    _locationCtl.dispose();
    super.dispose();
  }

  String _pickString(dynamic value) {
    final s = (value ?? '').toString().trim();
    return s;
  }

  Future<double> _imageAspectRatio(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final ui.Image image = await decodeImageFromList(bytes);
      if (image.width > 0 && image.height > 0) {
        return image.width / image.height;
      }
    } catch (_) {}
    return 1.0;
  }

  Future<double> _videoAspectRatio(String path) async {
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      final aspect = controller.value.aspectRatio;
      if (aspect.isFinite && aspect > 0) return aspect;
    } catch (_) {
      // fall back below
    } finally {
      await controller.dispose();
    }
    return 9 / 16;
  }

  Future<_PromoteDraftMedia> _buildDraftMedia(
    XFile file, {
    Duration? trimStart,
    Duration? trimEnd,
    Duration? duration,
  }) async {
    final path = file.path;
    final lower = file.name.toLowerCase();
    final isVideo = lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.3gp') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mkv');
    final aspect =
        isVideo ? await _videoAspectRatio(path) : await _imageAspectRatio(path);
    return _PromoteDraftMedia(
      path: path,
      isVideo: isVideo,
      aspectRatio: aspect,
      trimStart: trimStart,
      trimEnd: trimEnd,
      duration: duration,
    );
  }

  Future<void> _pickMedia() async {
    try {
      final choice = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 14),
                  _sheetOption(
                    icon: LucideIcons.imagePlus,
                    title: 'Add photos',
                    subtitle: 'Pick one or more images from your gallery',
                    onTap: () => Navigator.pop(ctx, 'image'),
                  ),
                  const SizedBox(height: 10),
                  _sheetOption(
                    icon: LucideIcons.video,
                    title: 'Add video',
                    subtitle: 'Pick a short vertical clip to promote',
                    onTap: () => Navigator.pop(ctx, 'video'),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      );
      if (choice == null) return;

      if (choice == 'video') {
        final file = await _picker.pickVideo(source: ImageSource.gallery);
        if (file == null) return;
        final media = await _buildDraftMedia(file);
        final trimmed = await Navigator.of(context).push<VideoEditResult>(
          MaterialPageRoute(
            builder: (_) => EditVideoScreen(
              media: MediaItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                type: MediaType.video,
                filePath: file.path,
                createdAt: DateTime.now(),
              ),
            ),
          ),
        );
        if (trimmed == null) return;
        if (!mounted) return;
        setState(() {
          _media
            ..clear()
            ..add(
              media.copyWith(
                trimStart: trimmed.trimStart,
                trimEnd: trimmed.trimEnd,
              ),
            );
        });
        return;
      }

      final picked = await _picker.pickMultiImage(imageQuality: 100);

      if (picked.isEmpty) return;

      final next = <_PromoteDraftMedia>[];
      for (final file in picked.take(6)) {
        next.add(await _buildDraftMedia(file));
      }

      if (!mounted || next.isEmpty) return;
      setState(() {
        if (_media.any((item) => item.isVideo)) {
          _media.clear();
        }
        if (next.any((item) => item.isVideo)) {
          _media
            ..clear()
            ..addAll(next.where((item) => item.isVideo));
        } else {
          _media.addAll(next.where((item) => !item.isVideo));
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick media')),
      );
    }
  }

  Future<void> _editVideoAt(int index) async {
    if (index < 0 || index >= _media.length) return;
    final item = _media[index];
    if (!item.isVideo) return;

    final trimmed = await Navigator.of(context).push<VideoEditResult>(
      MaterialPageRoute(
        builder: (_) => EditVideoScreen(
          media: MediaItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: MediaType.video,
            filePath: item.path,
            createdAt: DateTime.now(),
          ),
        ),
      ),
    );
    if (trimmed == null || !mounted) return;
    setState(() {
      _media[index] = item.copyWith(
        trimStart: trimmed.trimStart,
        trimEnd: trimmed.trimEnd,
      );
    });
  }

  Future<void> _tagPeople() async {
    if (_media.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add media before tagging people')),
      );
      return;
    }

    final mediaPaths = _media.map((item) => item.path).toList(growable: false);
    final isVideos = _media.map((item) => item.isVideo).toList(growable: false);
    final coverPaths = _media
        .map((item) => item.isVideo ? item.path : null)
        .toList(growable: false);
    final aspectRatios =
        _media.map((item) => item.aspectRatio).toList(growable: false);
    final adjustments =
        List<Map<String, int>>.generate(_media.length, (_) => const {});
    final result = await Navigator.of(context).push<List<dynamic>>(
      MaterialPageRoute(
        builder: (_) => TagPeopleScreen(
          mediaPaths: mediaPaths,
          isVideos: isVideos,
          coverPaths: coverPaths,
          filterNames: List<String>.filled(_media.length, 'Original'),
          adjustments: adjustments,
          alreadyProcessed: List<bool>.filled(_media.length, false),
          aspectRatios: aspectRatios,
          initialTagsByIndex: const {},
          initialIndex: 0,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _peopleTags
        ..clear()
        ..addAll(result.cast<Map<String, dynamic>>());
    });
  }

  Future<void> _pickLocation() async {
    final selected = await Navigator.of(context).push<LocationPlace>(
      MaterialPageRoute(builder: (_) => const LocationSearchScreen()),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _location = selected;
      _locationCtl.text = selected.searchText;
    });
  }

  Future<void> _openProductEditor({int? index}) async {
    final existing = index != null && index >= 0 && index < _products.length
        ? _products[index]
        : null;
    final result = await Navigator.of(context).push<_PromoteDraftProduct>(
      MaterialPageRoute(
        builder: (_) => _PromoteProductEditorScreen(initial: existing),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (index != null && index >= 0 && index < _products.length) {
        _products[index] = result;
      } else {
        _products.add(result);
      }
    });
  }

  void _addHashtagFromInput() {
    final raw = _tagCtl.text.trim();
    if (raw.isEmpty) return;
    final value = raw.startsWith('#') ? raw : '#$raw';
    if (_hashtags.contains(value)) {
      _tagCtl.clear();
      return;
    }
    setState(() {
      _hashtags.add(value);
      _tagCtl.clear();
    });
  }

  Future<Map<String, dynamic>> _uploadProductImage(String path) async {
    final uploaded = await _uploadApi.uploadPromoteProductFile(path);
    final fileName = _pickString(uploaded['fileName'] ?? uploaded['filename']);
    final fileUrl = _pickString(
      uploaded['fileUrl'] ?? uploaded['file_url'] ?? uploaded['url'],
    );
    return {
      if (fileName.isNotEmpty) 'fileName': fileName,
      if (fileUrl.isNotEmpty) 'promote_img': UrlHelper.normalizeUrl(fileUrl),
    };
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_media.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add media for the promote')),
      );
      return;
    }

    final caption = _captionCtl.text.trim();
    final autoTags = RegExp(r'#[a-zA-Z0-9_]+')
        .allMatches(caption)
        .map((m) => m.group(0)!)
        .toList();
    final tags = <String>{
      ...autoTags,
      ..._hashtags,
    }.toList();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final mediaPayload = <Map<String, dynamic>>[];
      for (final item in _media) {
        final path = item.isVideo
            ? await _createService.trimVideoForUpload(
                  inputPath: item.path,
                  trimStart: item.trimStart,
                  trimEnd: item.trimEnd,
                  videoDuration: item.duration,
                ) ??
                item.path
            : item.path;
        final uploaded = item.isVideo
            ? await _uploadApi.uploadPromoteFile(path)
            : await _uploadApi.uploadPromoteFile(path);
        final fileName =
            _pickString(uploaded['fileName'] ?? uploaded['filename']);
        final fileUrl = _pickString(
          uploaded['fileUrl'] ?? uploaded['file_url'] ?? uploaded['url'],
        );
        final normalizedUrl = UrlHelper.normalizeUrl(fileUrl);
        mediaPayload.add({
          if (fileName.isNotEmpty) 'fileName': fileName,
          if (normalizedUrl.isNotEmpty) 'fileUrl': normalizedUrl,
          'ratio': item.aspectRatio,
          'filter': 'none',
          'type': item.isVideo ? 'video' : 'image',
          if (item.trimStart != null)
            'trimStartMs': item.trimStart!.inMilliseconds,
          if (item.trimEnd != null) 'trimEndMs': item.trimEnd!.inMilliseconds,
        });
      }

      final productsPayload = <Map<String, dynamic>>[];
      for (final product in _products) {
        final payload = <String, dynamic>{
          'product_name': product.name.trim(),
          'product_description': product.description.trim(),
          'product_price': num.tryParse(product.price.trim())?.toDouble() ?? 0,
          'discount_amount':
              num.tryParse(product.discountAmount.trim())?.toDouble() ?? 0,
          'visit_link': product.visitLink.trim(),
        };
        if (product.imagePath != null && product.imagePath!.isNotEmpty) {
          payload.addAll(await _uploadProductImage(product.imagePath!));
        }
        productsPayload.add(payload);
      }

      final peopleTags = _peopleTags.map((tag) {
        final user = tag['user'];
        final userMap = user is Map ? Map<String, dynamic>.from(user) : null;
        return <String, dynamic>{
          'user_id': userMap?['id'] ?? userMap?['_id'] ?? tag['user_id'],
          'username': userMap?['username'] ?? userMap?['name'],
          'x': tag['x'],
          'y': tag['y'],
          if (tag['mediaIndex'] != null) 'mediaIndex': tag['mediaIndex'],
        };
      }).toList();

      await _postsApi.createPost(
        media: mediaPayload,
        caption: caption.isEmpty ? null : caption,
        location: _location?.fullText ?? _locationCtl.text.trim(),
        locationPlace: _location?.toJson(),
        tags: tags,
        peopleTags: peopleTags,
        products: productsPayload,
        hideLikesCount: _hideLikes,
        turnOffCommenting: _turnOffCommenting,
        type: 'promote',
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promote created successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create promote: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _goNext() {
    if (_step >= _stepTitles.length - 1) {
      _submit();
      return;
    }
    setState(() {
      _step++;
    });
  }

  void _goBack() {
    if (_step <= 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _step--;
    });
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD77A), Color(0xFFB57B17)],
                  ),
                ),
                child: Icon(icon, color: Colors.black, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Choose your media',
          subtitle: 'Vertical videos work best for promote placements.',
        ),
        const SizedBox(height: 16),
        _buildHeroCard(
          child: Column(
            children: [
              if (_media.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 42,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No media selected yet',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add one or more images, or a single video.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _media.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = _media[index];
                      return _MediaPreviewCard(
                        media: item,
                        onEditVideo:
                            item.isVideo ? () => _editVideoAt(index) : null,
                        onRemove: () {
                          setState(() => _media.removeAt(index));
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ActionPill(
                      label: 'Add media',
                      icon: LucideIcons.plus,
                      onTap: _pickMedia,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionPill(
                      label: 'Tag people',
                      icon: LucideIcons.userRoundPlus,
                      onTap: _tagPeople,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Add products',
          subtitle: 'Create premium product cards with title, price and link.',
        ),
        const SizedBox(height: 16),
        if (_products.isEmpty)
          _buildHeroCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_bag_rounded,
                    size: 42,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No products added yet',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add items that can be shown under the promote reel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._products.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProductPreviewCard(
                product: item,
                onEdit: () => _openProductEditor(index: index),
                onRemove: () => setState(() => _products.removeAt(index)),
              ),
            );
          }),
        const SizedBox(height: 14),
        _ActionPill(
          label: 'Add product',
          icon: LucideIcons.squarePen,
          onTap: () => _openProductEditor(),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Caption and details',
          subtitle: 'Reuse the same social fields as the main create flow.',
        ),
        const SizedBox(height: 16),
        _buildHeroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _captionCtl,
                maxLines: 6,
                minLines: 4,
                style: const TextStyle(color: Colors.white),
                cursorColor: const Color(0xFFFFD77A),
                decoration: _fieldDecoration(
                  label: 'Caption',
                  hint: 'Write a short, compelling promote caption...',
                  icon: LucideIcons.penLine,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagCtl,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: const Color(0xFFFFD77A),
                      onSubmitted: (_) => _addHashtagFromInput(),
                      decoration: _fieldDecoration(
                        label: 'Tags',
                        hint: 'Add hashtag and press enter',
                        icon: LucideIcons.hash,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _ActionPill(
                    label: 'Add',
                    icon: LucideIcons.plus,
                    onTap: _addHashtagFromInput,
                  ),
                ],
              ),
              if (_hashtags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _hashtags.map((tag) {
                    return InputChip(
                      label: Text(tag),
                      onDeleted: () => setState(() => _hashtags.remove(tag)),
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      labelStyle: const TextStyle(color: Colors.white),
                      deleteIconColor: Colors.white70,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 14),
              _LocationCard(
                title: 'Location',
                subtitle: _location?.searchText ?? _locationCtl.text.trim(),
                onTap: _pickLocation,
              ),
              const SizedBox(height: 12),
              _ToggleCard(
                title: 'Hide likes count',
                subtitle: 'Only you can see the like count on this promote.',
                value: _hideLikes,
                onChanged: (value) => setState(() => _hideLikes = value),
              ),
              const SizedBox(height: 12),
              _ToggleCard(
                title: 'Turn off commenting',
                subtitle: 'Stop comments on this promote once it is live.',
                value: _turnOffCommenting,
                onChanged: (value) =>
                    setState(() => _turnOffCommenting = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final caption = _captionCtl.text.trim();
    final summary = <String>[
      '${_media.length} media item(s)',
      '${_products.length} product(s)',
      if (caption.isNotEmpty) 'Caption ready',
      if (_location?.searchText.isNotEmpty ??
          _locationCtl.text.trim().isNotEmpty)
        'Location added',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Review and publish',
          subtitle: 'Double-check everything before we submit the promote.',
        ),
        const SizedBox(height: 16),
        _buildHeroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: summary
                    .map(
                      (item) => Chip(
                        label: Text(item),
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        labelStyle: const TextStyle(color: Colors.white),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              _ReviewRow(
                  label: 'Likes hidden', value: _hideLikes ? 'Yes' : 'No'),
              _ReviewRow(
                label: 'Comments',
                value: _turnOffCommenting ? 'Disabled' : 'Enabled',
              ),
              _ReviewRow(
                label: 'Media mix',
                value: _media.any((item) => item.isVideo) ? 'Video' : 'Image',
              ),
              const SizedBox(height: 14),
              Text(
                'Products will be uploaded first, followed by the promote post payload.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ActionPill(
          label: _isSubmitting ? 'Publishing...' : 'Publish promote',
          icon: LucideIcons.rocket,
          onTap: _isSubmitting ? null : _submit,
          filled: true,
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 13.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF18110B), Color(0xFF0D0D0D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.white70, size: 18),
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide(color: Color(0xFFFFD77A)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPublish = _media.isNotEmpty && !_isSubmitting;
    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _goBack,
                    icon: const Icon(LucideIcons.arrowLeft),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Promote',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _stepTitles[_step],
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: canPublish ? _goNext : null,
                    child: Text(
                      _step == _stepTitles.length - 1 ? 'Publish' : 'Next',
                      style: const TextStyle(
                        color: Color(0xFFFFD77A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(_stepTitles.length, (index) {
                  final active = index == _step;
                  final done = index < _step;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: EdgeInsets.only(
                          right: index == _stepTitles.length - 1 ? 0 : 6),
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: active
                            ? const Color(0xFFFFD77A)
                            : done
                                ? const Color(0xFFB57B17)
                                : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Stack(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: SingleChildScrollView(
                      key: ValueKey<int>(_step),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: switch (_step) {
                        0 => _buildMediaStep(),
                        1 => _buildProductsStep(),
                        2 => _buildDetailsStep(),
                        _ => _buildReviewStep(),
                      },
                    ),
                  ),
                  if (_isSubmitting)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFFD77A),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoteProductEditorScreen extends StatefulWidget {
  final _PromoteDraftProduct? initial;

  const _PromoteProductEditorScreen({this.initial});

  @override
  State<_PromoteProductEditorScreen> createState() =>
      _PromoteProductEditorScreenState();
}

class _PromoteProductEditorScreenState
    extends State<_PromoteProductEditorScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameCtl = TextEditingController();
  final TextEditingController _descCtl = TextEditingController();
  final TextEditingController _priceCtl = TextEditingController();
  final TextEditingController _discountCtl = TextEditingController();
  final TextEditingController _linkCtl = TextEditingController();
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _nameCtl.text = initial.name;
      _descCtl.text = initial.description;
      _priceCtl.text = initial.price;
      _discountCtl.text = initial.discountAmount;
      _linkCtl.text = initial.visitLink;
      _imagePath = initial.imagePath;
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _descCtl.dispose();
    _priceCtl.dispose();
    _discountCtl.dispose();
    _linkCtl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    setState(() => _imagePath = file.path);
  }

  void _save() {
    if (_nameCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a product name')),
      );
      return;
    }
    Navigator.of(context).pop(
      _PromoteDraftProduct(
        name: _nameCtl.text.trim(),
        description: _descCtl.text.trim(),
        price: _priceCtl.text.trim(),
        discountAmount: _discountCtl.text.trim(),
        visitLink: _linkCtl.text.trim(),
        imagePath: _imagePath,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      cursorColor: const Color(0xFFFFD77A),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white70, size: 18),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: Color(0xFFFFD77A)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _imagePath != null && _imagePath!.isNotEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        title: const Text('Product editor'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFFFFD77A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Design a product card that feels premium and clickable.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF181818), Color(0xFF101010)],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Image.file(
                            File(_imagePath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.imagePlus,
                              size: 42,
                              color: Color(0xFFFFD77A),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Add product image',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Square or portrait images work best',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              _field(
                controller: _nameCtl,
                label: 'Product name',
                hint: 'Luxury tote bag',
                icon: LucideIcons.tag,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _descCtl,
                label: 'Description',
                hint: 'Tell people why they need it',
                icon: LucideIcons.fileText,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: _priceCtl,
                      label: 'Price',
                      hint: '2499',
                      icon: LucideIcons.indianRupee,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: _discountCtl,
                      label: 'Discount',
                      hint: '300',
                      icon: LucideIcons.badgePercent,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field(
                controller: _linkCtl,
                label: 'Visit link',
                hint: 'https://example.com/product',
                icon: LucideIcons.link,
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaPreviewCard extends StatelessWidget {
  final _PromoteDraftMedia media;
  final VoidCallback? onEditVideo;
  final VoidCallback onRemove;

  const _MediaPreviewCard({
    required this.media,
    required this.onEditVideo,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = media.isVideo;
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: isVideo
                ? _VideoThumb(path: media.path)
                : Image.file(
                    File(media.path),
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isVideo ? 'Video' : 'Image',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              children: [
                if (isVideo && onEditVideo != null)
                  _miniIconButton(
                    icon: LucideIcons.scissors,
                    onTap: onEditVideo!,
                  ),
                const SizedBox(width: 6),
                _miniIconButton(
                  icon: LucideIcons.trash2,
                  onTap: onRemove,
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.74),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Text(
                media.isVideo
                    ? 'Trimmed ${media.trimStart != null ? 'yes' : 'no'}'
                    : 'Ready for upload',
                maxLines: 2,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.48),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
      ),
    );
  }
}

class _VideoThumb extends StatelessWidget {
  final String path;

  const _VideoThumb({required this.path});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: Colors.white.withValues(alpha: 0.06),
        ),
        const Center(
          child: Icon(
            Icons.play_circle_fill_rounded,
            color: Colors.white70,
            size: 42,
          ),
        ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LocationCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(LucideIcons.mapPinned, color: Colors.white70),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle.isEmpty ? 'Add location' : subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.68),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.68),
            fontSize: 12.5,
          ),
        ),
        activeThumbColor: const Color(0xFFFFD77A),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  const _ActionPill({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? const LinearGradient(
            colors: [Color(0xFFFFD77A), Color(0xFFB57B17)],
          )
        : null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            gradient: bg,
            color: filled ? null : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: filled ? Colors.black : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: filled ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductPreviewCard extends StatelessWidget {
  final _PromoteDraftProduct product;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _ProductPreviewCard({
    required this.product,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 88,
              height: 88,
              child: product.imagePath == null
                  ? Container(
                      color: Colors.white.withValues(alpha: 0.06),
                      child: const Icon(
                        LucideIcons.imagePlus,
                        color: Colors.white54,
                      ),
                    )
                  : Image.file(File(product.imagePath!), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Price: ${product.price}  Discount: ${product.discountAmount}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(LucideIcons.squarePen),
                color: Colors.white,
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(LucideIcons.trash2),
                color: Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
