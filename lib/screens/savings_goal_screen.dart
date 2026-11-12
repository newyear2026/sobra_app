import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/income_entry.dart';
import '../models/savings_goal.dart';
import '../services/goal_product_import.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/goal_product_thumbnail.dart';
import '../widgets/pixel_ui.dart';
import 'completed_savings_goals_screen.dart';
import 'goal_product_browser_screen.dart';
import 'goal_purchase_screen.dart';
import 'register_screen.dart';

typedef GoalProductLoader =
    Future<GoalProductImport?> Function(BuildContext context, String url);

/// Link import is optional. The user confirms the amount before any save.
class SavingsGoalScreen extends StatefulWidget {
  const SavingsGoalScreen({
    super.key,
    this.existing,
    this.importProduct,
    this.replacingCompletedGoalId,
    this.initialStartingCentavos,
    this.readPrice,
  }) : assert(existing == null || replacingCompletedGoalId == null);

  final SavingsGoal? existing;
  final GoalProductLoader? importProduct;

  /// Replacement is committed together with the new goal's save, so leaving
  /// this screen never discards the completed goal.
  final String? replacingCompletedGoalId;

  /// Prefills "already saved" for a new goal, e.g. what a purchase left over.
  final int? initialStartingCentavos;

  /// Passed on to the purchase screen's price reader. Tests use a fake.
  final GoalProductLoader? readPrice;

  @override
  State<SavingsGoalScreen> createState() => _SavingsGoalScreenState();
}

