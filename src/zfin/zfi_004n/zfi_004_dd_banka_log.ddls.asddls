@AbapCatalog.sqlViewName: 'ZDDBNKLG'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Banka log tablosu view'
@Search.searchable: false
@Analytics.dataCategory: #DIMENSION
@Analytics.internalName: #LOCAL
@ObjectModel.modelingPattern: #ANALYTICAL_DIMENSION
@ObjectModel.supportedCapabilities: [ #ANALYTICAL_DIMENSION, #CDS_MODELING_ASSOCIATION_TARGET, #SQL_DATA_SOURCE, #CDS_MODELING_DATA_SOURCE ]
define view ZFI_004_DD_BANKA_LOG as select from zfi_004_t_bnk_lg
{
    key guid_tra as GuidTra,
    number_of_tra as NumberOfTra,
    company_code as CompanyCode,
    acc_iban as AccIban,
    acc_fec as AccFec,
    tra_id as TraId,
    tra_vms_transaction_type as TraVmsTransactionType,
    tra_type_name as TraTypeName,
    tra_transaction_type as TraTransactionType,
    tra_mt940transaction_type as TraMt940transactionType,
    tra_accounting_date as TraAccountingDate,
    tra_accounting_time as TraAccountingTime,
    tra_sender_identity_number as TraSenderIdentityNumber,
    tra_opponent_title as TraOpponentTitle,
    tra_opponent_iban as TraOpponentIban,
    tra_opponent_taxno as TraOpponentTaxno,
    tra_fis_no as TraFisNo,
    tra_description as TraDescription,
    tra_amount as TraAmount,
    tra_type as TraType
}
