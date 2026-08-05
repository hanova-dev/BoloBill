import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/providers.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_color_tokens.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/id_generator.dart';
import '../../../data/media/photo_store.dart';
import '../../../domain/entities/customer.dart';

/// Screen C2 — new customer creation (FR-3.4.4): photo-first, so the
/// retailer can recognize a customer by face later without reading a name.
/// Name/phone stay manual-only here (unlike billing's voice+manual parity) —
/// customer records are created rarely compared to line items, and get it
/// right once rather than risk a misheard name on a persistent record.
class NewCustomerScreen extends ConsumerStatefulWidget {
  const NewCustomerScreen({super.key});

  @override
  ConsumerState<NewCustomerScreen> createState() => _NewCustomerScreenState();
}

class _NewCustomerScreenState extends ConsumerState<NewCustomerScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _picker = ImagePicker();

  String? _profilePhotoPath;
  String? _cnicPhotoPath;
  bool _addCnic = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto({required bool forCnic}) async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(source: source, maxWidth: 1024, imageQuality: 85);
    if (picked == null) return;

    final savedPath = await PhotoStore.save(picked);
    setState(() {
      if (forCnic) {
        _cnicPhotoPath = savedPath;
      } else {
        _profilePhotoPath = savedPath;
      }
    });
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty;

  Future<void> _save() async {
    final shop = ref.read(currentShopProvider);
    if (shop == null || !_canSave) return;

    setState(() => _saving = true);
    final customer = Customer(
      customerId: IdGenerator.newId(),
      shopId: shop.shopId,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      profilePhotoPath: _profilePhotoPath,
      cnicPhotoPath: _cnicPhotoPath,
      createdAt: DateTime.now(),
    );
    await ref.read(customerRepositoryProvider).createCustomer(customer);
    if (!mounted) return;
    Navigator.of(context).pop(customer);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newCustomerTitle)),
      body: SafeArea(
        child: _saving
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: () => _pickPhoto(forCnic: false),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: colors.tint,
                              backgroundImage: _profilePhotoPath == null
                                  ? null
                                  : FileImage(File(_profilePhotoPath!)),
                              child: _profilePhotoPath == null
                                  ? Icon(Icons.person, size: 48, color: colors.textSoft)
                                  : null,
                            ),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: colors.accent,
                              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        l10n.tapToAddPhoto,
                        style: type.caption.copyWith(color: colors.textSoft),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(l10n.customerNameLabel, style: type.eyebrow.copyWith(color: colors.textSoft)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      style: type.bodyEmphasis.copyWith(color: colors.text),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(l10n.customerPhoneLabel, style: type.eyebrow.copyWith(color: colors.textSoft)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: type.bodyEmphasis.copyWith(color: colors.text),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _addCnic,
                      onChanged: (value) => setState(() => _addCnic = value),
                      title: Text(l10n.addCnicPhoto, style: type.body.copyWith(color: colors.text)),
                    ),
                    if (_addCnic) ...[
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () => _pickPhoto(forCnic: true),
                        icon: const Icon(Icons.credit_card),
                        label: Text(_cnicPhotoPath == null ? l10n.takePhoto : l10n.retakePhoto),
                      ),
                    ],
                    const SizedBox(height: 22),
                    ElevatedButton(
                      onPressed: _canSave ? _save : null,
                      child: Text(l10n.createKhataButton),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
