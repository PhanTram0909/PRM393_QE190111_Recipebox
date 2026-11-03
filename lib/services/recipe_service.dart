import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _recipesCollection =>
      _firestore.collection('recipes');

  // Stream of recipes for a specific user, sorted client-side by cookTime asc, then name (case-insensitive) asc
  Stream<List<Recipe>> getUserRecipesStream(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return _recipesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final recipes = snapshot.docs
          .map((doc) => Recipe.fromFirestore(doc))
          .toList();

      // Sort by cookTime shortest first; equal cook times ordered by name, not case-sensitive
      recipes.sort((a, b) {
        final timeComparison = a.cookTime.compareTo(b.cookTime);
        if (timeComparison != 0) {
          return timeComparison;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      return recipes;
    });
  }

  // Check if a recipe with the same name (case-insensitive) already exists for the user
  Future<void> _checkDuplicateName({
    required String userId,
    required String name,
    String? excludeRecipeId,
  }) async {
    final querySnapshot = await _recipesCollection
        .where('userId', isEqualTo: userId)
        .get();

    final normalizedTarget = name.trim().toLowerCase();

    for (final doc in querySnapshot.docs) {
      if (excludeRecipeId != null && doc.id == excludeRecipeId) {
        continue;
      }
      final existingName = (doc.data()['name'] as String? ?? '').trim().toLowerCase();
      if (existingName == normalizedTarget) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'already-exists',
          message: 'A recipe with this name already exists.',
        );
      }
    }
  }

  // Add a new recipe
  Future<Recipe> addRecipe({
    required String userId,
    required String name,
    required String category,
    required String difficulty,
    required int cookTime,
    int? servings,
    String? notes,
  }) async {
    // Check duplicate name for the user
    await _checkDuplicateName(
      userId: userId,
      name: name,
    );

    final newRecipe = Recipe(
      id: '',
      userId: userId,
      name: name.trim(),
      category: category,
      difficulty: difficulty,
      cookTime: cookTime,
      servings: servings,
      favorite: false,
      notes: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
      createdAt: DateTime.now(),
    );

    final docRef = await _recipesCollection.add(newRecipe.toMap());
    return newRecipe.copyWith(id: docRef.id);
  }

  // Update an existing recipe
  Future<void> updateRecipe({
    required String recipeId,
    required String userId,
    required String name,
    required String category,
    required String difficulty,
    required int cookTime,
    int? servings,
    bool? favorite,
    String? notes,
  }) async {
    // Check duplicate name for the user (excluding current recipe)
    await _checkDuplicateName(
      userId: userId,
      name: name,
      excludeRecipeId: recipeId,
    );

    final Map<String, dynamic> updateData = {
      'name': name.trim(),
      'category': category,
      'difficulty': difficulty,
      'cookTime': cookTime,
      'servings': servings,
      'notes': notes?.trim().isNotEmpty == true ? notes!.trim() : null,
    };

    if (favorite != null) {
      updateData['favorite'] = favorite;
    }

    await _recipesCollection.doc(recipeId).update(updateData);
  }

  // Toggle favorite status
  Future<void> toggleFavorite({
    required String recipeId,
    required bool currentFavorite,
  }) async {
    await _recipesCollection.doc(recipeId).update({
      'favorite': !currentFavorite,
    });
  }

  // Delete a recipe
  Future<void> deleteRecipe(String recipeId) async {
    await _recipesCollection.doc(recipeId).delete();
  }
}
