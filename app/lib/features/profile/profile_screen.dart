import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState authState = ref.watch(authControllerProvider);
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;

    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screen,
          child: Column(
            children: <Widget>[
              AppSpacing.gapXl,
              CircleAvatar(
                radius: 48,
                backgroundColor: colors.primaryContainer,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: textStyles.headlineMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AppSpacing.gapLg,
              Text(
                user.name,
                style: textStyles.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              AppSpacing.gapXs,
              Text(
                user.email,
                style: textStyles.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
              if (authState.isOffline) ...<Widget>[
                AppSpacing.gapSm,
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.tertiaryContainer,
                    borderRadius: AppRadius.small,
                  ),
                  child: Text(
                    'Offline Mode',
                    style: textStyles.labelSmall?.copyWith(color: colors.onTertiaryContainer),
                  ),
                ),
              ],
              AppSpacing.gapXxl,
              Card(
                elevation: 0,
                color: colors.surfaceContainerLow,
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.large),
                child: Padding(
                  padding: AppSpacing.card,
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        leading: Icon(Icons.school_outlined, color: colors.primary),
                        title: const Text('StudentOS Plan'),
                        subtitle: const Text('Free MVP Tier'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.security_outlined, color: colors.primary),
                        title: const Text('Security & Data'),
                        subtitle: const Text('Local SQLite cache + JWT'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.info_outline_rounded, color: colors.primary),
                        title: const Text('Version'),
                        subtitle: const Text('StudentOS MVP v1.0.0'),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.gapXxl,
              SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).logout();
                  },
                  icon: Icon(Icons.logout_rounded, color: colors.error),
                  label: Text('Sign Out', style: TextStyle(color: colors.error)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.error),
                    shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
