// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appName => 'BoloBill';

  @override
  String get appTagline => 'بولو اور بل بناؤ';

  @override
  String get chooseYourLanguage => 'اپنی زبان چنیں';

  @override
  String get languageUrdu => 'اردو';

  @override
  String get languageRomanUrdu => 'رومن اردو';

  @override
  String get languageEnglish => 'انگریزی';

  @override
  String get themeDarkLabel => 'ڈارک تھیم';

  @override
  String get themeLightLabel => 'لائٹ تھیم';

  @override
  String get placeholderTitle => 'تھیم اور زبان چیک';

  @override
  String get placeholderBody =>
      'یہ اسکرین ثابت کرتی ہے کہ اصل فیچرز بننے سے پہلے تھیم اور زبان کی تبدیلی درست کام کر رہی ہے۔';

  @override
  String get placeholderSampleAmountLabel => 'کل رقم';

  @override
  String get placeholderSampleAmount => '1,270 روپے';

  @override
  String get signInFailedMessage => 'سائن ان نہیں ہو سکا — دوبارہ کوشش کریں';

  @override
  String get createAccountTitle => 'اپنا اکاؤنٹ بنائیں';

  @override
  String get chooseAMethod => 'ایک طریقہ چنیں';

  @override
  String get continueWithGoogle => 'گوگل سے جاری رکھیں';

  @override
  String get continueWithPhone => 'فون نمبر سے جاری رکھیں';

  @override
  String get googlePrivacyNote =>
      'گوگل سے صرف نام اور ای میل لیا جائے گا — کوئی پوسٹ نہیں ہوگی۔';

  @override
  String get enterNumberTitle => 'نمبر لکھیں';

  @override
  String get mobileNumberLabel => 'موبائل نمبر';

  @override
  String get sendOtp => 'او ٹی پی بھیجیں';

  @override
  String get continueLabel => 'آگے بڑھیں';

  @override
  String get enterCodeTitle => 'کوڈ درج کریں';

  @override
  String otpSentTo(String phone) {
    return 'کوڈ $phone پر بھیجا گیا';
  }

  @override
  String get otpIncorrectMessage => 'یہ کوڈ درست نہیں لگتا — دوبارہ کوشش کریں';

  @override
  String get verifyLabel => 'تصدیق کریں';

  @override
  String get chooseShopTitle => 'اپنی دکان چنیں';

  @override
  String get chooseShopSubtitle => 'اپنی دکان جیسی تصویر پر دبائیں';

  @override
  String get businessTypeGrocery => 'کریانہ';

  @override
  String get businessTypeTeaStall => 'چائے کا کھوکھا';

  @override
  String get businessTypeVegetableCart => 'سبزی کارٹ';

  @override
  String get businessTypeTailor => 'درزی';

  @override
  String get businessTypeBakery => 'بیکری';

  @override
  String get businessTypeGeneralStore => 'جنرل اسٹور';

  @override
  String get businessTypeOther => 'دیگر';

  @override
  String get micPermissionDenied =>
      'بولنے کے لیے مائیک کی اجازت درکار ہے — آپ ٹائپ بھی کر سکتے ہیں';

  @override
  String get micUnavailable =>
      'اس ڈیوائس پر آواز فی الحال دستیاب نہیں — براہ کرم ٹائپ کریں';

  @override
  String get sayYourShopName => 'دکان کا نام بولیں';

  @override
  String get shopNameHint => 'آپ کی دکان کا نام';

  @override
  String get heardItCorrect => 'سن لیا — ٹھیک ہے؟';

  @override
  String get setupCompleteTitle => 'سب تیار ہے!';

  @override
  String get setupCompleteBody => 'آپ کی دکان تیار ہے۔ آئیں پہلا بل بنائیں۔';

  @override
  String get startBillingButton => 'بلنگ شروع کریں';

  @override
  String get todayLabel => 'آج';

  @override
  String get startNewBill => 'نیا بل بنائیں';

  @override
  String get tapMicOrManual => 'بولنے کے لیے مائیک دبائیں، یا خود لکھیں';

  @override
  String get enterManually => 'خود لکھیں';

  @override
  String get confirmVoiceEntryTitle => 'تصدیق کریں';

  @override
  String get manualEntryTitle => 'چیز شامل کریں';

  @override
  String get lowConfidenceBanner => 'صاف سنائی نہیں دیا — چیک کر کے درست کریں';

  @override
  String get itemNameLabel => 'چیز کا نام';

  @override
  String get unitLabel => 'یونٹ';

  @override
  String get quantityLabel => 'مقدار';

  @override
  String pricePerUnitLabel(String unit) {
    return '$unit کی قیمت';
  }

  @override
  String get addToBill => 'بل میں شامل کریں';

  @override
  String get unitPiece => 'عدد';

  @override
  String get unitDozen => 'درجن';

  @override
  String get unitKg => 'کلو';

  @override
  String get unitGram => 'گرام';

  @override
  String get unitLitre => 'لیٹر';

  @override
  String get unitMeter => 'میٹر';

  @override
  String get unitCustom => 'دیگر';

  @override
  String get newBillTitle => 'نیا بل';

  @override
  String get khataTag => 'کھاتہ';

  @override
  String get manualLabel => 'لکھیں';

  @override
  String get calculateTotal => 'جمع کریں';

  @override
  String get noisyPrompt => 'صاف سنائی نہیں دیا — دوبارہ کوشش کریں';

  @override
  String get listeningEllipsis => 'سن رہا ہے…';

  @override
  String get tapMicToRetry => 'دوبارہ بولنے کے لیے مائیک دبائیں';

  @override
  String get billTotalLabel => 'کل رقم';

  @override
  String get listenAgain => 'دوبارہ سنیں';

  @override
  String get editItems => 'چیزیں تبدیل کریں';

  @override
  String get confirmBill => 'بل کی تصدیق کریں';

  @override
  String totalReadBackSpeech(int amount) {
    return 'کل رقم $amount روپے ہے';
  }

  @override
  String get selectCustomerTitle => 'گاہک چنیں';

  @override
  String get newCustomerTitle => 'نیا گاہک';

  @override
  String get customerNameLabel => 'گاہک کا نام';

  @override
  String get customerPhoneLabel => 'فون نمبر';

  @override
  String get noCustomersYet =>
      'ابھی کوئی گاہک نہیں — کھاتہ شروع کرنے کے لیے ایک شامل کریں';

  @override
  String get createKhataButton => 'گاہک شامل کریں';

  @override
  String get howWillTheyPay => 'ادائیگی کیسے ہوگی؟';

  @override
  String get paymentCash => 'نقد';

  @override
  String get paymentKhata => 'کھاتہ';

  @override
  String previousBalance(String balance) {
    return 'پرانا بقایا: $balance';
  }

  @override
  String get billSavedTitle => 'بل محفوظ ہو گیا';

  @override
  String get billSavedBody => 'بل کامیابی سے محفوظ ہو گیا ہے۔';

  @override
  String get newBillButton => 'نیا بل';

  @override
  String get khataListTitle => 'کھاتہ';

  @override
  String get sortByBalance => 'زیادہ بقایا';

  @override
  String get sortByRecent => 'حالیہ';

  @override
  String get takePhoto => 'تصویر لیں';

  @override
  String get chooseFromGallery => 'گیلری سے چنیں';

  @override
  String get tapToAddPhoto => 'تصویر شامل کرنے کے لیے دبائیں';

  @override
  String get addCnicPhoto => 'شناختی کارڈ کی تصویر شامل کریں (اختیاری)';

  @override
  String get retakePhoto => 'دوبارہ تصویر لیں';

  @override
  String get customerOwesLabel => 'گاہک کے ذمے';

  @override
  String get customerClearLabel => 'بقایا صاف ہے';

  @override
  String get shopOwesCustomerLabel => 'آپ کے ذمے';

  @override
  String get noLedgerEntriesYet => 'اس گاہک کے لیے ابھی کوئی لین دین نہیں';

  @override
  String get ledgerSaleOnKhata => 'کھاتے پر فروخت';

  @override
  String get ledgerPaymentReceived => 'ادائیگی موصول ہوئی';

  @override
  String get recordPaymentButton => 'ادائیگی درج کریں';

  @override
  String get recordPaymentTitle => 'ادائیگی درج کریں';

  @override
  String paymentFromLabel(String name) {
    return '$name کی ادائیگی';
  }

  @override
  String get receiptTitle => 'رسید';

  @override
  String get shareViaWhatsApp => 'واٹس ایپ پر بھیجیں';

  @override
  String get printReceipt => 'رسید پرنٹ کریں';

  @override
  String get bluetoothPermissionDenied =>
      'پرنٹ کرنے کے لیے بلوٹوتھ کی اجازت درکار ہے';

  @override
  String get noPairedPrinters =>
      'کوئی پرنٹر نہیں ملا — پہلے بلوٹوتھ سیٹنگز میں پرنٹر جوڑیں';

  @override
  String get printerConnectFailed =>
      'پرنٹر سے رابطہ نہیں ہو سکا — دوبارہ کوشش کریں';

  @override
  String get reportsTitle => 'رپورٹس';

  @override
  String get todaysSales => 'آج کی فروخت';

  @override
  String get thisWeeksSales => 'اس ہفتے کی فروخت';

  @override
  String get khataOutstandingLabel => 'کل کھاتہ بقایا';

  @override
  String get recentBillsLabel => 'حالیہ بل';

  @override
  String get noBillsYet => 'ابھی کوئی بل نہیں';

  @override
  String get settingsTitle => 'ترتیبات';

  @override
  String get shopProfileLabel => 'دکان کی معلومات';

  @override
  String get languageLabel => 'زبان';

  @override
  String get darkThemeLabel => 'ڈارک تھیم';

  @override
  String get syncStatusLabel => 'سنک اسٹیٹس';

  @override
  String get syncNowButton => 'ابھی سنک کریں';

  @override
  String get syncStatusIdle => 'ابھی تک سنک نہیں ہوا';

  @override
  String get syncStatusInProgress => 'سنک ہو رہا ہے…';

  @override
  String get syncStatusOffline =>
      'آپ آف لائن ہیں — سب کچھ اس ڈیوائس پر محفوظ ہے اور آن لائن آتے ہی سنک ہو جائے گا۔';

  @override
  String get syncStatusError =>
      'سنک نہیں ہو سکا — دوبارہ خودکار کوشش کی جائے گی۔';

  @override
  String get syncLastSyncedLabel => 'آخری سنک';

  @override
  String get billSavedOfflineToast => 'بل محفوظ ہو گیا (آف لائن)';

  @override
  String get receiptSentWhatsAppToast => 'رسید واٹس ایپ پر بھیج دی گئی';

  @override
  String get offlineWillSyncToast => 'انٹرنیٹ نہیں ہے — بعد میں سنک ہو جائے گا';

  @override
  String overdueReminderTitle(String name, int days) {
    return '$name — $days دن سے واجب الادا';
  }

  @override
  String overdueReminderBody(String amount) {
    return '$amount واجب الادا ہیں۔ یاد دہانی بھیجیں؟';
  }

  @override
  String overdueReminderGroupTitle(int count) {
    return '$count گاہک 30+ دن سے واجب الادا';
  }

  @override
  String get remindersChannelName => 'کھاتہ یاد دہانیاں';

  @override
  String get remindersChannelDescription =>
      'واجب الادا کھاتہ بیلنس والے گاہکوں کی یاد دہانیاں۔';

  @override
  String get viewKhataAction => 'کھاتہ دیکھیں';

  @override
  String get laterReminderAction => 'بعد میں';
}

