import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'product_models.dart';

abstract interface class ProductRepository {
  Future<ProductState> load();
  Future<void> save(ProductState state);
}

final class LocalProductRepository implements ProductRepository {
  static const _storage = MethodChannel('pt.taxy.app/storage');
  File? _file;

  Future<File> get _dataFile async {
    if (_file case final file?) return file;
    final path = await _storage.invokeMethod<String>('getAppDataPath');
    if (path == null || path.isEmpty) throw StateError('storage unavailable');
    return _file = File('$path${Platform.pathSeparator}product-state-v1.json');
  }

  @override
  Future<ProductState> load() async {
    final file = await _dataFile;
    if (!await file.exists()) return ProductState.initial();
    final source = await file.readAsString();
    if (source.trim().isEmpty) return ProductState.initial();
    return ProductState.fromJson((jsonDecode(source) as Map).cast());
  }

  @override
  Future<void> save(ProductState state) async {
    final file = await _dataFile;
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(state.toJson()), flush: true);
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }
}

final class MemoryProductRepository implements ProductRepository {
  MemoryProductRepository([ProductState? state])
    : _state = state ?? ProductState.initial();

  ProductState _state;

  @override
  Future<ProductState> load() async => _state;

  @override
  Future<void> save(ProductState state) async => _state = state;
}
