import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../widgets/custom_text_field.dart';

class DetailScreen extends StatefulWidget {
  final Recipe recipe;

  const DetailScreen({super.key, required this.recipe});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final RecipeService _recipeService = RecipeService();
  late Recipe _currentRecipe;

  bool _isEditing = false;
  bool _submitted = false;
  bool _isLoading = false;
  String? _firestoreError;

  // Edit Controllers
  late TextEditingController _nameController;
  late TextEditingController _cookTimeController;
  late TextEditingController _servingsController;
  late TextEditingController _notesController;

  String? _selectedCategory;
  String? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _currentRecipe = widget.recipe;
    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: _currentRecipe.name);
    _cookTimeController =
        TextEditingController(text: _currentRecipe.cookTime.toString());
    _servingsController = TextEditingController(
      text: _currentRecipe.servings != null
          ? _currentRecipe.servings.toString()
          : '',
    );
    _notesController =
        TextEditingController(text: _currentRecipe.notes ?? '');
    _selectedCategory = _currentRecipe.category;
    _selectedDifficulty = _currentRecipe.difficulty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

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
      return null; // Servings is optional
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

  Future<void> _handleSave() async {
    setState(() {
      _submitted = true;
      _firestoreError = null;
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
      _isLoading = true;
    });

    try {
      final int cookTime = int.parse(_cookTimeController.text.trim());
      final int? servings = _servingsController.text.trim().isNotEmpty
          ? int.parse(_servingsController.text.trim())
          : null;
      final String? notes = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null;

      await _recipeService.updateRecipe(
        recipeId: _currentRecipe.id,
        userId: _currentRecipe.userId,
        name: _nameController.text.trim(),
        category: _selectedCategory!,
        difficulty: _selectedDifficulty!,
        cookTime: cookTime,
        servings: servings,
        notes: notes,
      );

      setState(() {
        _currentRecipe = _currentRecipe.copyWith(
          name: _nameController.text.trim(),
          category: _selectedCategory!,
          difficulty: _selectedDifficulty!,
          cookTime: cookTime,
          servings: servings,
          notes: notes,
        );
        _isEditing = false;
        _submitted = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe updated successfully'),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on FirebaseException catch (e) {
      setState(() {
        _firestoreError = e.message ?? 'Failed to update recipe.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _firestoreError = e.toString();
        _isLoading = false;
      });
    }
  }

  void _handleCancel() {
    setState(() {
      _isEditing = false;
      _submitted = false;
      _firestoreError = null;
      _initControllers();
    });
  }

  Future<void> _toggleFavorite() async {
    final newFav = !_currentRecipe.favorite;
    setState(() {
      _currentRecipe = _currentRecipe.copyWith(favorite: newFav);
    });

    try {
      await _recipeService.toggleFavorite(
        recipeId: _currentRecipe.id,
        currentFavorite: !newFav,
      );
    } catch (e) {
      // Revert if error
      setState(() {
        _currentRecipe = _currentRecipe.copyWith(favorite: !newFav);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Recipe'),
          content: Text(
            'Are you sure you want to delete "${_currentRecipe.name}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _recipeService.deleteRecipe(_currentRecipe.id);
        if (mounted) {
          Navigator.pop(context); // Return to list screen immediately
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete recipe: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Recipe' : _currentRecipe.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: Icon(
                _currentRecipe.favorite
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: _currentRecipe.favorite
                    ? Colors.amber.shade600
                    : Colors.grey.shade400,
                size: 28,
              ),
              tooltip: _currentRecipe.favorite
                  ? 'Unmark favorite'
                  : 'Mark favorite',
              onPressed: _toggleFavorite,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFFE65100)),
              tooltip: 'Edit',
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _firestoreError = null;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              tooltip: 'Delete',
              onPressed: _confirmDelete,
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: _isEditing ? _buildEditMode() : _buildViewMode(),
        ),
      ),
    );
  }

  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name Header Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _currentRecipe.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _currentRecipe.favorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: _currentRecipe.favorite
                          ? Colors.amber.shade600
                          : Colors.grey.shade400,
                      size: 32,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTagChip('Category', _currentRecipe.category,
                      const Color(0xFFE65100)),
                  _buildTagChip('Difficulty', _currentRecipe.difficulty,
                      Colors.blue.shade700),
                  _buildTagChip('Cook Time', '${_currentRecipe.cookTime} min',
                      Colors.teal.shade700),
                  if (_currentRecipe.servings != null)
                    _buildTagChip('Servings', '${_currentRecipe.servings}',
                        Colors.purple.shade700),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Detail Fields
        _buildInfoTile(
          icon: Icons.category_outlined,
          label: 'Category',
          value: _currentRecipe.category,
        ),
        _buildInfoTile(
          icon: Icons.speed_rounded,
          label: 'Difficulty',
          value: _currentRecipe.difficulty,
        ),
        _buildInfoTile(
          icon: Icons.access_time_rounded,
          label: 'Cook time',
          value: '${_currentRecipe.cookTime} min',
        ),
        _buildInfoTile(
          icon: Icons.people_outline_rounded,
          label: 'Servings',
          value: _currentRecipe.servings != null
              ? '${_currentRecipe.servings}'
              : 'Not specified',
        ),
        _buildInfoTile(
          icon: Icons.notes_rounded,
          label: 'Notes',
          value: (_currentRecipe.notes != null &&
                  _currentRecipe.notes!.isNotEmpty)
              ? _currentRecipe.notes!
              : 'None',
        ),

        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                    _firestoreError = null;
                  });
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Recipe'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE65100),
                  side: const BorderSide(color: Color(0xFFE65100)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Name
        CustomTextField(
          controller: _nameController,
          label: 'Name',
          hint: 'Enter recipe name',
          errorText: _nameError,
          onChanged: (_) {
            if (_submitted) setState(() {});
          },
        ),
        const SizedBox(height: 16),

        // Category dropdown
        _buildDropdown(
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
        const SizedBox(height: 16),

        // Difficulty dropdown
        _buildDropdown(
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
        const SizedBox(height: 16),

        // Cook time
        CustomTextField(
          controller: _cookTimeController,
          label: 'Cook time (minutes)',
          hint: 'e.g. 25',
          keyboardType: TextInputType.number,
          errorText: _cookTimeError,
          onChanged: (_) {
            if (_submitted) setState(() {});
          },
        ),
        const SizedBox(height: 16),

        // Servings (optional)
        CustomTextField(
          controller: _servingsController,
          label: 'Servings (optional)',
          hint: 'e.g. 4',
          keyboardType: TextInputType.number,
          errorText: _servingsError,
          onChanged: (_) {
            if (_submitted) setState(() {});
          },
        ),
        const SizedBox(height: 16),

        // Notes (optional)
        CustomTextField(
          controller: _notesController,
          label: 'Notes (optional)',
          hint: 'Special instructions or notes...',
          maxLines: 3,
          errorText: _notesError,
          onChanged: (_) {
            if (_submitted) setState(() {});
          },
        ),
        const SizedBox(height: 24),

        // Firestore Error Message
        if (_firestoreError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              _firestoreError!,
              style: TextStyle(
                color: Colors.red.shade800,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],

        // Action Buttons: Save & Cancel
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _handleCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown({
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
}