/// The translations for Urdu, using the Latin script (`ur_Latn`).
class AppLocalizationsUrLatn extends AppLocalizationsUr {
  AppLocalizationsUrLatn() : super('ur_Latn');

  @override
  String get appName => 'BoloBill';

  @override
  String get appTagline => 'Bolo aur Bill Banao';

  @override
  String get chooseYourLanguage => 'APNI ZUBAAN CHUNAIN';

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
  String get placeholderTitle => 'Theme aur Zubaan Check';

  @override
  String get placeholderBody =>
      'Yeh screen sabit karti hai keh asal features banne se pehle theme aur zubaan ki tabdeeli theek kaam kar rahi hai.';

  @override
  String get placeholderSampleAmountLabel => 'BILL TOTAL';

  @override
  String get placeholderSampleAmount => 'Rs. 1,270';

  @override
  String get signInFailedMessage =>
      'Sign-in nahi ho saka — dobara koshish karein';

  @override
  String get createAccountTitle => 'Apna Account Banayein';

  @override
  String get chooseAMethod => 'Ek tareeqa chunain';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithPhone => 'Phone Number Se Jaari Rakhein';

  @override
  String get googlePrivacyNote =>
      'Google se sirf naam aur email liya jayega — koi post nahi hogi.';

  @override
  String get enterNumberTitle => 'Number Likhein';

