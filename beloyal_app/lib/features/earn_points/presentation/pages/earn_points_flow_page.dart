import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/earn_points_controller.dart';
import 'guest_identification_screen.dart';
import 'bill_details_screen.dart';
import 'confirmation_screen.dart';
import 'earn_points_result_page.dart';

/// Top-level page for the Earn Points wizard.
///
/// Hosts 3 steps: Guest Identification → Bill Details → Confirmation.
/// Navigation is driven by [EarnPointsDraftState.currentStep].
class EarnPointsFlowPage extends ConsumerStatefulWidget {
  const EarnPointsFlowPage({super.key, required this.businessId});

  final int businessId;

  @override
  ConsumerState<EarnPointsFlowPage> createState() => _EarnPointsFlowPageState();
}

class _EarnPointsFlowPageState extends ConsumerState<EarnPointsFlowPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Reset the wizard state when the flow opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(earnPointsControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = ref.watch(
      earnPointsControllerProvider.select((s) => s.currentStep),
    );
    final isSuccess = ref.watch(
      earnPointsControllerProvider.select((s) => s.isSuccess),
    );

    // Sync PageView with state-driven step changes or success state.
    final targetPage = isSuccess ? 3 : currentStep.index;
    if (_pageController.hasClients &&
        _pageController.page?.round() != targetPage) {
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    return PopScope(
      canPop:
          currentStep == WizardStep.guestIdentification ||
          ref.read(earnPointsControllerProvider).isSuccess,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          // Go back one step instead of popping the route.
          final ctrl = ref.read(earnPointsControllerProvider.notifier);
          if (currentStep == WizardStep.confirmation) {
            ctrl.goToStep(WizardStep.billDetails);
          } else if (currentStep == WizardStep.billDetails) {
            ctrl.goToStep(WizardStep.guestIdentification);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            GuestIdentificationScreen(businessId: widget.businessId),
            BillDetailsScreen(businessId: widget.businessId),
            ConfirmationScreen(businessId: widget.businessId),
            const EarnPointsResultPage(),
          ],
        ),
      ),
    );
  }
}
