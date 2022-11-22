import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../models/pocketbase_model.dart';
import '../provider/pocketbase_provider.dart';

typedef JsonMap = Map<String, dynamic>;

class JsonConverter {
  static JsonMap toRecordModelJson(
    BaseModel model, {
    List<String>? relations,
  }) {
    var json = model.toJson();
    for (final relation in relations ?? []) {
      final relKey = json[relation];
      if (relKey is BaseModel) {
        json[relation] = json[relation].id;
      }
      // TODO untested
      if (relKey is List<BaseModel>) {
        json[relation] = (json[relation] as List<BaseModel>)
            .map((BaseModel i) => i.id)
            .toList();
      }
    }
    return json;
  }

  static JsonMap toBaseModelJson(
    RecordModel model, {
    List<String>? relations,
  }) {
    var json = model.toJson();
    if (json.containsKey("expand") && (json['expand'] as Map).isNotEmpty) {
      (json['expand'] as Map).forEach((field, data) => json[field] = data);
      json.remove("expand");
    } else {
      for (final relation in relations ?? []) {
        if ((json[relation] as String).isEmpty) {
          json.remove(relation);
        }
      }
    }
    return json;
  }
}

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
    return data
        .map((rm) => JsonConverter.toBaseModelJson(rm, relations: relations));
  }

  Future<String?> create(T model) async {
    /// Returns an error string, null for success
    try {
      await recordService.create(
        body: JsonConverter.toRecordModelJson(model, relations: relations),
      );
      getAll(loading: false);
    } on ClientException catch (e) {
      return "${e.response['message']}: ${e.response['data']}";
    }
    return null;
  }

  Future<String?> update(T model) async {
    try {
      await recordService.update(
        model.id!,
        body: JsonConverter.toRecordModelJson(model, relations: relations),
      );
    } on ClientException catch (e) {
      return "${e.response['message']}: ${e.response['data']}";
    }
    getAll(loading: false);
  }

  Future<void> delete(String id) async {
    await recordService.delete(id);
    getAll(loading: false);
  }
}
