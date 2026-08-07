import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur'),
    Locale.fromSubtags(languageCode: 'ur', scriptCode: 'Latn'),
  ];

  /// Brand name — never translated (SRS §11.1: phonetically simple in all three languages).
  ///
  /// In en, this message translates to:
  /// **'BoloBill'**
  String get appName;

  /// SRS §11.1 tagline, 'Bolo aur Bill Banao', localized per language.
  ///
  /// In en, this message translates to:
  /// **'Speak and make a bill'**
  String get appTagline;

  /// No description provided for @chooseYourLanguage.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE YOUR LANGUAGE'**
  String get chooseYourLanguage;

  /// No description provided for @languageUrdu.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get languageUrdu;

  /// No description provided for @languageRomanUrdu.
  ///
  /// In en, this message translates to:
  /// **'Roman Urdu'**
  String get languageRomanUrdu;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @themeDarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get themeDarkLabel;

  /// No description provided for @themeLightLabel.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get themeLightLabel;

  /// No description provided for @placeholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme & Language Check'**
  String get placeholderTitle;

  /// No description provided for @placeholderBody.
  ///
  /// In en, this message translates to:
  /// **'This screen proves theme and language switching work end-to-end before any real feature is built.'**
  String get placeholderBody;

  /// No description provided for @placeholderSampleAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'BILL TOTAL'**
  String get placeholderSampleAmountLabel;

  /// No description provided for @placeholderSampleAmount.
  ///
  /// In en, this message translates to:
  /// **'Rs. 1,270'**
  String get placeholderSampleAmount;

  /// No description provided for @signInFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign-in didn\'t work — please try again'**
  String get signInFailedMessage;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Your Account'**
  String get createAccountTitle;

  /// No description provided for @chooseAMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose a method'**
  String get chooseAMethod;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Continue with Phone Number'**
  String get continueWithPhone;

  /// No description provided for @googlePrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'We only use your name and email from Google — nothing will be posted.'**
  String get googlePrivacyNote;

  /// No description provided for @enterNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Number'**
  String get enterNumberTitle;

  /// No description provided for @mobileNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'MOBILE NUMBER'**
  String get mobileNumberLabel;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @enterCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Code'**
  String get enterCodeTitle;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {phone}'**
  String otpSentTo(String phone);

  /// No description provided for @otpIncorrectMessage.
  ///
  /// In en, this message translates to:
  /// **'That code doesn\'t look right — try again'**
  String get otpIncorrectMessage;

  /// No description provided for @verifyLabel.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyLabel;

  /// No description provided for @chooseShopTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Shop'**
  String get chooseShopTitle;

  /// No description provided for @chooseShopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap a picture that matches your shop'**
  String get chooseShopSubtitle;

  /// No description provided for @businessTypeGrocery.
  ///
  /// In en, this message translates to:
  /// **'Grocery'**
  String get businessTypeGrocery;

  /// No description provided for @businessTypeTeaStall.
  ///
  /// In en, this message translates to:
  /// **'Tea Stall'**
  String get businessTypeTeaStall;

  /// No description provided for @businessTypeVegetableCart.
  ///
  /// In en, this message translates to:
  /// **'Vegetable Cart'**
  String get businessTypeVegetableCart;

  /// No description provided for @businessTypeTailor.
  ///
  /// In en, this message translates to:
  /// **'Tailor'**
  String get businessTypeTailor;

  /// No description provided for @businessTypeBakery.
  ///
  /// In en, this message translates to:
  /// **'Bakery'**
  String get businessTypeBakery;

  /// No description provided for @businessTypeGeneralStore.
  ///
  /// In en, this message translates to:
  /// **'General Store'**
  String get businessTypeGeneralStore;

  /// No description provided for @businessTypeMedicalStore.
  ///
  /// In en, this message translates to:
  /// **'Medical Store'**
  String get businessTypeMedicalStore;

  /// No description provided for @businessTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get businessTypeOther;

  /// No description provided for @micPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is needed to speak — you can still type instead'**
  String get micPermissionDenied;

  /// No description provided for @micUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice isn\'t available on this device right now — please type instead'**
  String get micUnavailable;

  /// No description provided for @sayYourShopName.
  ///
  /// In en, this message translates to:
  /// **'Say your shop\'s name'**
  String get sayYourShopName;

  /// No description provided for @shopNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your shop\'s name'**
  String get shopNameHint;

  /// No description provided for @heardItCorrect.
  ///
  /// In en, this message translates to:
  /// **'Heard it — correct?'**
  String get heardItCorrect;

  /// No description provided for @setupCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get setupCompleteTitle;

  /// No description provided for @setupCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Your shop is ready. Let\'s make your first bill.'**
  String get setupCompleteBody;

  /// No description provided for @startBillingButton.
  ///
  /// In en, this message translates to:
  /// **'Start Billing'**
  String get startBillingButton;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @startNewBill.
  ///
  /// In en, this message translates to:
  /// **'Start a new bill'**
  String get startNewBill;

  /// No description provided for @tapMicOrManual.
  ///
  /// In en, this message translates to:
  /// **'Tap the mic to speak, or enter items manually'**
  String get tapMicOrManual;

  /// No description provided for @enterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter Manually'**
  String get enterManually;

  /// No description provided for @confirmVoiceEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Entry'**
  String get confirmVoiceEntryTitle;

  /// No description provided for @manualEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get manualEntryTitle;

  /// No description provided for @lowConfidenceBanner.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t catch that clearly — please check and correct'**
  String get lowConfidenceBanner;

  /// No description provided for @itemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'ITEM NAME'**
  String get itemNameLabel;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'UNIT'**
  String get unitLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'QUANTITY'**
  String get quantityLabel;

  /// No description provided for @pricePerUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'PRICE PER {unit}'**
  String pricePerUnitLabel(String unit);

  /// No description provided for @addQuantityOrWeight.
  ///
  /// In en, this message translates to:
  /// **'Add quantity or weight'**
  String get addQuantityOrWeight;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'PRICE'**
  String get priceLabel;

  /// No description provided for @addToBill.
  ///
  /// In en, this message translates to:
  /// **'Add to Bill'**
  String get addToBill;

  /// No description provided for @unitPiece.
  ///
  /// In en, this message translates to:
  /// **'Piece'**
  String get unitPiece;

  /// No description provided for @unitDozen.
  ///
  /// In en, this message translates to:
  /// **'Dozen'**
  String get unitDozen;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'Kg'**
  String get unitKg;

  /// No description provided for @unitGram.
  ///
  /// In en, this message translates to:
  /// **'Gram'**
  String get unitGram;

  /// No description provided for @unitLitre.
  ///
  /// In en, this message translates to:
  /// **'Litre'**
  String get unitLitre;

  /// No description provided for @unitMeter.
  ///
  /// In en, this message translates to:
  /// **'Meter'**
  String get unitMeter;

  /// No description provided for @unitCustom.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get unitCustom;

  /// No description provided for @newBillTitle.
  ///
  /// In en, this message translates to:
  /// **'New Bill'**
  String get newBillTitle;

  /// No description provided for @khataTag.
  ///
  /// In en, this message translates to:
  /// **'Khata'**
  String get khataTag;

  /// No description provided for @manualLabel.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manualLabel;

  /// No description provided for @calculateTotal.
  ///
  /// In en, this message translates to:
  /// **'Jama Karain'**
  String get calculateTotal;

  /// No description provided for @noisyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t hear that clearly — please try again'**
  String get noisyPrompt;

  /// No description provided for @listeningEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get listeningEllipsis;

  /// No description provided for @holdMicToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Hold the mic and speak'**
  String get holdMicToSpeak;

  /// No description provided for @billTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'BILL TOTAL'**
  String get billTotalLabel;

  /// No description provided for @listenAgain.
  ///
  /// In en, this message translates to:
  /// **'Listen Again'**
  String get listenAgain;

  /// No description provided for @editItems.
  ///
  /// In en, this message translates to:
  /// **'Edit Items'**
  String get editItems;

  /// No description provided for @confirmBill.
  ///
  /// In en, this message translates to:
  /// **'Confirm Bill'**
  String get confirmBill;

  /// No description provided for @totalReadBackSpeech.
  ///
  /// In en, this message translates to:
  /// **'The total is {amount} rupees'**
  String totalReadBackSpeech(int amount);

  /// No description provided for @selectCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Customer'**
  String get selectCustomerTitle;

  /// No description provided for @newCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'New Customer'**
  String get newCustomerTitle;

  /// No description provided for @customerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'CUSTOMER NAME'**
  String get customerNameLabel;

  /// No description provided for @customerPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'PHONE NUMBER'**
  String get customerPhoneLabel;

  /// No description provided for @noCustomersYet.
  ///
  /// In en, this message translates to:
  /// **'No customers yet — add one to start a khata'**
  String get noCustomersYet;

  /// No description provided for @createKhataButton.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get createKhataButton;

  /// No description provided for @howWillTheyPay.
  ///
  /// In en, this message translates to:
  /// **'How will they pay?'**
  String get howWillTheyPay;

  /// No description provided for @paymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentCash;

  /// No description provided for @paymentKhata.
  ///
  /// In en, this message translates to:
  /// **'Khata'**
  String get paymentKhata;

  /// No description provided for @previousBalance.
  ///
  /// In en, this message translates to:
  /// **'Previous balance: {balance}'**
  String previousBalance(String balance);

  /// No description provided for @billSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Bill Saved'**
  String get billSavedTitle;

  /// No description provided for @billSavedBody.
  ///
  /// In en, this message translates to:
  /// **'The bill was saved successfully.'**
  String get billSavedBody;

  /// No description provided for @newBillButton.
  ///
  /// In en, this message translates to:
  /// **'New Bill'**
  String get newBillButton;

  /// No description provided for @khataListTitle.
  ///
  /// In en, this message translates to:
  /// **'Khata'**
  String get khataListTitle;

  /// No description provided for @sortByBalance.
  ///
  /// In en, this message translates to:
  /// **'Highest Balance'**
  String get sortByBalance;

  /// No description provided for @sortByRecent.
  ///
  /// In en, this message translates to:
  /// **'Most Recent'**
  String get sortByRecent;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @tapToAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to add a photo'**
  String get tapToAddPhoto;

  /// No description provided for @addCnicPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add CNIC photo (optional)'**
  String get addCnicPhoto;

  /// No description provided for @retakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake Photo'**
  String get retakePhoto;

  /// No description provided for @customerOwesLabel.
  ///
  /// In en, this message translates to:
  /// **'CUSTOMER OWES'**
  String get customerOwesLabel;

  /// No description provided for @customerClearLabel.
  ///
  /// In en, this message translates to:
  /// **'BALANCE CLEAR'**
  String get customerClearLabel;

  /// No description provided for @shopOwesCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'YOU OWE CUSTOMER'**
  String get shopOwesCustomerLabel;

  /// No description provided for @noLedgerEntriesYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet for this customer'**
  String get noLedgerEntriesYet;

  /// No description provided for @ledgerSaleOnKhata.
  ///
  /// In en, this message translates to:
  /// **'Sale on Khata'**
  String get ledgerSaleOnKhata;

  /// No description provided for @ledgerPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get ledgerPaymentReceived;

  /// No description provided for @ledgerPaymentReversed.
  ///
  /// In en, this message translates to:
  /// **'Payment Reversed'**
  String get ledgerPaymentReversed;

  /// No description provided for @recordPaymentButton.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPaymentButton;

  /// No description provided for @recordPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPaymentTitle;

  /// No description provided for @paymentFromLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment from {name}'**
  String paymentFromLabel(String name);

  /// No description provided for @undoPaymentAction.
  ///
  /// In en, this message translates to:
  /// **'Undo Payment'**
  String get undoPaymentAction;

  /// No description provided for @undoPaymentConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Undo this payment?'**
  String get undoPaymentConfirmTitle;

  /// No description provided for @undoPaymentConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This reverses the {amount} payment and adds it back to the balance. This can\'t be undone.'**
  String undoPaymentConfirmBody(String amount);

  /// No description provided for @undoPaymentConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Undo Payment'**
  String get undoPaymentConfirmButton;

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @paymentUndoneToast.
  ///
  /// In en, this message translates to:
  /// **'Payment undone'**
  String get paymentUndoneToast;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptTitle;

  /// No description provided for @shareViaWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Share via WhatsApp'**
  String get shareViaWhatsApp;

  /// No description provided for @printReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print Receipt'**
  String get printReceipt;

  /// No description provided for @bluetoothPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth access is needed to print'**
  String get bluetoothPermissionDenied;

  /// No description provided for @noPairedPrinters.
  ///
  /// In en, this message translates to:
  /// **'No paired printers found — pair one in Bluetooth settings first'**
  String get noPairedPrinters;

  /// No description provided for @printerConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect to the printer — please try again'**
  String get printerConnectFailed;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @todaysSales.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S SALES'**
  String get todaysSales;

  /// No description provided for @thisWeeksSales.
  ///
  /// In en, this message translates to:
  /// **'THIS WEEK\'S SALES'**
  String get thisWeeksSales;

  /// No description provided for @khataOutstandingLabel.
  ///
  /// In en, this message translates to:
  /// **'TOTAL KHATA OUTSTANDING'**
  String get khataOutstandingLabel;

  /// No description provided for @recentBillsLabel.
  ///
  /// In en, this message translates to:
  /// **'RECENT BILLS'**
  String get recentBillsLabel;

  /// No description provided for @noBillsYet.
  ///
  /// In en, this message translates to:
  /// **'No bills yet'**
  String get noBillsYet;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @shopProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'SHOP PROFILE'**
  String get shopProfileLabel;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get languageLabel;

  /// No description provided for @darkThemeLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkThemeLabel;

  /// No description provided for @syncStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'SYNC STATUS'**
  String get syncStatusLabel;

  /// No description provided for @syncNowButton.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNowButton;

  /// No description provided for @syncStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get syncStatusIdle;

  /// No description provided for @syncStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncStatusInProgress;

  /// No description provided for @syncStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — everything stays saved on this device and will sync when you\'re back online.'**
  String get syncStatusOffline;

  /// No description provided for @syncStatusError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync — will try again automatically.'**
  String get syncStatusError;

  /// No description provided for @syncLastSyncedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last synced'**
  String get syncLastSyncedLabel;

  /// No description provided for @billSavedOfflineToast.
  ///
  /// In en, this message translates to:
  /// **'Bill saved (offline)'**
  String get billSavedOfflineToast;

  /// No description provided for @receiptSentWhatsAppToast.
  ///
  /// In en, this message translates to:
  /// **'Receipt sent via WhatsApp'**
  String get receiptSentWhatsAppToast;

  /// No description provided for @offlineWillSyncToast.
  ///
  /// In en, this message translates to:
  /// **'No internet — will sync later'**
  String get offlineWillSyncToast;

  /// No description provided for @overdueReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} — overdue {days} days'**
  String overdueReminderTitle(String name, int days);

  /// No description provided for @overdueReminderBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} owed. Send a reminder?'**
  String overdueReminderBody(String amount);

  /// No description provided for @overdueReminderGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} customers overdue 30+ days'**
  String overdueReminderGroupTitle(int count);

  /// No description provided for @remindersChannelName.
  ///
  /// In en, this message translates to:
  /// **'Khata Reminders'**
  String get remindersChannelName;

  /// No description provided for @remindersChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Reminders about customers with overdue khata balances.'**
  String get remindersChannelDescription;

  /// No description provided for @viewKhataAction.
  ///
  /// In en, this message translates to:
  /// **'View Khata'**
  String get viewKhataAction;

  /// No description provided for @laterReminderAction.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get laterReminderAction;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'ur':
      {
        switch (locale.scriptCode) {
          case 'Latn':
            return AppLocalizationsUrLatn();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
