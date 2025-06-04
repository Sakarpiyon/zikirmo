// lib/features/zikir/providers/zikir_counter_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Sayaç değerini tutan StateNotifier
class ZikirCounterNotifier extends StateNotifier<int> {
  ZikirCounterNotifier() : super(0);
  
  void increment() => state++;
  
  void reset() => state = 0;
  
  void setValue(int value) => state = value;
}

// Sayaç değeri provider'ı
final zikirCounterProvider = StateNotifierProvider<ZikirCounterNotifier, int>((ref) {
  return ZikirCounterNotifier();
});