@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Document no search help'
define root view entity ZFI_004_DD_DOCUMENT_NO
  as select from zfi_004_t_bnk_lg
{
  key document_no
}
where
  document_no is not initial 
