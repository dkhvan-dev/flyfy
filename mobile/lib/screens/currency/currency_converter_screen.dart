import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:intl/intl.dart';

import '../../core/ui/app_list_screen_header.dart';
import '../../features/currency/data/currency_api.dart';
import '../../features/currency/models/currency_conversion_result.dart';
import '../../features/help_center/data/help_center_api.dart';
import '../../features/help_center/widgets/contextual_help_section.dart';
import '../../l10n/generated/app_localizations.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key, this._api});

  final CurrencyApi? _api;

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  late final CurrencyApi _api = widget._api ?? CurrencyApi();
  final TextEditingController _amountController = TextEditingController(
    text: '15000',
  );
  final FocusNode _amountFocusNode = FocusNode();

  List<CurrencyOption> _currencies = defaultCurrencyOptions;
  CurrencyConversionResult? _result;
  Timer? _convertDebounce;
  Timer? _dailyRateRefreshTimer;
  int _conversionRequestId = 0;
  String? _loadedCurrencyLocale;
  String _fromCurrency = 'KZT';
  String _toCurrency = 'USD';
  bool _isLoading = false;
  bool _isCurrencyListLoading = true;
  String? _errorText;

  static const _popularPairs = [
    ('KZT', 'USD'),
    ('KZT', 'EUR'),
    ('KZT', 'RUB'),
    ('USD', 'KZT'),
    ('EUR', 'KZT'),
    ('AED', 'KZT'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _convertNow();
      _startDailyRateRefresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (_loadedCurrencyLocale == locale) return;
    _loadedCurrencyLocale = locale;
    unawaited(_loadCurrencies(locale));
  }

  @override
  void dispose() {
    _convertDebounce?.cancel();
    _dailyRateRefreshTimer?.cancel();
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencies(String locale) async {
    try {
      final currencies = await _api.listCurrencies(locale: locale);
      if (!mounted) return;
      setState(() {
        _currencies = currencies;
        _isCurrencyListLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currencies = defaultCurrencyOptions;
        _isCurrencyListLoading = false;
      });
    }
  }

  Future<void> _convert({bool dismissKeyboard = false}) async {
    final l10n = AppLocalizations.of(context)!;
    final amount = _amountController.text.trim().replaceAll(',', '.');
    final requestId = ++_conversionRequestId;

    if (amount.isEmpty) {
      setState(() {
        _errorText = null;
        _isLoading = false;
        _result = null;
      });
      return;
    }

    final numericAmount = num.tryParse(amount);
    if (numericAmount == null || numericAmount < 0) {
      setState(() {
        _errorText = l10n.currencyConverterAmountValidation;
        _isLoading = false;
        _result = null;
      });
      return;
    }

    if (dismissKeyboard) {
      FocusManager.instance.primaryFocus?.unfocus();
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final result = await _api.convert(
        amount: amount,
        fromCurrency: _fromCurrency,
        toCurrency: _toCurrency,
      );
      if (!mounted || requestId != _conversionRequestId) return;
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _conversionRequestId) return;
      setState(() {
        _errorText = l10n.currencyConverterLoadFailed;
        _isLoading = false;
      });
    }
  }

  void _scheduleConvert({Duration delay = const Duration(milliseconds: 450)}) {
    _convertDebounce?.cancel();
    _convertDebounce = Timer(delay, () {
      if (mounted) unawaited(_convert());
    });
  }

  void _convertNow({bool dismissKeyboard = false}) {
    _convertDebounce?.cancel();
    unawaited(_convert(dismissKeyboard: dismissKeyboard));
  }

  void _startDailyRateRefresh() {
    _dailyRateRefreshTimer?.cancel();
    _dailyRateRefreshTimer = Timer.periodic(const Duration(days: 1), (_) {
      if (mounted) _convertNow();
    });
  }

  void _swapCurrencies() {
    setState(() {
      final previousFrom = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = previousFrom;
      _errorText = null;
    });
    _scheduleConvert(delay: Duration.zero);
  }

  void _selectPair((String, String) pair) {
    setState(() {
      _fromCurrency = pair.$1;
      _toCurrency = pair.$2;
      _errorText = null;
    });
    _scheduleConvert(delay: Duration.zero);
  }

  Future<void> _openCurrencyPicker({required bool isSource}) async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _CurrencyPickerScreen(
          currencies: _currencies,
          selectedCurrency: isSource ? _fromCurrency : _toCurrency,
          recentCurrencyCodes: _recentCurrencyCodes,
        ),
      ),
    );

    if (!mounted || selected == null) return;
    final current = isSource ? _fromCurrency : _toCurrency;
    if (selected == current) return;

    setState(() {
      if (isSource) {
        _fromCurrency = selected;
      } else {
        _toCurrency = selected;
      }
      _errorText = null;
    });
    _scheduleConvert(delay: Duration.zero);
  }

  List<String> get _recentCurrencyCodes {
    final codes = <String>[_fromCurrency, _toCurrency, 'KZT', 'USD', 'EUR'];
    final seen = <String>{};
    return [
      for (final code in codes)
        if (seen.add(code)) code,
    ];
  }

  String get _currentSupportLocale =>
      Localizations.localeOf(context).languageCode;

  Map<String, String> get _currencySupportContext {
    final amount = _amountController.text.trim();
    final convertedAmount = _result?.convertedAmount.trim();
    return {
      'screen': 'currency_converter',
      'locale': _currentSupportLocale,
      'from_currency': _fromCurrency,
      'to_currency': _toCurrency,
      'currency_pair': '$_fromCurrency-$_toCurrency',
      if (amount.isNotEmpty) 'amount': _amountController.text.trim(),
      if (convertedAmount != null && convertedAmount.isNotEmpty)
        'converted_amount': convertedAmount,
    };
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 600;
    final horizontalPadding = isCompact ? 18.0 : 32.0;
    final contentMaxWidth = isCompact ? double.infinity : 680.0;

    return Theme(
      data: AppDesignSystem.themeFor(context),
      child: Scaffold(
        backgroundColor: colors.background,
        body: DecoratedBox(
          decoration: AppBoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors.screenGradientColors,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                AppListScreenHeader(
                  title: l10n.currencyConverterTitle,
                  notificationsTooltip: l10n.profileNotificationsRowTitle,
                  onBackTap: _goBack,
                  onNotificationsTap: () => context.push('/notifications'),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: AppEdgeInsets.fromLTRB(
                      horizontalPadding,
                      8,
                      horizontalPadding,
                      24 + mediaQuery.viewInsets.bottom,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentMaxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ExchangeStack(
                              amountController: _amountController,
                              amountFocusNode: _amountFocusNode,
                              fromCurrency: _fromCurrency,
                              toCurrency: _toCurrency,
                              fromOption: _currencyByCode(
                                _currencies,
                                _fromCurrency,
                              ),
                              toOption: _currencyByCode(
                                _currencies,
                                _toCurrency,
                              ),
                              result: _result,
                              isLoading: _isLoading,
                              isCurrencyListLoading: _isCurrencyListLoading,
                              errorText: _errorText,
                              onAmountChanged: (_) => _scheduleConvert(),
                              onAmountSubmitted: (_) =>
                                  _convertNow(dismissKeyboard: true),
                              onFromTap: () =>
                                  _openCurrencyPicker(isSource: true),
                              onToTap: () =>
                                  _openCurrencyPicker(isSource: false),
                              onSwap: _swapCurrencies,
                              l10n: l10n,
                            ),
                            const SizedBox(height: 22),
                            _QuickSwitchSection(
                              pairs: _popularPairs,
                              selectedFrom: _fromCurrency,
                              selectedTo: _toCurrency,
                              result: _result,
                              currencies: _currencies,
                              onSelected: _selectPair,
                              l10n: l10n,
                            ),
                            const SizedBox(height: 18),
                            _NoticePanel(l10n: l10n),
                            const SizedBox(height: 18),
                            ContextualHelpSection(
                              surface: HelpCenterSurface.currencyConverter,
                              tags: const ['currency', 'payments'],
                              supportContext: _currencySupportContext,
                            ),
                          ],
                        ),
                      ),
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

class _ExchangeStack extends StatelessWidget {
  const _ExchangeStack({
    required this.amountController,
    required this.amountFocusNode,
    required this.fromCurrency,
    required this.toCurrency,
    required this.fromOption,
    required this.toOption,
    required this.result,
    required this.isLoading,
    required this.isCurrencyListLoading,
    required this.errorText,
    required this.onAmountChanged,
    required this.onAmountSubmitted,
    required this.onFromTap,
    required this.onToTap,
    required this.onSwap,
    required this.l10n,
  });

  final TextEditingController amountController;
  final FocusNode amountFocusNode;
  final String fromCurrency;
  final String toCurrency;
  final CurrencyOption fromOption;
  final CurrencyOption toOption;
  final CurrencyConversionResult? result;
  final bool isLoading;
  final bool isCurrencyListLoading;
  final String? errorText;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<String> onAmountSubmitted;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final VoidCallback onSwap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                _AmountCard(
                  label: l10n.currencyConverterYouSend,
                  currency: fromCurrency,
                  option: fromOption,
                  amountController: amountController,
                  amountFocusNode: amountFocusNode,
                  isInput: true,
                  backgroundColor: colors.surfaceRaised,
                  onCurrencyTap: onFromTap,
                  onAmountChanged: onAmountChanged,
                  onAmountSubmitted: onAmountSubmitted,
                  isCurrencyListLoading: isCurrencyListLoading,
                  errorText: errorText,
                ),
                const SizedBox(height: 8),
                _AmountCard(
                  label: l10n.currencyConverterYouReceive,
                  currency: toCurrency,
                  option: toOption,
                  amountText: result?.convertedAmount,
                  isInput: false,
                  backgroundColor: colors.surfaceHigh,
                  onCurrencyTap: onToTap,
                  isCurrencyListLoading: isCurrencyListLoading,
                  isLoading: isLoading && result == null,
                ),
              ],
            ),
            _SwapFloatingButton(onSwap: onSwap, l10n: l10n),
          ],
        ),
        const SizedBox(height: 14),
        _RateStatusRow(result: result, isLoading: isLoading, l10n: l10n),
      ],
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.label,
    required this.currency,
    required this.option,
    required this.isInput,
    required this.backgroundColor,
    required this.onCurrencyTap,
    required this.isCurrencyListLoading,
    this.amountController,
    this.amountFocusNode,
    this.amountText,
    this.onAmountChanged,
    this.onAmountSubmitted,
    this.errorText,
    this.isLoading = false,
  });

  final String label;
  final String currency;
  final CurrencyOption option;
  final bool isInput;
  final Color backgroundColor;
  final VoidCallback onCurrencyTap;
  final bool isCurrencyListLoading;
  final TextEditingController? amountController;
  final FocusNode? amountFocusNode;
  final String? amountText;
  final ValueChanged<String>? onAmountChanged;
  final ValueChanged<String>? onAmountSubmitted;
  final String? errorText;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: backgroundColor,
        borderRadius: AppBorderRadius.circular(28),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Padding(
        padding: const AppEdgeInsets.fromLTRB(20, 18, 20, 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 142),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle(
                        color: colors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  _CurrencyPill(
                    currency: currency,
                    option: option,
                    isLoading: isCurrencyListLoading,
                    onTap: onCurrencyTap,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _CurrencySymbol(symbol: _currencySymbol(option)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: isInput
                        ? TextField(
                            controller: amountController,
                            focusNode: amountFocusNode,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            style: AppTextStyle(
                              color: colors.textPrimary,
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                            decoration: AppInputDecoration(
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              hintText: '0',
                              hintStyle: AppTextStyle(
                                color: colors.textMuted,
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                              contentPadding: AppEdgeInsets.zero,
                              isDense: true,
                            ),
                            onChanged: onAmountChanged,
                            onSubmitted: onAmountSubmitted,
                          )
                        : Align(
                            alignment: Alignment.centerRight,
                            child: isLoading
                                ? SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: colors.primary,
                                    ),
                                  )
                                : FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      amountText ?? '-',
                                      maxLines: 1,
                                      style: AppTextStyle(
                                        color: colors.textPrimary,
                                        fontSize: 44,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ),
                          ),
                  ),
                ],
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorText!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTextStyle(
                    color: colors.primary,
                    fontSize: 12,
                    height: 1.3,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencySymbol extends StatelessWidget {
  const _CurrencySymbol({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return SizedBox(
      width: 56,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          symbol,
          maxLines: 1,
          style: AppTextStyle(
            color: colors.textPrimary,
            fontSize: 46,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  const _CurrencyPill({
    required this.currency,
    required this.option,
    required this.isLoading,
    required this.onTap,
  });

  final String currency;
  final CurrencyOption option;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Tooltip(
      message: option.name,
      child: Material(
        color: colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: AppBorderRadius.circular(999),
          child: Ink(
            decoration: AppBoxDecoration(
              color: colors.primaryContainer,
              borderRadius: AppBorderRadius.circular(999),
            ),
            padding: const AppEdgeInsets.fromLTRB(6, 5, 10, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CurrencyFlagIcon(code: currency, size: 30),
                const SizedBox(width: 8),
                Text(
                  currency,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colors.textPrimary.withValues(alpha: 0.84),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwapFloatingButton extends StatelessWidget {
  const _SwapFloatingButton({required this.onSwap, required this.l10n});

  final VoidCallback onSwap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Tooltip(
      message: l10n.currencyConverterSwapTooltip,
      child: Material(
        color: colors.primary,
        shape: const CircleBorder(),
        elevation: 8,
        shadowColor: Theme.of(context).brightness == Brightness.dark
            ? colors.primary.withValues(alpha: 0.35)
            : colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onSwap,
          child: SizedBox(
            width: 58,
            height: 58,
            child: Icon(
              Icons.swap_vert_rounded,
              color: colors.textPrimary,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}

class _RateStatusRow extends StatelessWidget {
  const _RateStatusRow({
    required this.result,
    required this.isLoading,
    required this.l10n,
  });

  final CurrencyConversionResult? result;
  final bool isLoading;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final rateText = result == null
        ? l10n.currencyConverterInfoNotice
        : '1 ${result!.sourceCurrency} = ${result!.rate} ${result!.targetCurrency}';
    final updatedText = _updatedText(context, result, l10n);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 380;
        final leading = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded, color: colors.primary, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                rateText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle(
                  color: colors.textSecondary,
                  fontSize: 12.5,
                  height: 1.35,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        );

        final trailing = AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLoading
              ? SizedBox(
                  key: ValueKey('loading'),
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                )
              : Text(
                  updatedText,
                  key: ValueKey(updatedText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTextStyle(
                    color: colors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              if (updatedText.isNotEmpty || isLoading) ...[
                const SizedBox(height: 8),
                trailing,
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: leading),
            const SizedBox(width: 12),
            Flexible(child: trailing),
          ],
        );
      },
    );
  }
}

class _QuickSwitchSection extends StatelessWidget {
  const _QuickSwitchSection({
    required this.pairs,
    required this.selectedFrom,
    required this.selectedTo,
    required this.result,
    required this.currencies,
    required this.onSelected,
    required this.l10n,
  });

  final List<(String, String)> pairs;
  final String selectedFrom;
  final String selectedTo;
  final CurrencyConversionResult? result;
  final List<CurrencyOption> currencies;
  final ValueChanged<(String, String)> onSelected;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.currencyConverterQuickSwitch.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle(
            color: colors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = constraints.maxWidth < 460
                ? constraints.maxWidth
                : (constraints.maxWidth - 10) / 2;

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final pair in pairs)
                  _QuickSwitchTile(
                    width: tileWidth,
                    pair: pair,
                    sourceOption: _currencyByCode(currencies, pair.$1),
                    targetOption: _currencyByCode(currencies, pair.$2),
                    selected: selectedFrom == pair.$1 && selectedTo == pair.$2,
                    ratePreview: _quickRatePreview(pair, result),
                    onTap: () => onSelected(pair),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickSwitchTile extends StatelessWidget {
  const _QuickSwitchTile({
    required this.width,
    required this.pair,
    required this.sourceOption,
    required this.targetOption,
    required this.selected,
    required this.ratePreview,
    required this.onTap,
  });

  final double width;
  final (String, String) pair;
  final CurrencyOption sourceOption;
  final CurrencyOption targetOption;
  final bool selected;
  final String ratePreview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Tooltip(
      message: '${sourceOption.name} / ${targetOption.name}',
      child: SizedBox(
        width: width,
        child: Material(
          color: colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppBorderRadius.circular(22),
            child: Ink(
              decoration: AppBoxDecoration(
                color: selected ? colors.primaryContainer : colors.surface,
                borderRadius: AppBorderRadius.circular(22),
                border: Border.all(
                  color: selected ? colors.primary : colors.borderSoft,
                ),
              ),
              padding: const AppEdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: Row(
                children: [
                  _CurrencyFlagIcon(code: pair.$1, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pair.$1} / ${pair.$2}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          ratePreview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                            height: 1.2,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _CurrencyFlagIcon(code: pair.$2, size: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticePanel extends StatelessWidget {
  const _NoticePanel({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.surface,
        borderRadius: AppBorderRadius.circular(18),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined, color: colors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.currencyConverterInfoNotice,
                style: AppTextStyle(
                  color: colors.textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyPickerScreen extends StatefulWidget {
  const _CurrencyPickerScreen({
    required this.currencies,
    required this.selectedCurrency,
    required this.recentCurrencyCodes,
  });

  final List<CurrencyOption> currencies;
  final String selectedCurrency;
  final List<String> recentCurrencyCodes;

  @override
  State<_CurrencyPickerScreen> createState() => _CurrencyPickerScreenState();
}

class _CurrencyPickerScreenState extends State<_CurrencyPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final allCurrencies = _dedupeCurrencies(widget.currencies);
    final filteredCurrencies = _filterCurrencies(allCurrencies, _query, l10n);
    final recentCurrencies = [
      for (final code in widget.recentCurrencyCodes)
        if (allCurrencies.any((item) => item.code == code))
          _currencyByCode(allCurrencies, code),
    ];
    final showRecent = _query.trim().isEmpty && recentCurrencies.isNotEmpty;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const AppEdgeInsets.fromLTRB(8, 8, 8, 2),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: colors.textPrimary,
                    ),
                  ),
                  Padding(
                    padding: const AppEdgeInsets.symmetric(horizontal: 56),
                    child: Text(
                      l10n.currencyConverterSelectCurrencyTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const AppEdgeInsets.fromLTRB(18, 14, 18, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                style: AppTextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
                decoration: AppInputDecoration(
                  hintText: l10n.currencyConverterSearchCurrencyHint,
                  hintStyle: AppTextStyle(
                    color: colors.textMuted,
                    letterSpacing: 0,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: colors.primary),
                  filled: true,
                  fillColor: colors.surface,
                  contentPadding: const AppEdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppBorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppBorderRadius.circular(999),
                    borderSide: BorderSide(color: colors.primary),
                  ),
                ),
              ),
            ),
            Expanded(
              child: filteredCurrencies.isEmpty
                  ? _CurrencyPickerEmptyState(l10n: l10n)
                  : ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const AppEdgeInsets.fromLTRB(18, 4, 18, 24),
                      children: [
                        if (showRecent) ...[
                          _CurrencyPickerSectionTitle(
                            title: l10n.currencyConverterRecentSection,
                          ),
                          const SizedBox(height: 8),
                          for (final currency in recentCurrencies)
                            _CurrencyPickerRow(
                              currency: currency,
                              l10n: l10n,
                              selected:
                                  currency.code == widget.selectedCurrency,
                              onTap: () =>
                                  Navigator.of(context).pop(currency.code),
                            ),
                          const SizedBox(height: 16),
                        ],
                        _CurrencyPickerSectionTitle(
                          title: l10n.currencyConverterAllCurrenciesSection,
                        ),
                        const SizedBox(height: 8),
                        for (final currency in filteredCurrencies)
                          _CurrencyPickerRow(
                            currency: currency,
                            l10n: l10n,
                            selected: currency.code == widget.selectedCurrency,
                            onTap: () =>
                                Navigator.of(context).pop(currency.code),
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

class _CurrencyPickerSectionTitle extends StatelessWidget {
  const _CurrencyPickerSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Text(
      title.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyle(
        color: colors.primary,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}

class _CurrencyPickerRow extends StatelessWidget {
  const _CurrencyPickerRow({
    required this.currency,
    required this.l10n,
    required this.selected,
    required this.onTap,
  });

  final CurrencyOption currency;
  final AppLocalizations l10n;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final name = _localizedCurrencyName(currency, l10n);
    final country = _localizedCurrencyCountry(currency, l10n);

    return Padding(
      padding: const AppEdgeInsets.only(bottom: 10),
      child: Material(
        color: colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppBorderRadius.circular(20),
          child: Ink(
            decoration: AppBoxDecoration(
              color: selected ? colors.primaryContainer : colors.surface,
              borderRadius: AppBorderRadius.circular(20),
              border: Border.all(
                color: selected ? colors.primary : colors.borderSoft,
              ),
            ),
            padding: const AppEdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            child: Row(
              children: [
                _CurrencyFlagIcon(code: currency.code, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${currency.code} - $country',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle(
                          color: colors.textSecondary,
                          fontSize: 12.5,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.check_circle_rounded,
                    color: colors.primary,
                    size: 22,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrencyPickerEmptyState extends StatelessWidget {
  const _CurrencyPickerEmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Center(
      child: Padding(
        padding: const AppEdgeInsets.all(24),
        child: Text(
          l10n.currencyConverterNoCurrenciesFound,
          textAlign: TextAlign.center,
          style: AppTextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            height: 1.35,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

const _compactCurrencyFlagScale = 0.72;

abstract final class _CurrencyFlagPalette {
  static const amberSoft11 = Color(0xFFFCD856);
  static const black = Color(0xFF000000);
  static const blueMuted01 = Color(0xFF00A3DD);
  static const blueMuted03 = Color(0xFF1EB2E8);
  static const blueMuted04 = Color(0xFF244AA5);
  static const blueMuted05 = Color(0xFF2E5B9A);
  static const blueMuted06 = Color(0xFF3157A4);
  static const blueMuted07 = Color(0xFF3474A8);
  static const blueMuted08 = Color(0xFF394F90);
  static const blueMuted09 = Color(0xFF3C6CA8);
  static const blueMuted10 = Color(0xFF3F6EA8);
  static const blueMuted11 = Color(0xFF40538F);
  static const blueMuted12 = Color(0xFF426AA0);
  static const blueMuted14 = Color(0xFF496DA0);
  static const blueMuted15 = Color(0xFF496FB0);
  static const blueMuted18 = Color(0xFF4F5C9C);
  static const blueMuted19 = Color(0xFF4F7FAE);
  static const blueMuted22 = Color(0xFF5A88A5);
  static const blueMuted23 = Color(0xFF5F578D);
  static const blueSoft05 = Color(0xFF5A9BC8);
  static const blueSoft08 = Color(0xFF6E6FB3);
  static const blueSoft09 = Color(0xFF74ACDF);
  static const blueSurface01 = Color(0xFF010066);
  static const blueSurface02 = Color(0xFF012169);
  static const blueSurfaceHigh01 = Color(0xFF000080);
  static const blueSurfaceHigh02 = Color(0xFF002776);
  static const blueSurfaceHigh03 = Color(0xFF002A8F);
  static const blueSurfaceHigh04 = Color(0xFF0032A0);
  static const blueSurfaceHigh05 = Color(0xFF0033A0);
  static const blueSurfaceHigh06 = Color(0xFF0038A8);
  static const blueSurfaceHigh07 = Color(0xFF0039A6);
  static const blueSurfaceHigh08 = Color(0xFF003F87);
  static const blueSurfaceHigh09 = Color(0xFF0047A0);
  static const blueSurfaceHigh10 = Color(0xFF0057B7);
  static const blueSurfaceHigh11 = Color(0xFF0066B3);
  static const blueSurfaceHigh12 = Color(0xFF006AA7);
  static const blueSurfaceHigh13 = Color(0xFF02529C);
  static const blueSurfaceHigh15 = Color(0xFF0C4076);
  static const blueSurfaceHigh17 = Color(0xFF11457E);
  static const blueSurfaceHigh23 = Color(0xFF2D2A4A);
  static const blueSurfaceHigh24 = Color(0xFF2F4D8F);
  static const blueSurfaceHigh28 = Color(0xFF3C3B6E);
  static const greenMuted04 = Color(0xFF1EB53A);
  static const greenMuted05 = Color(0xFF3F8C62);
  static const greenMuted06 = Color(0xFF477B4B);
  static const greenMuted07 = Color(0xFF4AA657);
  static const greenMuted09 = Color(0xFF509E2F);
  static const greenMuted11 = Color(0xFF6B8B4A);
  static const greenSurface01 = Color(0xFF006233);
  static const greenSurface02 = Color(0xFF006600);
  static const greenSurfaceHigh01 = Color(0xFF00732F);
  static const greenSurfaceHigh02 = Color(0xFF007A3D);
  static const greenSurfaceHigh03 = Color(0xFF007E3A);
  static const greenSurfaceHigh04 = Color(0xFF00843D);
  static const greenSurfaceHigh05 = Color(0xFF009639);
  static const greenSurfaceHigh06 = Color(0xFF009A49);
  static const greenSurfaceHigh07 = Color(0xFF009B3A);
  static const greenSurfaceHigh08 = Color(0xFF138808);
  static const greenSurfaceHigh10 = Color(0xFF23864C);
  static const greenSurfaceHigh12 = Color(0xFF257B54);
  static const greenSurfaceHigh16 = Color(0xFF2D8B63);
  static const greenSurfaceHigh19 = Color(0xFF407D57);
  static const neutralInk02 = Color(0xFF111111);
  static const orangeSoft43 = Color(0xFFFF9933);
  static const redMuted01 = Color(0xFFAF4C4F);
  static const redMuted02 = Color(0xFFB22234);
  static const redMuted03 = Color(0xFFB65C73);
  static const redMuted04 = Color(0xFFB94A48);
  static const redMuted05 = Color(0xFFB95A55);
  static const redMuted06 = Color(0xFFC1272D);
  static const redMuted07 = Color(0xFFC44456);
  static const redMuted08 = Color(0xFFC53D42);
  static const redMuted09 = Color(0xFFC60C30);
  static const redMuted10 = Color(0xFFC6363C);
  static const redMuted11 = Color(0xFFC8102E);
  static const redMuted12 = Color(0xFFC8313E);
  static const redMuted13 = Color(0xFFC8404F);
  static const redMuted14 = Color(0xFFC84E44);
  static const redMuted15 = Color(0xFFC94C4C);
  static const redMuted16 = Color(0xFFC95353);
  static const redMuted17 = Color(0xFFCC0000);
  static const redMuted18 = Color(0xFFCC0001);
  static const redMuted19 = Color(0xFFCC142B);
  static const redMuted20 = Color(0xFFCD2E3A);
  static const redMuted21 = Color(0xFFCE1126);
  static const redMuted22 = Color(0xFFCF142B);
  static const redMuted23 = Color(0xFFD21034);
  static const redMuted24 = Color(0xFFD52B1E);
  static const redMuted25 = Color(0xFFD62828);
  static const redMuted26 = Color(0xFFD64C3C);
  static const redMuted27 = Color(0xFFD7141A);
  static const redMuted28 = Color(0xFFD80621);
  static const redMuted30 = Color(0xFFD90012);
  static const redMuted31 = Color(0xFFDA2032);
  static const redMuted32 = Color(0xFFDA251D);
  static const redMuted33 = Color(0xFFDC143C);
  static const redMuted34 = Color(0xFFDC1E35);
  static const redMuted35 = Color(0xFFDE2910);
  static const redMuted36 = Color(0xFFE30A17);
  static const redMuted37 = Color(0xFFE8112D);
  static const redMuted39 = Color(0xFFFF0000);
  static const redSoft01 = Color(0xFFC85A65);
  static const redSoft02 = Color(0xFFC96B70);
  static const redSoft06 = Color(0xFFEF3340);
  static const redSurfaceHigh04 = Color(0xFF8B3A2B);
  static const redSurfaceHigh05 = Color(0xFF8D153A);
  static const redSurfaceHigh06 = Color(0xFFA51931);
  static const redSurfaceHigh07 = Color(0xFFB00020);
  static const redSurfaceHigh08 = Color(0xFFBB0000);
  static const redSurfaceHigh09 = Color(0xFFBC002D);
  static const tealMuted01 = Color(0xFF00AFCA);
  static const tealMuted02 = Color(0xFF00B5E2);
  static const tealMuted05 = Color(0xFF2396A8);
  static const tealMuted08 = Color(0xFF3D8B7D);
  static const tealSurface01 = Color(0xFF00534E);
  static const tealSurface02 = Color(0xFF006847);
  static const tealSurfaceHigh01 = Color(0xFF168D95);
  static const tealSurfaceHigh02 = Color(0xFF187B5F);
  static const tealSurfaceHigh09 = Color(0xFF338E7B);
  static const violetMuted02 = Color(0xFF7342A4);
  static const violetMuted04 = Color(0xFF8B65A6);
  static const warmMuted03 = Color(0xFF8C6239);
  static const warmMuted11 = Color(0xFF9A5E39);
  static const warmMuted13 = Color(0xFF9A6A38);
  static const warmMuted20 = Color(0xFFB65C38);
  static const warmMuted24 = Color(0xFFB9763D);
  static const warmMuted25 = Color(0xFFC45D24);
  static const warmMuted31 = Color(0xFFF2A800);
  static const warmMuted33 = Color(0xFFF6B40E);
  static const warmMuted34 = Color(0xFFF7C800);
  static const warmMuted35 = Color(0xFFF8C300);
  static const warmMuted36 = Color(0xFFFCD116);
  static const warmMuted38 = Color(0xFFFECC00);
  static const warmMuted42 = Color(0xFFFF7F00);
  static const warmMuted50 = Color(0xFFFFB700);
  static const warmMuted51 = Color(0xFFFFCC00);
  static const warmMuted52 = Color(0xFFFFD100);
  static const warmMuted53 = Color(0xFFFFD700);
  static const warmMuted54 = Color(0xFFFFD900);
  static const warmMuted55 = Color(0xFFFFDE00);
  static const warmMuted56 = Color(0xFFFFDF00);
  static const warmSurfaceHigh32 = Color(0xFF8C4A24);
  static const warmSurfaceHigh38 = Color(0xFFC09300);
  static const white = Color(0xFFFFFFFF);
}

class _CurrencyFlagIcon extends StatelessWidget {
  const _CurrencyFlagIcon({required this.code, required this.size});

  final String code;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final regionCode = _currencyFlagRegion(code);
    final badgeColor = _avatarColor(code);
    final innerSize = size * _compactCurrencyFlagScale;

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          color: badgeColor.withValues(alpha: 0.24),
          shape: BoxShape.circle,
          border: Border.all(color: colors.borderSoft),
        ),
        child: Center(
          child: Semantics(
            label: code,
            child: regionCode == null
                ? _CurrencyFallbackGlyph(size: innerSize)
                : Container(
                    width: innerSize,
                    height: innerSize,
                    clipBehavior: Clip.antiAlias,
                    decoration: AppBoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.border,
                        width: math.max(1, size * 0.035),
                      ),
                    ),
                    child: CustomPaint(
                      painter: _CurrencyFlagPainter(
                        regionCode: regionCode,
                        fallbackColor: badgeColor,
                      ),
                      child: SizedBox.square(dimension: innerSize),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CurrencyFlagPainter extends CustomPainter {
  const _CurrencyFlagPainter({
    required this.regionCode,
    required this.fallbackColor,
  });

  final String regionCode;
  final Color fallbackColor;

  @override
  void paint(Canvas canvas, Size size) {
    switch (regionCode) {
      case 'AE':
        _drawUnitedArabEmirates(canvas, size);
      case 'AM':
        _drawArmenia(canvas, size);
      case 'AR':
        _drawArgentina(canvas, size);
      case 'AU':
        _drawAustralia(canvas, size);
      case 'AZ':
        _drawAzerbaijan(canvas, size);
      case 'BR':
        _drawBrazil(canvas, size);
      case 'BY':
        _drawBelarus(canvas, size);
      case 'CA':
        _drawCanada(canvas, size);
      case 'CH':
        _drawSwitzerland(canvas, size);
      case 'CN':
        _drawChina(canvas, size);
      case 'CU':
        _drawCuba(canvas, size);
      case 'CZ':
        _drawCzechia(canvas, size);
      case 'DK':
        _drawDenmark(canvas, size);
      case 'EG':
        _drawEgypt(canvas, size);
      case 'EU':
        _drawEuropeanUnion(canvas, size);
      case 'GB':
        _drawUnitedKingdom(canvas, size);
      case 'GE':
        _drawGeorgia(canvas, size);
      case 'ID':
        _drawIndonesia(canvas, size);
      case 'IN':
        _drawIndia(canvas, size);
      case 'IS':
        _drawIceland(canvas, size);
      case 'JP':
        _drawJapan(canvas, size);
      case 'KE':
        _drawKenya(canvas, size);
      case 'KG':
        _drawKyrgyzstan(canvas, size);
      case 'KR':
        _drawSouthKorea(canvas, size);
      case 'KZ':
        _drawKazakhstan(canvas, size);
      case 'LK':
        _drawSriLanka(canvas, size);
      case 'MA':
        _drawMorocco(canvas, size);
      case 'MD':
        _drawMoldova(canvas, size);
      case 'MN':
        _drawMongolia(canvas, size);
      case 'MV':
        _drawMaldives(canvas, size);
      case 'MX':
        _drawMexico(canvas, size);
      case 'MY':
        _drawMalaysia(canvas, size);
      case 'NZ':
        _drawNewZealand(canvas, size);
      case 'PH':
        _drawPhilippines(canvas, size);
      case 'PL':
        _drawPoland(canvas, size);
      case 'RS':
        _drawSerbia(canvas, size);
      case 'RU':
        _drawRussia(canvas, size);
      case 'SC':
        _drawSeychelles(canvas, size);
      case 'SE':
        _drawSweden(canvas, size);
      case 'SG':
        _drawSingapore(canvas, size);
      case 'TH':
        _drawThailand(canvas, size);
      case 'TJ':
        _drawTajikistan(canvas, size);
      case 'TM':
        _drawTurkmenistan(canvas, size);
      case 'TR':
        _drawTurkey(canvas, size);
      case 'TZ':
        _drawTanzania(canvas, size);
      case 'UA':
        _drawUkraine(canvas, size);
      case 'US':
        _drawUnitedStates(canvas, size);
      case 'UZ':
        _drawUzbekistan(canvas, size);
      case 'VN':
        _drawVietnam(canvas, size);
      default:
        _drawFallbackFlag(canvas, size, regionCode, fallbackColor);
    }
  }

  void _drawUnitedArabEmirates(Canvas canvas, Size size) {
    final redWidth = size.width * 0.3;
    _fill(canvas, size, _CurrencyFlagPalette.greenSurfaceHigh01);
    _drawHorizontalStripes(
      canvas,
      Rect.fromLTWH(redWidth, 0, size.width - redWidth, size.height),
      const [
        _CurrencyFlagPalette.greenSurfaceHigh06,
        _CurrencyFlagPalette.white,
        _CurrencyFlagPalette.black,
      ],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, redWidth, size.height),
      _paint(_CurrencyFlagPalette.redMuted39),
    );
  }

  void _drawArmenia(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      _CurrencyFlagPalette.redMuted30,
      _CurrencyFlagPalette.blueSurfaceHigh05,
      _CurrencyFlagPalette.warmMuted31,
    ]);
  }

  void _drawArgentina(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      _CurrencyFlagPalette.blueSoft09,
      _CurrencyFlagPalette.white,
      _CurrencyFlagPalette.blueSoft09,
    ]);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.08,
      _paint(_CurrencyFlagPalette.warmMuted33),
    );
  }

  void _drawAustralia(Canvas canvas, Size size) {
    _drawBlueEnsign(canvas, size, starColor: _CurrencyFlagPalette.white);
  }

  void _drawAzerbaijan(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      _CurrencyFlagPalette.tealMuted02,
      _CurrencyFlagPalette.redSoft06,
      _CurrencyFlagPalette.greenMuted09,
    ]);
    _drawCrescent(
      canvas,
      Offset(size.width * 0.45, size.height * 0.5),
      size.shortestSide * 0.12,
      _CurrencyFlagPalette.white,
      _CurrencyFlagPalette.redSoft06,
    );
    _drawStar(
      canvas,
      Offset(size.width * 0.63, size.height * 0.5),
      size.shortestSide * 0.055,
      _CurrencyFlagPalette.white,
    );
  }

  void _drawBrazil(Canvas canvas, Size size) {
    _fill(canvas, size, _CurrencyFlagPalette.greenSurfaceHigh07);
    _drawDiamond(
      canvas,
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.5),
        width: size.width * 0.72,
        height: size.height * 0.5,
      ),
      _CurrencyFlagPalette.warmMuted56,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.17,
      _paint(_CurrencyFlagPalette.blueSurfaceHigh02),
    );
  }

  void _drawBelarus(Canvas canvas, Size size) {
    _drawWeightedHorizontalStripes(canvas, Offset.zero & size, const [
      (_CurrencyFlagPalette.redMuted12, 2.0),
      (_CurrencyFlagPalette.greenMuted07, 1.0),
    ]);
    final ornamentWidth = size.width * 0.18;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, ornamentWidth, size.height),
      _paint(_CurrencyFlagPalette.white),
    );
    for (var i = 0; i < 4; i += 1) {
      _drawDiamond(
        canvas,
        Rect.fromCenter(
          center: Offset(ornamentWidth * 0.5, size.height * (0.16 + i * 0.22)),
          width: ornamentWidth * 0.45,
          height: ornamentWidth * 0.45,
        ),
        _CurrencyFlagPalette.redMuted12,
      );
    }
  }

  void _drawCanada(Canvas canvas, Size size) {
    _drawVerticalStripes(canvas, Offset.zero & size, const [
      _CurrencyFlagPalette.redMuted28,
      _CurrencyFlagPalette.white,
      _CurrencyFlagPalette.redMuted28,
    ]);
    _drawStar(
      canvas,
      Offset(size.width * 0.5, size.height * 0.52),
      size.shortestSide * 0.14,
      _CurrencyFlagPalette.redMuted28,
    );
  }

  void _drawSwitzerland(Canvas canvas, Size size) {
    _fill(canvas, size, _CurrencyFlagPalette.redMuted39);
    _drawCenteredCross(
      canvas,
      size,
      _CurrencyFlagPalette.white,
      size.shortestSide * 0.18,
    );
  }

  void _drawChina(Canvas canvas, Size size) {
    _fill(canvas, size, _CurrencyFlagPalette.redMuted35);
    _drawStar(
      canvas,
      Offset(size.width * 0.32, size.height * 0.34),
      size.shortestSide * 0.16,
      _CurrencyFlagPalette.warmMuted55,
    );
    for (final center in [
      Offset(size.width * 0.58, size.height * 0.22),
      Offset(size.width * 0.68, size.height * 0.36),
      Offset(size.width * 0.68, size.height * 0.54),
      Offset(size.width * 0.56, size.height * 0.68),
    ]) {
      _drawStar(
        canvas,
        center,
        size.shortestSide * 0.05,
        _CurrencyFlagPalette.warmMuted55,
      );
    }
  }

  void _drawEuropeanUnion(Canvas canvas, Size size) {
    _fill(canvas, size, _CurrencyFlagPalette.blueMuted04);
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final orbit = size.shortestSide * 0.24;
    final dotRadius = size.shortestSide * 0.025;
    for (var i = 0; i < 12; i += 1) {
      final angle = -math.pi / 2 + (math.pi * 2 * i / 12);
      canvas.drawCircle(
        center + Offset(math.cos(angle) * orbit, math.sin(angle) * orbit),
        dotRadius,
        _paint(_CurrencyFlagPalette.warmMuted51),
      );
    }
  }

  void _drawUnitedKingdom(Canvas canvas, Size size) {
    _fill(canvas, size, _CurrencyFlagPalette.blueSurface02);
    _drawDiagonal(
      canvas,
      size,
      _CurrencyFlagPalette.white,
      size.shortestSide * 0.17,
    );
    _drawDiagonal(
      canvas,
      size,
      _CurrencyFlagPalette.redMuted11,
      size.shortestSide * 0.08,
    );
    _drawCenteredCross(
      canvas,
      size,
      _CurrencyFlagPalette.white,
      size.shortestSide * 0.2,
    );
    _drawCenteredCross(
      canvas,
      size,
      _CurrencyFlagPalette.redMuted11,
      size.shortestSide * 0.11,
    );
  }

  void _drawCuba(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      _CurrencyFlagPalette.blueSurfaceHigh03,
      _CurrencyFlagPalette.white,
      _CurrencyFlagPalette.blueSurfaceHigh03,
      _CurrencyFlagPalette.white,
      _CurrencyFlagPalette.blueSurfaceHigh03,
    ]);
    _drawTriangle(canvas, [
      Offset.zero,
      Offset(0, size.height),
      Offset(size.width * 0.45, size.height * 0.5),
    ], _CurrencyFlagPalette.redMuted22);
    _drawStar(
      canvas,
      Offset(size.width * 0.16, size.height * 0.5),
      size.shortestSide * 0.065,
      _CurrencyFlagPalette.white,
    );
  }

  void _drawCzechia(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      _CurrencyFlagPalette.white,
      _CurrencyFlagPalette.redMuted27,
    ]);
    _drawTriangle(canvas, [
      Offset.zero,
      Offset(0, size.height),
      Offset(size.width * 0.54, size.height * 0.5),
    ], _CurrencyFlagPalette.blueSurfaceHigh17);
  }

  void _drawDenmark(Canvas canvas, Size size) {
    _drawNordicCross(
      canvas,
      size,
      background: _CurrencyFlagPalette.redMuted09,
      cross: _CurrencyFlagPalette.white,
    );
  }

  void _drawEgypt(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      _CurrencyFlagPalette.redMuted21,
      _CurrencyFlagPalette.white,
      _CurrencyFlagPalette.black,
    ]);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.055,
      _paint(_CurrencyFlagPalette.warmSurfaceHigh38),
    );
  }

  void _drawGeorgia(Canvas canvas, Size size) {
    _fill(canvas, size, _CurrencyFlagPalette.white);
    _drawCenteredCross(
      canvas,
      size,
      _CurrencyFlagPalette.redMuted39,
      size.width * 0.13,
    );
    for (final center in [
      Offset(size.width * 0.25, size.height * 0.25),
      Offset(size.width * 0.75, size.height * 0.25),
      Offset(size.width * 0.25, size.height * 0.75),
      Offset(size.width * 0.75, size.height * 0.75),
    ]) {
      _drawTinyCross(canvas, center, size.shortestSide * 0.12);
    }
  }

  void _drawIndonesia(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      _CurrencyFlagPalette.redMuted39,
      _CurrencyFlagPalette.white,
    ]);
  }

  void _drawIndia(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      _CurrencyFlagPalette.orangeSoft43,
      _CurrencyFlagPalette.white,
      _CurrencyFlagPalette.greenSurfaceHigh08,
    ]);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.08,
      Paint()
        ..color = _CurrencyFlagPalette.blueSurfaceHigh01
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.018,
    );
  }

  void _drawIceland(Canvas canvas, Size size) {
    _drawNordicCross(
      canvas,
      size,
      background: _CurrencyFlagPalette.blueSurfaceHigh13,
      border: _CurrencyFlagPalette.white,
      cross: _CurrencyFlagPalette.redMuted34,
    );
  }

  void _drawJapan(Canvas canvas, Size size) {
    _fill(canvas, size, _CurrencyFlagPalette.white);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.24,
      _paint(_CurrencyFlagPalette.redSurfaceHigh09),
    );
  }

  void _drawKyrgyzstan(Canvas canvas, Size size) {
    _fill(canvas, size, _CurrencyFlagPalette.redMuted37);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.2,
      _paint(_CurrencyFlagPalette.warmMuted53),
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.07,
      _paint(_CurrencyFlagPalette.redMuted37),
    );
  }

  void _drawSouthKorea(Canvas canvas, Size size) {
    _fill(canvas, size, _CurrencyFlagPalette.white);
    final taegeuk = Rect.fromCircle(
      center: Offset(size.width * 0.5, size.height * 0.5),
      radius: size.shortestSide * 0.18,
    );
    canvas.drawArc(
      taegeuk,
      math.pi,
      math.pi,
      true,
      _paint(_CurrencyFlagPalette.redMuted20),
    );
    canvas.drawArc(
      taegeuk,
      0,
      math.pi,
      true,
      _paint(_CurrencyFlagPalette.blueSurfaceHigh09),
    );
    _drawMiniBars(canvas, size, _CurrencyFlagPalette.neutralInk02);
  }

  void _drawKazakhstan(Canvas canvas, Size size) {
    _fill(canvas, size, _CurrencyFlagPalette.tealMuted01);
    final gold = _paint(_CurrencyFlagPalette.warmMuted52);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * 0.16, size.height), gold);
    canvas.drawCircle(
      Offset(size.width * 0.55, size.height * 0.42),
      size.shortestSide * 0.15,
      gold,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.34,
        size.height * 0.52,
        size.width * 0.42,
        size.height * 0.22,
      ),
      0,
      math.pi,
      false,
      Paint()
        ..color = _CurrencyFlagPalette.warmMuted52
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.05
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawKenya(Canvas canvas, Size size) {
    _drawWeightedHorizontalStripes(canvas, Offset.zero & size, const [
      (_CurrencyFlagPalette.black, 1.0),
      (_CurrencyFlagPalette.white, 0.16),
      (_CurrencyFlagPalette.redSurfaceHigh08, 1.0),
      (_CurrencyFlagPalette.white, 0.16),
      (_CurrencyFlagPalette.greenSurface02, 1.0),
    ]);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.5),
        width: size.width * 0.18,
        height: size.height * 0.38,
      ),
      _paint(_CurrencyFlagPalette.redSurfaceHigh04),
    );
  }

  void _drawSriLanka(Canvas canvas, Size size) {
    _fill(canvas, size, _CurrencyFlagPalette.warmMuted50);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.14,
        size.width * 0.16,
        size.height * 0.72,
      ),
      _paint(_CurrencyFlagPalette.tealSurface01),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.26,
        size.height * 0.14,
        size.width * 0.16,
        size.height * 0.72,
      ),
      _paint(_CurrencyFlagPalette.warmMuted42),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.48,
        size.height * 0.14,
        size.width * 0.42,
        size.height * 0.72,
      ),
      _paint(_CurrencyFlagPalette.redSurfaceHigh05),
    );
  }

  void _drawMorocco(Canvas canvas, Size size) {
    _fill(canvas, size, _CurrencyFlagPalette.redMuted06);
    _drawStar(
      canvas,
      Offset(size.width * 0.5, size.height * 0.52),
      size.shortestSide * 0.17,
      _CurrencyFlagPalette.greenSurface01,
    );
  }

  void _drawMoldova(Canvas canvas, Size size) {
    _drawVerticalStripes(canvas, Offset.zero & size, const [
      _CurrencyFlagPalette.blueSurfaceHigh04,
      _CurrencyFlagPalette.warmMuted52,
      _CurrencyFlagPalette.redMuted21,
    ]);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.06,
      _paint(_CurrencyFlagPalette.warmSurfaceHigh32),
    );
  }

  void _drawMongolia(Canvas canvas, Size size) {
    _drawVerticalStripes(canvas, Offset.zero & size, const [
      _CurrencyFlagPalette.redMuted31,
      _CurrencyFlagPalette.blueSurfaceHigh11,
      _CurrencyFlagPalette.redMuted31,
    ]);
    final gold = _paint(_CurrencyFlagPalette.warmMuted54);
    canvas
      ..drawCircle(
        Offset(size.width * 0.23, size.height * 0.34),
        size.shortestSide * 0.055,
        gold,
      )
      ..drawRect(
        Rect.fromCenter(
          center: Offset(size.width * 0.23, size.height * 0.58),
          width: size.width * 0.07,
          height: size.height * 0.22,
        ),
        gold,
      );
  }

  void _drawMaldives(Canvas canvas, Size size) {
    _fill(canvas, size, _CurrencyFlagPalette.redMuted23);
    final greenRect = Rect.fromLTWH(
      size.width * 0.18,
      size.height * 0.22,
      size.width * 0.64,
      size.height * 0.56,
    );
    canvas.drawRect(greenRect, _paint(_CurrencyFlagPalette.greenSurfaceHigh03));
    _drawCrescent(
      canvas,
      Offset(size.width * 0.52, size.height * 0.5),
      size.shortestSide * 0.13,
      _CurrencyFlagPalette.white,
      _CurrencyFlagPalette.greenSurfaceHigh03,
      cutoutShift: Offset(size.width * 0.045, 0),
    );
  }

  void _drawMexico(Canvas canvas, Size size) {
    _drawVerticalStripes(canvas, Offset.zero & size, const [
      _CurrencyFlagPalette.tealSurface02,
      _CurrencyFlagPalette.white,
      _CurrencyFlagPalette.redMuted21,
    ]);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.055,
      _paint(_CurrencyFlagPalette.warmMuted03),
    );
  }

  void _drawMalaysia(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      _CurrencyFlagPalette.redMuted18,
      _CurrencyFlagPalette.white,
      _CurrencyFlagPalette.redMuted18,
      _CurrencyFlagPalette.white,
      _CurrencyFlagPalette.redMuted18,
      _CurrencyFlagPalette.white,
      _CurrencyFlagPalette.redMuted18,
      _CurrencyFlagPalette.white,
    ]);
    final canton = Rect.fromLTWH(0, 0, size.width * 0.52, size.height * 0.56);
    canvas.drawRect(canton, _paint(_CurrencyFlagPalette.blueSurface01));
    _drawCrescent(
      canvas,
      Offset(canton.width * 0.42, canton.height * 0.5),
      size.shortestSide * 0.11,
      _CurrencyFlagPalette.warmMuted51,
      _CurrencyFlagPalette.blueSurface01,
    );
  }

  void _drawNewZealand(Canvas canvas, Size size) {
    _drawBlueEnsign(canvas, size, starColor: _CurrencyFlagPalette.redMuted19);
  }

  void _drawPhilippines(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      _CurrencyFlagPalette.blueSurfaceHigh06,
      _CurrencyFlagPalette.redMuted21,
    ]);
    _drawTriangle(canvas, [
      Offset.zero,
      Offset(0, size.height),
      Offset(size.width * 0.48, size.height * 0.5),
    ], _CurrencyFlagPalette.white);
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.5),
      size.shortestSide * 0.06,
      _paint(_CurrencyFlagPalette.warmMuted36),
    );
  }

  void _drawPoland(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      _CurrencyFlagPalette.white,
      _CurrencyFlagPalette.redMuted33,
    ]);
  }

  void _drawSerbia(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      _CurrencyFlagPalette.redMuted10,
      _CurrencyFlagPalette.blueSurfaceHigh15,
      _CurrencyFlagPalette.white,
    ]);
    canvas.drawCircle(
      Offset(size.width * 0.34, size.height * 0.48),
      size.shortestSide * 0.07,
      _paint(_CurrencyFlagPalette.warmMuted53),
    );
  }

  void _drawRussia(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      _CurrencyFlagPalette.white,
      _CurrencyFlagPalette.blueSurfaceHigh07,
      _CurrencyFlagPalette.redMuted24,
    ]);
  }

  void _drawSeychelles(Canvas canvas, Size size) {
    final points = [
      (_CurrencyFlagPalette.blueSurfaceHigh08, Offset.zero),
      (_CurrencyFlagPalette.amberSoft11, Offset(size.width * 0.2, 0)),
      (_CurrencyFlagPalette.redMuted25, Offset(size.width * 0.48, 0)),
      (_CurrencyFlagPalette.white, Offset(size.width * 0.74, 0)),
      (_CurrencyFlagPalette.greenSurfaceHigh02, Offset(size.width, 0)),
    ];
    for (var i = 0; i < points.length; i += 1) {
      final nextX = i == points.length - 1 ? size.width : points[i + 1].$2.dx;
      final path = Path()
        ..moveTo(0, size.height)
        ..lineTo(points[i].$2.dx, 0)
        ..lineTo(nextX, 0)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(path, _paint(points[i].$1));
    }
  }

  void _drawSweden(Canvas canvas, Size size) {
    _drawNordicCross(
      canvas,
      size,
      background: _CurrencyFlagPalette.blueSurfaceHigh12,
      cross: _CurrencyFlagPalette.warmMuted38,
    );
  }

  void _drawSingapore(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      _CurrencyFlagPalette.redSoft06,
      _CurrencyFlagPalette.white,
    ]);
    _drawCrescent(
      canvas,
      Offset(size.width * 0.27, size.height * 0.28),
      size.shortestSide * 0.095,
      _CurrencyFlagPalette.white,
      _CurrencyFlagPalette.redSoft06,
    );
    for (final center in [
      Offset(size.width * 0.42, size.height * 0.18),
      Offset(size.width * 0.48, size.height * 0.27),
      Offset(size.width * 0.38, size.height * 0.36),
    ]) {
      canvas.drawCircle(
        center,
        size.shortestSide * 0.018,
        _paint(_CurrencyFlagPalette.white),
      );
    }
  }

  void _drawThailand(Canvas canvas, Size size) {
    _drawWeightedHorizontalStripes(canvas, Offset.zero & size, const [
      (_CurrencyFlagPalette.redSurfaceHigh06, 1.0),
      (_CurrencyFlagPalette.white, 1.0),
      (_CurrencyFlagPalette.blueSurfaceHigh23, 2.0),
      (_CurrencyFlagPalette.white, 1.0),
      (_CurrencyFlagPalette.redSurfaceHigh06, 1.0),
    ]);
  }

  void _drawTajikistan(Canvas canvas, Size size) {
    _drawWeightedHorizontalStripes(canvas, Offset.zero & size, const [
      (_CurrencyFlagPalette.redMuted17, 1.0),
      (_CurrencyFlagPalette.white, 1.5),
      (_CurrencyFlagPalette.greenSurface02, 1.0),
    ]);
    final gold = _paint(_CurrencyFlagPalette.warmMuted35);
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.5),
        radius: size.shortestSide * 0.095,
      ),
      math.pi * 0.08,
      math.pi * 0.84,
      false,
      Paint()
        ..color = _CurrencyFlagPalette.warmMuted35
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.025,
    );
    for (final dx in [0.42, 0.5, 0.58]) {
      canvas.drawCircle(
        Offset(size.width * dx, size.height * 0.42),
        size.shortestSide * 0.018,
        gold,
      );
    }
  }

  void _drawTurkmenistan(Canvas canvas, Size size) {
    _fill(canvas, size, _CurrencyFlagPalette.greenSurfaceHigh04);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.14, 0, size.width * 0.16, size.height),
      _paint(_CurrencyFlagPalette.redSurfaceHigh07),
    );
    for (var i = 0; i < 4; i += 1) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * 0.17,
          size.height * (0.12 + i * 0.2),
          size.width * 0.1,
          size.height * 0.06,
        ),
        _paint(_CurrencyFlagPalette.warmMuted34),
      );
    }
    _drawCrescent(
      canvas,
      Offset(size.width * 0.6, size.height * 0.33),
      size.shortestSide * 0.11,
      _CurrencyFlagPalette.white,
      _CurrencyFlagPalette.greenSurfaceHigh04,
    );
  }

  void _drawTurkey(Canvas canvas, Size size) {
    _fill(canvas, size, _CurrencyFlagPalette.redMuted36);
    final center = Offset(size.width * 0.43, size.height * 0.5);
    canvas.drawCircle(
      center,
      size.shortestSide * 0.2,
      _paint(_CurrencyFlagPalette.white),
    );
    canvas.drawCircle(
      center + Offset(size.width * 0.07, 0),
      size.shortestSide * 0.16,
      _paint(_CurrencyFlagPalette.redMuted36),
    );
    _drawStar(
      canvas,
      Offset(size.width * 0.63, size.height * 0.5),
      size.shortestSide * 0.09,
      _CurrencyFlagPalette.white,
    );
  }

  void _drawTanzania(Canvas canvas, Size size) {
    _fill(canvas, size, _CurrencyFlagPalette.greenMuted04);
    _drawTriangle(canvas, [
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ], _CurrencyFlagPalette.blueMuted01);
    _drawDiagonalBand(
      canvas,
      size,
      _CurrencyFlagPalette.warmMuted36,
      size.shortestSide * 0.24,
    );
    _drawDiagonalBand(
      canvas,
      size,
      _CurrencyFlagPalette.black,
      size.shortestSide * 0.14,
    );
  }

  void _drawUkraine(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      _CurrencyFlagPalette.blueSurfaceHigh10,
      _CurrencyFlagPalette.warmMuted53,
    ]);
  }

  void _drawUnitedStates(Canvas canvas, Size size) {
    const red = _CurrencyFlagPalette.redMuted02;
    const blue = _CurrencyFlagPalette.blueSurfaceHigh28;
    final stripeHeight = size.height / 13;
    for (var i = 0; i < 13; i += 1) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight + 0.5),
        _paint(i.isEven ? red : _CurrencyFlagPalette.white),
      );
    }
    final canton = Rect.fromLTWH(0, 0, size.width * 0.56, stripeHeight * 7);
    canvas.drawRect(canton, _paint(blue));
    final dot = _paint(_CurrencyFlagPalette.white);
    for (var row = 0; row < 4; row += 1) {
      for (var col = 0; col < 5; col += 1) {
        canvas.drawCircle(
          Offset(
            canton.left + canton.width * (0.14 + col * 0.18),
            canton.top + canton.height * (0.18 + row * 0.22),
          ),
          size.shortestSide * 0.012,
          dot,
        );
      }
    }
  }

  void _drawUzbekistan(Canvas canvas, Size size) {
    _fill(canvas, size, _CurrencyFlagPalette.white);
    final blueHeight = size.height * 0.34;
    final greenHeight = size.height * 0.3;
    final redLine = size.height * 0.04;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, blueHeight),
      _paint(_CurrencyFlagPalette.blueMuted03),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, blueHeight, size.width, redLine),
      _paint(_CurrencyFlagPalette.redMuted21),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height - greenHeight - redLine,
        size.width,
        redLine,
      ),
      _paint(_CurrencyFlagPalette.redMuted21),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - greenHeight, size.width, greenHeight),
      _paint(_CurrencyFlagPalette.greenSurfaceHigh05),
    );
    canvas.drawCircle(
      Offset(size.width * 0.26, size.height * 0.17),
      size.shortestSide * 0.08,
      _paint(_CurrencyFlagPalette.white),
    );
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.17),
      size.shortestSide * 0.07,
      _paint(_CurrencyFlagPalette.blueMuted03),
    );
  }

  void _drawVietnam(Canvas canvas, Size size) {
    _fill(canvas, size, _CurrencyFlagPalette.redMuted32);
    _drawStar(
      canvas,
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.2,
      _CurrencyFlagPalette.warmMuted53,
    );
  }

  void _drawVerticalStripes(Canvas canvas, Rect rect, List<Color> colors) {
    final stripeWidth = rect.width / colors.length;
    for (var i = 0; i < colors.length; i += 1) {
      canvas.drawRect(
        Rect.fromLTWH(
          rect.left + i * stripeWidth,
          rect.top,
          stripeWidth + 0.5,
          rect.height,
        ),
        _paint(colors[i]),
      );
    }
  }

  void _drawWeightedHorizontalStripes(
    Canvas canvas,
    Rect rect,
    List<(Color, double)> stripes,
  ) {
    final totalWeight = stripes.fold<double>(
      0,
      (sum, stripe) => sum + stripe.$2,
    );
    var top = rect.top;
    for (final stripe in stripes) {
      final stripeHeight = rect.height * stripe.$2 / totalWeight;
      canvas.drawRect(
        Rect.fromLTWH(rect.left, top, rect.width, stripeHeight + 0.5),
        _paint(stripe.$1),
      );
      top += stripeHeight;
    }
  }

  void _drawHorizontalStripes(Canvas canvas, Rect rect, List<Color> colors) {
    final stripeHeight = rect.height / colors.length;
    for (var i = 0; i < colors.length; i += 1) {
      canvas.drawRect(
        Rect.fromLTWH(
          rect.left,
          rect.top + i * stripeHeight,
          rect.width,
          stripeHeight + 0.5,
        ),
        _paint(colors[i]),
      );
    }
  }

  void _drawNordicCross(
    Canvas canvas,
    Size size, {
    required Color background,
    required Color cross,
    Color? border,
  }) {
    _fill(canvas, size, background);
    final verticalCenter = size.width * 0.38;
    final horizontalCenter = size.height * 0.5;
    if (border != null) {
      final borderWidth = size.shortestSide * 0.2;
      canvas
        ..drawRect(
          Rect.fromLTWH(
            verticalCenter - borderWidth / 2,
            0,
            borderWidth,
            size.height,
          ),
          _paint(border),
        )
        ..drawRect(
          Rect.fromLTWH(
            0,
            horizontalCenter - borderWidth / 2,
            size.width,
            borderWidth,
          ),
          _paint(border),
        );
    }

    final crossWidth = size.shortestSide * 0.12;
    canvas
      ..drawRect(
        Rect.fromLTWH(
          verticalCenter - crossWidth / 2,
          0,
          crossWidth,
          size.height,
        ),
        _paint(cross),
      )
      ..drawRect(
        Rect.fromLTWH(
          0,
          horizontalCenter - crossWidth / 2,
          size.width,
          crossWidth,
        ),
        _paint(cross),
      );
  }

  void _drawTriangle(Canvas canvas, List<Offset> points, Color color) {
    if (points.length < 3) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(path, _paint(color));
  }

  void _drawDiamond(Canvas canvas, Rect rect, Color color) {
    final path = Path()
      ..moveTo(rect.center.dx, rect.top)
      ..lineTo(rect.right, rect.center.dy)
      ..lineTo(rect.center.dx, rect.bottom)
      ..lineTo(rect.left, rect.center.dy)
      ..close();
    canvas.drawPath(path, _paint(color));
  }

  void _drawCrescent(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    Color cutoutColor, {
    Offset? cutoutShift,
  }) {
    canvas.drawCircle(center, radius, _paint(color));
    canvas.drawCircle(
      center + (cutoutShift ?? Offset(radius * 0.36, 0)),
      radius * 0.82,
      _paint(cutoutColor),
    );
  }

  void _drawDiagonal(Canvas canvas, Size size, Color color, double width) {
    final paint = _paint(color)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.square;
    canvas
      ..drawLine(Offset.zero, Offset(size.width, size.height), paint)
      ..drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  void _drawDiagonalBand(Canvas canvas, Size size, Color color, double width) {
    final paint = _paint(color)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), paint);
  }

  void _drawCenteredCross(Canvas canvas, Size size, Color color, double width) {
    final paint = _paint(color);
    canvas
      ..drawRect(
        Rect.fromLTWH((size.width - width) / 2, 0, width, size.height),
        paint,
      )
      ..drawRect(
        Rect.fromLTWH(0, (size.height - width) / 2, size.width, width),
        paint,
      );
  }

  void _drawTinyCross(Canvas canvas, Offset center, double size) {
    final paint = _paint(_CurrencyFlagPalette.redMuted39);
    final width = size * 0.34;
    canvas
      ..drawRect(
        Rect.fromCenter(center: center, width: width, height: size),
        paint,
      )
      ..drawRect(
        Rect.fromCenter(center: center, width: size, height: width),
        paint,
      );
  }

  void _drawBlueEnsign(Canvas canvas, Size size, {required Color starColor}) {
    _fill(canvas, size, _CurrencyFlagPalette.blueSurface02);
    _drawMiniUnionJack(
      canvas,
      Rect.fromLTWH(0, 0, size.width * 0.52, size.height * 0.48),
    );
    final outline = starColor == _CurrencyFlagPalette.white
        ? null
        : _CurrencyFlagPalette.white;
    for (final center in [
      Offset(size.width * 0.7, size.height * 0.28),
      Offset(size.width * 0.82, size.height * 0.48),
      Offset(size.width * 0.68, size.height * 0.68),
      Offset(size.width * 0.9, size.height * 0.7),
    ]) {
      if (outline != null) {
        _drawStar(canvas, center, size.shortestSide * 0.06, outline);
      }
      _drawStar(canvas, center, size.shortestSide * 0.045, starColor);
    }
  }

  void _drawMiniUnionJack(Canvas canvas, Rect rect) {
    canvas
      ..save()
      ..clipRect(rect)
      ..translate(rect.left, rect.top);
    _drawUnitedKingdom(canvas, rect.size);
    canvas.restore();
  }

  void _drawMiniBars(Canvas canvas, Size size, Color color) {
    final paint = _paint(color);
    final barWidth = size.width * 0.18;
    final barHeight = size.height * 0.025;
    for (final base in [
      Offset(size.width * 0.2, size.height * 0.25),
      Offset(size.width * 0.62, size.height * 0.25),
      Offset(size.width * 0.2, size.height * 0.72),
      Offset(size.width * 0.62, size.height * 0.72),
    ]) {
      for (var i = 0; i < 3; i += 1) {
        canvas.drawRect(
          Rect.fromLTWH(
            base.dx,
            base.dy + i * barHeight * 2,
            barWidth,
            barHeight,
          ),
          paint,
        );
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    final innerRadius = radius * 0.42;
    for (var i = 0; i < 10; i += 1) {
      final currentRadius = i.isEven ? radius : innerRadius;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point =
          center +
          Offset(
            math.cos(angle) * currentRadius,
            math.sin(angle) * currentRadius,
          );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, _paint(color));
  }

  void _drawFallbackFlag(
    Canvas canvas,
    Size size,
    String regionCode,
    Color fallbackColor,
  ) {
    final seed = regionCode.codeUnits.fold<int>(
      0,
      (value, codeUnit) => value + codeUnit,
    );
    final first = HSLColor.fromColor(
      fallbackColor,
    ).withLightness(0.42 + (seed % 3) * 0.08).withSaturation(0.62).toColor();
    final second = HSLColor.fromColor(fallbackColor)
        .withHue((HSLColor.fromColor(fallbackColor).hue + 72) % 360)
        .withLightness(0.78)
        .withSaturation(0.46)
        .toColor();
    _drawHorizontalStripes(canvas, Offset.zero & size, [
      first,
      second,
      first.withValues(alpha: 0.88),
    ]);
  }

  void _fill(Canvas canvas, Size size, Color color) {
    canvas.drawRect(Offset.zero & size, _paint(color));
  }

  Paint _paint(Color color) => Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  @override
  bool shouldRepaint(covariant _CurrencyFlagPainter oldDelegate) {
    return oldDelegate.regionCode != regionCode ||
        oldDelegate.fallbackColor != fallbackColor;
  }
}

class _CurrencyFallbackGlyph extends StatelessWidget {
  const _CurrencyFallbackGlyph({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Text(
      '¤',
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: AppTextStyle(
        color: colors.textPrimary,
        fontSize: size <= 30 ? 16 : 22,
        fontWeight: FontWeight.w800,
        height: 1,
        letterSpacing: 0,
      ),
    );
  }
}

CurrencyOption _currencyByCode(List<CurrencyOption> currencies, String code) {
  for (final currency in currencies) {
    if (currency.code == code) return currency;
  }
  return CurrencyOption(
    code: code,
    name: code,
    symbol: _fallbackCurrencySymbols[code] ?? code,
  );
}

List<CurrencyOption> _dedupeCurrencies(List<CurrencyOption> currencies) {
  final seen = <String>{};
  return [
    for (final currency in currencies)
      if (seen.add(currency.code)) currency,
  ];
}

List<CurrencyOption> _filterCurrencies(
  List<CurrencyOption> currencies,
  String query,
  AppLocalizations l10n,
) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return currencies;
  return [
    for (final currency in currencies)
      if (currency.code.toLowerCase().contains(normalizedQuery) ||
          currency.name.toLowerCase().contains(normalizedQuery) ||
          _localizedCurrencyName(
            currency,
            l10n,
          ).toLowerCase().contains(normalizedQuery) ||
          _localizedCurrencyCountry(
            currency,
            l10n,
          ).toLowerCase().contains(normalizedQuery))
        currency,
  ];
}

String _currencySymbol(CurrencyOption option) {
  final symbol = option.symbol.trim();
  if (symbol.isNotEmpty) return symbol;
  return _fallbackCurrencySymbols[option.code] ?? option.code;
}

String _currencyCountry(CurrencyOption option) {
  return _currencyCountries[option.code] ?? option.name;
}

String _localizedCurrencyName(CurrencyOption currency, AppLocalizations l10n) {
  final localized =
      _localizedCurrencyNames[_languageCode(l10n)]?[currency.code];
  return localized ?? currency.name;
}

String _localizedCurrencyCountry(
  CurrencyOption currency,
  AppLocalizations l10n,
) {
  return _localizedCurrencyCountries[_languageCode(l10n)]?[currency.code] ??
      _currencyCountry(currency);
}

String _languageCode(AppLocalizations l10n) {
  return l10n.localeName.toLowerCase().split(RegExp('[-_]')).first;
}

String? _currencyFlagRegion(String code) {
  final regionCode = _currencyFlagRegions[code.toUpperCase()];
  if (regionCode == null || regionCode.length != 2) return null;
  return regionCode;
}

String _quickRatePreview(
  (String, String) pair,
  CurrencyConversionResult? result,
) {
  if (result != null &&
      result.sourceCurrency == pair.$1 &&
      result.targetCurrency == pair.$2) {
    return '1 ${result.sourceCurrency} = ${result.rate} ${result.targetCurrency}';
  }
  return '${_currencySymbol(_currencyByCode(defaultCurrencyOptions, pair.$1))} / ${_currencySymbol(_currencyByCode(defaultCurrencyOptions, pair.$2))}';
}

String _updatedText(
  BuildContext context,
  CurrencyConversionResult? result,
  AppLocalizations l10n,
) {
  if (result?.rateAsOf == null) return '';
  final localeName = Localizations.localeOf(context).toLanguageTag();
  final formatted = DateFormat.yMMMd(
    localeName,
  ).format(result!.rateAsOf!.toLocal());
  return l10n.currencyConverterUpdatedAt(formatted).toUpperCase();
}

Color _avatarColor(String code) {
  return switch (code) {
    'AED' => _CurrencyFlagPalette.tealSurfaceHigh02,
    'AMD' => _CurrencyFlagPalette.warmMuted20,
    'ARS' => _CurrencyFlagPalette.blueSoft05,
    'AUD' => _CurrencyFlagPalette.blueSurfaceHigh24,
    'AZN' => _CurrencyFlagPalette.tealSurfaceHigh09,
    'BRL' => _CurrencyFlagPalette.greenSurfaceHigh10,
    'BYN' => _CurrencyFlagPalette.redMuted05,
    'CAD' => _CurrencyFlagPalette.redMuted13,
    'CHF' => _CurrencyFlagPalette.redMuted08,
    'CNY' => _CurrencyFlagPalette.redMuted26,
    'CUP' => _CurrencyFlagPalette.blueMuted05,
    'CZK' => _CurrencyFlagPalette.blueMuted14,
    'DKK' => _CurrencyFlagPalette.redMuted07,
    'EGP' => _CurrencyFlagPalette.warmMuted11,
    'EUR' => _CurrencyFlagPalette.blueMuted06,
    'GBP' => _CurrencyFlagPalette.violetMuted02,
    'GEL' => _CurrencyFlagPalette.redMuted16,
    'IDR' => _CurrencyFlagPalette.redMuted15,
    'INR' => _CurrencyFlagPalette.warmMuted24,
    'ISK' => _CurrencyFlagPalette.blueMuted10,
    'JPY' => _CurrencyFlagPalette.redSoft02,
    'KES' => _CurrencyFlagPalette.greenMuted06,
    'KGS' => _CurrencyFlagPalette.warmMuted25,
    'KRW' => _CurrencyFlagPalette.blueSoft08,
    'KZT' => _CurrencyFlagPalette.tealSurfaceHigh01,
    'LKR' => _CurrencyFlagPalette.warmMuted13,
    'MAD' => _CurrencyFlagPalette.redMuted01,
    'MDL' => _CurrencyFlagPalette.violetMuted04,
    'MNT' => _CurrencyFlagPalette.blueMuted15,
    'MVR' => _CurrencyFlagPalette.greenSurfaceHigh19,
    'MXN' => _CurrencyFlagPalette.greenMuted05,
    'MYR' => _CurrencyFlagPalette.blueMuted11,
    'NZD' => _CurrencyFlagPalette.blueMuted08,
    'PHP' => _CurrencyFlagPalette.blueMuted12,
    'PLN' => _CurrencyFlagPalette.redMuted03,
    'RSD' => _CurrencyFlagPalette.blueMuted18,
    'RUB' => _CurrencyFlagPalette.blueMuted09,
    'SCR' => _CurrencyFlagPalette.blueMuted22,
    'SEK' => _CurrencyFlagPalette.blueMuted07,
    'SGD' => _CurrencyFlagPalette.redSoft01,
    'THB' => _CurrencyFlagPalette.blueMuted23,
    'TJS' => _CurrencyFlagPalette.greenMuted11,
    'TMT' => _CurrencyFlagPalette.greenSurfaceHigh12,
    'TRY' => _CurrencyFlagPalette.redMuted04,
    'TZS' => _CurrencyFlagPalette.tealMuted08,
    'UAH' => _CurrencyFlagPalette.blueMuted19,
    'USD' => _CurrencyFlagPalette.greenSurfaceHigh16,
    'UZS' => _CurrencyFlagPalette.tealMuted05,
    'VND' => _CurrencyFlagPalette.redMuted14,
    _ => _generatedAvatarColor(code),
  };
}

Color _generatedAvatarColor(String code) {
  final seed = code.codeUnits.fold<int>(
    0,
    (value, codeUnit) => value * 31 + codeUnit,
  );
  return HSLColor.fromAHSL(1, (seed % 360).toDouble(), 0.54, 0.42).toColor();
}

const _fallbackCurrencySymbols = {
  'AED': 'Dh',
  'CNY': '¥',
  'EUR': '€',
  'GBP': '£',
  'KGS': 'som',
  'KZT': '₸',
  'RUB': '₽',
  'TRY': '₺',
  'USD': r'$',
};

const _currencyCountries = {
  'AED': 'United Arab Emirates',
  'CNY': 'China',
  'EUR': 'European Union',
  'GBP': 'United Kingdom',
  'JPY': 'Japan',
  'KGS': 'Kyrgyzstan',
  'KRW': 'South Korea',
  'KZT': 'Kazakhstan',
  'RUB': 'Russia',
  'TRY': 'Turkey',
  'USD': 'United States',
  'UZS': 'Uzbekistan',
};

const _localizedCurrencyNames = {
  'en': {
    'AED': 'UAE Dirham',
    'CNY': 'Chinese Yuan',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'KGS': 'Kyrgyzstani Som',
    'KRW': 'South Korean Won',
    'KZT': 'Kazakhstani Tenge',
    'RUB': 'Russian Ruble',
    'TRY': 'Turkish Lira',
    'USD': 'US Dollar',
    'UZS': 'Uzbekistani Som',
  },
  'ru': {
    'AED': 'Дирхам ОАЭ',
    'CNY': 'Китайский юань',
    'EUR': 'Евро',
    'GBP': 'Британский фунт',
    'JPY': 'Японская иена',
    'KGS': 'Киргизский сом',
    'KRW': 'Южнокорейская вона',
    'KZT': 'Казахстанский тенге',
    'RUB': 'Российский рубль',
    'TRY': 'Турецкая лира',
    'USD': 'Доллар США',
    'UZS': 'Узбекский сум',
  },
  'kk': {
    'AED': 'БАЭ дирхамы',
    'CNY': 'Қытай юані',
    'EUR': 'Еуро',
    'GBP': 'Британ фунты',
    'JPY': 'Жапон иенасы',
    'KGS': 'Қырғыз сомы',
    'KRW': 'Оңтүстік Корея воны',
    'KZT': 'Қазақстан теңгесі',
    'RUB': 'Ресей рублі',
    'TRY': 'Түрік лирасы',
    'USD': 'АҚШ доллары',
    'UZS': 'Өзбек сомы',
  },
};

const _localizedCurrencyCountries = {
  'en': _currencyCountries,
  'ru': {
    'AED': 'ОАЭ',
    'CNY': 'Китай',
    'EUR': 'Европейский союз',
    'GBP': 'Великобритания',
    'JPY': 'Япония',
    'KGS': 'Кыргызстан',
    'KRW': 'Южная Корея',
    'KZT': 'Казахстан',
    'RUB': 'Россия',
    'TRY': 'Турция',
    'USD': 'США',
    'UZS': 'Узбекистан',
  },
  'kk': {
    'AED': 'БАЭ',
    'CNY': 'Қытай',
    'EUR': 'Еуропалық одақ',
    'GBP': 'Ұлыбритания',
    'JPY': 'Жапония',
    'KGS': 'Қырғызстан',
    'KRW': 'Оңтүстік Корея',
    'KZT': 'Қазақстан',
    'RUB': 'Ресей',
    'TRY': 'Түркия',
    'USD': 'АҚШ',
    'UZS': 'Өзбекстан',
  },
};

const _currencyFlagRegions = {
  'AED': 'AE',
  'AMD': 'AM',
  'ARS': 'AR',
  'AUD': 'AU',
  'AZN': 'AZ',
  'BRL': 'BR',
  'BYN': 'BY',
  'CAD': 'CA',
  'CHF': 'CH',
  'CNY': 'CN',
  'CUP': 'CU',
  'CZK': 'CZ',
  'DKK': 'DK',
  'EGP': 'EG',
  'EUR': 'EU',
  'GBP': 'GB',
  'GEL': 'GE',
  'IDR': 'ID',
  'INR': 'IN',
  'ISK': 'IS',
  'JPY': 'JP',
  'KES': 'KE',
  'KGS': 'KG',
  'KRW': 'KR',
  'KZT': 'KZ',
  'LKR': 'LK',
  'MAD': 'MA',
  'MDL': 'MD',
  'MNT': 'MN',
  'MVR': 'MV',
  'MXN': 'MX',
  'MYR': 'MY',
  'NZD': 'NZ',
  'PHP': 'PH',
  'PLN': 'PL',
  'RSD': 'RS',
  'RUB': 'RU',
  'SCR': 'SC',
  'SEK': 'SE',
  'SGD': 'SG',
  'THB': 'TH',
  'TJS': 'TJ',
  'TMT': 'TM',
  'TRY': 'TR',
  'TZS': 'TZ',
  'UAH': 'UA',
  'USD': 'US',
  'UZS': 'UZ',
  'VND': 'VN',
};