  @override
  String get mobileNumberLabel => 'MOBILE NUMBER';

  @override
  String get sendOtp => 'OTP Bhejein';

  @override
  String get continueLabel => 'Aagay Barhein';

  @override
  String get enterCodeTitle => 'Code Darj Karein';

  @override
  String otpSentTo(String phone) {
    return 'Code $phone par bheja gaya';
  }

  @override
  String get otpIncorrectMessage =>
      'Yeh code theek nahi lagta — dobara koshish karein';

  @override
  String get verifyLabel => 'Tasdeeq Karein';

  @override
  String get chooseShopTitle => 'Apni Dukaan Chunain';

  @override
  String get chooseShopSubtitle => 'Tap a picture that matches your shop';

  @override
  String get businessTypeGrocery => 'Kirana';

  @override
  String get businessTypeTeaStall => 'Chai Khoka';

  @override
  String get businessTypeVegetableCart => 'Sabzi Cart';

  @override
  String get businessTypeTailor => 'Tailor';

  @override
  String get businessTypeBakery => 'Bakery';

  @override
  String get businessTypeGeneralStore => 'General';

  @override
  String get businessTypeOther => 'Other';

  @override
  String get micPermissionDenied =>
      'Bolne ke liye mic ki ijazat chahiye — aap type bhi kar sakte hain';

