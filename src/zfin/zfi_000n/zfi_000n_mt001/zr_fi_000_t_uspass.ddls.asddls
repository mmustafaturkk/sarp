@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: '##GENERATED ZFI_000_T_USPASS'
define root view entity ZR_FI_000_T_USPASS
  as select from zfi_000_t_uspass
{
  key ent_type as EntType,
  ent_user as EntUser,
  ent_pass as EntPass,
  ent_base64 as EntBase64,
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
