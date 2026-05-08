import 'package:flutter/material.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/features/customer_ui/mock/customer_mock_data.dart';

class CustomerViewAllOffersPage extends StatefulWidget {
  const CustomerViewAllOffersPage({super.key});

  @override
  State<CustomerViewAllOffersPage> createState() => _CustomerViewAllOffersPageState();
}

class _CustomerViewAllOffersPageState extends State<CustomerViewAllOffersPage> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _hotOnly = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MockOffer> get _filtered {
    return CustomerMockData.hotOffers.where((o) {
      if (_searchQuery.isNotEmpty &&
          !o.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !o.businessName.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_hotOnly && !o.isHot) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final offers = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0812),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0812),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hot Offers', style: AppTypography.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textOnDark)),
            Text('Limited-time deals', style: AppTypography.dmSans(fontSize: 12, color: AppColors.textMutedDark)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: AppTypography.dmSans(fontSize: 14, color: AppColors.textOnDark),
                    decoration: InputDecoration(
                      hintText: 'Search offers...',
                      hintStyle: AppTypography.dmSans(fontSize: 14, color: AppColors.textMutedDark),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMutedDark, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                              child: const Icon(Icons.clear_rounded, color: AppColors.textMutedDark, size: 18),
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.cardDark,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.glassBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.glassBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => setState(() => _hotOnly = !_hotOnly),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _hotOnly ? AppColors.error.withValues(alpha: 0.15) : AppColors.cardDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _hotOnly ? AppColors.error.withValues(alpha: 0.4) : AppColors.glassBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department_rounded, color: _hotOnly ? AppColors.error : AppColors.textMutedDark, size: 16),
                        const SizedBox(width: 4),
                        Text('Hot', style: AppTypography.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: _hotOnly ? AppColors.error : AppColors.textMutedDark)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: offers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_offer_outlined, size: 56, color: AppColors.textMutedDark.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('No offers found.', style: AppTypography.dmSans(fontSize: 14, color: AppColors.textMutedDark)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                    physics: const BouncingScrollPhysics(),
                    itemCount: offers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _OfferDetailCard(offer: offers[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OfferDetailCard extends StatelessWidget {
  const _OfferDetailCard({required this.offer});
  final MockOffer offer;

  @override
  Widget build(BuildContext context) {
    final daysLeft = offer.validUntil.difference(DateTime.now()).inDays;
    final hoursLeft = offer.validUntil.difference(DateTime.now()).inHours;
    final urgency = daysLeft <= 0 ? '${hoursLeft}h left' : daysLeft == 1 ? 'Ends tomorrow' : '$daysLeft days left';
    final isUrgent = daysLeft <= 1;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: offer.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: offer.gradientColors.last.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(offer.businessName, style: AppTypography.dmSans(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                    const Spacer(),
                    if (offer.isHot)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department_rounded, size: 11, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('HOT', style: AppTypography.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(offer.multiplier, style: AppTypography.dmMono(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white)),
                Text(offer.title, style: AppTypography.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 6),
                Text(offer.description, style: AppTypography.dmSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.8), height: 1.5)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isUrgent ? Colors.red : Colors.white).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    urgency,
                    style: AppTypography.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isUrgent ? const Color(0xFFFF8080) : Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