  @override
  String get micUnavailable =>
      'Is device par awaz abhi dastyab nahi — please type karein';

  @override
  String get sayYourShopName => 'Dukaan ka naam bolein';

  @override
  String get shopNameHint => 'Aap ki dukaan ka naam';

  @override
  String get heardItCorrect => 'Sun liya — theek hai?';

  @override
  String get setupCompleteTitle => 'Sab tayar hai!';

  @override
  String get setupCompleteBody =>
      'Aap ki dukaan tayar hai. Aayein pehla bill banayein.';

  @override
  String get startBillingButton => 'Billing Shuru Karein';

  @override
  String get todayLabel => 'Aaj';

  @override
  String get startNewBill => 'Naya Bill Banayein';

  @override
  String get tapMicOrManual => 'Bolne ke liye mic dabayein, ya khud likhein';

  @override
  String get enterManually => 'Khud Likhein';

  @override
  String get confirmVoiceEntryTitle => 'Tasdeeq Karein';

  @override
  String get manualEntryTitle => 'Cheez Shamil Karein';

  @override
  String get lowConfidenceBanner =>
      'Saaf sunai nahi diya — check kar ke theek karein';

  @override
  String get itemNameLabel => 'Cheez Ka Naam';

  @override
  String get unitLabel => 'Unit';

  @override
  String get quantityLabel => 'Miqdaar';

  @override
  String pricePerUnitLabel(String unit) {
    return '$unit Ki Qeemat';
  }

  @override
  String get addToBill => 'Bill Mein Shamil Karein';

  @override
  String get unitPiece => 'Adad';

  @override
  String get unitDozen => 'Dozen';

  @override
  String get unitKg => 'Kilo';

  @override
  String get unitGram => 'Gram';

  @override
  String get unitLitre => 'Litre';

  @override
  String get unitMeter => 'Meter';

  @override
  String get unitCustom => 'Doosra';

  @override
  String get newBillTitle => 'Naya Bill';

  @override
  String get khataTag => 'Khata';

  @override
  String get manualLabel => 'Likhein';

  @override
  String get calculateTotal => 'Jama Karain';

  @override
  String get noisyPrompt => 'Saaf sunai nahi diya — dobara koshish karein';

  @override
  String get listeningEllipsis => 'Sun raha hai…';

  @override
  String get tapMicToRetry => 'Dobara bolne ke liye mic dabayein';

  @override
  String get billTotalLabel => 'Kul Raqam';

  @override
  String get listenAgain => 'Dobara Sunein';

  @override
  String get editItems => 'Cheezein Tabdeel Karein';

  @override
  String get confirmBill => 'Bill Confirm Karein';

  @override
  String totalReadBackSpeech(int amount) {
    return 'Kul raqam $amount rupay hai';
  }

  @override
  String get selectCustomerTitle => 'Grahak Chunain';

  @override
  String get newCustomerTitle => 'Naya Grahak';

  @override
  String get customerNameLabel => 'Grahak Ka Naam';

  @override
  String get customerPhoneLabel => 'Phone Number';

  @override
  String get noCustomersYet =>
      'Abhi koi grahak nahi — khata shuru karne ke liye ek shamil karein';

  @override
  String get createKhataButton => 'Grahak Shamil Karein';

  @override
  String get howWillTheyPay => 'Payment Kaise Hogi?';

  @override
  String get paymentCash => 'Nakad';

  @override
  String get paymentKhata => 'Khata';

