// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'main.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CreditCardState {

 CreditCardStatus get status; String? get cardNumber; String? get expiryDate;
/// Create a copy of CreditCardState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreditCardStateCopyWith<CreditCardState> get copyWith => _$CreditCardStateCopyWithImpl<CreditCardState>(this as CreditCardState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreditCardState&&(identical(other.status, status) || other.status == status)&&(identical(other.cardNumber, cardNumber) || other.cardNumber == cardNumber)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate));
}


@override
int get hashCode => Object.hash(runtimeType,status,cardNumber,expiryDate);

@override
String toString() {
  return 'CreditCardState(status: $status, cardNumber: $cardNumber, expiryDate: $expiryDate)';
}


}

/// @nodoc
abstract mixin class $CreditCardStateCopyWith<$Res>  {
  factory $CreditCardStateCopyWith(CreditCardState value, $Res Function(CreditCardState) _then) = _$CreditCardStateCopyWithImpl;
@useResult
$Res call({
 CreditCardStatus status, String? cardNumber, String? expiryDate
});




}
/// @nodoc
class _$CreditCardStateCopyWithImpl<$Res>
    implements $CreditCardStateCopyWith<$Res> {
  _$CreditCardStateCopyWithImpl(this._self, this._then);

  final CreditCardState _self;
  final $Res Function(CreditCardState) _then;

/// Create a copy of CreditCardState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? cardNumber = freezed,Object? expiryDate = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CreditCardStatus,cardNumber: freezed == cardNumber ? _self.cardNumber : cardNumber // ignore: cast_nullable_to_non_nullable
as String?,expiryDate: freezed == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CreditCardState].
extension CreditCardStatePatterns on CreditCardState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreditCardState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreditCardState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreditCardState value)  $default,){
final _that = this;
switch (_that) {
case _CreditCardState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreditCardState value)?  $default,){
final _that = this;
switch (_that) {
case _CreditCardState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CreditCardStatus status,  String? cardNumber,  String? expiryDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreditCardState() when $default != null:
return $default(_that.status,_that.cardNumber,_that.expiryDate);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CreditCardStatus status,  String? cardNumber,  String? expiryDate)  $default,) {final _that = this;
switch (_that) {
case _CreditCardState():
return $default(_that.status,_that.cardNumber,_that.expiryDate);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CreditCardStatus status,  String? cardNumber,  String? expiryDate)?  $default,) {final _that = this;
switch (_that) {
case _CreditCardState() when $default != null:
return $default(_that.status,_that.cardNumber,_that.expiryDate);case _:
  return null;

}
}

}

/// @nodoc


class _CreditCardState implements CreditCardState {
  const _CreditCardState({this.status = CreditCardStatus.initial, this.cardNumber, this.expiryDate});
  

@override@JsonKey() final  CreditCardStatus status;
@override final  String? cardNumber;
@override final  String? expiryDate;

/// Create a copy of CreditCardState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreditCardStateCopyWith<_CreditCardState> get copyWith => __$CreditCardStateCopyWithImpl<_CreditCardState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreditCardState&&(identical(other.status, status) || other.status == status)&&(identical(other.cardNumber, cardNumber) || other.cardNumber == cardNumber)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate));
}


@override
int get hashCode => Object.hash(runtimeType,status,cardNumber,expiryDate);

@override
String toString() {
  return 'CreditCardState(status: $status, cardNumber: $cardNumber, expiryDate: $expiryDate)';
}


}

/// @nodoc
abstract mixin class _$CreditCardStateCopyWith<$Res> implements $CreditCardStateCopyWith<$Res> {
  factory _$CreditCardStateCopyWith(_CreditCardState value, $Res Function(_CreditCardState) _then) = __$CreditCardStateCopyWithImpl;
@override @useResult
$Res call({
 CreditCardStatus status, String? cardNumber, String? expiryDate
});




}
/// @nodoc
class __$CreditCardStateCopyWithImpl<$Res>
    implements _$CreditCardStateCopyWith<$Res> {
  __$CreditCardStateCopyWithImpl(this._self, this._then);

  final _CreditCardState _self;
  final $Res Function(_CreditCardState) _then;

/// Create a copy of CreditCardState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? cardNumber = freezed,Object? expiryDate = freezed,}) {
  return _then(_CreditCardState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CreditCardStatus,cardNumber: freezed == cardNumber ? _self.cardNumber : cardNumber // ignore: cast_nullable_to_non_nullable
as String?,expiryDate: freezed == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
