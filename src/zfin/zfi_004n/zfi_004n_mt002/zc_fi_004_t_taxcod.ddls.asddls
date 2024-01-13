@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: 'Projection View for ZR_FI_004_T_TAXCOD'
@ObjectModel.semanticKey: [ 'TaxCode' ]
define root view entity ZC_FI_004_T_TAXCOD
  provider contract transactional_query
  as projection on ZR_FI_004_T_TAXCOD
{
  key TaxCode,
  TaxType,
  MoveType,
  Percent,
  @Consumption.valueHelpDefinition: [ { entity: { name: 'ZFI_004_DD_F4_DEBIT_CREDIT', element: 'value_low' }}]
  DebitCredit,
  LocalLastChangedAt
  
}
