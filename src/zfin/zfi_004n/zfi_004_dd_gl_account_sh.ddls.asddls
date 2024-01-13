@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Karşıt Hesap Search Help'
define root view entity ZFI_004_dd_gl_account_sh
  with parameters
    p_companycode : zfi_004_de_sirket_kodu
  as select from    I_GLAccount     as account
    left outer join I_GLAccountText as text on  text.GLAccount       = account.GLAccount
                                            and text.ChartOfAccounts = account.ChartOfAccounts
                                            and text.Language        = 'T'
{
  key account.GLAccount,
  key account.CompanyCode,
      text.GLAccountLongName
}
where
      account.GLAccount   not like '0%'
  and account.CompanyCode = $parameters.p_companycode
