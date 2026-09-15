import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const _loginFontFallback = <String>[
  'Noto Sans KR',
  'Noto Sans CJK KR',
  'Apple SD Gothic Neo',
  'sans-serif',
];

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onGoogleContinue,
    required this.onGuestContinue,
    this.isInitialOffer = true,
  });

  final VoidCallback onGoogleContinue;
  final VoidCallback onGuestContinue;

  /// Whether this is the one-time offer the app opens on.
  ///
  /// False when Ajustes pushes it later, where the second control dismisses a
  /// screen the user went looking for rather than starting the app without an
  /// account — a thing they did months ago.
  final bool isInitialOffer;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _connecting = false;

  Future<void> _continueWithGoogle() async {
    if (_connecting) return;
    setState(() => _connecting = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    widget.onGoogleContinue();
  }

  @override
  Widget build(BuildContext context) {
    final copy = _LoginCopy.forLocale(Localizations.localeOf(context));
    return RepaintBoundary(
      key: const ValueKey('login-capture'),
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ColoredBox(
              color: AppColors.surface,
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            image: true,
                            label: copy.heroLabel,
                            child: AspectRatio(
                              aspectRatio: 853 / 800,
                              child: Image.asset(
                                'assets/login/michi-device-transfer-hero.png',
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.none,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  copy.title,
                                  style:
                                      pixelText(
                                        size: 34,
                                        bold: true,
                                        height: 1.08,
                                      ).copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontFamilyFallback: _loginFontFallback,
                                      ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  copy.body,
                                  style:
                                      pixelText(
                                        size: 15,
                                        color: AppColors.inkSoft,
                                        height: 1.45,
                                      ).copyWith(
                                        fontFamilyFallback: _loginFontFallback,
                                      ),
                                ),
                                const SizedBox(height: 24),
                                _GoogleLoginButton(
                                  label: _connecting
                                      ? copy.connecting
                                      : copy.googleButton,
                                  connecting: _connecting,
                                  onPressed: _connecting
                                      ? null
                                      : _continueWithGoogle,
                                ),
                                const SizedBox(height: 16),
                                _PrivacyNote(text: copy.privacyNote),
                                const SizedBox(height: 14),
                                Semantics(
                                  button: true,
                                  child: TextButton(
                                    onPressed: _connecting
                                        ? null
                                        : widget.onGuestContinue,
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                    child: Text(
                                      widget.isInitialOffer
                                          ? copy.guestButton
                                          : copy.dismissButton,
                                      style:
                                          pixelText(
                                            size: 14,
                                            bold: true,
                                            color: AppColors.tealInk,
                                          ).copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontFamilyFallback:
                                                _loginFontFallback,
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
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLoginButton extends StatefulWidget {
  const _GoogleLoginButton({
    required this.label,
    required this.connecting,
    required this.onPressed,
  });

  final String label;
  final bool connecting;
  final VoidCallback? onPressed;

  @override
  State<_GoogleLoginButton> createState() => _GoogleLoginButtonState();
}

class _GoogleLoginButtonState extends State<_GoogleLoginButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final pressed = enabled && _pressed;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            transform: Matrix4.translationValues(0, pressed ? 5 : 0, 0),
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.ink, width: 2.5),
              boxShadow: pressed || !enabled
                  ? null
                  : const [
                      BoxShadow(color: AppColors.teal, offset: Offset(4, 5)),
                    ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.connecting)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.teal,
                    ),
                  )
                else
                  Image.asset(
                    'assets/login/google-g.png',
                    width: 32,
                    height: 32,
                    filterQuality: FilterQuality.high,
                    excludeFromSemantics: true,
                  ),
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: pixelText(size: 17, bold: true).copyWith(
                      fontWeight: FontWeight.w700,
                      fontFamilyFallback: _loginFontFallback,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.cashSoft,
      border: Border.all(color: AppColors.cashInk, width: 2.5),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.cashInk, size: 23),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              text,
              style:
                  pixelText(
                    size: 13,
                    bold: true,
                    color: AppColors.cashInk,
                    height: 1.35,
                  ).copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamilyFallback: _loginFontFallback,
                  ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _LoginCopy {
  const _LoginCopy({
    required this.title,
    required this.body,
    required this.googleButton,
    required this.connecting,
    required this.privacyNote,
    required this.guestButton,
    required this.dismissButton,
    required this.heroLabel,
  });

  final String title;
  final String body;
  final String googleButton;
  final String connecting;
  final String privacyNote;
  final String guestButton;

  /// The way out when the screen was opened from Ajustes rather than shown at
  /// startup. "Start without an account" makes no sense to somebody who has
  /// been using Sobra without one since the day they installed it.
  final String dismissButton;
  final String heroLabel;

  static _LoginCopy forLocale(Locale locale) => switch (locale.languageCode) {
    'ko' => const _LoginCopy(
      title: '내 기록,\n어디서든 그대로',
      body: '구글 계정에 연결하면 휴대폰이 바뀌어도\n지금의 Sobrita를 이어갈 수 있어요.',
      googleButton: 'Google로 계속하기',
      connecting: 'Google에 연결하는 중…',
      privacyNote: '로그인 정보와 지출 기록은 따로 안전하게 보관돼요.',
      guestButton: '계정 없이 시작하기',
      dismissButton: '나중에 하기',
      heroLabel: '가방을 들고 새 휴대폰으로 이동하는 미치',
    ),
    'es' => const _LoginCopy(
      title: 'Tus registros,\nsiempre contigo',
      body:
          'Conecta tu cuenta de Google para retomar Sobrita aunque cambies de teléfono.',
      googleButton: 'Continuar con Google',
      connecting: 'Conectando con Google…',
      privacyNote: 'Tus datos de acceso y tus gastos se guardan por separado.',
      guestButton: 'Empezar sin cuenta',
      dismissButton: 'Ahora no',
      heroLabel: 'Michi lleva sus registros a un teléfono nuevo',
    ),
    _ => const _LoginCopy(
      title: 'Your records,\nright where you left them',
      body: 'Connect your Google account to pick up Sobrita on a new phone.',
      googleButton: 'Continue with Google',
      connecting: 'Connecting to Google…',
      privacyNote: 'Your sign-in and spending records are stored separately.',
      guestButton: 'Start without an account',
      dismissButton: 'Not now',
      heroLabel: 'Michi carries your records to a new phone',
    ),
  };
}
