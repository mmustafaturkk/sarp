//@AbapCatalog.sqlViewName: 'ZFI_CDS_CUSTAGIN'
//@AbapCatalog.compiler.compareFilter: true
//@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Müşteri Yaşlandırma Raporu'
define view entity ZFI_005_DD_CUSTOMER_AGING
  with parameters
    P_LeadingLedger          : fins_ledger,
    P_KeyDate                : vdm_v_key_date,
    P_OverdueInterval1Days   : abap.int2,
    P_OverdueInterval2Days   : abap.int2,
    P_OverdueInterval3Days   : abap.int2,
    P_OverdueInterval4Days   : abap.int2,
    P_OverdueInterval5Days   : abap.int2,
    P_OverdueInterval6Days   : abap.int2,
    P_FutureDueInterval1Days : abap.int2,
    P_FutureDueInterval2Days : abap.int2,
    P_FutureDueInterval3Days : abap.int2,
    P_FutureDueInterval4Days : abap.int2,
    P_FutureDueInterval5Days : abap.int2,
    P_FutureDueInterval6Days : abap.int2
  //  as select distinct from I_JournalEntryItem                                    as item
  as select from    ZFI_005_DD_CUSTOMER_AGING_MAS(P_LeadingLedger : $parameters.P_LeadingLedger,
                                                  P_KeyDate       : $parameters.P_KeyDate,
                                                  P_Interval1     : $parameters.P_OverdueInterval6Days,
                                                  P_Interval2     : $parameters.P_FutureDueInterval6Days ) as item

  //Future
    left outer join zfi_005_dd_customer_aging_sum( P_LeadingLedger : $parameters.P_LeadingLedger,
                                                   P_KeyDate       : $parameters.P_KeyDate,
                                                   P_Interval1     : 0,
                                                   P_Interval2     : $parameters.P_FutureDueInterval1Days ,
                                                   P_Sign          : 1 )                                   as future1  on  future1.Customer            = item.Customer
                                                                                                                       and future1.TransactionCurrency = item.TransactionCurrency

    left outer join zfi_005_dd_customer_aging_sum( P_LeadingLedger : $parameters.P_LeadingLedger,
                                                   P_KeyDate       : $parameters.P_KeyDate,
                                                   P_Interval1     : $parameters.P_FutureDueInterval1Days ,
                                                   P_Interval2     : $parameters.P_FutureDueInterval2Days ,
                                                   P_Sign          : 1 )                                   as future2  on  future2.Customer            = item.Customer
                                                                                                                       and future2.TransactionCurrency = item.TransactionCurrency

    left outer join zfi_005_dd_customer_aging_sum( P_LeadingLedger : $parameters.P_LeadingLedger,
                                                   P_KeyDate       : $parameters.P_KeyDate,
                                                   P_Interval1     : $parameters.P_FutureDueInterval2Days ,
                                                   P_Interval2     : $parameters.P_FutureDueInterval3Days ,
                                                   P_Sign          : 1 )                                   as future3  on  future3.Customer            = item.Customer
                                                                                                                       and future3.TransactionCurrency = item.TransactionCurrency

    left outer join zfi_005_dd_customer_aging_sum( P_LeadingLedger : $parameters.P_LeadingLedger,
                                                   P_KeyDate       : $parameters.P_KeyDate,
                                                   P_Interval1     : $parameters.P_FutureDueInterval3Days ,
                                                   P_Interval2     : $parameters.P_FutureDueInterval4Days ,
                                                   P_Sign          : 1 )                                   as future4  on  future4.Customer            = item.Customer
                                                                                                                       and future4.TransactionCurrency = item.TransactionCurrency

    left outer join zfi_005_dd_customer_aging_sum( P_LeadingLedger : $parameters.P_LeadingLedger,
                                                   P_KeyDate       : $parameters.P_KeyDate,
                                                   P_Interval1     : $parameters.P_FutureDueInterval4Days ,
                                                   P_Interval2     : $parameters.P_FutureDueInterval5Days ,
                                                   P_Sign          : 1 )                                   as future5  on  future5.Customer            = item.Customer
                                                                                                                       and future5.TransactionCurrency = item.TransactionCurrency

    left outer join zfi_005_dd_customer_aging_sum( P_LeadingLedger : $parameters.P_LeadingLedger,
                                                   P_KeyDate       : $parameters.P_KeyDate,
                                                   P_Interval1     : $parameters.P_FutureDueInterval5Days ,
                                                   P_Interval2     : $parameters.P_FutureDueInterval6Days ,
                                                   P_Sign          : 1 )                                   as future6  on  future6.Customer            = item.Customer
                                                                                                                       and future6.TransactionCurrency = item.TransactionCurrency
  //Overdue
    left outer join zfi_005_dd_customer_aging_sum( P_LeadingLedger : $parameters.P_LeadingLedger,
                                                   P_KeyDate       : $parameters.P_KeyDate,
                                                   P_Interval1     : $parameters.P_OverdueInterval1Days ,
                                                   P_Interval2     : 0,
                                                   P_Sign          : -1 )                                  as overdue1 on  overdue1.Customer            = item.Customer
                                                                                                                       and overdue1.TransactionCurrency = item.TransactionCurrency
    left outer join zfi_005_dd_customer_aging_sum( P_LeadingLedger : $parameters.P_LeadingLedger,
                                                   P_KeyDate       : $parameters.P_KeyDate,
                                                   P_Interval1     : $parameters.P_OverdueInterval2Days ,
                                                   P_Interval2     : $parameters.P_OverdueInterval1Days ,
                                                   P_Sign          : -1 )                                  as overdue2 on  overdue2.Customer            = item.Customer
                                                                                                                       and overdue2.TransactionCurrency = item.TransactionCurrency

    left outer join zfi_005_dd_customer_aging_sum( P_LeadingLedger : $parameters.P_LeadingLedger,
                                                   P_KeyDate       : $parameters.P_KeyDate,
                                                   P_Interval1     : $parameters.P_OverdueInterval3Days ,
                                                   P_Interval2     : $parameters.P_OverdueInterval2Days ,
                                                   P_Sign          : -1 )                                  as overdue3 on  overdue3.Customer            = item.Customer
                                                                                                                       and overdue3.TransactionCurrency = item.TransactionCurrency

    left outer join zfi_005_dd_customer_aging_sum( P_LeadingLedger : $parameters.P_LeadingLedger,
                                                   P_KeyDate       : $parameters.P_KeyDate,
                                                   P_Interval1     : $parameters.P_OverdueInterval4Days ,
                                                   P_Interval2     : $parameters.P_OverdueInterval3Days ,
                                                   P_Sign          : -1 )                                  as overdue4 on  overdue4.Customer            = item.Customer
                                                                                                                       and overdue4.TransactionCurrency = item.TransactionCurrency

    left outer join zfi_005_dd_customer_aging_sum( P_LeadingLedger : $parameters.P_LeadingLedger,
                                                   P_KeyDate       : $parameters.P_KeyDate,
                                                   P_Interval1     : $parameters.P_OverdueInterval5Days ,
                                                   P_Interval2     : $parameters.P_OverdueInterval4Days ,
                                                   P_Sign          : -1 )                                  as overdue5 on  overdue5.Customer            = item.Customer
                                                                                                                       and overdue5.TransactionCurrency = item.TransactionCurrency

    left outer join zfi_005_dd_customer_aging_sum( P_LeadingLedger : $parameters.P_LeadingLedger,
                                                   P_KeyDate       : $parameters.P_KeyDate,
                                                   P_Interval1     : $parameters.P_OverdueInterval6Days ,
                                                   P_Interval2     : $parameters.P_OverdueInterval5Days ,
                                                   P_Sign          : -1 )                                  as overdue6 on  overdue6.Customer            = item.Customer
                                                                                                                       and overdue6.TransactionCurrency = item.TransactionCurrency
{
  key item.CompanyCode,
  key item.Ledger,
  key item.Customer,
      item.TransactionCurrency,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      cast(  (case when future1.amount is not null then cast( future1.amount as abap.fltp ) else 0  end )  as abap.curr( 23, 10 ) )  as amount_future1,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      cast(  (case when future2.amount is not null then cast( future2.amount as abap.fltp ) else 0  end ) as abap.curr( 23, 10 ) )   as amount_future2,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      cast( (case when future3.amount is not null then cast( future3.amount as abap.fltp ) else 0  end ) as abap.curr( 23, 10 ) )    as amount_future3,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      cast(  (case when future4.amount is not null then cast( future4.amount as abap.fltp ) else 0  end ) as abap.curr( 23, 10 ) )   as amount_future4,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      cast(  (case when future5.amount is not null then cast( future5.amount as abap.fltp ) else 0  end ) as abap.curr( 23, 10 ) )   as amount_future5,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      cast(  (case when future6.amount is not null then cast( future6.amount as abap.fltp ) else 0  end ) as abap.curr( 23, 10 ) )   as amount_future6,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      cast(  (case when overdue1.amount is not null then cast( overdue1.amount as abap.fltp ) else 0  end ) as abap.curr( 23, 10 ) ) as amount_overdue1,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      cast(  (case when overdue2.amount is not null then cast( overdue2.amount as abap.fltp ) else 0  end ) as abap.curr( 23, 10 ) ) as amount_overdue2,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      cast(  (case when overdue3.amount is not null then cast( overdue3.amount as abap.fltp ) else 0  end ) as abap.curr( 23, 10 ) ) as amount_overdue3,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      cast(  (case when overdue4.amount is not null then cast( overdue4.amount as abap.fltp ) else 0  end ) as abap.curr( 23, 10 ) ) as amount_overdue4,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      cast(  (case when overdue5.amount is not null then cast( overdue5.amount as abap.fltp ) else 0  end ) as abap.curr( 23, 10 ) ) as amount_overdue5,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      cast(  (case when overdue6.amount is not null then cast( overdue6.amount as abap.fltp ) else 0  end ) as abap.curr( 23, 10 ) ) as amount_overdue6,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      cast( ( case when overdue1.amount is not null then cast( overdue1.amount as abap.fltp ) else 0 end +
              case when overdue2.amount is not null then cast( overdue2.amount as abap.fltp ) else 0 end +
              case when overdue3.amount is not null then cast( overdue3.amount as abap.fltp ) else 0 end +
              case when overdue4.amount is not null then cast( overdue4.amount as abap.fltp ) else 0 end +
              case when overdue5.amount is not null then cast( overdue5.amount as abap.fltp ) else 0 end +
              case when overdue6.amount is not null then cast( overdue6.amount as abap.fltp ) else 0 end ) as abap.curr( 23, 10 ) )  as total_overdue,

      @Semantics.amount.currencyCode: 'TransactionCurrency'
      cast( (case when future1.amount is not null then cast( future1.amount as abap.fltp ) else 0 end +
             case when future2.amount is not null then cast( future2.amount as abap.fltp ) else 0 end +
             case when future3.amount is not null then cast( future3.amount as abap.fltp ) else 0 end +
             case when future4.amount is not null then cast( future4.amount as abap.fltp ) else 0 end +
             case when future5.amount is not null then cast( future5.amount as abap.fltp ) else 0 end +
             case when future6.amount is not null then cast( future6.amount as abap.fltp ) else 0 end  ) as abap.curr( 23, 10 ) )    as total_future,

      @Semantics.amount.currencyCode: 'TransactionCurrency'
      cast( ( case when overdue1.amount is not null then cast( overdue1.amount as abap.fltp ) else 0 end +
              case when overdue2.amount is not null then cast( overdue2.amount as abap.fltp ) else 0 end +
              case when overdue3.amount is not null then cast( overdue3.amount as abap.fltp ) else 0 end +
              case when overdue4.amount is not null then cast( overdue4.amount as abap.fltp ) else 0 end +
              case when overdue5.amount is not null then cast( overdue5.amount as abap.fltp ) else 0 end +
              case when overdue6.amount is not null then cast( overdue6.amount as abap.fltp ) else 0 end +
              case when future1.amount  is not null then cast( future1.amount  as abap.fltp ) else 0 end +
              case when future2.amount  is not null then cast( future2.amount  as abap.fltp ) else 0 end +
              case when future3.amount  is not null then cast( future3.amount  as abap.fltp ) else 0 end +
              case when future4.amount  is not null then cast( future4.amount  as abap.fltp ) else 0 end +
              case when future5.amount  is not null then cast( future5.amount  as abap.fltp ) else 0 end +
              case when future6.amount  is not null then cast( future6.amount  as abap.fltp ) else 0 end  ) as abap.curr( 23, 10 ) ) as total

}
