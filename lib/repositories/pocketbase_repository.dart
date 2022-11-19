import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../models/pocketbase_model.dart';
import '../provider/pocketbase_provider.dart';

final collectionServiceProvider = Provider.family<RecordService, String>(
    (ref, collection) => ref.watch(pocketBaseProvider).collection(collection));

abstract class PocketbaseRepository<T extends BaseModel>
    extends StateNotifier<AsyncValue<List<T>>> {
  final RecordService recordService;
  List<String>? relations;

  PocketbaseRepository(this.recordService) : super(const AsyncData([]));

  Future<void> getAll({bool loading = false});

  Future<Iterable> getAsMap() async {
    final data = await recordService.getFullList(expand: relations?.join(","));
    return data.map((rm) {
      var json = rm.toJson();

      if (json.containsKey("expand") && (json['expand'] as Map).isNotEmpty) {
        (json['expand'] as Map).forEach((field, data) => json[field] = data);
      } else {
        for (final relation in relations ?? []) {
          if ((json[relation] as String).isEmpty) {
            json.remove(relation);
          }
        }
      }
      return json;
    });
  }

  Future<String> create(T model) async {
    var j = model.toJson();
    // TODO move to private function
    for (final relation in relations ?? []) {
      final relKey = j[relation];
      if (relKey is BaseModel) {
        j[relation] = j[relation].id;
      }
      // TODO untested
      if (relKey is List<BaseModel>) {
        j[relation] = (j[relation] as List<BaseModel>)
            .map((BaseModel i) => i.id)
            .toList();
      }
    }
    final rec = await recordService.create(body: j);
    getAll(loading: false);
    return rec.id;
  }

  Future<void> update(T model) async {
    // TODO transform json as in create()
    await recordService.update(model.id!, body: model.toJson());
    getAll(loading: false);
  }

  Future<void> delete(String id) async {
    await recordService.delete(id);
    getAll(loading: false);
  }
}
