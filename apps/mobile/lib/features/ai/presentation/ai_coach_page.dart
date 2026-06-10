import 'package:aura_core/aura_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glow_button.dart';
import '../ai_coach_provider.dart';

/// The AI coach: a chat-style screen grounded in the user's habit data, powered
/// by Gemini or OpenAI (user-selectable) through `aura_core`.
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
    FocusScope.of(context).unfocus();
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.auto_awesome_rounded,
                  color: AppColors.onPrimary, size: 17),
            ),
            const SizedBox(width: 10),
            const Text('AI Coach'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'API keys',
            icon: Icon(Icons.key_rounded, color: AppColors.muted),
            onPressed: () => _ApiKeySheet.show(context, ref),
          ),
          if (providers.length > 1)
            PopupMenuButton<AiProviderKind>(
              icon: Icon(Icons.tune_rounded, color: AppColors.muted),
              color: AppColors.cardElevated,
              onSelected: ctrl.setProvider,
              itemBuilder: (_) => [
                for (final p in providers)
                  PopupMenuItem(
                    value: p,
                    child: Row(
                      children: [
                        if (state.provider == p)
                          Icon(Icons.check_rounded,
                              size: 16, color: AppColors.primary)
                        else
                          const SizedBox(width: 16),
                        const SizedBox(width: 8),
                        Text(p.label,
                            style: TextStyle(color: AppColors.text)),
                      ],
                    ),
                  ),
              ],
            ),
          if (state.messages.isNotEmpty)
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: AppColors.muted),
              onPressed: ctrl.clear,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.messages.isEmpty
                ? _intro(ctrl)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: state.messages.length + (state.loading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= state.messages.length) return const _Typing();
                      return _bubble(state.messages[i]);
                    },
                  ),
          ),
          _inputBar(state),
        ],
      ),
    );
  }

  Widget _intro(AiCoachController ctrl) {
    final configured = ctrl.isConfigured;
    final provider = ref.read(aiCoachProvider).provider;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.glow(AppColors.primary),
            ),
            child: Icon(Icons.auto_awesome_rounded,
                color: AppColors.onPrimary, size: 38),
          ),
        ),
        const SizedBox(height: 20),
        Text('Your habit coach',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          configured
              ? 'Ask anything about your habits. I read your real streaks and '
                  'success rates to give advice that fits you.'
              : 'Paste your own OpenRouter, OpenAI or Gemini API key to unlock '
                  'personalised coaching. Your key is stored only on this device.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: AppColors.muted, fontSize: 14, height: 1.5),
        ),
        if (!configured) ...[
          const SizedBox(height: 20),
          Center(
            child: GlowButton(
              label: 'Add API key',
              icon: Icons.key_rounded,
              onPressed: () => _ApiKeySheet.show(context, ref),
            ),
          ),
        ],
        if (configured) ...[
          const SizedBox(height: 8),
          Center(
            child: Text('Powered by ${provider?.label ?? 'AI'}',
                style: TextStyle(color: AppColors.faint, fontSize: 12)),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final (label, prompt) in aiPresetPrompts)
                GestureDetector(
                  onTap: () => _send(prompt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.alpha(AppColors.primary, 0.08),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                      border: Border.all(
                          color: AppColors.alpha(AppColors.primary, 0.3)),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _bubble(AiMessage m) {
    final user = m.fromUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 320),
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
        child: Text(
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                style: TextStyle(color: AppColors.text),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Ask your coach…',
                  hintStyle: TextStyle(color: AppColors.faint),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
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
            const SizedBox(width: 8),
            GestureDetector(
              onTap: state.loading ? null : _send,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_upward_rounded,
                    color: AppColors.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for entering AI provider API keys. Keys are stored only in the
/// local settings box (never synced, never embedded in builds).
class _ApiKeySheet extends ConsumerStatefulWidget {
  const _ApiKeySheet();

  static Future<void> show(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => const _ApiKeySheet(),
    );
  }

  @override
  ConsumerState<_ApiKeySheet> createState() => _ApiKeySheetState();
}

class _ApiKeySheetState extends ConsumerState<_ApiKeySheet> {
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

  void _save() {
    ref.read(aiCoachProvider.notifier).saveApiKeys(
          openRouter: _openRouter.text,
          openAi: _openAi.text,
          gemini: _gemini.text,
        );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI keys saved')),
    );
  }

  Widget _field(String label, String hint, TextEditingController c) {
    return Column(
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
        const SizedBox(height: 14),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + inset),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text('AI API keys',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Add at least one key. OpenRouter is tried first, then OpenAI, '
            'then Gemini. Keys are stored only on this device.',
            style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 18),
          _field('OpenRouter (recommended)', 'sk-or-v1-…', _openRouter),
          _field('OpenAI', 'sk-…', _openAi),
          _field('Google Gemini', 'AIza…', _gemini),
          GlowButton(
            label: 'Save keys',
            icon: Icons.check_rounded,
            expand: true,
            onPressed: _save,
          ),
        ],
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
            SizedBox(width: 10),
            Text('Thinking…', style: TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
