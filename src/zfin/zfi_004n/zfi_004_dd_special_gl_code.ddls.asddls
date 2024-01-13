@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Special Gl Code search help'
define root view entity zfi_004_dd_special_gl_code as select from I_SpecialGLCode
{
  key I_SpecialGLCode.SpecialGLCode,
  key I_SpecialGLCode.FinancialAccountType,
  I_SpecialGLCode._Text[ Language = 'T' ].SpecialGLCodeLongName,
  I_SpecialGLCode._Text[ Language = 'T' ].Language,
  I_SpecialGLCode._Text[ Language = 'T' ]._Language[ LanguageISOCode = 'TR' ].LanguageISOCode,
  //associations
  _FinancialAccountType,
  _Text[ Language = 'T' ],
  _Text[ Language = 'T' ]._Language[ LanguageISOCode = 'TR' ]
  
}
