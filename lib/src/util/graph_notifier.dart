part of flutter_data;

class DataGraphNotifier extends StateNotifier<DataGraphEvent> {
  DataGraphNotifier(this.box) : super(null);

  @protected
  @visibleForTesting
  final Box<Map<String, List<String>>> box;

  // read

  List<Map<String, List<String>>> getNodes(String namespace) {
    assert(namespace != null, 'namespace cannot be null');
    return box.keys
        .where((key) => key.toString().startsWith(namespace))
        .map((key) => box.get(key))
        .toList(growable: false);
  }

  Map<String, List<String>> getNode(String key) {
    assert(key != null, 'key cannot be null');
    return box.get(key);
  }

  bool hasNode(String key) {
    return box.containsKey(key);
  }

  List<String> getEdge(String key, {@required String metadata}) {
    final node = getNode(key);
    if (node != null) {
      return node[metadata];
    }
    return null;
  }

  bool hasEdge(String key, {@required String metadata}) {
    final fromNode = getNode(key);
    return fromNode?.keys?.contains(metadata) ?? false;
  }

  // write

  void addNodes(Iterable<String> keys, {bool notify = true}) {
    for (final key in keys) {
      addNode(key, notify: notify);
    }
  }

  void addNode(String key, {bool notify = true}) {
    assert(key != null, 'key cannot be null');
    if (!box.containsKey(key)) {
      box.put(key, {});
      if (notify) {
        state = DataGraphEvent(
            keys: [key], type: DataGraphEventType.addNode, graph: this);
      }
    }
  }

  void removeNode(String key, {bool notify = true}) {
    assert(key != null, 'key cannot be null');
    final fromNode = getNode(key);

    if (fromNode == null) {
      return;
    }

    // sever all incoming edges
    for (final toKey in connectedKeys(key)) {
      final toNode = getNode(toKey);
      // remove deleted key from all metadatas
      if (toNode != null) {
        for (final entry in toNode.entries.toSet()) {
          removeEdges(toKey, tos: [key], metadata: entry.key);
        }
      }
    }

    box.delete(key);

    if (notify) {
      state = DataGraphEvent(
          keys: [key], type: DataGraphEventType.removeNode, graph: this);
    }
  }

  void addEdge(String from, String to,
      {@required String metadata, String inverseMetadata, bool notify = true}) {
    addEdges(from,
        tos: [to],
        metadata: metadata,
        inverseMetadata: inverseMetadata,
        notify: notify);
  }

  void addEdges(String from,
      {@required String metadata,
      @required Iterable<String> tos,
      String inverseMetadata,
      bool notify = true}) {
    final fromNode = getNode(from);
    assert(fromNode != null && tos != null);

    if (tos.isEmpty) {
      return;
    }

    // use a set to ensure resulting list elements are unique
    fromNode[metadata] = {...?fromNode[metadata], ...tos}.toList();

    if (notify) {
      state = DataGraphEvent(
        keys: [from, ...tos],
        metadata: metadata,
        type: DataGraphEventType.addEdge,
        graph: this,
      );
    }

    if (inverseMetadata != null) {
      for (final to in tos) {
        // get or create toNode
        final toNode =
            hasNode(to) ? getNode(to) : (this..addNode(to)).getNode(to);

        // use a set to ensure resulting list elements are unique
        toNode[inverseMetadata] = {...?toNode[inverseMetadata], from}.toList();
      }

      if (notify) {
        state = DataGraphEvent(
          keys: [...tos, from],
          metadata: inverseMetadata,
          type: DataGraphEventType.addEdge,
          graph: this,
        );
      }
    }
  }

  void removeEdge(String from, String to,
      {@required String metadata, String inverseMetadata, bool notify = true}) {
    removeEdges(from,
        tos: [to],
        metadata: metadata,
        inverseMetadata: inverseMetadata,
        notify: notify);
  }

  void removeEdges(String from,
      {@required String metadata,
      Iterable<String> tos,
      String inverseMetadata,
      bool notify = true}) {
    final fromNode = getNode(from);
    assert(fromNode != null);

    if (tos != null && fromNode[metadata] != null) {
      // remove all tos from fromNode[metadata]
      fromNode[metadata].removeWhere(tos.contains);
      if (fromNode[metadata].isEmpty) {
        fromNode.remove(metadata);
      }
    } else {
      // tos == null as argument means ALL
      // remove metadata and retrieve all tos
      tos = fromNode.remove(metadata);
    }

    if (notify) {
      state = DataGraphEvent(
        keys: [from, ...?tos],
        metadata: metadata,
        type: DataGraphEventType.removeEdge,
        graph: this,
      );
    }

    if (tos != null && inverseMetadata != null) {
      for (final to in tos) {
        final toNode = getNode(to);
        if (toNode != null && toNode[inverseMetadata] != null) {
          toNode[inverseMetadata].remove(from);
          if (toNode[inverseMetadata].isEmpty) {
            toNode.remove(inverseMetadata);
          }
        }
        if (toNode.isEmpty) {
          removeNode(to, notify: notify);
        }
      }

      if (notify) {
        state = DataGraphEvent(
          keys: [...tos, from],
          metadata: inverseMetadata,
          type: DataGraphEventType.removeEdge,
          graph: this,
        );
      }
    }
  }

  void notify(List<String> keys, DataGraphEventType type) {
    state = DataGraphEvent(
      type: type,
      keys: keys,
      graph: this,
    );
  }

  // misc

  Set<String> connectedKeys(String key, {Iterable<String> metadatas}) {
    final node = getNode(key);
    if (node == null) {
      return {};
    }

    return node.entries.fold({}, (acc, entry) {
      if (metadatas != null && !metadatas.contains(entry.key)) {
        return acc;
      }
      return acc..addAll(entry.value);
    });
  }

  void clear() {
    box.clear();
  }

  Map<String, Map<String, List<String>>> toMap() => box.toMap().cast();
}

enum DataGraphEventType {
  addNode,
  removeNode,
  updateNode,
  addEdge,
  removeEdge,
  updateEdge
}

extension DataGraphEventTypeX on DataGraphEventType {
  bool get isNode => [
        DataGraphEventType.addNode,
        DataGraphEventType.updateNode,
        DataGraphEventType.removeNode,
      ].contains(this);
  bool get isEdge => [
        DataGraphEventType.addEdge,
        DataGraphEventType.updateEdge,
        DataGraphEventType.removeEdge,
      ].contains(this);
}

class DataGraphEvent {
  const DataGraphEvent({
    this.keys,
    this.metadata,
    this.type,
    this.graph,
  });
  final List<String> keys;
  final String metadata;
  final DataGraphEventType type;
  final DataGraphNotifier graph;

  @override
  String toString() {
    return '[GraphEvent] $type: $keys';
  }
}
