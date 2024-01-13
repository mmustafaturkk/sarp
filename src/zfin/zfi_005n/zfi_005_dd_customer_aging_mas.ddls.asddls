@AbapCatalog.sqlViewName: 'ZFI_CDS_CUSMAS'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Müşteri Yaşlandırma Ana Veri'
define view ZFI_005_DD_CUSTOMER_AGING_MAS
  with parameters
    P_LeadingLedger : fins_ledger,
    P_KeyDate       : abap.dats,
    P_Interval1     : abap.int2,
    P_Interval2     : abap.int2
  as select from I_JournalEntryItem as item
{
  key item.CompanyCode,
  key item.Ledger,
  key item.Customer,
  key item.TransactionCurrency
}
where
  (
       AccountingDocumentType =  'DG'
    or AccountingDocumentType =  'DR'
    or AccountingDocumentType =  'RV'
  )
  and  Customer               is not initial
  and  NetDueDate             >= dats_add_days( $parameters.P_KeyDate , ( -1 * $parameters.P_Interval1 ), 'INITIAL' )
  and  NetDueDate             <= dats_add_days( $parameters.P_KeyDate , (      $parameters.P_Interval2 ), 'INITIAL' )
  and  Ledger                 = $parameters.P_LeadingLedger
group by
  item.CompanyCode,
  item.Ledger,
  item.Customer,
  item.TransactionCurrency
