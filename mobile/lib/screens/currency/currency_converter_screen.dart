import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:intl/intl.dart';

import '../../features/currency/data/currency_api.dart';
import '../../features/currency/models/currency_conversion_result.dart';
import '../../features/help_center/data/help_center_api.dart';
import '../../features/help_center/widgets/contextual_help_section.dart';
import '../../l10n/generated/app_localizations.dart';

const _backgroundColor = AppPalette.warmInk35;
const _cardColor = AppPalette.warmSurface16;
const _cardColorAlt = AppPalette.warmSurface45;
const _surfaceColor = AppPalette.warmInk99;
const _pillColor = AppPalette.warmSurfaceHigh02;
const _primaryTextColor = AppPalette.orangeWash18;
const _secondaryTextColor = AppPalette.orangeSoft31;
const _mutedTextColor = AppPalette.orangeMuted01;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 600;
    final horizontalPadding = isCompact ? 18.0 : 32.0;
    final contentMaxWidth = isCompact ? double.infinity : 680.0;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: _backgroundColor,
        foregroundColor: _primaryTextColor,
        elevation: 0,
        title: Text(
          l10n.currencyConverterTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const AppTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                    fromOption: _currencyByCode(_currencies, _fromCurrency),
                    toOption: _currencyByCode(_currencies, _toCurrency),
                    result: _result,
                    isLoading: _isLoading,
                    isCurrencyListLoading: _isCurrencyListLoading,
                    errorText: _errorText,
                    onAmountChanged: (_) => _scheduleConvert(),
                    onAmountSubmitted: (_) =>
                        _convertNow(dismissKeyboard: true),
                    onFromTap: () => _openCurrencyPicker(isSource: true),
                    onToTap: () => _openCurrencyPicker(isSource: false),
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
                  backgroundColor: _cardColor,
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
                  backgroundColor: _cardColorAlt,
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
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: backgroundColor,
        borderRadius: AppBorderRadius.circular(28),
        border: Border.all(color: AppPalette.white.withValues(alpha: 0.07)),
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
                      style: const AppTextStyle(
                        color: _mutedTextColor,
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
                            style: const AppTextStyle(
                              color: _primaryTextColor,
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                            decoration: const AppInputDecoration(
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              hintText: '0',
                              hintStyle: AppTextStyle(
                                color: _mutedTextColor,
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
                                ? const SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: AppPalette.primary,
                                    ),
                                  )
                                : FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      amountText ?? '-',
                                      maxLines: 1,
                                      style: const AppTextStyle(
                                        color: _primaryTextColor,
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
                  style: const AppTextStyle(
                    color: AppPalette.primary,
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
    return SizedBox(
      width: 56,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          symbol,
          maxLines: 1,
          style: const AppTextStyle(
            color: _primaryTextColor,
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
    return Tooltip(
      message: option.name,
      child: Material(
        color: AppPalette.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: AppBorderRadius.circular(999),
          child: Ink(
            decoration: AppBoxDecoration(
              color: _pillColor,
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
                  style: const AppTextStyle(
                    color: _primaryTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _primaryTextColor.withValues(alpha: 0.84),
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
    return Tooltip(
      message: l10n.currencyConverterSwapTooltip,
      child: Material(
        color: AppPalette.primary,
        shape: const CircleBorder(),
        elevation: 8,
        shadowColor: AppPalette.primary.withValues(alpha: 0.35),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onSwap,
          child: const SizedBox(
            width: 58,
            height: 58,
            child: Icon(
              Icons.swap_vert_rounded,
              color: AppPalette.white,
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
            const Icon(
              Icons.info_outline_rounded,
              color: AppPalette.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                rateText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const AppTextStyle(
                  color: _secondaryTextColor,
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
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppPalette.primary,
                  ),
                )
              : Text(
                  updatedText,
                  key: ValueKey(updatedText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const AppTextStyle(
                    color: _mutedTextColor,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.currencyConverterQuickSwitch.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const AppTextStyle(
            color: AppPalette.primary,
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
    return Tooltip(
      message: '${sourceOption.name} / ${targetOption.name}',
      child: SizedBox(
        width: width,
        child: Material(
          color: AppPalette.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppBorderRadius.circular(22),
            child: Ink(
              decoration: AppBoxDecoration(
                color: selected
                    ? AppPalette.primary.withValues(alpha: 0.18)
                    : _surfaceColor,
                borderRadius: AppBorderRadius.circular(22),
                border: Border.all(
                  color: selected
                      ? AppPalette.primary.withValues(alpha: 0.72)
                      : AppPalette.white.withValues(alpha: 0.07),
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
                          style: const AppTextStyle(
                            color: _primaryTextColor,
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
                          style: const AppTextStyle(
                            color: _secondaryTextColor,
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
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: AppPalette.white.withValues(alpha: 0.05),
        borderRadius: AppBorderRadius.circular(18),
        border: Border.all(color: AppPalette.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.shield_outlined,
              color: AppPalette.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.currencyConverterInfoNotice,
                style: const AppTextStyle(
                  color: _secondaryTextColor,
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
    final allCurrencies = _dedupeCurrencies(widget.currencies);
    final filteredCurrencies = _filterCurrencies(allCurrencies, _query, l10n);
    final recentCurrencies = [
      for (final code in widget.recentCurrencyCodes)
        if (allCurrencies.any((item) => item.code == code))
          _currencyByCode(allCurrencies, code),
    ];
    final showRecent = _query.trim().isEmpty && recentCurrencies.isNotEmpty;

    return Scaffold(
      backgroundColor: _backgroundColor,
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
                      color: _primaryTextColor,
                    ),
                  ),
                  Padding(
                    padding: const AppEdgeInsets.symmetric(horizontal: 56),
                    child: Text(
                      l10n.currencyConverterSelectCurrencyTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const AppTextStyle(
                        color: _primaryTextColor,
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
                style: const AppTextStyle(
                  color: _primaryTextColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
                decoration: AppInputDecoration(
                  hintText: l10n.currencyConverterSearchCurrencyHint,
                  hintStyle: const AppTextStyle(
                    color: _mutedTextColor,
                    letterSpacing: 0,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppPalette.primary,
                  ),
                  filled: true,
                  fillColor: _surfaceColor,
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
                    borderSide: const BorderSide(color: AppPalette.primary),
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
    return Text(
      title.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const AppTextStyle(
        color: AppPalette.primary,
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
    final name = _localizedCurrencyName(currency, l10n);
    final country = _localizedCurrencyCountry(currency, l10n);

    return Padding(
      padding: const AppEdgeInsets.only(bottom: 10),
      child: Material(
        color: AppPalette.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppBorderRadius.circular(20),
          child: Ink(
            decoration: AppBoxDecoration(
              color: selected
                  ? AppPalette.primary.withValues(alpha: 0.16)
                  : _surfaceColor,
              borderRadius: AppBorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppPalette.primary.withValues(alpha: 0.72)
                    : AppPalette.white.withValues(alpha: 0.06),
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
                        style: const AppTextStyle(
                          color: _primaryTextColor,
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
                        style: const AppTextStyle(
                          color: _secondaryTextColor,
                          fontSize: 12.5,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppPalette.primary,
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
    return Center(
      child: Padding(
        padding: const AppEdgeInsets.all(24),
        child: Text(
          l10n.currencyConverterNoCurrenciesFound,
          textAlign: TextAlign.center,
          style: const AppTextStyle(
            color: _secondaryTextColor,
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

class _CurrencyFlagIcon extends StatelessWidget {
  const _CurrencyFlagIcon({required this.code, required this.size});

  final String code;
  final double size;

  @override
  Widget build(BuildContext context) {
    final regionCode = _currencyFlagRegion(code);
    final badgeColor = _avatarColor(code);
    final innerSize = size * _compactCurrencyFlagScale;

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          color: badgeColor.withValues(alpha: 0.24),
          shape: BoxShape.circle,
          border: Border.all(color: AppPalette.white.withValues(alpha: 0.16)),
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
                        color: AppPalette.white.withValues(alpha: 0.42),
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
    _fill(canvas, size, AppPalette.greenSurfaceHigh01);
    _drawHorizontalStripes(
      canvas,
      Rect.fromLTWH(redWidth, 0, size.width - redWidth, size.height),
      const [AppPalette.greenSurfaceHigh06, AppPalette.white, AppPalette.black],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, redWidth, size.height),
      _paint(AppPalette.redMuted39),
    );
  }

  void _drawArmenia(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      AppPalette.redMuted30,
      AppPalette.blueSurfaceHigh05,
      AppPalette.warmMuted31,
    ]);
  }

  void _drawArgentina(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      AppPalette.blueSoft09,
      AppPalette.white,
      AppPalette.blueSoft09,
    ]);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.08,
      _paint(AppPalette.warmMuted33),
    );
  }

  void _drawAustralia(Canvas canvas, Size size) {
    _drawBlueEnsign(canvas, size, starColor: AppPalette.white);
  }

  void _drawAzerbaijan(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      AppPalette.tealMuted02,
      AppPalette.redSoft06,
      AppPalette.greenMuted09,
    ]);
    _drawCrescent(
      canvas,
      Offset(size.width * 0.45, size.height * 0.5),
      size.shortestSide * 0.12,
      AppPalette.white,
      AppPalette.redSoft06,
    );
    _drawStar(
      canvas,
      Offset(size.width * 0.63, size.height * 0.5),
      size.shortestSide * 0.055,
      AppPalette.white,
    );
  }

  void _drawBrazil(Canvas canvas, Size size) {
    _fill(canvas, size, AppPalette.greenSurfaceHigh07);
    _drawDiamond(
      canvas,
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.5),
        width: size.width * 0.72,
        height: size.height * 0.5,
      ),
      AppPalette.warmMuted56,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.17,
      _paint(AppPalette.blueSurfaceHigh02),
    );
  }

  void _drawBelarus(Canvas canvas, Size size) {
    _drawWeightedHorizontalStripes(canvas, Offset.zero & size, const [
      (AppPalette.redMuted12, 2.0),
      (AppPalette.greenMuted07, 1.0),
    ]);
    final ornamentWidth = size.width * 0.18;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, ornamentWidth, size.height),
      _paint(AppPalette.white),
    );
    for (var i = 0; i < 4; i += 1) {
      _drawDiamond(
        canvas,
        Rect.fromCenter(
          center: Offset(ornamentWidth * 0.5, size.height * (0.16 + i * 0.22)),
          width: ornamentWidth * 0.45,
          height: ornamentWidth * 0.45,
        ),
        AppPalette.redMuted12,
      );
    }
  }

  void _drawCanada(Canvas canvas, Size size) {
    _drawVerticalStripes(canvas, Offset.zero & size, const [
      AppPalette.redMuted28,
      AppPalette.white,
      AppPalette.redMuted28,
    ]);
    _drawStar(
      canvas,
      Offset(size.width * 0.5, size.height * 0.52),
      size.shortestSide * 0.14,
      AppPalette.redMuted28,
    );
  }

  void _drawSwitzerland(Canvas canvas, Size size) {
    _fill(canvas, size, AppPalette.redMuted39);
    _drawCenteredCross(
      canvas,
      size,
      AppPalette.white,
      size.shortestSide * 0.18,
    );
  }

  void _drawChina(Canvas canvas, Size size) {
    _fill(canvas, size, AppPalette.redMuted35);
    _drawStar(
      canvas,
      Offset(size.width * 0.32, size.height * 0.34),
      size.shortestSide * 0.16,
      AppPalette.warmMuted55,
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
        AppPalette.warmMuted55,
      );
    }
  }

  void _drawEuropeanUnion(Canvas canvas, Size size) {
    _fill(canvas, size, AppPalette.blueMuted04);
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final orbit = size.shortestSide * 0.24;
    final dotRadius = size.shortestSide * 0.025;
    for (var i = 0; i < 12; i += 1) {
      final angle = -math.pi / 2 + (math.pi * 2 * i / 12);
      canvas.drawCircle(
        center + Offset(math.cos(angle) * orbit, math.sin(angle) * orbit),
        dotRadius,
        _paint(AppPalette.warmMuted51),
      );
    }
  }

  void _drawUnitedKingdom(Canvas canvas, Size size) {
    _fill(canvas, size, AppPalette.blueSurface02);
    _drawDiagonal(canvas, size, AppPalette.white, size.shortestSide * 0.17);
    _drawDiagonal(
      canvas,
      size,
      AppPalette.redMuted11,
      size.shortestSide * 0.08,
    );
    _drawCenteredCross(canvas, size, AppPalette.white, size.shortestSide * 0.2);
    _drawCenteredCross(
      canvas,
      size,
      AppPalette.redMuted11,
      size.shortestSide * 0.11,
    );
  }

  void _drawCuba(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      AppPalette.blueSurfaceHigh03,
      AppPalette.white,
      AppPalette.blueSurfaceHigh03,
      AppPalette.white,
      AppPalette.blueSurfaceHigh03,
    ]);
    _drawTriangle(canvas, [
      Offset.zero,
      Offset(0, size.height),
      Offset(size.width * 0.45, size.height * 0.5),
    ], AppPalette.redMuted22);
    _drawStar(
      canvas,
      Offset(size.width * 0.16, size.height * 0.5),
      size.shortestSide * 0.065,
      AppPalette.white,
    );
  }

  void _drawCzechia(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      AppPalette.white,
      AppPalette.redMuted27,
    ]);
    _drawTriangle(canvas, [
      Offset.zero,
      Offset(0, size.height),
      Offset(size.width * 0.54, size.height * 0.5),
    ], AppPalette.blueSurfaceHigh17);
  }

  void _drawDenmark(Canvas canvas, Size size) {
    _drawNordicCross(
      canvas,
      size,
      background: AppPalette.redMuted09,
      cross: AppPalette.white,
    );
  }

  void _drawEgypt(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      AppPalette.redMuted21,
      AppPalette.white,
      AppPalette.black,
    ]);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.055,
      _paint(AppPalette.warmSurfaceHigh38),
    );
  }

  void _drawGeorgia(Canvas canvas, Size size) {
    _fill(canvas, size, AppPalette.white);
    _drawCenteredCross(canvas, size, AppPalette.redMuted39, size.width * 0.13);
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
      AppPalette.redMuted39,
      AppPalette.white,
    ]);
  }

  void _drawIndia(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      AppPalette.orangeSoft43,
      AppPalette.white,
      AppPalette.greenSurfaceHigh08,
    ]);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.08,
      Paint()
        ..color = AppPalette.blueSurfaceHigh01
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.018,
    );
  }

  void _drawIceland(Canvas canvas, Size size) {
    _drawNordicCross(
      canvas,
      size,
      background: AppPalette.blueSurfaceHigh13,
      border: AppPalette.white,
      cross: AppPalette.redMuted34,
    );
  }

  void _drawJapan(Canvas canvas, Size size) {
    _fill(canvas, size, AppPalette.white);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.24,
      _paint(AppPalette.redSurfaceHigh09),
    );
  }

  void _drawKyrgyzstan(Canvas canvas, Size size) {
    _fill(canvas, size, AppPalette.redMuted37);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.2,
      _paint(AppPalette.warmMuted53),
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.07,
      _paint(AppPalette.redMuted37),
    );
  }

  void _drawSouthKorea(Canvas canvas, Size size) {
    _fill(canvas, size, AppPalette.white);
    final taegeuk = Rect.fromCircle(
      center: Offset(size.width * 0.5, size.height * 0.5),
      radius: size.shortestSide * 0.18,
    );
    canvas.drawArc(
      taegeuk,
      math.pi,
      math.pi,
      true,
      _paint(AppPalette.redMuted20),
    );
    canvas.drawArc(
      taegeuk,
      0,
      math.pi,
      true,
      _paint(AppPalette.blueSurfaceHigh09),
    );
    _drawMiniBars(canvas, size, AppPalette.neutralInk02);
  }

  void _drawKazakhstan(Canvas canvas, Size size) {
    _fill(canvas, size, AppPalette.tealMuted01);
    final gold = _paint(AppPalette.warmMuted52);
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
        ..color = AppPalette.warmMuted52
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.05
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawKenya(Canvas canvas, Size size) {
    _drawWeightedHorizontalStripes(canvas, Offset.zero & size, const [
      (AppPalette.black, 1.0),
      (AppPalette.white, 0.16),
      (AppPalette.redSurfaceHigh08, 1.0),
      (AppPalette.white, 0.16),
      (AppPalette.greenSurface02, 1.0),
    ]);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.5),
        width: size.width * 0.18,
        height: size.height * 0.38,
      ),
      _paint(AppPalette.redSurfaceHigh04),
    );
  }

  void _drawSriLanka(Canvas canvas, Size size) {
    _fill(canvas, size, AppPalette.warmMuted50);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.14,
        size.width * 0.16,
        size.height * 0.72,
      ),
      _paint(AppPalette.tealSurface01),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.26,
        size.height * 0.14,
        size.width * 0.16,
        size.height * 0.72,
      ),
      _paint(AppPalette.warmMuted42),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.48,
        size.height * 0.14,
        size.width * 0.42,
        size.height * 0.72,
      ),
      _paint(AppPalette.redSurfaceHigh05),
    );
  }

  void _drawMorocco(Canvas canvas, Size size) {
    _fill(canvas, size, AppPalette.redMuted06);
    _drawStar(
      canvas,
      Offset(size.width * 0.5, size.height * 0.52),
      size.shortestSide * 0.17,
      AppPalette.greenSurface01,
    );
  }

  void _drawMoldova(Canvas canvas, Size size) {
    _drawVerticalStripes(canvas, Offset.zero & size, const [
      AppPalette.blueSurfaceHigh04,
      AppPalette.warmMuted52,
      AppPalette.redMuted21,
    ]);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.06,
      _paint(AppPalette.warmSurfaceHigh32),
    );
  }

  void _drawMongolia(Canvas canvas, Size size) {
    _drawVerticalStripes(canvas, Offset.zero & size, const [
      AppPalette.redMuted31,
      AppPalette.blueSurfaceHigh11,
      AppPalette.redMuted31,
    ]);
    final gold = _paint(AppPalette.warmMuted54);
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
    _fill(canvas, size, AppPalette.redMuted23);
    final greenRect = Rect.fromLTWH(
      size.width * 0.18,
      size.height * 0.22,
      size.width * 0.64,
      size.height * 0.56,
    );
    canvas.drawRect(greenRect, _paint(AppPalette.greenSurfaceHigh03));
    _drawCrescent(
      canvas,
      Offset(size.width * 0.52, size.height * 0.5),
      size.shortestSide * 0.13,
      AppPalette.white,
      AppPalette.greenSurfaceHigh03,
      cutoutShift: Offset(size.width * 0.045, 0),
    );
  }

  void _drawMexico(Canvas canvas, Size size) {
    _drawVerticalStripes(canvas, Offset.zero & size, const [
      AppPalette.tealSurface02,
      AppPalette.white,
      AppPalette.redMuted21,
    ]);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.055,
      _paint(AppPalette.warmMuted03),
    );
  }

  void _drawMalaysia(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      AppPalette.redMuted18,
      AppPalette.white,
      AppPalette.redMuted18,
      AppPalette.white,
      AppPalette.redMuted18,
      AppPalette.white,
      AppPalette.redMuted18,
      AppPalette.white,
    ]);
    final canton = Rect.fromLTWH(0, 0, size.width * 0.52, size.height * 0.56);
    canvas.drawRect(canton, _paint(AppPalette.blueSurface01));
    _drawCrescent(
      canvas,
      Offset(canton.width * 0.42, canton.height * 0.5),
      size.shortestSide * 0.11,
      AppPalette.warmMuted51,
      AppPalette.blueSurface01,
    );
  }

  void _drawNewZealand(Canvas canvas, Size size) {
    _drawBlueEnsign(canvas, size, starColor: AppPalette.redMuted19);
  }

  void _drawPhilippines(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      AppPalette.blueSurfaceHigh06,
      AppPalette.redMuted21,
    ]);
    _drawTriangle(canvas, [
      Offset.zero,
      Offset(0, size.height),
      Offset(size.width * 0.48, size.height * 0.5),
    ], AppPalette.white);
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.5),
      size.shortestSide * 0.06,
      _paint(AppPalette.warmMuted36),
    );
  }

  void _drawPoland(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      AppPalette.white,
      AppPalette.redMuted33,
    ]);
  }

  void _drawSerbia(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      AppPalette.redMuted10,
      AppPalette.blueSurfaceHigh15,
      AppPalette.white,
    ]);
    canvas.drawCircle(
      Offset(size.width * 0.34, size.height * 0.48),
      size.shortestSide * 0.07,
      _paint(AppPalette.warmMuted53),
    );
  }

  void _drawRussia(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      AppPalette.white,
      AppPalette.blueSurfaceHigh07,
      AppPalette.redMuted24,
    ]);
  }

  void _drawSeychelles(Canvas canvas, Size size) {
    final points = [
      (AppPalette.blueSurfaceHigh08, Offset.zero),
      (AppPalette.amberSoft11, Offset(size.width * 0.2, 0)),
      (AppPalette.redMuted25, Offset(size.width * 0.48, 0)),
      (AppPalette.white, Offset(size.width * 0.74, 0)),
      (AppPalette.greenSurfaceHigh02, Offset(size.width, 0)),
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
      background: AppPalette.blueSurfaceHigh12,
      cross: AppPalette.warmMuted38,
    );
  }

  void _drawSingapore(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      AppPalette.redSoft06,
      AppPalette.white,
    ]);
    _drawCrescent(
      canvas,
      Offset(size.width * 0.27, size.height * 0.28),
      size.shortestSide * 0.095,
      AppPalette.white,
      AppPalette.redSoft06,
    );
    for (final center in [
      Offset(size.width * 0.42, size.height * 0.18),
      Offset(size.width * 0.48, size.height * 0.27),
      Offset(size.width * 0.38, size.height * 0.36),
    ]) {
      canvas.drawCircle(
        center,
        size.shortestSide * 0.018,
        _paint(AppPalette.white),
      );
    }
  }

  void _drawThailand(Canvas canvas, Size size) {
    _drawWeightedHorizontalStripes(canvas, Offset.zero & size, const [
      (AppPalette.redSurfaceHigh06, 1.0),
      (AppPalette.white, 1.0),
      (AppPalette.blueSurfaceHigh23, 2.0),
      (AppPalette.white, 1.0),
      (AppPalette.redSurfaceHigh06, 1.0),
    ]);
  }

  void _drawTajikistan(Canvas canvas, Size size) {
    _drawWeightedHorizontalStripes(canvas, Offset.zero & size, const [
      (AppPalette.redMuted17, 1.0),
      (AppPalette.white, 1.5),
      (AppPalette.greenSurface02, 1.0),
    ]);
    final gold = _paint(AppPalette.warmMuted35);
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.5),
        radius: size.shortestSide * 0.095,
      ),
      math.pi * 0.08,
      math.pi * 0.84,
      false,
      Paint()
        ..color = AppPalette.warmMuted35
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
    _fill(canvas, size, AppPalette.greenSurfaceHigh04);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.14, 0, size.width * 0.16, size.height),
      _paint(AppPalette.redSurfaceHigh07),
    );
    for (var i = 0; i < 4; i += 1) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * 0.17,
          size.height * (0.12 + i * 0.2),
          size.width * 0.1,
          size.height * 0.06,
        ),
        _paint(AppPalette.warmMuted34),
      );
    }
    _drawCrescent(
      canvas,
      Offset(size.width * 0.6, size.height * 0.33),
      size.shortestSide * 0.11,
      AppPalette.white,
      AppPalette.greenSurfaceHigh04,
    );
  }

  void _drawTurkey(Canvas canvas, Size size) {
    _fill(canvas, size, AppPalette.redMuted36);
    final center = Offset(size.width * 0.43, size.height * 0.5);
    canvas.drawCircle(
      center,
      size.shortestSide * 0.2,
      _paint(AppPalette.white),
    );
    canvas.drawCircle(
      center + Offset(size.width * 0.07, 0),
      size.shortestSide * 0.16,
      _paint(AppPalette.redMuted36),
    );
    _drawStar(
      canvas,
      Offset(size.width * 0.63, size.height * 0.5),
      size.shortestSide * 0.09,
      AppPalette.white,
    );
  }

  void _drawTanzania(Canvas canvas, Size size) {
    _fill(canvas, size, AppPalette.greenMuted04);
    _drawTriangle(canvas, [
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ], AppPalette.blueMuted01);
    _drawDiagonalBand(
      canvas,
      size,
      AppPalette.warmMuted36,
      size.shortestSide * 0.24,
    );
    _drawDiagonalBand(canvas, size, AppPalette.black, size.shortestSide * 0.14);
  }

  void _drawUkraine(Canvas canvas, Size size) {
    _drawHorizontalStripes(canvas, Offset.zero & size, const [
      AppPalette.blueSurfaceHigh10,
      AppPalette.warmMuted53,
    ]);
  }

  void _drawUnitedStates(Canvas canvas, Size size) {
    const red = AppPalette.redMuted02;
    const blue = AppPalette.blueSurfaceHigh28;
    final stripeHeight = size.height / 13;
    for (var i = 0; i < 13; i += 1) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight + 0.5),
        _paint(i.isEven ? red : AppPalette.white),
      );
    }
    final canton = Rect.fromLTWH(0, 0, size.width * 0.56, stripeHeight * 7);
    canvas.drawRect(canton, _paint(blue));
    final dot = _paint(AppPalette.white);
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
    _fill(canvas, size, AppPalette.white);
    final blueHeight = size.height * 0.34;
    final greenHeight = size.height * 0.3;
    final redLine = size.height * 0.04;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, blueHeight),
      _paint(AppPalette.blueMuted03),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, blueHeight, size.width, redLine),
      _paint(AppPalette.redMuted21),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height - greenHeight - redLine,
        size.width,
        redLine,
      ),
      _paint(AppPalette.redMuted21),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - greenHeight, size.width, greenHeight),
      _paint(AppPalette.greenSurfaceHigh05),
    );
    canvas.drawCircle(
      Offset(size.width * 0.26, size.height * 0.17),
      size.shortestSide * 0.08,
      _paint(AppPalette.white),
    );
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.17),
      size.shortestSide * 0.07,
      _paint(AppPalette.blueMuted03),
    );
  }

  void _drawVietnam(Canvas canvas, Size size) {
    _fill(canvas, size, AppPalette.redMuted32);
    _drawStar(
      canvas,
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.2,
      AppPalette.warmMuted53,
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
    final paint = _paint(AppPalette.redMuted39);
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
    _fill(canvas, size, AppPalette.blueSurface02);
    _drawMiniUnionJack(
      canvas,
      Rect.fromLTWH(0, 0, size.width * 0.52, size.height * 0.48),
    );
    final outline = starColor == AppPalette.white ? null : AppPalette.white;
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
    return Text(
      '¤',
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: AppTextStyle(
        color: _primaryTextColor,
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
    'AED' => AppPalette.tealSurfaceHigh02,
    'AMD' => AppPalette.warmMuted20,
    'ARS' => AppPalette.blueSoft05,
    'AUD' => AppPalette.blueSurfaceHigh24,
    'AZN' => AppPalette.tealSurfaceHigh09,
    'BRL' => AppPalette.greenSurfaceHigh10,
    'BYN' => AppPalette.redMuted05,
    'CAD' => AppPalette.redMuted13,
    'CHF' => AppPalette.redMuted08,
    'CNY' => AppPalette.redMuted26,
    'CUP' => AppPalette.blueMuted05,
    'CZK' => AppPalette.blueMuted14,
    'DKK' => AppPalette.redMuted07,
    'EGP' => AppPalette.warmMuted11,
    'EUR' => AppPalette.blueMuted06,
    'GBP' => AppPalette.violetMuted02,
    'GEL' => AppPalette.redMuted16,
    'IDR' => AppPalette.redMuted15,
    'INR' => AppPalette.warmMuted24,
    'ISK' => AppPalette.blueMuted10,
    'JPY' => AppPalette.redSoft02,
    'KES' => AppPalette.greenMuted06,
    'KGS' => AppPalette.warmMuted25,
    'KRW' => AppPalette.blueSoft08,
    'KZT' => AppPalette.tealSurfaceHigh01,
    'LKR' => AppPalette.warmMuted13,
    'MAD' => AppPalette.redMuted01,
    'MDL' => AppPalette.violetMuted04,
    'MNT' => AppPalette.blueMuted15,
    'MVR' => AppPalette.greenSurfaceHigh19,
    'MXN' => AppPalette.greenMuted05,
    'MYR' => AppPalette.blueMuted11,
    'NZD' => AppPalette.blueMuted08,
    'PHP' => AppPalette.blueMuted12,
    'PLN' => AppPalette.redMuted03,
    'RSD' => AppPalette.blueMuted18,
    'RUB' => AppPalette.blueMuted09,
    'SCR' => AppPalette.blueMuted22,
    'SEK' => AppPalette.blueMuted07,
    'SGD' => AppPalette.redSoft01,
    'THB' => AppPalette.blueMuted23,
    'TJS' => AppPalette.greenMuted11,
    'TMT' => AppPalette.greenSurfaceHigh12,
    'TRY' => AppPalette.redMuted04,
    'TZS' => AppPalette.tealMuted08,
    'UAH' => AppPalette.blueMuted19,
    'USD' => AppPalette.greenSurfaceHigh16,
    'UZS' => AppPalette.tealMuted05,
    'VND' => AppPalette.redMuted14,
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
