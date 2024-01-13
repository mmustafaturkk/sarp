@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Kullanıcı bilgileri data definition'
define root view entity ZFI_004_dd_user_pass as select from ZR_FI_000_T_USPASS
{
    key EntType,
    EntUser,
    EntPass,
    EntBase64
}where EntType = 'BANK_ENT'
