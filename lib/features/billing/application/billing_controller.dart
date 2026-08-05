import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/bill.dart';
import '../../../domain/entities/bill_item.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/enums.dart';
import 'draft_line_item.dart';

@immutable
class BillingState {
  const BillingState({
    this.items = const [],
    this.customer,
    this.total,
    this.paymentType,
  });

  final List<DraftLineItem> items;
  final Customer? customer;

  /// Non-null only right after Jama Karain calculates — any further edit
  /// to [items] clears it back to null, so the total on screen is never
  /// stale relative to the line items (FR-3.3.5: editing after seeing the
  /// total always requires an explicit recalculation, never an implicit one).
  final Money? total;
  final PaymentType? paymentType;

  bool get isCalculated => total != null;
  bool get hasItems => items.isNotEmpty;

  BillingState copyWith({
    List<DraftLineItem>? items,
    Customer? customer,
    bool clearCustomer = false,
    Money? total,
    bool clearTotal = false,
    PaymentType? paymentType,
  }) {
    return BillingState(
      items: items ?? this.items,
      customer: clearCustomer ? null : (customer ?? this.customer),
      total: clearTotal ? null : (total ?? this.total),
      paymentType: paymentType ?? this.paymentType,
    );
  }
}

/// The Bill Engine (SRS §9.1: createBill/addLineItem/calculateTotal/
/// confirmBill). Line items live in memory for the entire Draft →
/// Calculated cycle (FR-3.2.7, FR-3.2.8, FR-3.3.5) and are only persisted —
/// atomically, bill + every item + the khata debit if applicable — once
/// [confirmBill] runs, per FR-3.7.1's "immediately upon confirmation".
class BillingController extends StateNotifier<BillingState> {
  BillingController(this._ref) : super(const BillingState());

  final Ref _ref;

  void addItem(DraftLineItem item) {
    state = state.copyWith(items: [...state.items, item], clearTotal: true);
  }

  void updateItem(String localId, DraftLineItem updated) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.localId == localId) updated else item,
      ],
      clearTotal: true,
    );
  }

  void removeItem(String localId) {
    state = state.copyWith(
      items: state.items.where((i) => i.localId != localId).toList(),
      clearTotal: true,
    );
  }

  void selectCustomer(Customer? customer) {
    state = state.copyWith(customer: customer, clearCustomer: customer == null);
  }

  /// Jama Karain (FR-3.3.1/3.3.2) — always an explicit tap, never automatic.
  Money calculateTotal() {
    final total = state.items.fold<Money>(Money.zero, (sum, i) => sum + i.lineTotal);
    state = state.copyWith(total: total);
    return total;
  }

  void setPaymentType(PaymentType type) {
    state = state.copyWith(paymentType: type);
  }

  /// Persists the confirmed bill (FR-3.3.6) and, if khata, posts the debit
  /// (FR-3.4.6) — then resets the engine for the next bill.
  Future<Bill> confirmBill() async {
    final shop = _ref.read(currentShopProvider);
    if (shop == null) {
      throw StateError('confirmBill called with no current shop');
    }
    final total = state.total;
    final paymentType = state.paymentType;
    if (total == null) throw StateError('confirmBill called before calculateTotal');
    if (paymentType == null) throw StateError('confirmBill called before setPaymentType');
    if (paymentType == PaymentType.khata && state.customer == null) {
      throw StateError('khata payment requires a selected customer');
    }

    final billId = IdGenerator.newId();
    final bill = Bill(
      billId: billId,
      shopId: shop.shopId,
      customerId: state.customer?.customerId,
      paymentType: paymentType,
      totalAmount: total,
      status: BillStatus.confirmed,
      createdAt: DateTime.now(),
    );
    final items = [
      for (final draft in state.items)
        BillItem(
          billItemId: IdGenerator.newId(),
          billId: billId,
          itemNameRaw: draft.itemNameRaw,
          inputMethod: draft.inputMethod,
          quantity: draft.quantity,
          unit: draft.unit,
          pricePerUnit: draft.pricePerUnit,
          lineTotal: draft.lineTotal,
        ),
    ];

    await _ref.read(billRepositoryProvider).createConfirmedBill(bill, items);

    if (paymentType == PaymentType.khata) {
      await _ref.read(khataRepositoryProvider).postBillDebit(
            customerId: state.customer!.customerId,
            billId: billId,
            amount: total,
          );
    }

    state = const BillingState();
    return bill;
  }
}

final billingControllerProvider =
    StateNotifierProvider<BillingController, BillingState>(BillingController.new);
