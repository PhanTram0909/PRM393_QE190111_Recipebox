import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import '../services/auth_service.dart';
import '../services/recipe_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/recipe_card.dart';
import '../widgets/summary_card.dart';
import 'detail_screen.dart';

class ListScreen extends StatefulWidget {
  final User user;

  const ListScreen({super.key, required this.user});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final AuthService _authService = AuthService();
  final RecipeService _recipeService = RecipeService();

  // Add Recipe Form State
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cookTimeController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedCategory;
  String? _selectedDifficulty;

  bool _submitted = false;
  bool _isAdding = false;
  String? _addRecipeError;
  String? _addRecipeSuccessMessage;

  // Filter & Search State
  String _filterCategory = 'All';
  String _filterDifficulty = 'All';
  bool _filterFavoritesOnly = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- Add Form Validations ---
  String? get _nameError {
    if (!_submitted) return null;
    final text = _nameController.text;
    if (text.trim().isEmpty) {
      return 'Name is required';
    }
    if (text.length > 80) {
      return 'Name must be at most 80 characters';
    }
    return null;
  }

  String? get _categoryError {
    if (!_submitted) return null;
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      return 'Please choose a category';
    }
    return null;
  }

  String? get _difficultyError {
    if (!_submitted) return null;
    if (_selectedDifficulty == null || _selectedDifficulty!.isEmpty) {
      return 'Please choose a difficulty';
    }
    return null;
  }

  String? get _cookTimeError {
    if (!_submitted) return null;
    final text = _cookTimeController.text.trim();
    if (text.isEmpty) {
      return 'Cook time is required';
    }
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < 1 || parsed > 600) {
      return 'Cook time must be a whole number from 1 to 600';
    }
    return null;
  }

  String? get _servingsError {
    if (!_submitted) return null;
    final text = _servingsController.text.trim();
    if (text.isEmpty) {
      return null;
    }
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < 1 || parsed > 20) {
      return 'Servings must be a whole number from 1 to 20';
    }
    return null;
  }

  String? get _notesError {
    if (!_submitted) return null;
    final text = _notesController.text;
    if (text.length > 300) {
      return 'Notes must be at most 300 characters';
    }
    return null;
  }

  Future<void> _handleAddRecipe() async {
    setState(() {
      _submitted = true;
      _addRecipeError = null;
      _addRecipeSuccessMessage = null;
    });

    if (_nameError != null ||
        _categoryError != null ||
        _difficultyError != null ||
        _cookTimeError != null ||
        _servingsError != null ||
        _notesError != null) {
      return;
    }

    setState(() {
      _isAdding = true;
    });

    try {
      final int cookTime = int.parse(_cookTimeController.text.trim());
      final int? servings = _servingsController.text.trim().isNotEmpty
          ? int.parse(_servingsController.text.trim())
          : null;
      final String? notes = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null;

      await _recipeService.addRecipe(
        userId: widget.user.uid,
        name: _nameController.text.trim(),
        category: _selectedCategory!,
        difficulty: _selectedDifficulty!,
        cookTime: cookTime,
        servings: servings,
        notes: notes,
      );

      // Reset form on success
      _nameController.clear();
      _cookTimeController.clear();
      _servingsController.clear();
      _notesController.clear();

      setState(() {
        _selectedCategory = null;
        _selectedDifficulty = null;
        _submitted = false;
        _isAdding = false;
        _addRecipeSuccessMessage = 'Recipe added';
      });

      // Clear success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _addRecipeSuccessMessage = null;
          });
        }
      });
    } on FirebaseException catch (e) {
      setState(() {
        _addRecipeError = e.message ?? 'Failed to add recipe.';
        _isAdding = false;
      });
    } catch (e) {
      setState(() {
        _addRecipeError = e.toString();
        _isAdding = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _filterCategory = 'All';
      _filterDifficulty = 'All';
      _filterFavoritesOnly = false;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent returning to Login / Register screen via back button
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: Text(
            widget.user.email ?? 'Recipes',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0.5,
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.red),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: StreamBuilder<List<Recipe>>(
          stream: _recipeService.getUserRecipesStream(widget.user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE65100)),
              );
            }

            final allRecipes = snapshot.data ?? [];

            // Apply Filters and Search
            final filteredRecipes = allRecipes.where((recipe) {
              // Category filter
              if (_filterCategory != 'All' &&
                  recipe.category != _filterCategory) {
                return false;
              }
              // Difficulty filter
              if (_filterDifficulty != 'All' &&
                  recipe.difficulty != _filterDifficulty) {
                return false;
              }
              // Favorites only filter
              if (_filterFavoritesOnly && !recipe.favorite) {
                return false;
              }
              // Search box (name or notes contain typed text, not case-sensitive, trimmed)
              if (_searchQuery.isNotEmpty) {
                final queryLower = _searchQuery.toLowerCase();
                final nameMatch =
                    recipe.name.toLowerCase().contains(queryLower);
                final notesMatch =
                    recipe.notes?.toLowerCase().contains(queryLower) ?? false;
                if (!nameMatch && !notesMatch) {
                  return false;
                }
              }
              return true;
            }).toList();

            return CustomScrollView(
              slivers: [
                // Section A: Add a recipe
                SliverToBoxAdapter(
                  child: _buildAddRecipeSection(),
                ),

                // Section C: Filter, search & summary
                SliverToBoxAdapter(
                  child: _buildFilterAndSearchSection(),
                ),

                SliverToBoxAdapter(
                  child: SummaryCard(recipes: filteredRecipes),
                ),

                // Section B: The list header
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(18, 12, 18, 4),
                    child: Text(
                      'Recipe Collection',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),

                // Section B: The list items or empty state
                if (filteredRecipes.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                        child: Text(
                          'No recipes found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final recipe = filteredRecipes[index];
                        return RecipeCard(
                          recipe: recipe,
                          onToggleFavorite: () {
                            _recipeService.toggleFavorite(
                              recipeId: recipe.id,
                              currentFavorite: recipe.favorite,
                            );
                          },
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(recipe: recipe),
                              ),
                            );
                          },
                        );
                      },
                      childCount: filteredRecipes.length,
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 32),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddRecipeSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A000000),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.add_circle_outline, color: Color(0xFFE65100), size: 22),
              SizedBox(width: 8),
              Text(
                'Add Recipe',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Name field
          CustomTextField(
            controller: _nameController,
            label: 'Recipe Name',
            hint: 'e.g. Traditional Pho Bo',
            errorText: _nameError,
            onChanged: (_) {
              if (_submitted) setState(() {});
            },
          ),
          const SizedBox(height: 12),

          // Category dropdown
          _buildDropdownField(
            label: 'Category',
            value: _selectedCategory,
            hintText: 'Choose category',
            items: Recipe.categories,
            errorText: _categoryError,
            onChanged: (val) {
              setState(() {
                _selectedCategory = val;
              });
            },
          ),
          const SizedBox(height: 12),

          // Difficulty dropdown
          _buildDropdownField(
            label: 'Difficulty',
            value: _selectedDifficulty,
            hintText: 'Choose difficulty',
            items: Recipe.difficulties,
            errorText: _difficultyError,
            onChanged: (val) {
              setState(() {
                _selectedDifficulty = val;
              });
            },
          ),
          const SizedBox(height: 12),

          // Cook Time field
          CustomTextField(
            controller: _cookTimeController,
            label: 'Cook Time (minutes)',
            hint: '1 - 600',
            keyboardType: TextInputType.number,
            errorText: _cookTimeError,
            onChanged: (_) {
              if (_submitted) setState(() {});
            },
          ),
          const SizedBox(height: 12),

          // Servings field (optional)
          CustomTextField(
            controller: _servingsController,
            label: 'Servings (optional)',
            hint: '1 - 20',
            keyboardType: TextInputType.number,
            errorText: _servingsError,
            onChanged: (_) {
              if (_submitted) setState(() {});
            },
          ),
          const SizedBox(height: 12),

          // Notes field (optional)
          CustomTextField(
            controller: _notesController,
            label: 'Notes (optional)',
            hint: 'Short description or secret tips (max 300 chars)',
            maxLines: 2,
            errorText: _notesError,
            onChanged: (_) {
              if (_submitted) setState(() {});
            },
          ),
          const SizedBox(height: 16),

          // Success Message
          if (_addRecipeSuccessMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Text(
                _addRecipeSuccessMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],

          // Error Message
          if (_addRecipeError != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _addRecipeError!,
                style: TextStyle(
                  color: Colors.red.shade800,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],

          // Submit Button
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: _isAdding ? null : _handleAddRecipe,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 1,
              ),
              child: _isAdding
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Add Recipe',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required String hintText,
    required List<String> items,
    required String? errorText,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: errorText != null ? Colors.red : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: (value != null && items.contains(value)) ? value : null,
              hint: Text(hintText),
              isExpanded: true,
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    hintText,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
                ...items.map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  ),
                ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilterAndSearchSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter & Search',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    color: Color(0xFFE65100),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Box
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or notes...',
              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFE65100),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Category & Difficulty Dropdowns in a Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                        color: const Color(0xFFF8FAFC),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterCategory,
                          isExpanded: true,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                          items: ['All', ...Recipe.categories].map((c) {
                            return DropdownMenuItem(value: c, child: Text(c));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _filterCategory = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Difficulty',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                        color: const Color(0xFFF8FAFC),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterDifficulty,
                          isExpanded: true,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                          items: ['All', ...Recipe.difficulties].map((d) {
                            return DropdownMenuItem(value: d, child: Text(d));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _filterDifficulty = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Favorites-only switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Favorites only',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Switch(
                value: _filterFavoritesOnly,
                activeThumbColor: const Color(0xFFE65100),
                onChanged: (val) {
                  setState(() {
                    _filterFavoritesOnly = val;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
