@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: '##GENERATED ZFI_004_T_BNK_MT'
define root view entity ZR_FI_004_T_BNK_MT
  as select from zfi_004_t_bnk_mt
{
  key company_code as CompanyCode,
  key tra_vms_transaction_type as TraVmsTransactionType,
  key tra_transaction_type as TraTransactionType,
  key tra_mt940transaction_type as TraMt940transactionType,
  cost_center as CostCenter,
  gl_account as GlAccount,
  tax_code as TaxCode,
  @Semantics.user.createdBy: true
  local_created_by as LocalCreatedBy,
  @Semantics.systemDateTime.createdAt: true
  local_created_at as LocalCreatedAt,
  @Semantics.user.localInstanceLastChangedBy: true
  local_last_changed_by as LocalLastChangedBy,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  local_last_changed_at as LocalLastChangedAt,
  @Semantics.systemDateTime.lastChangedAt: true
  last_changed_at as LastChangedAt
  
}
