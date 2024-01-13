@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Currency search help'
define view entity ZFI_004_dd_currency_sh as select from I_CurrencyText
{
    key Language,
    key Currency,
    CurrencyName,
    CurrencyShortName,
    /* Associations */
    _Currency,
    _Language[ Language = 'T' ]
}
where Language = 'T'