class _SavingsGoalScreenState extends State<SavingsGoalScreen> {
  final _form = GlobalKey<FormState>();
  final _link = TextEditingController();
  final _name = TextEditingController();
  final _target = TextEditingController();
  final _starting = TextEditingController();
  final _nameFocus = FocusNode();
  String? _imageUrl;
  String? _merchantName;
  String? _sourceUrl;
  String? _sourceName;
  String? _sourceAmount;
  String? _linkError;
  String? _importCurrency;
  DateTime? _targetDate;
  SavingsGoalKind? _kind;
  bool _initialized = false;
  bool _showDetails = false;
  bool _saving = false;
  bool _importing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final store = SobraScope.of(context);
    final goal = widget.existing;
    _starting.text = amountFieldText(
      store.currency,
      goal?.startingCentavos ?? widget.initialStartingCentavos ?? 0,
    );
    if (goal == null) return;
    _kind = goal.kind;
    _showDetails = true;
    _link.text = goal.productUrl ?? '';
    _sourceUrl = goal.productUrl;
    _name.text = goal.name;
    _target.text = amountFieldText(store.currency, goal.targetCentavos);
    if (goal.productUrl != null) {
      _sourceName = _name.text;
      _sourceAmount = _target.text;
    }
    _imageUrl = goal.imageUrl;
    _merchantName = goal.merchantName;
    _targetDate = goal.targetDate;
  }

  @override
  void dispose() {
    for (final controller in [_link, _name, _target, _starting]) {
      controller.dispose();
    }
    _nameFocus.dispose();
    super.dispose();
  }

  void _linkChanged(String value) {
    setState(() {
      _linkError = null;
      if (value.trim() != _sourceUrl) {
        _imageUrl = null;
        _merchantName = null;
        _importCurrency = null;
        // A new product must not inherit the previous product's price. Keep
        // values the user already edited themselves, and allow unlinking a
        // product while retaining it as an ordinary manual goal.
        if (value.trim().isNotEmpty) {
          if (_name.text == _sourceName) _name.clear();
          if (_target.text == _sourceAmount) _target.clear();
        }
      }
    });
  }

  void _chooseKind(SavingsGoalKind kind) {
    setState(() {
      _kind = kind;
      _showDetails =
          kind == SavingsGoalKind.amount ||
          _showDetails ||
          _name.text.isNotEmpty ||
          _target.text.isNotEmpty;
      if (kind == SavingsGoalKind.amount) {
        _link.clear();
        _imageUrl = null;
        _merchantName = null;
        _sourceUrl = null;
        _sourceName = null;
        _sourceAmount = null;
        _linkError = null;
        _importCurrency = null;
      }
    });
  }

  Future<void> _pasteLink() async {
    try {
      final value = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted) return;
      _link.text = value?.text?.trim() ?? '';
      _linkChanged(_link.text);
    } on Object {
      if (mounted) {
        setState(
          () => _linkError = AppLocalizations.of(context).goalInvalidLink,
        );
      }
    }
  }

  Future<void> _import() async {
    if (_importing || _saving) return;
    final l10n = AppLocalizations.of(context);
    final url = safeGoalUrl(_link.text);
    if (url == null) {
      setState(() => _linkError = l10n.goalInvalidLink);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _importing = true;
      _linkError = null;
    });
    try {
      final result = await (widget.importProduct ?? openGoalProductBrowser)(
        context,
        url.toString(),
      );
      if (!mounted) return;
      if (result == null) {
        setState(() => _showDetails = true);
        return;
      }
      final currency = SobraScope.of(context).currency;
      setState(() {
        _sourceUrl = result.sourceUrl;
        _link.text = result.sourceUrl;
        _imageUrl = result.imageUrl;
        _merchantName = result.merchantName;
        _name.text = String.fromCharCodes((result.title ?? '').runes.take(60));
        _importCurrency = result.currencyCode;
        // Never relabel a price from another currency as the user's money.
        _target.text =
            result.priceCentavos != null && result.currencyCode == currency.code
            ? amountFieldText(currency, result.priceCentavos!)
            : '';
        _sourceName = _name.text;
        _sourceAmount = _target.text;
        _showDetails = true;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _showDetails = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.goalBrowserLoadFailed)));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _pickDate() async {
    final today = SobraScope.of(context).today;
    final initial = _targetDate ?? today;
    final future = DateTime(today.year + 10, today.month, today.day);
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: initial.isBefore(today) ? initial : today,
      lastDate: initial.isAfter(future) ? initial : future,
    );
    if (date != null && mounted) setState(() => _targetDate = date);
  }

  Future<void> _save() async {
    if (_saving || _kind == null || !_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final rawUrl = _kind == SavingsGoalKind.product ? _link.text.trim() : '';
    final uri = safeGoalUrl(rawUrl);
    if (rawUrl.isNotEmpty && uri == null) {
      setState(() => _linkError = l10n.goalInvalidLink);
      return;
    }
    final store = SobraScope.of(context);
    final amount = parseAmount(store.currency, _target.text)!;
    final starting = parseNonNegativeAmount(store.currency, _starting.text)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final saved = await guardStoreWrite(messenger, l10n, () async {
      await store.saveSavingsGoal(
        id: widget.existing?.id,
        replacingCompletedGoalId: widget.replacingCompletedGoalId,
        kind: _kind!,
        name: _name.text.trim(),
        targetCentavos: amount,
        startingCentavos: starting,
        targetDate: _targetDate,
        productUrl: uri?.toString(),
        imageUrl: _imageUrl,
        merchantName: _merchantName,
      );
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) {
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.goalSaved)));
    }
  }

  Future<void> _delete() async {
    final goal = widget.existing;
    if (goal == null || _saving) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.goalDeleteTitle),
        content: Text(l10n.goalDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.goalDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    final saved = await guardStoreWrite(
      ScaffoldMessenger.of(context),
      l10n,
      () => SobraScope.of(context).removeSavingsGoal(goal.id),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) Navigator.of(context).pop();
  }

  Future<void> _purchase() async {
    final goal = widget.existing;
    final store = SobraScope.of(context);
    if (goal == null ||
        _saving ||
        _importing ||
        store.activeSavingsGoal?.id != goal.id) {
      return;
    }
    final navigator = Navigator.of(context);
    final result = await navigator.push<GoalPurchaseResult>(
      MaterialPageRoute(
        builder: (_) =>
            GoalPurchaseScreen(goal: goal, readPrice: widget.readPrice),
      ),
    );
    if (result == null || !mounted) return;
    // This goal is in the history now, so its editor leaves the stack.
    final starting = result.nextGoalStartingCentavos;
    if (starting == null) {
      navigator.pop();
    } else {
      await navigator.pushReplacement<void, void>(
        MaterialPageRoute(
          builder: (_) => SavingsGoalScreen(initialStartingCentavos: starting),
        ),
      );
    }
  }

  Widget _purchaseButton(AppLocalizations l10n) => PixelButton(
    key: const ValueKey('goal-purchase'),
    label: l10n.goalPurchaseAction,
    icon: Icons.shopping_bag_outlined,
    variant: PixelButtonVariant.secondary,
    maxLines: 2,
    onPressed: _saving || _importing ? null : _purchase,
  );

  Future<void> _recordSavings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context).goalRecordSavings),
          ),
          body: RegisterScreen(
            initialMode: RegisterMode.income,
            initialIncomeAllocation: IncomeAllocation.savings,
            onSaved: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  void _newGoal() {
    final store = SobraScope.of(context);
    final goal = widget.existing;
    if (_saving ||
        _importing ||
        goal == null ||
        store.activeSavingsGoal?.id != goal.id ||
        !store.isSavingsGoalComplete) {
      return;
    }
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute(
        builder: (_) => SavingsGoalScreen(
          replacingCompletedGoalId: goal.id,
          importProduct: widget.importProduct,
        ),
      ),
    );
  }

  void _history() => Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => const CompletedSavingsGoalsScreen()),
  );

  Widget _label(String value) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(value, style: pixelText(size: 15, bold: true)),
  );

  Widget _typeChoice({
    required SavingsGoalKind kind,
    required String title,
    required String description,
    required IconData icon,
  }) => Semantics(
    button: true,
    child: PixelCard(
      key: ValueKey('goal-type-${kind.name}'),
      elevation: PixelElevation.none,
      onTap: () => _chooseKind(kind),
      child: Row(
        children: [
          Icon(icon, color: AppColors.tealInk, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: pixelText(size: 17, bold: true)),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: pixelText(
                    size: 13,
                    color: AppColors.muted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);
    final currency = store.currency;
    final existing = widget.existing;
    final active = store.activeSavingsGoal;
    final hasProgress = existing != null && active?.id == existing.id;
    final completed = hasProgress && store.isSavingsGoalComplete;
    final progress = hasProgress ? store.savingsGoalProgressCentavos : 0;
    final mismatch =
        _importCurrency != null && _importCurrency != currency.code;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PixelTopBar(
                    title: existing != null
                        ? l10n.goalEdit
                        : switch (_kind) {
                            SavingsGoalKind.amount => l10n.goalAmountType,
                            SavingsGoalKind.product => l10n.goalProductType,
                            null =>
                              widget.replacingCompletedGoalId != null
                                  ? l10n.goalNewGoal
                                  : l10n.goalCreate,
                          },
                    onBack: () {
                      if (!_saving) Navigator.pop(context);
                    },
                    trailing: IconButton(
                      key: const ValueKey('goal-history'),
                      tooltip: l10n.goalCompletedHistory,
                      onPressed: _saving || _importing ? null : _history,
                      icon: const Icon(Icons.history),
                    ),
                  ),
                  if (completed) ...[
                    const SizedBox(height: 18),
                    PixelCard(
                      key: const ValueKey('goal-completed-status'),
                      elevation: PixelElevation.none,
                      color: AppColors.tealSoft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.verified,
                                color: AppColors.tealInk,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n.goalCompleted,
                                  style: pixelText(size: 17, bold: true),
                                ),
                              ),
                              Text(
                                '100%',
                                style: pixelText(
                                  size: 16,
                                  bold: true,
                                  color: AppColors.tealInk,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            formatMoney(currency, progress),
                            style: pixelText(size: 20, bold: true),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.goalCompletionKept,
                            style: pixelText(size: 13, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _purchaseButton(l10n),
                    const SizedBox(height: 12),
                    PixelButton(
                      key: const ValueKey('goal-new'),
                      label: l10n.goalNewGoal,
                      icon: Icons.add,
                      onPressed: _saving || _importing ? null : _newGoal,
                      maxLines: 2,
                    ),
                  ],
                  if (_kind == null) ...[
                    _label(l10n.goalChooseType),
                    _typeChoice(
                      kind: SavingsGoalKind.amount,
                      title: l10n.goalAmountType,
                      description: l10n.goalAmountTypeDescription,
                      icon: Icons.savings_outlined,
                    ),
                    const SizedBox(height: 12),
                    _typeChoice(
                      kind: SavingsGoalKind.product,
                      title: l10n.goalProductType,
                      description: l10n.goalProductTypeDescription,
                      icon: Icons.shopping_bag_outlined,
                    ),
                  ] else ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: const ValueKey('goal-change-type'),
                        onPressed: _saving || _importing
                            ? null
                            : () {
                                FocusScope.of(context).unfocus();
                                setState(() => _kind = null);
                              },
                        child: Text(l10n.goalChangeType),
                      ),
                    ),
                    if (_kind == SavingsGoalKind.amount)
                      Text(
                        l10n.goalAmountIntro,
                        style: pixelText(
                          size: 13,
                          color: AppColors.muted,
                          height: 1.45,
                        ),
                      ),
                    if (_kind == SavingsGoalKind.product) ...[
                      _label(l10n.goalProductLink),
                      TextField(
                        key: const ValueKey('goal-link'),
                        controller: _link,
                        enabled: !_saving && !_importing,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        maxLength: 2048,
                        onChanged: _linkChanged,
                        decoration: InputDecoration(
                          hintText: l10n.goalProductLinkHint,
                          errorText: _linkError,
                          counterText: '',
                          suffixIcon: IconButton(
                            tooltip: l10n.goalPasteLink,
                            onPressed: _saving || _importing
                                ? null
                                : _pasteLink,
                            icon: const Icon(Icons.content_paste),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      PixelButton(
                        label: _importing
                            ? l10n.goalBrowserLoading
                            : l10n.goalImportFromLink,
                        icon: Icons.link,
                        onPressed: _saving || _importing ? null : _import,
                        variant: _showDetails
                            ? PixelButtonVariant.secondary
                            : PixelButtonVariant.primary,
                        maxLines: 2,
                      ),
                      if (!_showDetails) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          key: const ValueKey('goal-manual'),
                          onPressed: _importing
                              ? null
                              : () {
                                  setState(() => _showDetails = true);
                                  _nameFocus.requestFocus();
                                },
                          child: Text(l10n.goalManualEntry),
                        ),
                      ],
                    ],
                    if (_showDetails) ...[
                      if (_imageUrl != null || _merchantName != null) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            GoalProductThumbnail(url: _imageUrl, size: 64),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _merchantName ?? '',
                                style: pixelText(size: 14, bold: true),
                              ),
                            ),
                            if (_imageUrl != null)
                              IconButton(
                                tooltip: l10n.goalPhotoRemove,
                                onPressed: _saving
                                    ? null
                                    : () => setState(() => _imageUrl = null),
                                icon: const Icon(Icons.close),
                              ),
                          ],
                        ),
                      ],
                      if (_link.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          mismatch
                              ? l10n.goalCurrencyMismatch(_importCurrency!)
                              : l10n.goalPriceReview,
                          style: pixelText(
                            size: 13,
                            color: mismatch
                                ? AppColors.dangerInk
                                : AppColors.muted,
                            height: 1.45,
                          ),
                        ),
                      ],
                      _label(l10n.goalNameLabel),
                      TextFormField(
                        key: const ValueKey('goal-name'),
                        controller: _name,
                        focusNode: _nameFocus,
                        enabled: !_saving,
                        maxLength: 60,
                        decoration: InputDecoration(
                          hintText: _kind == SavingsGoalKind.amount
                              ? l10n.goalAmountNameHint
                              : l10n.goalNameHint,
                        ),
                        validator: (value) =>
                            (value ?? '').trim().isEmpty ||
                                (value ?? '').trim().runes.length > 60
                            ? l10n.goalNameRequired
                            : null,
                      ),
                      _label(l10n.goalTargetAmount),
                      TextFormField(
                        key: const ValueKey('goal-target'),
                        controller: _target,
                        enabled: !_saving,
                        keyboardType: amountKeyboardType(currency),
                        inputFormatters: amountInputFormattersFor(currency),
                        decoration: InputDecoration(
                          prefixText: '${currency.symbol} ',
                          suffixText: currency.code,
                        ),
                        style: pixelText(
                          size: 26,
                          bold: true,
                          color: AppColors.tealInk,
                        ),
                        validator: (value) =>
                            parseAmount(currency, value ?? '') == null
                            ? l10n.goalTargetAmountInvalid
                            : null,
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      _label(l10n.goalOptionalPlan),
                      _label(l10n.goalStartingAmount),
                      TextFormField(
                        key: const ValueKey('goal-starting'),
                        controller: _starting,
                        enabled: !_saving,
                        keyboardType: amountKeyboardType(currency),
                        inputFormatters: amountInputFormattersFor(currency),
                        decoration: InputDecoration(
                          prefixText: '${currency.symbol} ',
                          suffixText: currency.code,
                          helperText: l10n.goalStartingHint,
                          helperMaxLines: 3,
                        ),
                        validator: (value) =>
                            parseNonNegativeAmount(currency, value ?? '') ==
                                null
                            ? l10n.goalStartingAmountInvalid
                            : null,
                      ),
                      _label(l10n.goalTargetDate),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _saving ? null : _pickDate,
                              icon: const Icon(Icons.calendar_month),
                              label: Text(
                                _targetDate == null
                                    ? l10n.goalDateUnset
                                    : MaterialLocalizations.of(
                                        context,
                                      ).formatMediumDate(_targetDate!),
                              ),
                            ),
                          ),
                          if (_targetDate != null)
                            IconButton(
                              tooltip: l10n.goalDateClear,
                              onPressed: _saving
                                  ? null
                                  : () => setState(() => _targetDate = null),
                              icon: const Icon(Icons.close),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.goalProgressExplanation,
                        style: pixelText(
                          size: 13,
                          color: AppColors.muted,
                          height: 1.45,
                        ),
                      ),
                      if (hasProgress) ...[
                        const SizedBox(height: 18),
                        Text(
                          '${formatMoney(currency, progress)} / ${formatMoney(currency, existing.targetCentavos)}',
                          style: pixelText(size: 16, bold: true),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          progress >= existing.targetCentavos
                              ? l10n.goalReached
                              : l10n.goalRemaining(
                                  formatMoney(
                                    currency,
                                    existing.targetCentavos - progress,
                                  ),
                                ),
                          style: pixelText(size: 13, color: AppColors.tealInk),
                        ),
                      ],
                      const SizedBox(height: 24),
                      PixelButton(
                        key: const ValueKey('goal-save'),
                        label: l10n.goalSave,
                        onPressed: _saving || _importing ? null : _save,
                      ),
                      if (existing != null) ...[
                        if (hasProgress && !completed && progress > 0) ...[
                          const SizedBox(height: 14),
                          _purchaseButton(l10n),
                        ],
                        const SizedBox(height: 14),
                        PixelButton(
                          label: l10n.goalRecordSavings,
                          variant: PixelButtonVariant.secondary,
                          onPressed: _saving || _importing
                              ? null
                              : _recordSavings,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _saving ? null : _delete,
                          child: Text(
                            l10n.goalDelete,
                            style: pixelText(
                              size: 14,
                              bold: true,
                              color: AppColors.dangerInk,
                            ),
                          ),
                        ),
                      ],
                    ],
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
