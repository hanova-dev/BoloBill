import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../core/di/providers.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/utils/id_generator.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/shop.dart';
import '../../../domain/repositories/auth_repository.dart';

enum SignInMethod { google, phone }

@immutable
class OnboardingState {
  const OnboardingState({
    this.signInMethod,
    this.authResult,
    this.phoneNumber = '',
    this.verificationId,
    this.businessType,
    this.shopName = '',
  });

  final SignInMethod? signInMethod;
  final AuthResult? authResult;
  final String phoneNumber;

  /// Set once Firebase sends an SMS code (manual entry path); null while
  /// waiting, and irrelevant if Android auto-verifies without user input.
  final String? verificationId;
  final BusinessType? businessType;
  final String shopName;

  OnboardingState copyWith({
    SignInMethod? signInMethod,
    AuthResult? authResult,
    String? phoneNumber,
    String? verificationId,
    BusinessType? businessType,
    String? shopName,
  }) {
    return OnboardingState(
      signInMethod: signInMethod ?? this.signInMethod,
      authResult: authResult ?? this.authResult,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationId: verificationId ?? this.verificationId,
      businessType: businessType ?? this.businessType,
      shopName: shopName ?? this.shopName,
    );
  }
}

/// Accumulates the wizard's state across A1/E1/A3/A2/A4 and, on
/// [completeOnboarding], writes the resulting Shop + AppUser to the local
/// database in one place — so no individual screen needs direct repository
/// access beyond this controller.
class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController(this._ref) : super(const OnboardingState());

  final Ref _ref;

  void setSignInMethod(SignInMethod method) => state = state.copyWith(signInMethod: method);

  void setAuthResult(AuthResult result) => state = state.copyWith(authResult: result);

  /// Checks whether the identity that just signed in already owns a shop in
  /// the cloud — a reinstall or new device signing back into an existing
  /// account — and restores it locally if so. Call this right after
  /// [setAuthResult], before any of A2/A3/A4 run, so an existing user is
  /// never walked through onboarding-from-scratch a second time. Returns
  /// null (not an error) if there's nothing to restore, which is also what
  /// a genuinely new sign-up looks like — the caller should fall through to
  /// normal onboarding in that case.
  Future<Shop?> tryRestoreFromCloud() async {
    final uid = state.authResult?.uid;
    if (uid == null) return null;
    final shop = await _ref.read(shopRepositoryProvider).restoreFromCloud(uid);
    if (shop == null) return null;
    _ref.read(currentShopProvider.notifier).state = shop;
    _ref.read(localeProvider.notifier).state = shop.preferredLanguage;
    return shop;
  }

  void setPhoneNumber(String phoneNumber) => state = state.copyWith(phoneNumber: phoneNumber);

  void setVerificationId(String verificationId) =>
      state = state.copyWith(verificationId: verificationId);

  void setBusinessType(BusinessType type) => state = state.copyWith(businessType: type);

  void setShopName(String name) => state = state.copyWith(shopName: name);

  Future<Shop> completeOnboarding() async {
    final locale = _ref.read(localeProvider);
    final shopRepo = _ref.read(shopRepositoryProvider);
    final userRepo = _ref.read(userRepositoryProvider);

    final shop = Shop(
      shopId: IdGenerator.newId(),
      ownerPhone: state.phoneNumber,
      ownerUid: state.authResult?.uid,
      shopName: state.shopName,
      businessType: state.businessType!,
      preferredLanguage: locale,
      createdAt: DateTime.now(),
    );
    await shopRepo.createShop(shop);

    await userRepo.createUser(AppUser(
      userId: IdGenerator.newId(),
      shopId: shop.shopId,
      phone: state.phoneNumber,
      name: state.authResult?.displayName,
      role: UserRole.owner,
      createdAt: DateTime.now(),
    ));

    _ref.read(currentShopProvider.notifier).state = shop;
    return shop;
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>(OnboardingController.new);
