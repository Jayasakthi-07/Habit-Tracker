import 'package:aura_core/aura_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glow_button.dart';
import '../ai_coach_provider.dart';

/// Desktop AI coach — a centred chat grounded in the user's habit data, powered
/// by OpenRouter / OpenAI / Gemini (user-selectable) via `aura_core`. Mirrors
/// the Android coach so both platforms behave identically.
class AiCoachPage extends ConsumerStatefulWidget {
  const AiCoachPage({super.key});

  @override
  ConsumerState<AiCoachPage> createState() => _AiCoachPageState();
}

class _AiCoachPageState extends ConsumerState<AiCoachPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = preset ?? _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    ref.read(aiCoachProvider.notifier).ask(text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCoachProvider);
    final ctrl = ref.read(aiCoachProvider.notifier);
    final providers = ctrl.availableProviders;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              _header(state, ctrl, providers),
              const SizedBox(height: 16),
              Expanded(
                child: state.messages.isEmpty
                    ? _intro(ctrl, state)
                    : ListView.builder(
                        controller: _scroll,
                        itemCount:
                            state.messages.length + (state.loading ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i >= state.messages.length) return const _Typing();
                          return _bubble(state.messages[i]);
                        },
                      ),
              ),
              const SizedBox(height: 12),
              _inputBar(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(
      AiCoachState state, AiCoachController ctrl, List<AiProviderKind> providers) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(Icons.auto_awesome_rounded,
              color: AppColors.onPrimary, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Coach',
                style: Theme.of(context).textTheme.titleLarge),
            if (state.provider != null)
              Text('Powered by ${state.provider!.label}',
                  style: TextStyle(color: AppColors.faint, fontSize: 12)),
          ],
        ),
        const Spacer(),
        IconButton(
          tooltip: 'API keys',
          icon: Icon(Icons.key_rounded, color: AppColors.muted),
          onPressed: () => _ApiKeyDialog.show(context, ref),
        ),
        if (providers.length > 1)
          PopupMenuButton<AiProviderKind>(
            tooltip: 'Choose AI provider',
            icon: Icon(Icons.tune_rounded, color: AppColors.muted),
            color: AppColors.cardElevated,
            onSelected: ctrl.setProvider,
            itemBuilder: (_) => [
              for (final p in providers)
                PopupMenuItem(
                  value: p,
                  child: Row(
                    children: [
                      Icon(
                          state.provider == p
                              ? Icons.check_rounded
                              : Icons.circle_outlined,
                          size: 16,
                          color: state.provider == p
                              ? AppColors.primary
                              : AppColors.muted),
                      const SizedBox(width: 8),
                      Text(p.label, style: TextStyle(color: AppColors.text)),
                    ],
                  ),
                ),
            ],
          ),
        if (state.messages.isNotEmpty)
          IconButton(
            tooltip: 'New conversation',
            icon: Icon(Icons.refresh_rounded, color: AppColors.muted),
            onPressed: ctrl.clear,
          ),
      ],
    );
  }

  Widget _intro(AiCoachController ctrl, AiCoachState state) {
    final configured = ctrl.isConfigured;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: AppShadows.glow(AppColors.primary),
              ),
              child: Icon(Icons.auto_awesome_rounded,
                  color: AppColors.onPrimary, size: 40),
            ),
            const SizedBox(height: 20),
            Text('Your habit coach',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            SizedBox(
              width: 440,
              child: Text(
                configured
                    ? 'Ask anything about your habits. I read your real streaks '
                        'and success rates to give advice that fits you.'
                    : 'Paste your own OpenRouter, OpenAI or Gemini API key to '
                        'unlock personalised coaching. Your key is stored only '
                        'on this device.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.muted, fontSize: 14, height: 1.5),
              ),
            ),
            if (!configured) ...[
              const SizedBox(height: 20),
              GlowButton(
                label: 'Add API key',
                icon: Icons.key_rounded,
                onPressed: () => _ApiKeyDialog.show(context, ref),
              ),
            ],
            if (configured) ...[
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  for (final (label, prompt) in aiPresetPrompts)
                    _PromptChip(label: label, onTap: () => _send(prompt)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bubble(AiMessage m) {
    final user = m.fromUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          gradient: user ? AppColors.primaryGradient : null,
          color: user ? null : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(user ? 16 : 4),
            bottomRight: Radius.circular(user ? 4 : 16),
          ),
          border: user ? null : Border.all(color: AppColors.border),
        ),
        child: SelectableText(
          m.text,
          style: TextStyle(
            color: user ? AppColors.onPrimary : AppColors.text,
            fontSize: 14,
            height: 1.5,
            fontWeight: user ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _inputBar(AiCoachState state) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _input,
            style: TextStyle(color: AppColors.text),
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              hintText: 'Ask your coach…',
              hintStyle: TextStyle(color: AppColors.faint),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _SendButton(onTap: state.loading ? null : _send),
      ],
    );
  }
}

/// Dialog for entering AI provider API keys. Keys are stored only in the local
/// settings box (never synced, never embedded in builds).
class _ApiKeyDialog extends ConsumerStatefulWidget {
  const _ApiKeyDialog();

  static Future<void> show(BuildContext context, WidgetRef ref) {
    return showDialog(
      context: context,
      builder: (_) => const _ApiKeyDialog(),
    );
  }

  @override
  ConsumerState<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends ConsumerState<_ApiKeyDialog> {
  late final TextEditingController _openRouter;
  late final TextEditingController _openAi;
  late final TextEditingController _gemini;

  @override
  void initState() {
    super.initState();
    final ctrl = ref.read(aiCoachProvider.notifier);
    _openRouter =
        TextEditingController(text: ctrl.savedKeyFor(AiProviderKind.openrouter));
    _openAi =
        TextEditingController(text: ctrl.savedKeyFor(AiProviderKind.openai));
    _gemini =
        TextEditingController(text: ctrl.savedKeyFor(AiProviderKind.gemini));
  }

  @override
  void dispose() {
    _openRouter.dispose();
    _openAi.dispose();
    _gemini.dispose();
    super.dispose();
  }

  void _save(BuildContext dialogContext) {
    ref.read(aiCoachProvider.notifier).saveApiKeys(
          openRouter: _openRouter.text,
          openAi: _openAi.text,
          gemini: _gemini.text,
        );
    Navigator.of(dialogContext).pop();
  }

  Widget _field(String label, String hint, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            style: TextStyle(color: AppColors.text, fontSize: 13),
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI API keys',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Add at least one key. OpenRouter is tried first, then OpenAI, '
                'then Gemini. Keys are stored only on this device.',
                style: TextStyle(
                    color: AppColors.muted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 18),
              _field('OpenRouter (recommended)', 'sk-or-v1-…', _openRouter),
              _field('OpenAI', 'sk-…', _openAi),
              _field('Google Gemini', 'AIza…', _gemini),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GlowButton(
                    label: 'Cancel',
                    variant: GlowButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  GlowButton(
                    label: 'Save keys',
                    icon: Icons.check_rounded,
                    onPressed: () => _save(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.alpha(AppColors.primary, 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(color: AppColors.alpha(AppColors.primary, 0.3)),
          ),
          child: Text(label,
              style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_upward_rounded,
              color: AppColors.onPrimary),
        ),
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text('Thinking…', style: TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
