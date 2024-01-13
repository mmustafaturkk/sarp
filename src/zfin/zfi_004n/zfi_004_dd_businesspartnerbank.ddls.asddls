@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'i_businesspartnerbank'
/*@API.element.releaseState: #DECOMMISSIONED
@API.element.successor: 'SucceedingReleasedElement' */
define root view entity zfi_004_dd_businesspartnerbank
  as select from I_BusinessPartnerBank
{
  key BusinessPartner,
  key BankIdentification,
      BankCountryKey,
      BankName,
      BankNumber,
      SWIFTCode,
      BankControlKey,
      BankAccountHolderName,
      BankAccountName,
      ValidityStartDate,
      ValidityEndDate,
//      @API.element.releaseState: #DEPRECATED
//      @API.element.successor: 'BPIsActualDate'
//      IsActualDate,
      BPIsActualDate,
      IBAN,
      IBANValidityStartDate,
      BankAccount,
      BankAccountReferenceText,
      CollectionAuthInd,
      BusinessPartnerExternalBankID,
      BPBankDetailsChangeDate,
      BPBankDetailsChangeTargetID,
      BPBankIsProtected,
      BPBankUUID,
      CityName,
      AuthorizationGroup,
      /* Associations */
      _Bank,
      _BusinessPartner,
      _BusinessPartnerBankAlias,
      _IBAN
}
