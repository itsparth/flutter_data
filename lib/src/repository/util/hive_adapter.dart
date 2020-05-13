part of flutter_data;

class _HiveTypeAdapter<T extends DataSupport<T>> with TypeAdapter<T> {
  _HiveTypeAdapter(this.manager);
  final DataManager manager;

  @override
  int get typeId {
    final type = DataId.getType<T>();
    final key = '_type_$type';
    final id = manager._keysBox
        .get(key, defaultValue: manager._keysBox.keys.length.toString());
    manager._keysBox.put(key, id);
    return int.parse(id);
  }

  @override
  T read(reader) {
    final n = reader.readByte();
    var fields = <String, dynamic>{
      for (var i = 0; i < n; i++) reader.read().toString(): reader.read(),
    };
    final n2 = reader.readByte();
    final metadata = <String, dynamic>{
      for (var i = 0; i < n2; i++) reader.read().toString(): reader.read(),
    };
    return manager
        .locator<Repository<T>>()
        .localDeserialize(fixMap(fields), metadata: fixMap(metadata));
  }

  @override
  void write(writer, T obj) {
    final _map = manager.locator<Repository<T>>().localSerialize(obj);
    writer.writeByte(_map.keys.length);
    for (var k in _map.keys) {
      writer.write(k);
      writer.write(_map[k]);
    }
    final publicMetadata = Map.fromEntries(
        obj.flutterDataMetadata.entries.where((e) => !e.key.startsWith('_')));
    writer.writeByte(publicMetadata.length);
    for (var e in publicMetadata.entries) {
      writer.write(e.key);
      writer.write(e.value);
    }
  }

  @visibleForTesting
  @protected
  Map<String, dynamic> fixMap(Map<String, dynamic> map) {
    // Hive deserializes maps as Map<dynamic, dynamic>
    // but we *know* we serialized them as Map<String, dynamic>

    for (var e in map.entries) {
      if (e.value is Map && e.value is! Map<String, dynamic>) {
        map[e.key] = Map<String, dynamic>.from(e.value as Map);
      }
      if (e.value is List<Map>) {
        map[e.key] = List<Map<String, dynamic>>.from(e.value as List);
      }
    }
    return map;
  }
}