  @override
  String previousBalance(String balance) {
    return 'Purana baqaya: $balance';
  }

  @override
  String get billSavedTitle => 'Bill Save Ho Gaya';

  @override
  String get billSavedBody => 'Bill kamyabi se save ho gaya hai.';

  @override
  String get newBillButton => 'Naya Bill';

  @override
  String get khataListTitle => 'Khata';

  @override
  String get sortByBalance => 'Zyada Baqaya';

  @override
  String get sortByRecent => 'Haliya';

  @override
  String get takePhoto => 'Tasveer Lein';

  @override
  String get chooseFromGallery => 'Gallery Se Chunain';

  @override
  String get tapToAddPhoto => 'Tasveer shamil karne ke liye dabayein';

  @override
  String get addCnicPhoto => 'CNIC ki tasveer shamil karein (ikhtiyari)';

  @override
  String get retakePhoto => 'Dobara Tasveer Lein';

  @override
  String get customerOwesLabel => 'Grahak Ke Zimme';

  @override
  String get customerClearLabel => 'Baqaya Saaf Hai';

  @override
  String get shopOwesCustomerLabel => 'Aap Ke Zimme';

  @override
  String get noLedgerEntriesYet => 'Is grahak ke liye abhi koi len den nahi';

  @override
  String get ledgerSaleOnKhata => 'Khaty Par Farokht';

  @override
  String get ledgerPaymentReceived => 'Payment Mil Gayi';

  @override
  String get recordPaymentButton => 'Payment Darj Karein';

  @override
  String get recordPaymentTitle => 'Payment Darj Karein';

  @override
  String paymentFromLabel(String name) {
    return '$name Ki Payment';
  }

  @override
  String get receiptTitle => 'Receipt';

  @override
  String get shareViaWhatsApp => 'WhatsApp Par Bhejein';

  @override
  String get printReceipt => 'Receipt Print Karein';

  @override
  String get bluetoothPermissionDenied =>
      'Print karne ke liye Bluetooth ki ijazat chahiye';

  @override
  String get noPairedPrinters =>
      'Koi printer nahi mila — pehle Bluetooth settings mein printer jorein';

  @override
  String get printerConnectFailed =>
      'Printer se rabta nahi ho saka — dobara koshish karein';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get todaysSales => 'Aaj Ki Farokht';

  @override
  String get thisWeeksSales => 'Is Hafte Ki Farokht';

  @override
  String get khataOutstandingLabel => 'Kul Khata Baqaya';

  @override
  String get recentBillsLabel => 'Haliya Bill';

  @override
  String get noBillsYet => 'Abhi koi bill nahi';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get shopProfileLabel => 'Dukaan Ki Maloomat';

  @override
  String get languageLabel => 'Zubaan';

  @override
  String get darkThemeLabel => 'Dark Theme';

  @override
  String get syncStatusLabel => 'Sync Status';

  @override
  String get syncNowButton => 'Abhi Sync Karein';

  @override
  String get syncStatusIdle => 'Abhi tak sync nahi hua';

  @override
  String get syncStatusInProgress => 'Sync ho raha hai…';

  @override
  String get syncStatusOffline =>
      'Aap offline hain — sab kuch is device par mehfooz hai aur online aate hi sync ho jayega.';

  @override
  String get syncStatusError =>
      'Sync nahi ho saka — dobara khud-kaar koshish ki jayegi.';

  @override
  String get syncLastSyncedLabel => 'Aakhri Sync';

  @override
  String get billSavedOfflineToast => 'Bill mehfooz ho gaya (offline)';

  @override
  String get receiptSentWhatsAppToast => 'Receipt WhatsApp par bhej di gayi';

  @override
  String get offlineWillSyncToast =>
      'Internet nahi hai — baad mein sync ho jayega';

  @override
  String overdueReminderTitle(String name, int days) {
    return '$name — $days din se waajib-ul-ada';
  }

  @override
  String overdueReminderBody(String amount) {
    return '$amount waajib-ul-ada hain. Yaad dahani bhejein?';
  }

  @override
  String overdueReminderGroupTitle(int count) {
    return '$count customers 30+ din se waajib-ul-ada';
  }

  @override
  String get remindersChannelName => 'Khata Yaad Dahaniyan';

  @override
  String get remindersChannelDescription =>
      'Waajib-ul-ada khata balance wale customers ki yaad dahaniyan.';

  @override
  String get viewKhataAction => 'Khata Dekhein';

  @override
  String get laterReminderAction => 'Baad Mein';
}
