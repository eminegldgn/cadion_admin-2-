import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/admin_api_service.dart';

class PlatformWalletScreen extends StatefulWidget {
  const PlatformWalletScreen({
    super.key,
  });

  @override
  State<PlatformWalletScreen> createState() =>
      _PlatformWalletScreenState();
}

class _PlatformWalletScreenState
    extends State<PlatformWalletScreen> {

  final AdminApiService _apiService =
  AdminApiService();

  final TextEditingController
  _ibanController =
  TextEditingController();

  final TextEditingController
  _amountController =
  TextEditingController();

  bool _isLoading = true;
  bool _isWithdrawing = false;
  bool _hasError = false;

  double _balance = 0;
  double _totalEarned = 0;
  double _totalWithdrawn = 0;

  List<Map<String, dynamic>>
  _transactions = [];

  @override
  void initState() {
    super.initState();

    _loadWallet();
  }

  @override
  void dispose() {
    _ibanController.dispose();
    _amountController.dispose();

    super.dispose();
  }

  // =========================================================
  // PARA FORMAT
  // =========================================================

  String _money(
      dynamic value,
      ) {
    final double amount =
        double.tryParse(
          value?.toString() ?? '',
        ) ??
            0;

    return '${amount.toStringAsFixed(2).replaceAll('.', ',')} TL';
  }

  // =========================================================
  // TARİH FORMAT
  // =========================================================

  String _date(
      dynamic value,
      ) {
    if (value == null) {
      return '-';
    }

    final DateTime? date =
    DateTime.tryParse(
      value.toString(),
    );

    if (date == null) {
      return value.toString();
    }

    String twoDigits(
        int number,
        ) {
      return number
          .toString()
          .padLeft(
        2,
        '0',
      );
    }

    return '${twoDigits(date.day)}.'
        '${twoDigits(date.month)}.'
        '${date.year} '
        '${twoDigits(date.hour)}:'
        '${twoDigits(date.minute)}';
  }

  // =========================================================
  // PLATFORM CÜZDANINI GETİR
  // =========================================================

  Future<void> _loadWallet() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final Map<String, dynamic>
      result =
      await _apiService
          .getPlatformWallet();

      if (!mounted) {
        return;
      }

      if (
      result['success'] != true
      ) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });

        return;
      }

      final Map<String, dynamic>
      wallet =
      result['wallet'] is Map
          ? Map<String, dynamic>.from(
        result['wallet'],
      )
          : <String, dynamic>{};

      final List<dynamic>
      rawTransactions =
      result['transactions'] is List
          ? List<dynamic>.from(
        result['transactions'],
      )
          : <dynamic>[];

      final List<
          Map<String, dynamic>>
      transactions =
      rawTransactions
          .whereType<Map>()
          .map(
            (Map item) =>
        Map<String, dynamic>
            .from(
          item,
        ),
      )
          .toList();

      setState(() {
        _balance =
            double.tryParse(
              wallet['balance']
                  ?.toString() ??
                  '',
            ) ??
                0;

        _totalEarned =
            double.tryParse(
              wallet['total_earned']
                  ?.toString() ??
                  '',
            ) ??
                0;

        _totalWithdrawn =
            double.tryParse(
              wallet['total_withdrawn']
                  ?.toString() ??
                  '',
            ) ??
                0;

        _transactions =
            transactions;

        _hasError = false;
        _isLoading = false;
      });

    } catch (error) {

      debugPrint(
        'Platform cüzdanı yükleme hatası: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // =========================================================
  // PARA ÇEKME
  // =========================================================

  Future<void>
  _withdraw() async {

    if (_isWithdrawing) {
      return;
    }

    final String iban =
    _ibanController.text
        .replaceAll(
      ' ',
      '',
    )
        .trim()
        .toUpperCase();

    String amountText =
    _amountController.text
        .trim();

    amountText =
        amountText.replaceAll(
          ',',
          '.',
        );

    final double amount =
        double.tryParse(
          amountText,
        ) ??
            0;

    if (
    iban.length != 26 ||
        !iban.startsWith('TR')
    ) {
      _showMessage(
        'Geçerli bir Türkiye IBAN numarası girin.',
        error: true,
      );

      return;
    }

    if (
    amount <= 0
    ) {
      _showMessage(
        'Geçerli bir çekim tutarı girin.',
        error: true,
      );

      return;
    }

    if (
    amount > _balance
    ) {
      _showMessage(
        'Platform bakiyesi yetersiz.',
        error: true,
      );

      return;
    }

    final bool confirmed =
    await _confirmWithdraw(
      amount,
    );

    if (!confirmed) {
      return;
    }

    setState(() {
      _isWithdrawing = true;
    });

    try {
      final Map<String, dynamic>
      result =
      await _apiService
          .withdrawPlatformMoney(
        amount: amount,
        iban: iban,
      );

      if (!mounted) {
        return;
      }

      if (
      result['success'] == true
      ) {
        _amountController.clear();

        _showMessage(
          result['message']
              ?.toString() ??
              'Para çekme işlemi kaydedildi.',
        );

        await _loadWallet();

      } else {
        _showMessage(
          result['error']
              ?.toString() ??
              result['message']
                  ?.toString() ??
              'Para çekme işlemi başarısız.',
          error: true,
        );
      }

    } catch (error) {

      if (!mounted) {
        return;
      }

      _showMessage(
        'Para çekme işlemi sırasında hata oluştu.',
        error: true,
      );

    } finally {

      if (mounted) {
        setState(() {
          _isWithdrawing = false;
        });
      }
    }
  }

  // =========================================================
  // ONAY PENCERESİ
  // =========================================================

  Future<bool>
  _confirmWithdraw(
      double amount,
      ) async {

    final bool? result =
    await showDialog<bool>(
      context: context,
      builder:
          (
          BuildContext context,
          ) {
        return AlertDialog(
          backgroundColor:
          const Color(
            0xFF111C2E,
          ),

          title:
          const Text(
            'Para Çekme Onayı',
            style: TextStyle(
              color:
              Colors.white,
            ),
          ),

          content:
          Text(
            '${_money(amount)} tutarındaki platform bakiyesini çekmek istediğinize emin misiniz?',
            style:
            const TextStyle(
              color:
              Color(
                0xFFB8C4D8,
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
              const Text(
                'Vazgeç',
              ),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
              const Text(
                'Onayla',
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // =========================================================
  // MESAJ
  // =========================================================

  void _showMessage(
      String message, {
        bool error = false,
      }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger
        .of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger
        .of(context)
        .showSnackBar(
      SnackBar(
        content:
        Text(
          message,
        ),
        backgroundColor:
        error
            ? Colors.red
            : Colors.green,
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(
        0xFF050B14,
      ),

      appBar: AppBar(
        backgroundColor:
        const Color(
          0xFF050B14,
        ),

        elevation: 0,

        title:
        const Text(
          'Platform Finansları',
          style:
          TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),

        actions: [
          IconButton(
            onPressed:
            _isLoading
                ? null
                : _loadWallet,
            icon:
            const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      body:
      _isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : _hasError
          ? _buildError()
          : RefreshIndicator(
        onRefresh:
        _loadWallet,

        child:
        ListView(
          padding:
          const EdgeInsets
              .all(
            20,
          ),

          children: [

            // ================================
            // ANA BAKİYE
            // ================================

            _mainBalanceCard(),

            const SizedBox(
              height: 16,
            ),

            // ================================
            // İSTATİSTİKLER
            // ================================

            Row(
              children: [

                Expanded(
                  child:
                  _smallCard(
                    title:
                    'Toplam Kazanç',
                    value:
                    _money(
                      _totalEarned,
                    ),
                    icon:
                    Icons
                        .trending_up_rounded,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child:
                  _smallCard(
                    title:
                    'Toplam Çekilen',
                    value:
                    _money(
                      _totalWithdrawn,
                    ),
                    icon:
                    Icons
                        .account_balance_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 28,
            ),

            const Text(
              'Platform Bakiyesi Çek',
              style:
              TextStyle(
                color:
                Colors.white,
                fontSize:
                18,
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // ================================
            // IBAN
            // ================================

            TextField(
              controller:
              _ibanController,

              style:
              const TextStyle(
                color:
                Colors.white,
              ),

              textCapitalization:
              TextCapitalization
                  .characters,

              inputFormatters: [
                FilteringTextInputFormatter
                    .allow(
                  RegExp(
                    r'[A-Za-z0-9 ]',
                  ),
                ),
              ],

              decoration:
              _inputDecoration(
                label:
                'IBAN',
                hint:
                'TR00 0000 0000 0000 0000 0000 00',
                icon:
                Icons
                    .account_balance_rounded,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ================================
            // TUTAR
            // ================================

            TextField(
              controller:
              _amountController,

              style:
              const TextStyle(
                color:
                Colors.white,
              ),

              keyboardType:
              const TextInputType
                  .numberWithOptions(
                decimal:
                true,
              ),

              decoration:
              _inputDecoration(
                label:
                'Çekilecek Tutar',
                hint:
                'Örn: 100,00',
                icon:
                Icons
                    .currency_lira_rounded,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            SizedBox(
              height:
              52,

              child:
              FilledButton.icon(
                onPressed:
                _isWithdrawing
                    ? null
                    : _withdraw,

                icon:
                _isWithdrawing
                    ? const SizedBox(
                  width:
                  19,
                  height:
                  19,
                  child:
                  CircularProgressIndicator(
                    strokeWidth:
                    2,
                  ),
                )
                    : const Icon(
                  Icons
                      .payments_rounded,
                ),

                label:
                Text(
                  _isWithdrawing
                      ? 'İşleniyor...'
                      : 'Para Çek',
                ),
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            const Text(
              'Platform Hareketleri',
              style:
              TextStyle(
                color:
                Colors.white,
                fontSize:
                18,
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            if (
            _transactions
                .isEmpty
            )
              _emptyTransactions()
            else
              ..._transactions
                  .map(
                _transactionCard,
              ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ANA BAKİYE KARTI
  // =========================================================

  Widget _mainBalanceCard() {
    return Container(
      width:
      double.infinity,

      padding:
      const EdgeInsets
          .all(
        24,
      ),

      decoration:
      BoxDecoration(
        gradient:
        const LinearGradient(
          colors: [
            Color(
              0xFF0284C7,
            ),
            Color(
              0xFF06B6D4,
            ),
          ],
        ),

        borderRadius:
        BorderRadius
            .circular(
          22,
        ),
      ),

      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,

        children: [

          const Row(
            children: [
              Icon(
                Icons
                    .account_balance_wallet_rounded,
                color:
                Colors.white,
              ),

              SizedBox(
                width:
                8,
              ),

              Text(
                'Çekilebilir Platform Bakiyesi',
                style:
                TextStyle(
                  color:
                  Colors.white70,
                  fontSize:
                  13,
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
            18,
          ),

          Text(
            _money(
              _balance,
            ),
            style:
            const TextStyle(
              color:
              Colors.white,
              fontSize:
              31,
              fontWeight:
              FontWeight.w800,
            ),
          ),

          const SizedBox(
            height:
            8,
          ),

          const Text(
            'Platform komisyonlarından elde edilen bakiye',
            style:
            TextStyle(
              color:
              Colors.white70,
              fontSize:
              11,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // KÜÇÜK KART
  // =========================================================

  Widget _smallCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding:
      const EdgeInsets
          .all(
        16,
      ),

      decoration:
      BoxDecoration(
        color:
        const Color(
          0xFF111C2E,
        ),

        borderRadius:
        BorderRadius
            .circular(
          18,
        ),

        border:
        Border.all(
          color:
          const Color(
            0xFF23334D,
          ),
        ),
      ),

      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,

        children: [

          Icon(
            icon,
            color:
            const Color(
              0xFF38BDF8,
            ),
          ),

          const SizedBox(
            height:
            12,
          ),

          Text(
            value,
            maxLines:
            1,
            overflow:
            TextOverflow
                .ellipsis,
            style:
            const TextStyle(
              color:
              Colors.white,
              fontSize:
              17,
              fontWeight:
              FontWeight.w700,
            ),
          ),

          const SizedBox(
            height:
            4,
          ),

          Text(
            title,
            style:
            const TextStyle(
              color:
              Color(
                0xFF8493A9,
              ),
              fontSize:
              11,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HAREKET KARTI
  // =========================================================

  Widget _transactionCard(
      Map<String, dynamic> item,
      ) {
    final String type =
        item['transaction_type']
            ?.toString() ??
            '';

    final double amount =
        double.tryParse(
          item['amount']
              ?.toString() ??
              '',
        ) ??
            0;

    final bool withdrawal =
        type ==
            'withdrawal' ||
            amount <
                0;

    return Container(
      margin:
      const EdgeInsets.only(
        bottom:
        10,
      ),

      padding:
      const EdgeInsets
          .all(
        15,
      ),

      decoration:
      BoxDecoration(
        color:
        const Color(
          0xFF111C2E,
        ),

        borderRadius:
        BorderRadius
            .circular(
          17,
        ),

        border:
        Border.all(
          color:
          const Color(
            0xFF23334D,
          ),
        ),
      ),

      child:
      Row(
        children: [

          Container(
            width:
            44,
            height:
            44,

            decoration:
            BoxDecoration(
              color:
              withdrawal
                  ? Colors.red
                  .withValues(
                alpha:
                0.12,
              )
                  : Colors.green
                  .withValues(
                alpha:
                0.12,
              ),

              borderRadius:
              BorderRadius
                  .circular(
                14,
              ),
            ),

            child:
            Icon(
              withdrawal
                  ? Icons
                  .arrow_upward_rounded
                  : Icons
                  .add_rounded,

              color:
              withdrawal
                  ? Colors.redAccent
                  : Colors.greenAccent,
            ),
          ),

          const SizedBox(
            width:
            13,
          ),

          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,

              children: [

                Text(
                  item['description']
                      ?.toString() ??
                      (
                          withdrawal
                              ? 'Platform para çekme'
                              : 'Platform komisyonu'
                      ),

                  maxLines:
                  2,

                  overflow:
                  TextOverflow
                      .ellipsis,

                  style:
                  const TextStyle(
                    color:
                    Colors.white,
                    fontSize:
                    13,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height:
                  5,
                ),

                Text(
                  _date(
                    item['created_at'],
                  ),

                  style:
                  const TextStyle(
                    color:
                    Color(
                      0xFF8493A9,
                    ),

                    fontSize:
                    10,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width:
            10,
          ),

          Text(
            '${amount >= 0 ? '+' : ''}${_money(amount)}',

            style:
            TextStyle(
              color:
              withdrawal
                  ? Colors.redAccent
                  : Colors.greenAccent,

              fontWeight:
              FontWeight.w700,

              fontSize:
              13,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // INPUT TASARIMI
  // =========================================================

  InputDecoration
  _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText:
      label,

      hintText:
      hint,

      prefixIcon:
      Icon(
        icon,
      ),

      filled:
      true,

      fillColor:
      const Color(
        0xFF111C2E,
      ),

      labelStyle:
      const TextStyle(
        color:
        Color(
          0xFF8493A9,
        ),
      ),

      hintStyle:
      const TextStyle(
        color:
        Color(
          0xFF65758C,
        ),
      ),

      border:
      OutlineInputBorder(
        borderRadius:
        BorderRadius
            .circular(
          16,
        ),

        borderSide:
        const BorderSide(
          color:
          Color(
            0xFF23334D,
          ),
        ),
      ),

      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius
            .circular(
          16,
        ),

        borderSide:
        const BorderSide(
          color:
          Color(
            0xFF23334D,
          ),
        ),
      ),

      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius
            .circular(
          16,
        ),

        borderSide:
        const BorderSide(
          color:
          Color(
            0xFF38BDF8,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // HATA
  // =========================================================

  Widget _buildError() {
    return Center(
      child:
      Column(
        mainAxisSize:
        MainAxisSize.min,

        children: [

          const Icon(
            Icons
                .error_outline_rounded,
            color:
            Colors.redAccent,
            size:
            50,
          ),

          const SizedBox(
            height:
            14,
          ),

          const Text(
            'Platform finansları yüklenemedi.',
            style:
            TextStyle(
              color:
              Colors.white,
            ),
          ),

          const SizedBox(
            height:
            12,
          ),

          FilledButton(
            onPressed:
            _loadWallet,

            child:
            const Text(
              'Tekrar Dene',
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BOŞ HAREKET
  // =========================================================

  Widget _emptyTransactions() {
    return Container(
      padding:
      const EdgeInsets
          .all(
        28,
      ),

      decoration:
      BoxDecoration(
        color:
        const Color(
          0xFF111C2E,
        ),

        borderRadius:
        BorderRadius
            .circular(
          18,
        ),
      ),

      alignment:
      Alignment.center,

      child:
      const Text(
        'Henüz platform hareketi bulunmuyor.',
        style:
        TextStyle(
          color:
          Color(
            0xFF8493A9,
          ),
        ),
      ),
    );
  }
}