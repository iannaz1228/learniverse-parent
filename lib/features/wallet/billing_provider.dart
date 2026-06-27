import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'wallet_provider.dart';

// ── Product IDs — must match exactly what's set up in Google Play Console ──────

const kProductIds = {
  'coins_100':  100,
  'coins_350':  350,
  'coins_700':  700,
  'coins_1500': 1500,
};

// ── Billing state ─────────────────────────────────────────────────────────────

class BillingState {
  const BillingState({
    this.available = false,
    this.products = const [],
    this.loading = false,
    this.pendingProductId,
    this.errorMessage,
  });

  final bool available;
  final List<ProductDetails> products;
  final bool loading;
  final String? pendingProductId;
  final String? errorMessage;

  BillingState copyWith({
    bool? available,
    List<ProductDetails>? products,
    bool? loading,
    String? pendingProductId,
    String? errorMessage,
  }) =>
      BillingState(
        available: available ?? this.available,
        products: products ?? this.products,
        loading: loading ?? this.loading,
        pendingProductId: pendingProductId,
        errorMessage: errorMessage,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class BillingNotifier extends Notifier<BillingState> {
  StreamSubscription<List<PurchaseDetails>>? _sub;

  @override
  BillingState build() {
    ref.onDispose(() => _sub?.cancel());
    _init();
    return const BillingState();
  }

  Future<void> _init() async {
    final available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      state = state.copyWith(available: false, errorMessage: 'Store not available');
      return;
    }

    // Listen to purchase updates
    _sub = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (e) => state = state.copyWith(errorMessage: e.toString()),
    );

    // Load products
    final response = await InAppPurchase.instance
        .queryProductDetails(kProductIds.keys.toSet());
    state = state.copyWith(
      available: true,
      products: response.productDetails,
      errorMessage: response.notFoundIDs.isNotEmpty
          ? 'Products not found in Play Console: ${response.notFoundIDs}'
          : null,
    );
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        state = state.copyWith(loading: true, pendingProductId: purchase.productID);
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Deliver coins
        final coins = kProductIds[purchase.productID] ?? 0;
        if (coins > 0) {
          await ref.read(parentWalletProvider.notifier).addCoins(coins);
        }
        // Acknowledge the purchase with Google Play
        if (purchase.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchase);
        }
        state = state.copyWith(loading: false, pendingProductId: null, errorMessage: null);
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        state = state.copyWith(
          loading: false,
          pendingProductId: null,
          errorMessage: purchase.error?.message ?? 'Purchase failed',
        );
        if (purchase.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchase);
        }
      }

      if (purchase.status == PurchaseStatus.canceled) {
        state = state.copyWith(loading: false, pendingProductId: null);
      }
    }
  }

  /// Returns null on success, error string on failure.
  Future<String?> buyProduct(String productId) async {
    if (!state.available) return 'Store not available';
    final product = state.products.where((p) => p.id == productId).firstOrNull;
    if (product == null) return 'Product not found — check Play Console setup';

    final purchaseParam = PurchaseParam(productDetails: product);
    try {
      await InAppPurchase.instance.buyConsumable(
        purchaseParam: purchaseParam,
        autoConsume: true,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final billingProvider =
    NotifierProvider<BillingNotifier, BillingState>(BillingNotifier.new);
