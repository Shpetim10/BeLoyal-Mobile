import 'package:flutter/material.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/features/customer_ui/mock/customer_mock_data.dart';
import 'customer_business_detail_page.dart';

class CustomerViewAllBusinessesPage extends StatefulWidget {
  const CustomerViewAllBusinessesPage({
    super.key,
    this.title = 'All Businesses',
    this.subtitle = 'Where you have points',
    this.businesses,
    this.showAllBusinesses = false,
  });

  final String title;
  final String subtitle;
  final List<MockBusiness>? businesses;
  final bool showAllBusinesses;

  @override
  State<CustomerViewAllBusinessesPage> createState() => _CustomerViewAllBusinessesPageState();
}

class _CustomerViewAllBusinessesPageState extends State<CustomerViewAllBusinessesPage> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _selectedCategoryId = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MockBusiness> get _filtered {
    final source = widget.businesses ?? (widget.showAllBusinesses
        ? CustomerMockData.businesses
        : CustomerMockData.businessesWithPoints);
    var list = source.where((b) {
      if (_searchQuery.isNotEmpty &&
          !b.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !b.category.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_selectedCategoryId != 0 && b.categoryId != _selectedCategoryId) {
        return false;
      }
      return true;
    }).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final businesses = _filtered;

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
            Text(widget.title, style: AppTypography.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textOnDark)),
            Text(widget.subtitle, style: AppTypography.dmSans(fontSize: 12, color: AppColors.textMutedDark)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: AppTypography.dmSans(fontSize: 14, color: AppColors.textOnDark),
              decoration: InputDecoration(
                hintText: 'Search businesses...',
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
          // Category chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _CategoryChip(id: 0, label: 'All', isSelected: _selectedCategoryId == 0, onTap: () => setState(() => _selectedCategoryId = 0)),
                ...CustomerMockData.categories.map((c) => _CategoryChip(
                  id: c.id,
                  label: c.name,
                  isSelected: _selectedCategoryId == c.id,
                  color: c.color,
                  onTap: () => setState(() => _selectedCategoryId = _selectedCategoryId == c.id ? 0 : c.id),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // List
          Expanded(
            child: businesses.isEmpty
                ? _EmptyState(message: 'No businesses found.\nTry a different search or filter.')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                    physics: const BouncingScrollPhysics(),
                    itemCount: businesses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _BusinessListCard(business: businesses[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.id, required this.label, required this.isSelected, required this.onTap, this.color});
  final int id;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? c.withValues(alpha: 0.15) : AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? c.withValues(alpha: 0.5) : AppColors.glassBorder),
        ),
        child: Text(
          label,
          style: AppTypography.dmSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? c : AppColors.textMutedDark,
          ),
        ),
      ),
    );
  }
}

class _BusinessListCard extends StatelessWidget {
  const _BusinessListCard({required this.business});
  final MockBusiness business;

  @override
  Widget build(BuildContext context) {
    final progress = (business.points / business.nextRewardPoints).clamp(0.0, 1.0);
    final remaining = business.nextRewardPoints - business.points;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CustomerBusinessDetailPage(business: business)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            // Cover gradient bar
            Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: business.gradientColors,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: business.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: Text(business.logoEmoji, style: const TextStyle(fontSize: 26))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(business.name, style: AppTypography.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textOnDark)),
                            ),
                            if (business.hasOffer)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
                                ),
                                child: Text(business.offerLabel!, style: AppTypography.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.gold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(business.category, style: AppTypography.dmSans(fontSize: 11, color: AppColors.textMutedDark)),
                            const SizedBox(width: 8),
                            Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.textMutedDark)),
                            const SizedBox(width: 8),
                            const Icon(Icons.star_rounded, color: AppColors.gold, size: 12),
                            const SizedBox(width: 2),
                            Text('${business.rating}', style: AppTypography.dmSans(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.textMutedDark)),
                            const SizedBox(width: 8),
                            Text(business.distance, style: AppTypography.dmSans(fontSize: 11, color: AppColors.textMutedDark)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              '${business.points} pts',
                              style: AppTypography.dmMono(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textOnDark),
                            ),
                            const Spacer(),
                            Text(
                              '$remaining pts to reward',
                              style: AppTypography.dmSans(fontSize: 10, color: AppColors.textMutedDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.glassBorder,
                            color: business.gradientColors.last,
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMutedDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront_outlined, size: 56, color: AppColors.textMutedDark.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: AppTypography.dmSans(fontSize: 14, color: AppColors.textMutedDark, height: 1.6)),
        ],
      ),
    );
  }
}
