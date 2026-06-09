import 'package:aura_core/aura_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_card.dart';
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
          child: const Icon(Icons.auto_awesome_rounded,
              color: Color(0xFF002417), size: 20),
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
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFF002417), size: 40),
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
                    : 'Add an OpenRouter or OpenAI API key (see AI_SETUP.md) to '
                        'unlock personalised coaching.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.muted, fontSize: 14, height: 1.5),
              ),
            ),
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
            color: user ? const Color(0xFF002417) : AppColors.text,
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
                borderSide: const BorderSide(color: AppColors.primary),
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
          child: const Icon(Icons.arrow_upward_rounded,
              color: Color(0xFF002417)),
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
            const SizedBox(
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
