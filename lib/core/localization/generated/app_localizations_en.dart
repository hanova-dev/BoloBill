// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'BoloBill';

  @override
  String get appTagline => 'Speak and make a bill';

  @override
  String get chooseYourLanguage => 'CHOOSE YOUR LANGUAGE';

  @override
  String get languageUrdu => 'Urdu';

  @override
  String get languageRomanUrdu => 'Roman Urdu';

  @override
  String get languageEnglish => 'English';

  @override
  String get themeDarkLabel => 'Dark Theme';

  @override
  String get themeLightLabel => 'Light Theme';

  @override
  String get placeholderTitle => 'Theme & Language Check';

  @override
  String get placeholderBody =>
      'This screen proves theme and language switching work end-to-end before any real feature is built.';

  @override
  String get placeholderSampleAmountLabel => 'BILL TOTAL';

  @override
  String get placeholderSampleAmount => 'Rs. 1,270';

  @override
  String get signInFailedMessage => 'Sign-in didn\'t work — please try again';

  @override
  String get createAccountTitle => 'Create Your Account';

  @override
  String get chooseAMethod => 'Choose a method';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithPhone => 'Continue with Phone Number';

  @override
  String get googlePrivacyNote =>
      'We only use your name and email from Google — nothing will be posted.';

  @override
  String get enterNumberTitle => 'Enter Number';

  @override
  String get mobileNumberLabel => 'MOBILE NUMBER';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get continueLabel => 'Continue';

  @override
  String get enterCodeTitle => 'Enter Code';

  @override
  String otpSentTo(String phone) {
    return 'Code sent to $phone';
  }

  @override
  String get otpIncorrectMessage => 'That code doesn\'t look right — try again';

  @override
  String get verifyLabel => 'Verify';

  @override
  String get chooseShopTitle => 'Choose Your Shop';

  @override
  String get chooseShopSubtitle => 'Tap a picture that matches your shop';

  @override
  String get businessTypeGrocery => 'Grocery';

  @override
  String get businessTypeTeaStall => 'Tea Stall';

  @override
  String get businessTypeVegetableCart => 'Vegetable Cart';

  @override
  String get businessTypeTailor => 'Tailor';

  @override
  String get businessTypeBakery => 'Bakery';

  @override
  String get businessTypeGeneralStore => 'General Store';

  @override
  String get businessTypeMedicalStore => 'Medical Store';

  @override
  String get businessTypeOther => 'Other';

  @override
  String get micPermissionDenied =>
      'Microphone access is needed to speak — you can still type instead';

  @override
  String get micUnavailable =>
      'Voice isn\'t available on this device right now — please type instead';

  @override
  String get sayYourShopName => 'Say your shop\'s name';

  @override
  String get shopNameHint => 'Your shop\'s name';

  @override
  String get heardItCorrect => 'Heard it — correct?';

  @override
  String get setupCompleteTitle => 'You\'re all set!';

  @override
  String get setupCompleteBody =>
      'Your shop is ready. Let\'s make your first bill.';

  @override
  String get startBillingButton => 'Start Billing';

  @override
  String get todayLabel => 'Today';

  @override
  String get startNewBill => 'Start a new bill';

  @override
  String get tapMicOrManual => 'Tap the mic to speak, or enter items manually';

  @override
  String get enterManually => 'Enter Manually';

  @override
  String get confirmVoiceEntryTitle => 'Confirm Entry';

  @override
  String get manualEntryTitle => 'Add Item';

  @override
  String get lowConfidenceBanner =>
      'Didn\'t catch that clearly — please check and correct';

  @override
  String get itemNameLabel => 'ITEM NAME';

  @override
  String get unitLabel => 'UNIT';

  @override
  String get quantityLabel => 'QUANTITY';

  @override
  String pricePerUnitLabel(String unit) {
    return 'PRICE PER $unit';
  }

  @override
  String get addQuantityOrWeight => 'Add quantity or weight';

  @override
  String get priceLabel => 'PRICE';

  @override
  String get addToBill => 'Add to Bill';

  @override
  String get unitPiece => 'Piece';

  @override
  String get unitDozen => 'Dozen';

  @override
  String get unitKg => 'Kg';

  @override
  String get unitGram => 'Gram';

  @override
  String get unitLitre => 'Litre';

  @override
  String get unitMeter => 'Meter';

  @override
  String get unitCustom => 'Other';

  @override
  String get newBillTitle => 'New Bill';

  @override
  String get khataTag => 'Khata';

  @override
  String get manualLabel => 'Manual';

  @override
  String get calculateTotal => 'Jama Karain';

  @override
  String get noisyPrompt => 'Couldn\'t hear that clearly — please try again';

  @override
  String get listeningEllipsis => 'Listening…';

  @override
  String get tapMicToRetry => 'Tap the mic to speak again';

  @override
  String get billTotalLabel => 'BILL TOTAL';

  @override
  String get listenAgain => 'Listen Again';

  @override
  String get editItems => 'Edit Items';

  @override
  String get confirmBill => 'Confirm Bill';

  @override
  String totalReadBackSpeech(int amount) {
    return 'The total is $amount rupees';
  }

  @override
  String get selectCustomerTitle => 'Select Customer';

  @override
  String get newCustomerTitle => 'New Customer';

  @override
  String get customerNameLabel => 'CUSTOMER NAME';

  @override
  String get customerPhoneLabel => 'PHONE NUMBER';

  @override
  String get noCustomersYet => 'No customers yet — add one to start a khata';

  @override
  String get createKhataButton => 'Add Customer';

  @override
  String get howWillTheyPay => 'How will they pay?';

  @override
  String get paymentCash => 'Cash';

  @override
  String get paymentKhata => 'Khata';

  @override
  String previousBalance(String balance) {
    return 'Previous balance: $balance';
  }

  @override
  String get billSavedTitle => 'Bill Saved';

  @override
  String get billSavedBody => 'The bill was saved successfully.';

  @override
  String get newBillButton => 'New Bill';

  @override
  String get khataListTitle => 'Khata';

  @override
  String get sortByBalance => 'Highest Balance';

  @override
  String get sortByRecent => 'Most Recent';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get tapToAddPhoto => 'Tap to add a photo';

  @override
  String get addCnicPhoto => 'Add CNIC photo (optional)';

  @override
  String get retakePhoto => 'Retake Photo';

  @override
  String get customerOwesLabel => 'CUSTOMER OWES';

  @override
  String get customerClearLabel => 'BALANCE CLEAR';

  @override
  String get shopOwesCustomerLabel => 'YOU OWE CUSTOMER';

  @override
  String get noLedgerEntriesYet => 'No transactions yet for this customer';

  @override
  String get ledgerSaleOnKhata => 'Sale on Khata';

  @override
  String get ledgerPaymentReceived => 'Payment Received';

  @override
  String get recordPaymentButton => 'Record Payment';

  @override
  String get recordPaymentTitle => 'Record Payment';

  @override
  String paymentFromLabel(String name) {
    return 'Payment from $name';
  }

  @override
  String get receiptTitle => 'Receipt';

  @override
  String get shareViaWhatsApp => 'Share via WhatsApp';

  @override
  String get printReceipt => 'Print Receipt';

  @override
  String get bluetoothPermissionDenied => 'Bluetooth access is needed to print';

  @override
  String get noPairedPrinters =>
      'No paired printers found — pair one in Bluetooth settings first';

  @override
  String get printerConnectFailed =>
      'Couldn\'t connect to the printer — please try again';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get todaysSales => 'TODAY\'S SALES';

  @override
  String get thisWeeksSales => 'THIS WEEK\'S SALES';

  @override
  String get khataOutstandingLabel => 'TOTAL KHATA OUTSTANDING';

  @override
  String get recentBillsLabel => 'RECENT BILLS';

  @override
  String get noBillsYet => 'No bills yet';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get shopProfileLabel => 'SHOP PROFILE';

  @override
  String get languageLabel => 'LANGUAGE';

  @override
  String get darkThemeLabel => 'Dark Theme';

  @override
  String get syncStatusLabel => 'SYNC STATUS';

  @override
  String get syncNowButton => 'Sync Now';

  @override
  String get syncStatusIdle => 'Not synced yet';

  @override
  String get syncStatusInProgress => 'Syncing…';

  @override
  String get syncStatusOffline =>
      'You\'re offline — everything stays saved on this device and will sync when you\'re back online.';

  @override
  String get syncStatusError =>
      'Couldn\'t sync — will try again automatically.';

  @override
  String get syncLastSyncedLabel => 'Last synced';

  @override
  String get billSavedOfflineToast => 'Bill saved (offline)';

  @override
  String get receiptSentWhatsAppToast => 'Receipt sent via WhatsApp';

  @override
  String get offlineWillSyncToast => 'No internet — will sync later';

  @override
  String overdueReminderTitle(String name, int days) {
    return '$name — overdue $days days';
  }

  @override
  String overdueReminderBody(String amount) {
    return '$amount owed. Send a reminder?';
  }

  @override
  String overdueReminderGroupTitle(int count) {
    return '$count customers overdue 30+ days';
  }

  @override
  String get remindersChannelName => 'Khata Reminders';

  @override
  String get remindersChannelDescription =>
      'Reminders about customers with overdue khata balances.';

  @override
  String get viewKhataAction => 'View Khata';

  @override
  String get laterReminderAction => 'Later';
}
