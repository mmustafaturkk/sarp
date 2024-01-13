@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Müşteri Yaşlandırma Toplama'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity zfi_005_dd_customer_aging_sum
  with parameters
    P_LeadingLedger : fins_ledger,
    P_KeyDate       : abap.dats,
    P_Interval1     : abap.int2,
    P_Interval2     : abap.int2,
    P_Sign          : abap.int2
  as select from I_JournalEntryItem as item
{
  Customer,
  TransactionCurrency,
//  PostingDate,
  @Semantics.amount.currencyCode: 'TransactionCurrency'
  sum(AmountInTransactionCurrency) as amount
}
where
      item.Ledger = $parameters.P_LeadingLedger
  and NetDueDate <= dats_add_days( $parameters.P_KeyDate , ( $parameters.P_Sign * $parameters.P_Interval2 ), 'INITIAL' )
  and NetDueDate >= dats_add_days( $parameters.P_KeyDate , ( $parameters.P_Sign * $parameters.P_Interval1 ), 'INITIAL' )
group by
//  PostingDate,
  Customer,
  TransactionCurrency
