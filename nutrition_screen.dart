import 'package:flutter/material.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  Map<String, List<Map<String, dynamic>>> meals = {
    'Breakfast': [],
    'Lunch': [],
    'Snack': [],
    'Dinner': [],
  };

  @override
  Widget build(BuildContext context) {
    // Calculate totals
    double totalProtein = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;
    double totalCalories = 0.0;
    meals.forEach((_, mealList) {
      for (final meal in mealList) {
        if (meal['protein'] != null) totalProtein += meal['protein'];
        if (meal['carbs'] != null) totalCarbs += meal['carbs'];
        if (meal['fat'] != null) totalFat += meal['fat'];
        if (meal['protein'] != null &&
            meal['carbs'] != null &&
            meal['fat'] != null) {
          totalCalories +=
              meal['protein'] * 4 + meal['carbs'] * 4 + meal['fat'] * 9;
        }
      }
    });
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCaloriesProgress(totalCalories),
          _buildMacronutrientsSection(totalProtein, totalCarbs, totalFat),
          _buildMealCard('Breakfast'),
          _buildMealCard('Lunch'),
          _buildMealCard('Snack'),
          _buildMealCard('Dinner'),
        ],
      ),
    );
  }

  Widget _buildCaloriesProgress(double totalCalories) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calories Consumed',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                totalCalories.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Goal: 2,200',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (totalCalories / 2200).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF3366FF)),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              Text('${totalCalories.toStringAsFixed(0)} / 2,200',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              Text('2,200',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacronutrientsSection(
      double totalProtein, double totalCarbs, double totalFat) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Macronutrients',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard('Protein',
                  '${totalProtein.toStringAsFixed(1)} g', 'Goal: 120 g'),
              _buildMetricCard(
                  'Carbs', '${totalCarbs.toStringAsFixed(1)} g', 'Goal: 250 g'),
              _buildMetricCard(
                  'Fat', '${totalFat.toStringAsFixed(1)} g', 'Goal: 70 g'),
              _buildMetricCard('Water', '5 cups', 'Goal: 8 cups'),
            ],
          ),
          const SizedBox(height: 20),
          _buildWaterTracker(),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String goal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            goal,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterTracker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Water Intake',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            8,
            (index) => GestureDetector(
              onTap: () {
                // Implement water cup toggle
              },
              child: Container(
                width: 36,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: Stack(
                  children: [
                    if (index < 5)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3366FF),
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(String mealType) {
    final mealList = meals[mealType] ?? [];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  mealType,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      tooltip: 'Scan barcode',
                      onPressed: () => _showBarcodeDialog(mealType),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Add or change food',
                      onPressed: () => _showFoodSearchDialog(mealType),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (mealList.isEmpty)
            ListTile(
              title: Text(
                'No food selected',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            ...mealList.map((meal) => Card(
                  color: Colors.blue[50],
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF3366FF),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _macroChip(
                                '💪 Protein',
                                (meal['protein'] ?? 0.0).toStringAsFixed(1) +
                                    'g',
                                Colors.green[100]!,
                                Colors.green[800]!),
                            const SizedBox(height: 8),
                            _macroChip(
                                '🍚 Carbs',
                                (meal['carbs'] ?? 0.0).toStringAsFixed(1) + 'g',
                                Colors.orange[100]!,
                                Colors.orange[800]!),
                            const SizedBox(height: 8),
                            _macroChip(
                                '🧈 Fat',
                                (meal['fat'] ?? 0.0).toStringAsFixed(1) + 'g',
                                Colors.purple[100]!,
                                Colors.purple[800]!),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  void _showFoodSearchDialog(String mealType) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        TextEditingController _searchController = TextEditingController();
        List<off.Product> searchResults = [];
        bool isLoading = false;
        String? errorMessage;
        bool hasSearched = false;
        int? selectedIndex;
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> searchProducts() async {
              final query = _searchController.text.trim();
              if (query.isEmpty) return;
              setState(() {
                isLoading = true;
                errorMessage = null;
                hasSearched = true;
              });
              final parameters = <off.Parameter>[
                off.SearchTerms(terms: [query]),
              ];
              final configuration = off.ProductSearchQueryConfiguration(
                parametersList: parameters,
                fields: [
                  off.ProductField.BARCODE,
                  off.ProductField.NAME,
                  off.ProductField.NUTRIMENTS,
                ],
                language: off.OpenFoodFactsLanguage.ENGLISH,
                version: off.ProductQueryVersion.v3,
              );
              try {
                final result = await off.OpenFoodAPIClient.searchProducts(
                  null,
                  configuration,
                );
                setState(() {
                  searchResults = result.products ?? [];
                  isLoading = false;
                  errorMessage = null;
                  selectedIndex = null;
                });
              } catch (e) {
                setState(() {
                  isLoading = false;
                  errorMessage =
                      'Failed to load results. Please check your internet connection or try again later.';
                });
              }
            }

            return AlertDialog(
              title: Text('Search Food for $mealType'),
              content: SizedBox(
                width: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Enter food name',
                        suffixIcon: IconButton(
                          icon: Icon(Icons.search),
                          onPressed: searchProducts,
                        ),
                      ),
                      onSubmitted: (_) => searchProducts(),
                    ),
                    const SizedBox(height: 16),
                    if (isLoading)
                      const CircularProgressIndicator()
                    else if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else if (hasSearched && searchResults.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No results found.'),
                      )
                    else if (searchResults.isNotEmpty)
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final product = searchResults[index];
                            final nutriments = product.nutriments;
                            final protein = nutriments?.getValue(
                                    off.Nutrient.proteins,
                                    off.PerSize.oneHundredGrams) ??
                                0.0;
                            final carbs = nutriments?.getValue(
                                    off.Nutrient.carbohydrates,
                                    off.PerSize.oneHundredGrams) ??
                                0.0;
                            final fat = nutriments?.getValue(off.Nutrient.fat,
                                    off.PerSize.oneHundredGrams) ??
                                0.0;
                            return ListTile(
                              selected: selectedIndex == index,
                              selectedTileColor: Colors.blue[50],
                              title: Text(product.productName ?? 'No name'),
                              subtitle: Text(
                                'Protein: ${protein.toStringAsFixed(1)}g, '
                                'Carbs: ${carbs.toStringAsFixed(1)}g, '
                                'Fat: ${fat.toStringAsFixed(1)}g (per 100g)',
                              ),
                              onTap: () {
                                setState(() {
                                  selectedIndex = index;
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: selectedIndex == null
                      ? null
                      : () {
                          final product = searchResults[selectedIndex!];
                          final nutriments = product.nutriments;
                          final protein = nutriments?.getValue(
                                  off.Nutrient.proteins,
                                  off.PerSize.oneHundredGrams) ??
                              0.0;
                          final carbs = nutriments?.getValue(
                                  off.Nutrient.carbohydrates,
                                  off.PerSize.oneHundredGrams) ??
                              0.0;
                          final fat = nutriments?.getValue(off.Nutrient.fat,
                                  off.PerSize.oneHundredGrams) ??
                              0.0;
                          setState(() {
                            meals[mealType] = List<Map<String, dynamic>>.from(
                                meals[mealType] ?? [])
                              ..add({
                                'name': product.productName ?? 'Unknown',
                                'protein': protein,
                                'carbs': carbs,
                                'fat': fat,
                              });
                          });
                          Navigator.pop(context, true);
                        },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
    if (result == true) setState(() {});
  }

  void _showBarcodeDialog(String mealType) {
    // Placeholder for barcode scan logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Barcode Scan'),
        content: const Text('Barcode scanning not implemented yet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _macroChip(
      String label, String value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: textColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
