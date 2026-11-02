import 'package:flutter/material.dart';
import 'package:leafcheck/features/diagnosis/presentation/strings/diagnosis_strings.dart';
import 'package:leafcheck/ui/assets/app_assets.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/widgets/diagnosis/leaf_photo.dart';
import 'package:leafcheck/ui/widgets/layout/layout.dart';

/// S1a: camera or gallery. In the mock phase both open a picker of the
/// bundled sample leaves (image_picker arrives in F1). Returns a photo path.
abstract final class PhotoSourceSheet {
  static Future<String?> show(BuildContext context) async {
    final source = await AppBottomSheet.show<bool>(
      context,
      builder: (c) => const _SourceList(),
    );
    if (source == null || !context.mounted) return null;
    return AppBottomSheet.show<String>(
      context,
      expand: true,
      builder: (_) => const _SamplePicker(),
    );
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
            onTap: () => Navigator.pop(context, true),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
            leading: const Icon(AppIcons.gallery),
            title: const Text(DiagnosisStrings.fromGallery),
            onTap: () => Navigator.pop(context, false),
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
