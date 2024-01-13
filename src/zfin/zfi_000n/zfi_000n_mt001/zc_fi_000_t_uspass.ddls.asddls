@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: 'Projection View for ZR_FI_000_T_USPASS'
@ObjectModel.semanticKey: [ 'EntType' ]
define root view entity ZC_FI_000_T_USPASS
  provider contract transactional_query
  as projection on ZR_FI_000_T_USPASS
{
  key EntType,
  EntUser,
  EntPass,
  EntBase64,
  LocalLastChangedAt
  
}
