import 'package:flutter/material.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/core/widgets/besa_loader.dart';

class CustomerLoadingState extends StatelessWidget {
  const CustomerLoadingState({
    super.key,
    this.message = 'Loading your rewards…',
    this.padding = const EdgeInsets.all(24),
    this.fullPage = false,
  });

  final String message;
  final EdgeInsetsGeometry padding;
  final bool fullPage;

  @override
  Widget build(BuildContext context) {
    if (fullPage) {
      return BesaLoadingPage(message: message, showBackground: false);
    }
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BesaLoader(size: 32),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.dmSans(
                fontSize: 13,
                color: AppColors.textMutedDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerErrorState extends StatelessWidget {
  const CustomerErrorState({
    super.key,
    required this.onRetry,
    this.title = 'Could not load customer data',
    this.message = 'Please try again.',
  });

  final VoidCallback onRetry;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.error,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textOnDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.dmSans(
                  fontSize: 13,
                  color: AppColors.textMutedDark,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
