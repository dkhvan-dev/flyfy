import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/ui/app_colors.dart';
import '../../features/currency/data/currency_api.dart';
import '../../features/currency/models/currency_conversion_result.dart';
import '../../l10n/generated/app_localizations.dart';

const _backgroundColor = Color(0xFF1A1008);
const _cardColor = Color(0xFF2A1C10);
const _cardColorAlt = Color(0xFF342416);
const _surfaceColor = Color(0xFF24170C);
const _pillColor = Color(0xFF4B392B);
const _primaryTextColor = Color(0xFFF8E9DC);
const _secondaryTextColor = Color(0xFFCDB9A8);
const _mutedTextColor = Color(0xFF9E8B7D);

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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
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
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
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
                      style: const TextStyle(
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
                            style: const TextStyle(
                              color: _primaryTextColor,
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              hintText: '0',
                              hintStyle: TextStyle(
                                color: _mutedTextColor,
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                              contentPadding: EdgeInsets.zero,
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
                                      color: AppColors.accent,
                                    ),
                                  )
                                : FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      amountText ?? '-',
                                      maxLines: 1,
                                      style: const TextStyle(
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
                  style: const TextStyle(
                    color: AppColors.accent,
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
          style: const TextStyle(
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
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            decoration: BoxDecoration(
              color: _pillColor,
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CurrencyFlagIcon(code: currency, size: 30),
                const SizedBox(width: 8),
                Text(
                  currency,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
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
        color: AppColors.accent,
        shape: const CircleBorder(),
        elevation: 8,
        shadowColor: AppColors.accent.withValues(alpha: 0.35),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onSwap,
          child: const SizedBox(
            width: 58,
            height: 58,
            child: Icon(Icons.swap_vert_rounded, color: Colors.white, size: 30),
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
              color: AppColors.accent,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                rateText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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
                    color: AppColors.accent,
                  ),
                )
              : Text(
                  updatedText,
                  key: ValueKey(updatedText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
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
          style: const TextStyle(
            color: AppColors.accent,
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
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Ink(
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accent.withValues(alpha: 0.18)
                    : _surfaceColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected
                      ? AppColors.accent.withValues(alpha: 0.72)
                      : Colors.white.withValues(alpha: 0.07),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          style: const TextStyle(
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
                          style: const TextStyle(
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.shield_outlined,
              color: AppColors.accent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.currencyConverterInfoNotice,
                style: const TextStyle(
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
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
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
                    padding: const EdgeInsets.symmetric(horizontal: 56),
                    child: Text(
                      l10n.currencyConverterSelectCurrencyTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                style: const TextStyle(
                  color: _primaryTextColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
                decoration: InputDecoration(
                  hintText: l10n.currencyConverterSearchCurrencyHint,
                  hintStyle: const TextStyle(
                    color: _mutedTextColor,
                    letterSpacing: 0,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.accent,
                  ),
                  filled: true,
                  fillColor: _surfaceColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(color: AppColors.accent),
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
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
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
      style: const TextStyle(
        color: AppColors.accent,
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.16)
                  : _surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppColors.accent.withValues(alpha: 0.72)
                    : Colors.white.withValues(alpha: 0.06),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        style: const TextStyle(
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
                        style: const TextStyle(
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
                    color: AppColors.accent,
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
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.currencyConverterNoCurrenciesFound,
          textAlign: TextAlign.center,
          style: const TextStyle(
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

class _CurrencyFlagIcon extends StatelessWidget {
  const _CurrencyFlagIcon({required this.code, required this.size});

  final String code;
  final double size;

  @override
  Widget build(BuildContext context) {
    final flag = _currencyFlagEmoji(code);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _avatarColor(code),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      alignment: Alignment.center,
      child: Semantics(
        label: code,
        child: Text(
          flag,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: TextStyle(
            color: Colors.white,
            fontSize: size <= 30 ? 16 : 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            fontFamilyFallback: const [
              'Apple Color Emoji',
              'Noto Color Emoji',
              'Segoe UI Emoji',
            ],
          ),
        ),
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

String _currencyFlagEmoji(String code) {
  final regionCode = _currencyFlagRegions[code.toUpperCase()];
  if (regionCode == null || regionCode.length != 2) return '¤';
  return String.fromCharCodes(
    regionCode.codeUnits.map((unit) => 0x1F1E6 + unit - 0x41),
  );
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
    'AED' => const Color(0xFF187B5F),
    'CNY' => const Color(0xFFD64C3C),
    'EUR' => const Color(0xFF3157A4),
    'GBP' => const Color(0xFF7342A4),
    'KGS' => const Color(0xFFC45D24),
    'KZT' => const Color(0xFF168D95),
    'RUB' => const Color(0xFF3C6CA8),
    'TRY' => const Color(0xFFB94A48),
    'USD' => const Color(0xFF2D8B63),
    _ => AppColors.accent,
  };
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
