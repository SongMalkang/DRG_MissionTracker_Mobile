import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// 인앱 구매 서비스 (Android Play Store 전용)
///
/// 사용법:
/// 1. Google Play Console에서 인앱 상품 등록 후 [_productIds]에 ID 추가
/// 2. [initialize] 호출로 스토어 연결
/// 3. [buyProduct] 호출로 구매 시작
class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _available = false;
  List<ProductDetails> _products = [];

  bool get isAvailable => _available;
  List<ProductDetails> get products => _products;

  // ── 상품 ID (Play Console 등록 후 추가) ────────────────────────────────
  static const Set<String> _productIds = <String>{
    // 예시: 'tip_small', 'tip_medium', 'tip_large'
    // Play Console에서 인앱 상품 생성 후 여기에 ID 기입
  };

  // ── 초기화 ──────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    _available = await _iap.isAvailable();
    if (!_available) {
      debugPrint('PurchaseService: 스토어 사용 불가');
      return;
    }

    // 구매 이벤트 구독
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('PurchaseService stream error: $error'),
    );

    // 상품 목록 조회
    if (_productIds.isNotEmpty) {
      final response = await _iap.queryProductDetails(_productIds);
      if (response.error != null) {
        debugPrint('PurchaseService query error: ${response.error}');
      }
      _products = response.productDetails;
    }
  }

  // ── 구매 시작 ──────────────────────────────────────────────────────────
  Future<bool> buyProduct(ProductDetails product) async {
    if (!_available) return false;
    final purchaseParam = PurchaseParam(productDetails: product);
    return _iap.buyConsumable(purchaseParam: purchaseParam);
  }

  // ── 구매 이벤트 처리 ──────────────────────────────────────────────────
  void _onPurchaseUpdated(List<PurchaseDetails> purchaseList) {
    for (final purchase in purchaseList) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // 구매 완료 처리
          _completePurchase(purchase);
          break;
        case PurchaseStatus.error:
          debugPrint('PurchaseService error: ${purchase.error}');
          _completePurchase(purchase);
          break;
        case PurchaseStatus.pending:
          // 대기 중
          break;
        case PurchaseStatus.canceled:
          _completePurchase(purchase);
          break;
      }
    }
  }

  Future<void> _completePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  // ── 정리 ──────────────────────────────────────────────────────────────
  void dispose() {
    _subscription?.cancel();
  }
}
