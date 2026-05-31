import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/ui/app_colors.dart';
import '../../features/currency/data/currency_api.dart';
import '../../features/currency/models/currency_conversion_result.dart';
import '../../l10n/generated/app_localizations.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key, CurrencyApi? api}) : _api = api;

  final CurrencyApi? _api;

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  late final CurrencyApi _api = widget._api ?? CurrencyApi();
  final TextEditingController _amountController =
      TextEditingController(text: '15000');
  final FocusNode _amountFocusNode = FocusNode();

  List<CurrencyOption> _currencies = defaultCurrencyOptions;
  CurrencyConversionResult? _result;
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
    unawaited(_loadCurrencies());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencies() async {
    try {
      final currencies = await _api.listCurrencies();
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

  Future<void> _convert() async {
    final l10n = AppLocalizations.of(context)!;
    final amount = _amountController.text.trim().replaceAll(',', '.');
    final numericAmount = num.tryParse(amount);
    if (numericAmount == null || numericAmount < 0) {
      setState(() {
        _errorText = l10n.currencyConverterAmountValidation;
        _result = null;
      });
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
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
      if (!mounted) return;
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = l10n.currencyConverterLoadFailed;
        _isLoading = false;
      });
    }
  }

  void _swapCurrencies() {
    setState(() {
      final previousFrom = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = previousFrom;
      _result = null;
      _errorText = null;
    });
  }

  void _selectPair((String, String) pair) {
    setState(() {
      _fromCurrency = pair.$1;
      _toCurrency = pair.$2;
      _result = null;
      _errorText = null;
    });
    unawaited(_convert());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final isCompact = width < 600;
    final horizontalPadding = isCompact ? 18.0 : 32.0;
    final contentMaxWidth = isCompact ? double.infinity : 680.0;

    return Scaffold(
      backgroundColor: const Color(0xFF160D07),
      appBar: AppBar(
        backgroundColor: const Color(0xFF160D07),
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          l10n.currencyConverterTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            10,
            horizontalPadding,
            24 + mediaQuery.viewInsets.bottom,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.currencyConverterSubtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.35,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ConverterPanel(
                    amountController: _amountController,
                    amountFocusNode: _amountFocusNode,
                    currencies: _currencies,
                    fromCurrency: _fromCurrency,
                    toCurrency: _toCurrency,
                    isCurrencyListLoading: _isCurrencyListLoading,
                    onFromChanged: (value) {
                      setState(() {
                        _fromCurrency = value;
                        _result = null;
                        _errorText = null;
                      });
                    },
                    onToChanged: (value) {
                      setState(() {
                        _toCurrency = value;
                        _result = null;
                        _errorText = null;
                      });
                    },
                    onSwap: _swapCurrencies,
                    onConvert: _convert,
                    isLoading: _isLoading,
                    errorText: _errorText,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 16),
                  if (_result != null)
                    _ResultPanel(result: _result!, l10n: l10n),
                  const SizedBox(height: 18),
                  _PopularPairs(
                    pairs: _popularPairs,
                    selectedFrom: _fromCurrency,
                    selectedTo: _toCurrency,
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

class _ConverterPanel extends StatelessWidget {
  const _ConverterPanel({
    required this.amountController,
    required this.amountFocusNode,
    required this.currencies,
    required this.fromCurrency,
    required this.toCurrency,
    required this.isCurrencyListLoading,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onSwap,
    required this.onConvert,
    required this.isLoading,
    required this.errorText,
    required this.l10n,
  });

  final TextEditingController amountController;
  final FocusNode amountFocusNode;
  final List<CurrencyOption> currencies;
  final String fromCurrency;
  final String toCurrency;
  final bool isCurrencyListLoading;
  final ValueChanged<String> onFromChanged;
  final ValueChanged<String> onToChanged;
  final VoidCallback onSwap;
  final VoidCallback onConvert;
  final bool isLoading;
  final String? errorText;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useStackedSelectors = width < 420;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF21170D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: amountController,
              focusNode: amountFocusNode,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
              decoration: InputDecoration(
                labelText: l10n.currencyConverterAmountLabel,
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(
                  Icons.payments_rounded,
                  color: AppColors.accent,
                ),
                enabledBorder: _inputBorder(),
                focusedBorder: _inputBorder(color: AppColors.accent),
                errorText: errorText,
              ),
              onSubmitted: (_) => onConvert(),
            ),
            const SizedBox(height: 16),
            if (useStackedSelectors)
              Column(
                children: [
                  _CurrencySelector(
                    label: l10n.currencyConverterFromLabel,
                    value: fromCurrency,
                    currencies: currencies,
                    onChanged: onFromChanged,
                    isLoading: isCurrencyListLoading,
                  ),
                  const SizedBox(height: 10),
                  _SwapButton(onSwap: onSwap, l10n: l10n),
                  const SizedBox(height: 10),
                  _CurrencySelector(
                    label: l10n.currencyConverterToLabel,
                    value: toCurrency,
                    currencies: currencies,
                    onChanged: onToChanged,
                    isLoading: isCurrencyListLoading,
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _CurrencySelector(
                      label: l10n.currencyConverterFromLabel,
                      value: fromCurrency,
                      currencies: currencies,
                      onChanged: onFromChanged,
                      isLoading: isCurrencyListLoading,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: _SwapButton(onSwap: onSwap, l10n: l10n),
                  ),
                  Expanded(
                    child: _CurrencySelector(
                      label: l10n.currencyConverterToLabel,
                      value: toCurrency,
                      currencies: currencies,
                      onChanged: onToChanged,
                      isLoading: isCurrencyListLoading,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: isLoading ? null : onConvert,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.calculate_rounded),
              label: Text(
                isLoading
                    ? l10n.currencyConverterLoading
                    : l10n.currencyConverterConvertButton,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _inputBorder({Color? color}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide:
          BorderSide(color: color ?? Colors.white.withValues(alpha: 0.1)),
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  const _CurrencySelector({
    required this.label,
    required this.value,
    required this.currencies,
    required this.onChanged,
    required this.isLoading,
  });

  final String label;
  final String value;
  final List<CurrencyOption> currencies;
  final ValueChanged<String> onChanged;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final effectiveCurrencies = currencies.any((item) => item.code == value)
        ? currencies
        : [
            ...currencies,
            CurrencyOption(code: value, name: value, symbol: value)
          ];

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      iconEnabledColor: AppColors.accent,
      dropdownColor: const Color(0xFF21170D),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
      items: [
        for (final currency in effectiveCurrencies)
          DropdownMenuItem<String>(
            value: currency.code,
            child: Text(
              '${currency.code} ${currency.symbol}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
      ],
      onChanged: isLoading
          ? null
          : (value) {
              if (value != null) onChanged(value);
            },
    );
  }
}

class _SwapButton extends StatelessWidget {
  const _SwapButton({required this.onSwap, required this.l10n});

  final VoidCallback onSwap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: l10n.currencyConverterSwapTooltip,
      child: IconButton.filledTonal(
        onPressed: onSwap,
        icon: const Icon(Icons.swap_vert_rounded),
        color: AppColors.accent,
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.result, required this.l10n});

  final CurrencyConversionResult result;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final updatedAt = result.rateAsOf == null
        ? null
        : DateFormat.yMMMd(localeName)
            .add_Hm()
            .format(result.rateAsOf!.toLocal());

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF2A1D10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.currencyConverterResultTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                '${result.convertedAmount} ${result.targetCurrency}',
                maxLines: 1,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '1 ${result.sourceCurrency} = ${result.rate} ${result.targetCurrency}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.3,
                letterSpacing: 0,
              ),
            ),
            if (result.provider.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                l10n.currencyConverterProvider(result.provider),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textCaption,
                  fontSize: 12,
                  height: 1.3,
                  letterSpacing: 0,
                ),
              ),
            ],
            if (updatedAt != null) ...[
              const SizedBox(height: 6),
              Text(
                l10n.currencyConverterUpdatedAt(updatedAt),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      result.stale ? AppColors.accent : AppColors.textCaption,
                  fontSize: 12,
                  height: 1.3,
                  letterSpacing: 0,
                ),
              ),
            ],
            if (result.stale) ...[
              const SizedBox(height: 10),
              Text(
                l10n.currencyConverterStaleWarning,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  height: 1.35,
                  letterSpacing: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PopularPairs extends StatelessWidget {
  const _PopularPairs({
    required this.pairs,
    required this.selectedFrom,
    required this.selectedTo,
    required this.onSelected,
    required this.l10n,
  });

  final List<(String, String)> pairs;
  final String selectedFrom;
  final String selectedTo;
  final ValueChanged<(String, String)> onSelected;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.currencyConverterPopularPairs,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final pair in pairs)
              ChoiceChip(
                label: Text(
                  '${pair.$1} → ${pair.$2}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                selected: selectedFrom == pair.$1 && selectedTo == pair.$2,
                onSelected: (_) => onSelected(pair),
                selectedColor: AppColors.accent.withValues(alpha: 0.24),
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                labelStyle: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
          ],
        ),
      ],
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.accent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.currencyConverterInfoNotice,
                style: const TextStyle(
                  color: AppColors.textSecondary,
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
