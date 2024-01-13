@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Profit Center Search Help'
define root view entity ZFI_004_DD_PROFIT_CENTER
  as select from I_ProfitCenterText as profit
{
  key profit.ProfitCenter,
      profit.ProfitCenterName,
      profit.ProfitCenterLongName
}
//where
//  cost.Language = $session.system_language
