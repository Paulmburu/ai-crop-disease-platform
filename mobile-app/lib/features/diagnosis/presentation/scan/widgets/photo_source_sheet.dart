import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:leafcheck/features/diagnosis/presentation/strings/diagnosis_strings.dart';
import 'package:leafcheck/ui/assets/app_assets.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/widgets/diagnosis/leaf_photo.dart';
import 'package:leafcheck/ui/widgets/layout/layout.dart';

enum _Source { camera, gallery, sample }

/// S1a: camera, gallery, or one of the bundled sample leaves (handy on an
/// emulator and for demos). Returns a photo path.
abstract final class PhotoSourceSheet {
  static Future<String?> show(BuildContext context) async {
    final source = await AppBottomSheet.show<_Source>(
      context,
      builder: (c) => const _SourceList(),
    );
    if (source == null || !context.mounted) return null;
    if (source == _Source.sample) {
      return AppBottomSheet.show<String>(
        context,
        expand: true,
        builder: (_) => const _SamplePicker(),
      );
    }
    // Capped size keeps uploads (second opinion) well under the 5 MB limit.
    final photo = await ImagePicker().pickImage(
      source: source == _Source.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    return photo?.path;
  }
}

class _SourceList extends StatelessWidget {
  const _SourceList();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xl,
              0,
              AppSpace.xl,
              AppSpace.sm,
            ),
            child: Text(
              DiagnosisStrings.addPhoto,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
            leading: const Icon(AppIcons.camera),
            title: const Text(DiagnosisStrings.takePhoto),
            onTap: () => Navigator.pop(context, _Source.camera),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
            leading: const Icon(AppIcons.gallery),
            title: const Text(DiagnosisStrings.fromGallery),
            onTap: () => Navigator.pop(context, _Source.gallery),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
            leading: const Icon(AppIcons.sample),
            title: const Text(DiagnosisStrings.useSample),
            onTap: () => Navigator.pop(context, _Source.sample),
          ),
        ],
      ),
    ),
  );
}

class _SamplePicker extends StatelessWidget {
  const _SamplePicker();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        0,
        AppSpace.lg,
        AppSpace.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DiagnosisStrings.pickDemoPhoto,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpace.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpace.sm,
            crossAxisSpacing: AppSpace.sm,
            children: [
              for (final path in AppAssets.leafPhotos)
                Semantics(
                  button: true,
                  label: path.split('/').last,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    onTap: () => Navigator.pop(context, path),
                    child: LeafPhoto(image: AssetImage(path)),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
