import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../models/auth/apple_auth_models.dart';
import '../../services/auth/auth_service.dart';

class AppleSignInButton extends StatefulWidget {
  final String label;
  final Future<void> Function(AppleAuthenticationResult result)?
      onCredentialCaptured;

  const AppleSignInButton({
    super.key,
    this.label = 'Continue with Apple',
    this.onCredentialCaptured,
  });

  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  State<AppleSignInButton> createState() => _AppleSignInButtonState();
}

class _AppleSignInButtonState extends State<AppleSignInButton> {
  final _authService = AuthService();

  bool _loading = false;
  String? _error;

  Future<void> _handleAppleSignIn() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _authService.loginWithApple();
      if (!mounted) return;

      if (result == null) {
        return;
      }

      if (widget.onCredentialCaptured != null) {
        await widget.onCredentialCaptured!(result);
      } else {
        _showPendingBackendMessage(result);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (e is UnsupportedError) {
          _error = 'Sign in with Apple is not available on this device.';
        } else {
          _error = e.toString();
        }
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showPendingBackendMessage(AppleAuthenticationResult result) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          'Apple credential captured for ${result.summaryLabel}. Backend integration is pending.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AppleSignInButton.isSupportedPlatform) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.white : Colors.black;
    final foregroundColor = isDark ? Colors.black : Colors.white;
    final borderColor = backgroundColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: Semantics(
            button: true,
            label: widget.label,
            child: Tooltip(
              message: widget.label,
              child: OutlinedButton(
                onPressed: _loading ? null : _handleAppleSignIn,
                style: OutlinedButton.styleFrom(
                  backgroundColor: backgroundColor,
                  foregroundColor: foregroundColor,
                  side: BorderSide(color: borderColor, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Center(
                  child: _loading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              foregroundColor,
                            ),
                          ),
                        )
                      : FaIcon(
                          FontAwesomeIcons.apple,
                          size: 22,
                          color: foregroundColor,
                        ),
                ),
              ),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
