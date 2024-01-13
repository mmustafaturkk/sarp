@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Cost Center Search Help'
define root view entity ZFI_004_DD_COST_CENTER
  as select from I_CostCenterText as cost
{
  key cost.CostCenter,
      cost.CostCenterName,
      cost.CostCenterDescription
}
//where
//  cost.Language = $session.system_language
