import 'dart:math';

import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';
import '../../models/family.dart';
import '../../models/house.dart';
import '../../models/person.dart';
import '../setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);
  setUp(setUpFn);

  test('produces a new key', () {
    var key = manager.getKeyForId('people', '1');
    expect(key, isNull);
    key = manager.getKeyForId('people', '1',
        keyIfAbsent: Repository.generateKey<Person>());
    expect(key, startsWith('people#'));
  });

  test('reuses a provided key', () {
    final key =
        manager.getKeyForId('people', '29', keyIfAbsent: 'people#78a92b');
    expect(key, 'people#78a92b');
    expect(manager.getId(key), '29');
  });

  test('reassign a key', () {
    final key =
        manager.getKeyForId('people', '1', keyIfAbsent: 'people#a5a5a5');
    expect(key, 'people#a5a5a5');

    manager.getKeyForId('people', '2', keyIfAbsent: 'people#a5a5a5');
    expect(manager.getId(key), '2');
  });

  // static utils

  test('getType & generateKey', () {
    expect(Repository.getType(), isNull);
    expect(Repository.getType<Person>(), 'people');
    expect(Repository.getType('Family'), 'families');
    // `type` argument takes precedence
    expect(Repository.getType<Person>('animal'), 'animals');
    expect(Repository.generateKey(), isNull);
  });

  test('by keys', () {
    // including ids that contain '#' (also used in internal format)
    manager.getKeyForId('people', 'p#1', keyIfAbsent: 'people#a1a1a1');
    manager.getKeyForId('people', '2', keyIfAbsent: 'people#b2b2b2');
    manager.getKeyForId('people', '3', keyIfAbsent: 'people#c3c3c3');

    final ids =
        ['people#a1a1a1', 'people#b2b2b2', 'people#c3c3c3'].map(manager.getId);
    expect(ids, ['p#1', '2', '3']);
  });

  test('by key', () {
    manager.getKeyForId('families', '3', keyIfAbsent: 'families#c3c3c3');

    final key = 'families#c3c3c3';
    expect(key, manager.getKeyForId('families', '3'));
  });

  test('two models with id should get the same key', () {
    expect(manager.getKeyForId('families', '2812', keyIfAbsent: 'f1'),
        manager.getKeyForId('families', '2812', keyIfAbsent: 'f1'));
  });

  test('should prioritize ID', () {
    final key = manager.getKeyForId('people', '772',
        keyIfAbsent: Repository.generateKey<Person>());

    final randomNewKey = Repository.generateKey<Person>();

    // we are telling manager to reuse the existing key
    // BUT a key for id=772 already exists, so that one will precede
    final finalKey =
        manager.getKeyForId('people', '772', keyIfAbsent: randomNewKey);

    expect(finalKey, isNot(randomNewKey));
    expect(key, finalKey);
  });

  test('keys and IDs do not clash', () {
    manager.getKeyForId('people', '1', keyIfAbsent: 'people#a1a1a1');
    manager.getKeyForId('people', 'a1a1a1', keyIfAbsent: 'people#a2a2a2');
    expect(manager.getKeyForId('people', 'a1a1a1'), 'people#a2a2a2');
    expect(manager.dumpGraph().keys.toSet(),
        {'people#a2a2a2', 'people#a1a1a1', 'id:people#a1a1a1', 'id:people#1'});
    expect(manager.getKeyForId('people', '1'), 'people#a1a1a1');
    manager.removeKey('people#a1a1a1');
    expect(manager.getKeyForId('people', '1'), isNull);
  });

  test('saves key', () async {
    final residence = House(address: '123 Main St').init(manager: manager);

    for (var i = 0; i < 518; i++) {
      final family = Family(
        id: '$i',
        surname: 'Smith',
        residence: residence.asBelongsTo,
        persons: HasMany(),
      ).init(manager: manager);

      // add some people
      if (i % 19 == 0) {
        family.persons
            .add(Person(name: 'new kid #$i', age: 0).init(manager: manager));
      }

      // remove some residence relationships
      if (Random().nextBool()) {
        family.residence.value = null;
      }

      await family.save();
    }

    expect(manager.metaBox.toMap(), manager.dumpGraph());
  });

  test('namespaced keys crud', () {
    expect(() => manager.addNode('superman'), throwsA(isA<AssertionError>()));

    manager.addNode('superman:1');
    expect(manager.getNode('superman:1'), isA<Map<String, List<String>>>());

    expect(
        () => manager.addEdge('superman:1', 'nonamespace',
            metadata: 'nonamespace'),
        throwsA(isA<AssertionError>()));

    manager.addEdge('superman:1', 'nonamespace', metadata: 'superman:prefix');
    expect(manager.getEdge('superman:1', metadata: 'superman:prefix'),
        containsAll(['nonamespace']));
    manager.removeEdges('superman:1', metadata: 'superman:prefix');
    expect(manager.hasEdge('superman:1', metadata: 'superman:prefix'), false);

    manager.removeNode('superman:1');
    expect(manager.hasNode('superman:1'), isFalse);

    expect(
        () => manager.addNode('super:man:1'), throwsA(isA<AssertionError>()));
  });

  test('denamespace', () {
    expect(manager.denamespace('superman:1'), '1');
  });
}
