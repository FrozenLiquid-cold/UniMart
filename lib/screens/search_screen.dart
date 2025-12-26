import 'package:flutter/material.dart';
import '../data/item_store.dart';
import '../models/item.dart';
import 'item_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  RangeValues _priceRange = const RangeValues(0, 1000);
  bool _showFilters = false;
  late final ItemStore _itemStore;
  late final ValueNotifier<List<Item>> _itemsNotifier;
  List<Item> _items = [];

  @override
  void initState() {
    super.initState();
    _itemStore = ItemStore.instance;
    _itemsNotifier = _itemStore.itemsNotifier;
    _items = List<Item>.from(_itemsNotifier.value);
    _itemsNotifier.addListener(_handleItemsChanged);
  }

  List<Item> get _results {
    final query = _controller.text.trim().toLowerCase();
    return _items.where((item) {
      final matchesQuery =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
      final matchesPrice =
          item.price >= _priceRange.start && item.price <= _priceRange.end;
      return matchesQuery && matchesPrice;
    }).toList();
  }

  @override
  void dispose() {
    _itemsNotifier.removeListener(_handleItemsChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleItemsChanged() {
    setState(() {
      _items = List<Item>.from(_itemsNotifier.value);
    });
  }

  void _openItem(Item item) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final mutedColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final results = _results;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(results.length, theme, borderColor),
            Expanded(
              child: results.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final item = results[index];
                        return GestureDetector(
                          onTap: () => _openItem(item),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.3)
                                      : const Color(0x11000000),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    item.image,
                                    width: 88,
                                    height: 88,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(color: mutedColor),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            '\$${item.price.toStringAsFixed(0)}',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              item.category,
                                              style: TextStyle(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int resultsCount, ThemeData theme, Color borderColor) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : const Color(0x11000000),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Marketplace',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
              color: theme.colorScheme.surface.withValues(alpha: 0.5),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.search, color: theme.colorScheme.outline),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Search items, books, electronics...',
                      border: InputBorder.none,
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _controller.clear();
                      setState(() {});
                    },
                    icon: Icon(Icons.close, color: theme.colorScheme.outline),
                  ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                  icon: Icon(
                    Icons.tune,
                    color: _showFilters
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          if (_showFilters) ...[
            const SizedBox(height: 16),
            Text(
              'Price Range: \$${_priceRange.start.toStringAsFixed(0)} - \$${_priceRange.end.toStringAsFixed(0)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: 1000,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                setState(() {
                  _priceRange = value;
                });
              },
            ),
          ],
          if (_controller.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '$resultsCount results',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final query = _controller.text.trim();
    final muted = theme.brightness == Brightness.dark
        ? Colors.white54
        : const Color(0xFF475569);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 72,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? 'Start searching for items'
                  : 'No items found for "$query"',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
