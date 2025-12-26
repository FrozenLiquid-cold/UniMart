import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/item.dart';
import '../services/firestore_service.dart';

class ItemStore {
  ItemStore._();

  static final ItemStore instance = ItemStore._();

  final ValueNotifier<List<Item>> itemsNotifier = ValueNotifier<List<Item>>([]);
  StreamSubscription<List<Item>>? _itemsSubscription;

  List<Item> get items => List.unmodifiable(itemsNotifier.value);

  /// Initialize and start listening to Firestore
  void initialize() {
    _itemsSubscription?.cancel();
    _itemsSubscription = FirestoreService.getItemsStream().listen(
      (items) {
        itemsNotifier.value = items;
      },
      onError: (error) {
        debugPrint('Error listening to items: $error');
      },
    );
  }

  /// Start listening to items by category
  void listenToCategory(String category) {
    _itemsSubscription?.cancel();
    _itemsSubscription = FirestoreService.getItemsByCategoryStream(category)
        .listen(
          (items) {
            itemsNotifier.value = items;
          },
          onError: (error) {
            debugPrint('Error listening to items by category: $error');
          },
        );
  }

  /// Start listening to items by seller
  void listenToSeller(String sellerId) {
    _itemsSubscription?.cancel();
    _itemsSubscription = FirestoreService.getItemsBySellerStream(sellerId)
        .listen(
          (items) {
            itemsNotifier.value = items;
          },
          onError: (error) {
            debugPrint('Error listening to items by seller: $error');
          },
        );
  }

  /// Add item (creates in Firestore)
  Future<void> addItem(Item item) async {
    await FirestoreService.createItem(item);
    // Item will be added via stream automatically
  }

  /// Update item (updates in Firestore)
  Future<void> updateItem(Item item) async {
    await FirestoreService.updateItem(item);
    // Item will be updated via stream automatically
  }

  /// Dispose resources
  void dispose() {
    _itemsSubscription?.cancel();
  }
}
