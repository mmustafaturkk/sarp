@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Supplier search help'
define view entity zfi_004_dd_supplier_sh as select from zfi_004_dd_supplier
{
    key Supplier,
    SupplierFullName
}
