@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Debit Credit F4'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZFI_004_DD_F4_DEBIT_CREDIT
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE( p_domain_name: 'ZFI_004_DM_DEBIT_CREDIT')
{
      //  key domain_name,
      //  key value_position,
  key value_low,
      case when value_low = 'S' then '-' else '+' end as TEXT

}
