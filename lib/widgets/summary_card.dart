import 'package:flutter/material.dart';
import '../models/recipe.dart';

class SummaryCard extends StatelessWidget {
  final List<Recipe> recipes;

  const SummaryCard({
    super.key,
    required this.recipes,
  });

  @override
  Widget build(BuildContext context) {
    final int recipeCount = recipes.length;
    final int favoriteCount = recipes.where((r) => r.favorite).length;
    final int totalCookTime =
        recipes.fold<int>(0, (sum, r) => sum + r.cookTime);

    // Count categories
    final Map<String, int> categoryCounts = {};
    for (final recipe in recipes) {
      categoryCounts[recipe.category] =
          (categoryCounts[recipe.category] ?? 0) + 1;
    }

    // Sort category breakdown:
    // the category with the most recipes first (equal counts: Breakfast, Lunch, Dinner, then Dessert)
    const priority = {
      'Breakfast': 0,
      'Lunch': 1,
      'Dinner': 2,
      'Dessert': 3,
    };

    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value); // most first
        if (countCompare != 0) {
          return countCompare;
        }
        final prioA = priority[a.key] ?? 99;
        final prioB = priority[b.key] ?? 99;
        return prioA.compareTo(prioB);
      });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recipes: $recipeCount',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              Text(
                'Favorites: $favoriteCount',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              Text(
                'Total time: $totalCookTime min',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          if (sortedCategories.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            ),
            const Text(
              'Category Breakdown:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            ...sortedCategories.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
