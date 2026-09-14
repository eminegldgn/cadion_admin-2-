import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/admin_api_service.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({
    super.key,
    required this.adminId,
  });

  final String adminId;

  @override
  State<SalesScreen> createState() =>
      _SalesScreenState();
}

class _SalesScreenState
    extends State<SalesScreen> {
  final AdminApiService _apiService =
  AdminApiService();

  final TextEditingController
  _searchController =
  TextEditingController();

  bool _isLoading = true;

  String? _errorMessage;

  List<Map<String, dynamic>>
  _purchases =
  <Map<String, dynamic>>[];

  List<Map<String, dynamic>>
  _filteredPurchases =
  <Map<String, dynamic>>[];

  Map<String, dynamic> _statistics =
  <String, dynamic>{};

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _filterPurchases,
    );

    _loadAll();
  }

  @override
  void dispose() {
    _searchController.removeListener(
      _filterPurchases,
    );

    _searchController.dispose();

    super.dispose();
  }

  Future<void> _loadAll() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final List<dynamic> results =
    await Future.wait<dynamic>(
      <Future<dynamic>>[
        _apiService.getPurchases(
          page: 1,
          limit: 100,
        ),
        _apiService.getSalesStatistics(
          days: 30,
        ),
      ],
    );

    if (!mounted) {
      return;
    }

    final Map<String, dynamic>
    purchasesResult =
    Map<String, dynamic>.from(
      results[0] as Map,
    );

    final Map<String, dynamic>
    statisticsResult =
    Map<String, dynamic>.from(
      results[1] as Map,
    );

    if (
    purchasesResult['success'] !=
        true
    ) {
      setState(() {
        _isLoading = false;

        _errorMessage =
            purchasesResult['error']
                ?.toString() ??
                'Satış kayıtları getirilemedi.';
      });

      return;
    }

    final List<Map<String, dynamic>>
    parsedPurchases =
    <Map<String, dynamic>>[];

    final dynamic purchasesValue =
        purchasesResult['purchases'] ??
            purchasesResult['sales'] ??
            purchasesResult['data'];

    if (purchasesValue is List) {
      for (
      final dynamic item
      in purchasesValue
      ) {
        if (item is Map) {
          parsedPurchases.add(
            Map<String, dynamic>.from(
              item,
            ),
          );
        }
      }
    }

    final Map<String, dynamic>
    parsedStatistics =
    _extractStatistics(
      statisticsResult,
    );

    setState(() {
      _isLoading = false;

      _purchases = parsedPurchases;

      _filteredPurchases =
      List<Map<String, dynamic>>.from(
        parsedPurchases,
      );

      _statistics =
          parsedStatistics;
    });

    _filterPurchases();
  }

  Map<String, dynamic> _extractStatistics(
      Map<String, dynamic> result,
      ) {
    final dynamic statisticsValue =
        result['statistics'] ??
            result['summary'] ??
            result['data'];

    if (statisticsValue is Map) {
      return Map<String, dynamic>.from(
        statisticsValue,
      );
    }

    return <String, dynamic>{};
  }

  void _filterPurchases() {
    if (!mounted) {
      return;
    }

    final String search =
    _searchController.text
        .trim()
        .toLowerCase();

    setState(() {
      if (search.isEmpty) {
        _filteredPurchases =
        List<Map<String, dynamic>>.from(
          _purchases,
        );

        return;
      }

      _filteredPurchases =
          _purchases.where(
                (
                Map<String, dynamic>
                purchase,
                ) {
              final String noteTitle =
              _value(
                purchase,
                <String>[
                  'note_title',
                  'title',
                ],
              ).toLowerCase();

              final String buyerId =
              _value(
                purchase,
                <String>[
                  'buyer_id',
                  'user_id',
                  'purchaser_id',
                ],
              ).toLowerCase();

              final String sellerId =
              _value(
                purchase,
                <String>[
                  'seller_id',
                  'note_owner_id',
                  'owner_id',
                ],
              ).toLowerCase();

              return noteTitle.contains(
                search,
              ) ||
                  buyerId.contains(
                    search,
                  ) ||
                  sellerId.contains(
                    search,
                  );
            },
          ).toList();
    });
  }
  String _value(
      Map<String, dynamic> data,
      List<String> keys, {
        String fallback = '-',
      }) {
    for (final String key in keys) {
      final dynamic value = data[key];

      if (
      value != null &&
          value.toString().trim().isNotEmpty
      ) {
        return value.toString();
      }
    }

    return fallback;
  }

  double _number(
      Map<String, dynamic> data,
      List<String> keys,
      ) {
    for (final String key in keys) {
      final dynamic value = data[key];

      if (value == null) {
        continue;
      }

      final double? parsed =
      double.tryParse(
        value.toString().replaceAll(
          ',',
          '.',
        ),
      );

      if (parsed != null) {
        return parsed;
      }
    }

    return 0;
  }

  int _integer(
      Map<String, dynamic> data,
      List<String> keys,
      ) {
    return _number(
      data,
      keys,
    ).round();
  }

  String _money(
      double value,
      ) {
    return '${value.toStringAsFixed(2)} TL';
  }

  bool _isFreePurchase(
      Map<String, dynamic> purchase,
      ) {
    final String freeValue =
    _value(
      purchase,
      <String>[
        'is_free',
        'free_download',
        'used_free_right',
      ],
      fallback: '',
    ).toLowerCase();

    if (
    freeValue == '1' ||
        freeValue == 'true'
    ) {
      return true;
    }

    final double paidAmount =
    _number(
      purchase,
      <String>[
        'paid_amount',
        'amount',
        'price',
        'sale_price',
      ],
    );

    return paidAmount <= 0;
  }

  Map<String, dynamic>
  _calculateLocalSummary() {
    int totalSales = 0;
    int freeDownloads = 0;

    double totalVolume = 0;
    double totalCommission = 0;
    double totalSellerEarning = 0;

    for (
    final Map<String, dynamic> purchase
    in _purchases
    ) {
      final bool isFree =
      _isFreePurchase(
        purchase,
      );

      if (isFree) {
        freeDownloads++;
      } else {
        totalSales++;
      }

      totalVolume += _number(
        purchase,
        <String>[
          'paid_amount',
          'amount',
          'price',
          'sale_price',
        ],
      );

      totalCommission += _number(
        purchase,
        <String>[
          'commission_amount',
          'platform_commission',
          'commission',
        ],
      );

      totalSellerEarning += _number(
        purchase,
        <String>[
          'seller_earning',
          'seller_amount',
          'net_amount',
        ],
      );
    }

    return <String, dynamic>{
      'total_sales': totalSales,
      'free_downloads': freeDownloads,
      'total_volume': totalVolume,
      'total_commission':
      totalCommission,
      'seller_earnings':
      totalSellerEarning,
    };
  }

  dynamic _statValue(
      List<String> keys,
      dynamic localFallback,
      ) {
    for (final String key in keys) {
      final dynamic value =
      _statistics[key];

      if (value != null) {
        return value;
      }
    }

    return localFallback;
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(18),
        children: [
          _buildSummary(),

          const SizedBox(
            height: 16,
          ),

          _buildSearch(),

          const SizedBox(
            height: 16,
          ),

          if (_isLoading)
            const Padding(
              padding:
              EdgeInsets.all(70),
              child: Center(
                child:
                CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            _buildError()
          else if (
            _filteredPurchases.isEmpty
            )
              _buildEmpty()
            else
              ..._filteredPurchases.map(
                _buildPurchaseCard,
              ),
        ],
      ),
    );
  }
  Widget _buildSummary() {
    final Map<String, dynamic> localSummary =
    _calculateLocalSummary();

    final int totalSales =
        int.tryParse(
          _statValue(
            <String>[
              'total_sales',
              'sale_count',
              'purchase_count',
              'total_purchases',
            ],
            localSummary['total_sales'],
          ).toString(),
        ) ??
            0;

    final int freeDownloads =
        int.tryParse(
          _statValue(
            <String>[
              'free_downloads',
              'free_purchase_count',
              'free_count',
            ],
            localSummary['free_downloads'],
          ).toString(),
        ) ??
            0;

    final double totalVolume =
        double.tryParse(
          _statValue(
            <String>[
              'total_volume',
              'total_revenue',
              'gross_revenue',
              'sales_total',
            ],
            localSummary['total_volume'],
          ).toString().replaceAll(',', '.'),
        ) ??
            0;

    final double totalCommission =
        double.tryParse(
          _statValue(
            <String>[
              'total_commission',
              'platform_revenue',
              'commission_total',
            ],
            localSummary['total_commission'],
          ).toString().replaceAll(',', '.'),
        ) ??
            0;

    final double sellerEarnings =
        double.tryParse(
          _statValue(
            <String>[
              'seller_earnings',
              'total_seller_earning',
              'seller_total',
            ],
            localSummary['seller_earnings'],
          ).toString().replaceAll(',', '.'),
        ) ??
            0;

    return LayoutBuilder(
      builder: (
          BuildContext context,
          BoxConstraints constraints,
          ) {
        final double cardWidth =
            (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                title: 'Ücretli Satış',
                value: totalSales.toString(),
                icon: Icons.shopping_cart_rounded,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                title: 'Ücretsiz İndirme',
                value: freeDownloads.toString(),
                icon: Icons.card_giftcard_rounded,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                title: 'Satış Hacmi',
                value: _money(totalVolume),
                icon: Icons.payments_rounded,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                title: 'Komisyon',
                value: _money(totalCommission),
                icon: Icons.account_balance_rounded,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                title: 'Satıcı Kazancı',
                value: _money(sellerEarnings),
                icon: Icons.wallet_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding:
      const EdgeInsets.all(16),
      decoration:
      BoxDecoration(
        color:
        AdminColors.surface,
        borderRadius:
        BorderRadius.circular(17),
        border: Border.all(
          color:
          AdminColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
            BoxDecoration(
              color: AdminColors.primary
                  .withValues(
                alpha: 0.13,
              ),
              borderRadius:
              BorderRadius.circular(
                13,
              ),
            ),
            child: Icon(
              icon,
              color:
              AdminColors.primary,
              size: 22,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    color: AdminColors
                        .textPrimary,
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  title,
                  style:
                  const TextStyle(
                    color: AdminColors
                        .textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller:
      _searchController,
      decoration:
      InputDecoration(
        hintText:
        'Not, alıcı veya satıcı ara...',
        prefixIcon:
        const Icon(
          Icons.search_rounded,
        ),
        suffixIcon:
        _searchController.text.isEmpty
            ? IconButton(
          onPressed: _loadAll,
          tooltip: 'Yenile',
          icon: const Icon(
            Icons.refresh_rounded,
          ),
        )
            : IconButton(
          onPressed: () {
            _searchController
                .clear();
          },
          icon: const Icon(
            Icons.clear_rounded,
          ),
        ),
      ),
    );
  }
  Widget _buildPurchaseCard(
      Map<String, dynamic> purchase,
      ) {
    final String noteTitle =
    _value(
      purchase,
      <String>[
        'note_title',
        'title',
      ],
      fallback: 'Not bulunamadı',
    );

    final String buyerId =
    _value(
      purchase,
      <String>[
        'buyer_id',
        'user_id',
        'purchaser_id',
      ],
    );

    final String sellerId =
    _value(
      purchase,
      <String>[
        'seller_id',
        'note_owner_id',
        'owner_id',
      ],
    );

    final String createdAt =
    _value(
      purchase,
      <String>[
        'created_at',
        'purchase_date',
        'date',
      ],
    );

    final double salePrice =
    _number(
      purchase,
      <String>[
        'paid_amount',
        'amount',
        'price',
        'sale_price',
      ],
    );

    final double commission =
    _number(
      purchase,
      <String>[
        'commission_amount',
        'platform_commission',
        'commission',
      ],
    );

    double sellerEarning =
    _number(
      purchase,
      <String>[
        'seller_earning',
        'seller_amount',
        'net_amount',
      ],
    );

    if (
    sellerEarning <= 0 &&
        salePrice > 0
    ) {
      sellerEarning =
          salePrice - commission;
    }

    final bool isFree =
    _isFreePurchase(
      purchase,
    );

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
      const EdgeInsets.all(16),
      decoration:
      BoxDecoration(
        color:
        AdminColors.surface,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          AdminColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                BoxDecoration(
                  color: isFree
                      ? AdminColors.success
                      .withValues(
                    alpha: 0.13,
                  )
                      : AdminColors.primary
                      .withValues(
                    alpha: 0.13,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  isFree
                      ? Icons
                      .card_giftcard_rounded
                      : Icons
                      .shopping_cart_rounded,
                  color: isFree
                      ? AdminColors.success
                      : AdminColors.primary,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      noteTitle,
                      maxLines: 2,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        color: AdminColors
                            .textPrimary,
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      createdAt,
                      style:
                      const TextStyle(
                        color: AdminColors
                            .textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              _typeChip(
                isFree,
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          const Divider(
            color:
            AdminColors.border,
          ),

          const SizedBox(
            height: 10,
          ),

          _infoRow(
            icon:
            Icons.person_rounded,
            label: 'Alıcı',
            value: buyerId,
          ),

          const SizedBox(
            height: 9,
          ),

          _infoRow(
            icon:
            Icons.storefront_rounded,
            label: 'Satıcı',
            value: sellerId,
          ),

          const SizedBox(
            height: 14,
          ),

          _buildAmounts(
            isFree: isFree,
            salePrice: salePrice,
            commission: commission,
            sellerEarning:
            sellerEarning,
          ),
        ],
      ),
    );
  }

  Widget _typeChip(
      bool isFree,
      ) {
    final Color color = isFree
        ? AdminColors.success
        : AdminColors.primary;

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration:
      BoxDecoration(
        color: color.withValues(
          alpha: 0.12,
        ),
        borderRadius:
        BorderRadius.circular(10),
      ),
      child: Text(
        isFree
            ? 'Ücretsiz'
            : 'Satış',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight:
          FontWeight.w700,
        ),
      ),
    );
  }
  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color:
          AdminColors.textMuted,
          size: 17,
        ),

        const SizedBox(
          width: 8,
        ),

        SizedBox(
          width: 55,
          child: Text(
            label,
            style:
            const TextStyle(
              color: AdminColors
                  .textMuted,
              fontSize: 11,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style:
            const TextStyle(
              color: AdminColors
                  .textSecondary,
              fontSize: 12,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmounts({
    required bool isFree,
    required double salePrice,
    required double commission,
    required double sellerEarning,
  }) {
    if (isFree) {
      return Container(
        width: double.infinity,
        padding:
        const EdgeInsets.all(13),
        decoration:
        BoxDecoration(
          color: AdminColors.success
              .withValues(
            alpha: 0.09,
          ),
          borderRadius:
          BorderRadius.circular(
            13,
          ),
          border: Border.all(
            color: AdminColors.success
                .withValues(
              alpha: 0.25,
            ),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons
                  .card_giftcard_rounded,
              color:
              AdminColors.success,
              size: 19,
            ),

            SizedBox(
              width: 9,
            ),

            Expanded(
              child: Text(
                'Kullanıcının ücretsiz indirme hakkı kullanılmıştır.',
                style: TextStyle(
                  color: AdminColors
                      .textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _amountBox(
            title:
            'Satış Fiyatı',
            value:
            _money(salePrice),
            icon:
            Icons.payments_rounded,
          ),
        ),

        const SizedBox(
          width: 9,
        ),

        Expanded(
          child: _amountBox(
            title: 'Komisyon',
            value:
            _money(commission),
            icon:
            Icons.percent_rounded,
          ),
        ),

        const SizedBox(
          width: 9,
        ),

        Expanded(
          child: _amountBox(
            title:
            'Satıcı Kazancı',
            value: _money(
              sellerEarning,
            ),
            icon:
            Icons.wallet_rounded,
          ),
        ),
      ],
    );
  }

  Widget _amountBox({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding:
      const EdgeInsets.all(12),
      decoration:
      BoxDecoration(
        color:
        AdminColors.surfaceSecondary,
        borderRadius:
        BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color:
            AdminColors.primary,
            size: 18,
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            value,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style:
            const TextStyle(
              color: AdminColors
                  .textPrimary,
              fontSize: 12,
              fontWeight:
              FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 3,
          ),

          Text(
            title,
            style:
            const TextStyle(
              color: AdminColors
                  .textMuted,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(40),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .error_outline_rounded,
              color:
              AdminColors.error,
              size: 52,
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              _errorMessage ??
                  'Bir hata oluştu.',
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                color: AdminColors
                    .textSecondary,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            FilledButton.icon(
              onPressed: _loadAll,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Tekrar Dene',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding:
      EdgeInsets.all(55),
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            Icons
                .shopping_cart_outlined,
            color:
            AdminColors.textMuted,
            size: 52,
          ),

          SizedBox(
            height: 12,
          ),

          Text(
            'Gösterilecek satış kaydı bulunamadı.',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              color: AdminColors
                  .textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}