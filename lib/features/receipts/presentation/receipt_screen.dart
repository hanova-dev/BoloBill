import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/di/providers.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_color_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/id_generator.dart';
import '../../../domain/entities/bill.dart';
import '../../../domain/entities/bill_item.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/receipt.dart';
import '../../../shared_widgets/receipt_paper.dart';
import '../../billing/presentation/billing_home_screen.dart';
import '../../notifications/presentation/in_app_toast.dart';
import '../application/esc_pos_receipt_formatter.dart';

class _ReceiptData {
  _ReceiptData({required this.bill, required this.items, required this.shopName, this.customerName});
  final Bill bill;
  final List<BillItem> items;
  final String shopName;
  final String? customerName;
}

/// Screen D1 — the post-confirmation receipt (FR-3.5.1-3.5.3): an on-device
/// rendered image the retailer can share to WhatsApp or print over
/// Bluetooth. Replaces the interim bill-saved placeholder that stood in for
/// this since build order step 4.
class ReceiptScreen extends ConsumerStatefulWidget {
  const ReceiptScreen({super.key, required this.billId});

  final String billId;

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  final _receiptKey = GlobalKey();
  late final Future<_ReceiptData> _future = _load();
  bool _busy = false;
  String? _statusMessage;

  Future<_ReceiptData> _load() async {
    final bill = await ref.read(billRepositoryProvider).getBill(widget.billId);
    final items = await ref.read(billRepositoryProvider).getLineItems(widget.billId);
    final shop = await ref.read(shopRepositoryProvider).getShop(bill!.shopId);
    final customer = bill.customerId == null
        ? null
        : await ref.read(customerRepositoryProvider).getCustomer(bill.customerId!);
    return _ReceiptData(bill: bill, items: items, shopName: shop!.shopName, customerName: customer?.name);
  }

  Future<Uint8List> _captureImage() async {
    final boundary = _receiptKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.5);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _logReceipt(_ReceiptData data, ReceiptFormat format, DeliveryChannel channel) {
    return ref.read(receiptRepositoryProvider).createReceipt(Receipt(
          receiptId: IdGenerator.newId(),
          billId: data.bill.billId,
          format: format,
          deliveryChannel: channel,
          sentAt: channel == DeliveryChannel.skipped ? null : DateTime.now(),
        ));
  }

  Future<void> _shareViaWhatsApp(_ReceiptData data) async {
    setState(() => _busy = true);
    try {
      final bytes = await _captureImage();
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, 'receipt_${data.bill.billId}.png'));
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: data.shopName));
      await _logReceipt(data, ReceiptFormat.image, DeliveryChannel.whatsapp);
      if (mounted) {
        showBoloToast(
          context,
          kind: BoloToastKind.whatsapp,
          message: AppLocalizations.of(context).receiptSentWhatsAppToast,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _printViaBluetooth(_ReceiptData data) async {
    final l10n = AppLocalizations.of(context);
    await Permission.bluetoothConnect.request();

    final granted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
    if (!granted) {
      setState(() => _statusMessage = l10n.bluetoothPermissionDenied);
      return;
    }

    final devices = await PrintBluetoothThermal.pairedBluetooths;
    if (devices.isEmpty) {
      setState(() => _statusMessage = l10n.noPairedPrinters);
      return;
    }
    if (!mounted) return;

    final selected = await showModalBottomSheet<BluetoothInfo>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final device in devices)
              ListTile(
                leading: const Icon(Icons.print_outlined),
                title: Text(device.name),
                subtitle: Text(device.macAdress),
                onTap: () => Navigator.of(sheetContext).pop(device),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;

    setState(() {
      _busy = true;
      _statusMessage = null;
    });
    try {
      final connected = await PrintBluetoothThermal.connect(macPrinterAddress: selected.macAdress);
      if (!connected) {
        setState(() => _statusMessage = l10n.printerConnectFailed);
        return;
      }
      final bytes = await EscPosReceiptFormatter.format(
        shopName: data.shopName,
        bill: data.bill,
        items: data.items,
        customerName: data.customerName,
      );
      await PrintBluetoothThermal.writeBytes(bytes);
      await PrintBluetoothThermal.disconnect;
      await _logReceipt(data, ReceiptFormat.print, DeliveryChannel.bluetoothPrinter);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish(_ReceiptData data) async {
    await _logReceipt(data, ReceiptFormat.image, DeliveryChannel.skipped);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const BillingHomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.receiptTitle)),
      body: SafeArea(
        child: FutureBuilder<_ReceiptData>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final data = snapshot.data!;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Center(
                      child: RepaintBoundary(
                        key: _receiptKey,
                        child: ReceiptPaper(
                          shopName: data.shopName,
                          bill: data.bill,
                          items: data.items,
                          customerName: data.customerName,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_statusMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      _statusMessage!,
                      style: type.caption.copyWith(color: colors.alert),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: _busy
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _shareViaWhatsApp(data),
                                    icon: const Icon(Icons.chat_outlined),
                                    label: Text(l10n.shareViaWhatsApp),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _printViaBluetooth(data),
                                    icon: const Icon(Icons.print_outlined),
                                    label: Text(l10n.printReceipt),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () => _finish(data),
                              child: Text(l10n.newBillButton),
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
