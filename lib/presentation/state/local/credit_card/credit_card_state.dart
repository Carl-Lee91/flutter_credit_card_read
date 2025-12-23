part of 'credit_card_cubit.dart';

enum CreditCardStatus { initial, processing, success, notFound, error }

@freezed
abstract class CreditCardState with _$CreditCardState {
  const factory CreditCardState({
    @Default(CreditCardStatus.initial) CreditCardStatus status,
    String? cardNumber,
    String? expiryDate,
  }) = _CreditCardState;
}
