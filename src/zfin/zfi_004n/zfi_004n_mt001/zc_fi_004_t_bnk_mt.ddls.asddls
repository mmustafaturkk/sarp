@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: 'Projection View for ZR_FI_004_T_BNK_MT'
@ObjectModel.semanticKey: [ 'CompanyCode','TraVmsTransactionType', 'TraTransactionType', 'TraMt940transactionType' ]
define root view entity ZC_FI_004_T_BNK_MT
  provider contract transactional_query
  as projection on ZR_FI_004_T_BNK_MT
{
  key CompanyCode,
  key TraVmsTransactionType,
  key TraTransactionType,
  key TraMt940transactionType,
  CostCenter,
  GlAccount,
  TaxCode,
  LocalLastChangedAt
  
}
