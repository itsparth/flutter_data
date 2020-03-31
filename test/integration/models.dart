import 'package:flutter_data/annotations.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@freezed
@DataRepository()
abstract class Model with DataSupport<Model> implements _$Model {
  Model._();
  factory Model({
    String id,
    String name,
    BelongsTo<Company> company,
  }) = _Model;

  factory Model.fromJson(Map<String, dynamic> json) => _$ModelFromJson(json);
}

@freezed
@DataRepository()
abstract class City with DataSupport<City> implements _$City {
  City._();
  factory City({
    String id,
    String name,
  }) = _City;

  factory City.fromJson(Map<String, dynamic> json) => _$CityFromJson(json);
}

@freezed
@DataRepository()
abstract class Company with DataSupport<Company> implements _$Company {
  Company._();
  factory Company({
    String id,
    String name,
    String nasdaq,
    DateTime updatedAt,
    BelongsTo<City> headquarters,
    HasMany<Model> models,
  }) = _Company;

  factory Company.fromJson(Map<String, dynamic> json) =>
      _$CompanyFromJson(json);
}

//

mixin TestMixin<T extends DataSupport<T>> on RemoteAdapter<T> {
  @override
  get baseUrl => 'http://127.0.0.1:17083/';
}

class ModelTestRepository = $ModelRepository with TestMixin;
class CityTestRepository = $CityRepository with TestMixin;
class CompanyTestRepository = $CompanyRepository with TestMixin;