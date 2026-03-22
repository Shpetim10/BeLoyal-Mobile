import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/admin_business_dtos.dart';
import '../controllers/admin_business_controller.dart';

class AdminBusinessDetailsPage extends ConsumerStatefulWidget {
  const AdminBusinessDetailsPage({super.key, required this.businessId});
  
  final int businessId;

  @override
  ConsumerState<AdminBusinessDetailsPage> createState() => _AdminBusinessDetailsPageState();
}

class _AdminBusinessDetailsPageState extends ConsumerState<AdminBusinessDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final businessAsync = ref.watch(adminBusinessDetailsProvider(widget.businessId));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: businessAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => _buildErrorState(err.toString()),
        data: (business) => _buildFancyDetails(context, business),
      ),
    );
  }

  Widget _buildFancyDetails(BuildContext context, BusinessDetailsDto business) {
    final hasLogo = business.logoPath != null && business.logoPath!.isNotEmpty;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppColors.surfaceDark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (hasLogo)
                  Image.network(business.logoPath!, fit: BoxFit.cover)
                else
                  Container(
                    color: AppColors.bgDark,
                    child: const Icon(Icons.business_rounded, size: 80, color: AppColors.textMuted),
                  ),
                // Gradient overlay for text legibility
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                        AppColors.bgDark,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        business.businessName,
                        style: const TextStyle(
                           color: Colors.white,
                           fontSize: 28,
                           fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (business.businessType.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            business.businessType,
                            style: const TextStyle(
                               color: AppColors.primaryLight,
                               fontSize: 12,
                               fontWeight: FontWeight.w700,
                               letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildStatusSection(business),
              const SizedBox(height: 20),
              _buildSectionCard('About', Icons.info_outline_rounded, [
                if (business.businessDescription.isNotEmpty)
                  Text(business.businessDescription, style: const TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5))
                else
                  const Text('No description provided.', style: TextStyle(color: AppColors.textMuted, fontStyle: FontStyle.italic)),
              ]),
              const SizedBox(height: 20),
              _buildSectionCard('Contact & Location', Icons.pin_drop_outlined, [
                _buildInfoRow(Icons.phone_rounded, 'Phone', business.businessPhoneNumber),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.location_on_rounded, 'Address', '${business.address}\n${business.city}, ${business.country}'),
                if (business.vatId != null && business.vatId!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.receipt_long_rounded, 'VAT ID', business.vatId!),
                ],
              ]),
              const SizedBox(height: 20),
              _buildSectionCard('Team Members', Icons.people_outline_rounded, [
                if (business.businessMembers.isEmpty)
                  const Text('No team members found.', style: TextStyle(color: AppColors.textMuted))
                else
                  ...business.businessMembers.map((m) => _buildMemberTile(m)),
              ]),
              const SizedBox(height: 60),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection(BusinessDetailsDto business) {
    Color statColor = AppColors.textMuted;
    if (business.businessStatus == 'ACTIVE') statColor = AppColors.secondary;
    if (business.businessStatus == 'PENDING') statColor = AppColors.warning;
    if (business.businessStatus == 'REJECTED') statColor = AppColors.error;

    final DateFormat formatter = DateFormat('MMM d, yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  business.businessStatus,
                  style: TextStyle(color: statColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          if (business.rejectionReason != null && business.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: const Border(left: BorderSide(color: AppColors.error, width: 4)),
              ),
              child: Text(
                'Reason: ${business.rejectionReason}',
                style: const TextStyle(color: AppColors.errorLight, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: AppColors.glassBorder, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDateColumn('Submitted', business.submittedAt != null ? formatter.format(business.submittedAt!) : 'N/A'),
              _buildDateColumn('Reviewed', business.reviewedAt != null ? formatter.format(business.reviewedAt!) : 'Pending'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateColumn(String label, String date) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(date, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryLight, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildMemberTile(BusinessMemberDetailsDto member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            foregroundColor: AppColors.primaryLight,
            child: Text(member.firstName.isNotEmpty ? member.firstName[0].toUpperCase() : '?'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(member.email, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Text(
              member.role.replaceAll('ROLE_', ''),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 64),
            const SizedBox(height: 16),
            const Text('Oops!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.refresh(adminBusinessDetailsProvider(widget.businessId)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
