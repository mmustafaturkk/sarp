@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'i_housebankaccountlinkage'
define root view entity zfi_004_dd_housebankaccountlin
  as select from I_HouseBankAccountLinkage
{
  key CompanyCode,
  key HouseBank,
  key HouseBankAccount,
      BankAccountInternalID,
      BankInternalID,
      BankCountry,
      SWIFTCode,
      BankName,
      BankNumber,
      BankAccount,
      BankAccountAlternative,
      ReferenceInfo,
      BankControlKey,
      BankAccountCurrency,
      IBAN,
      BankAccountDescription,
      GLAccount,
      BankAccountHolderName,
      BankAccountNumber,
      /* Associations */
      _BankAccount,
      _CompanyCode,
      _HouseBank
}
