import 'package:bolobill/domain/entities/enums.dart';
import 'package:bolobill/domain/repositories/auth_repository.dart';
import 'package:bolobill/features/onboarding/application/onboarding_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accumulates wizard state across setters without losing earlier fields', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(onboardingControllerProvider.notifier);

    controller.setSignInMethod(SignInMethod.phone);
    controller.setPhoneNumber('+923001234567');
    controller.setBusinessType(BusinessType.teaStall);
    controller.setShopName('Rahim Tea Stall');

    final state = container.read(onboardingControllerProvider);
    expect(state.signInMethod, SignInMethod.phone);
    expect(state.phoneNumber, '+923001234567');
    expect(state.businessType, BusinessType.teaStall);
    expect(state.shopName, 'Rahim Tea Stall');

    // Setting one field must not clobber the others already collected.
    controller.setVerificationId('verif-123');
    final after = container.read(onboardingControllerProvider);
    expect(after.verificationId, 'verif-123');
    expect(after.phoneNumber, '+923001234567');
    expect(after.businessType, BusinessType.teaStall);
  });

  test('setAuthResult stores displayName used later as the AppUser name', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(onboardingControllerProvider.notifier);

    controller.setAuthResult(const AuthResult(
      uid: 'uid-1',
      displayName: 'Rahim Khan',
      email: 'rahim@example.com',
    ));

    final state = container.read(onboardingControllerProvider);
    expect(state.authResult?.displayName, 'Rahim Khan');
    expect(state.authResult?.uid, 'uid-1');
  });
}
