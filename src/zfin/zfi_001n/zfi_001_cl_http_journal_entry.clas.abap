CLASS zfi_001_cl_http_journal_entry DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_inputs.
             INCLUDE TYPE zfi_001_s_journal_entry_header.
    TYPES:   items TYPE STANDARD TABLE OF  zfi_001_s_journal_entry_item WITH EMPTY KEY,
           END OF ty_inputs,

           BEGIN OF ty_output,
             items TYPE STANDARD TABLE OF zfi_001_s_journal_entry_respon WITH EMPTY KEY,
           END OF ty_output.

    INTERFACES if_http_service_extension .
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA: lt_req            TYPE ty_inputs,
          lv_error(1)       TYPE c,
          lv_text           TYPE string,
          es_response       TYPE ty_output,
          lc_header_content TYPE string VALUE 'content-type',
          lc_content_type   TYPE string VALUE 'text/json'.
ENDCLASS.



CLASS ZFI_001_CL_HTTP_JOURNAL_ENTRY IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.

    "Gelen Veri BEG
    DATA(lv_req_body) = request->get_text( ).
    DATA(get_method) = request->get_method( ).

    "first deserialize the request
    xco_cp_json=>data->from_string( lv_req_body )->apply( VALUE #(
        ( xco_cp_json=>transformation->pascal_case_to_underscore )
      ) )->write_to( REF #( lt_req ) ).

    IF 1 = 1.

    ENDIF.
    "Gelen Veri END

**********************************************************************

    "Verinin İşleneceği Yer BEG


    DATA: lt_je_deep TYPE TABLE FOR ACTION IMPORT i_journalentrytp~post,
          lv_cid     TYPE abp_behv_cid.


    TRY.
        lv_cid = to_upper( cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ) ).
      CATCH cx_uuid_error.
        ASSERT 1 = 0.
    ENDTRY.


    SELECT
    i_journalentry~companycode,
    i_journalentry~fiscalyear,
    i_journalentry~accountingdocument,
*    i_journalentry~_businesstransactiontype,
    i_journalentry~accountingdocumenttype,
    i_journalentry~accountingdoccreatedbyuser,
    i_journalentry~documentdate,
    i_journalentry~postingdate,
    _journalentryitem~glaccount,
*I_JournalEntry._AdditionalCurrency1Role.CurrencyRole
    i_journalentry~transactioncurrency,
    _journalentryitem~amountintransactioncurrency,
    _journalentryitem~customer,
    _journalentryitem~supplier,
    _additionalcurrency1role~currencyrole,
    _addlledgeroplacctgdocitem~taxcode

*    _journalentryitem~_customer,
*    _journalentryitem~_supplier,
*    _journalentryitem~glaccount
*I_JournalEntry._AddlLedgerOplAcctgDocItem.TaxCode
     FROM

    i_journalentry
    LEFT OUTER JOIN i_journalentryitem
       AS _journalentryitem             ON i_journalentry~companycode    = _journalentryitem~companycode
                                                                       AND i_journalentry~fiscalyear                 = _journalentryitem~fiscalyear
                                                                       AND i_journalentry~accountingdocument         = _journalentryitem~accountingdocument
    LEFT OUTER JOIN i_currencyrole
       AS _additionalcurrency1role      ON  i_journalentry~additionalcurrency1role = _additionalcurrency1role~currencyrole
    LEFT OUTER JOIN i_addlledgeroplacctgdocitem
       AS _addlledgeroplacctgdocitem    ON i_journalentry~companycode                = _addlledgeroplacctgdocitem~companycode
                                                                                     AND i_journalentry~fiscalyear                 = _addlledgeroplacctgdocitem~fiscalyear
                                                                                     AND i_journalentry~accountingdocument         = _addlledgeroplacctgdocitem~accountingdocument
    INTO TABLE @DATA(lt_data).
    READ TABLE lt_data INTO DATA(ls_data) INDEX 1.

    APPEND INITIAL LINE TO lt_je_deep ASSIGNING FIELD-SYMBOL(<je_deep>).
    <je_deep>-%cid = lv_cid.
    <je_deep>-%param = VALUE #(
     companycode = <je_deep>-%param-companycode
     createdbyuser = <je_deep>-%param-createdbyuser
     businesstransactiontype = <je_deep>-%param-businesstransactiontype
     accountingdocumenttype = <je_deep>-%param-accountingdocumenttype
     documentdate = <je_deep>-%param-documentdate
     postingdate = <je_deep>-%param-postingdate


     _glitems = VALUE #(  ( glaccount = ls_data-glaccount
                            _currencyamount = VALUE #( ( currencyrole = ls_data-currencyrole
                                                       journalentryitemamount = ls_data-amountintransactioncurrency
                                                       currency = ls_data-transactioncurrency
                                                       ) )
                            _profitabilitysupplement = VALUE #( customer = ls_data-customer )
                                                       )

                                                       )
                                                       _apitems = VALUE #( (
                                                       supplier = ls_data-supplier
                                                       glaccount = ls_data-glaccount ) )
                                                       _taxitems = VALUE #( (
                                                       taxcode = ls_data-taxcode
                                                        ) )
                                                        )
                                                        .








    MODIFY ENTITIES OF i_journalentrytp
     ENTITY journalentry
     EXECUTE post FROM lt_je_deep
     FAILED DATA(ls_failed_deep)
     REPORTED DATA(ls_reported_deep)
     MAPPED DATA(ls_mapped_deep).


    IF ls_failed_deep IS NOT INITIAL.


      LOOP AT ls_reported_deep-journalentry ASSIGNING FIELD-SYMBOL(<ls_reported_deep>).
        DATA(lv_result) = <ls_reported_deep>-%msg->if_message~get_text( ).
        ...
      ENDLOOP.
    ELSE.


      COMMIT ENTITIES BEGIN
       RESPONSE OF i_journalentrytp
       FAILED DATA(lt_commit_failed)
       REPORTED DATA(lt_commit_reported).
      ...
      COMMIT ENTITIES END.
    ENDIF.




*    LOOP AT lt_req-items INTO DATA(ls_req).
*
*      APPEND INITIAL LINE TO es_response-items ASSIGNING FIELD-SYMBOL(<fs_response>).
*
*      <fs_response>-rowno = sy-tabix.
*      <fs_response>-message = | { sy-tabix } 'Başarılı' |.
**insert zfi_001_t.
*    ENDLOOP.

    "Verinin İşleneceği Yer END

**********************************************************************

    "Response BEG
    "respond with success payload
    response->set_status('200').

    DATA(lv_json_string) = xco_cp_json=>data->from_abap( es_response )->apply( VALUE #(
  ( xco_cp_json=>transformation->underscore_to_pascal_case )
  ) )->to_string( ).

    response->set_text( lv_json_string ).
    response->set_header_field( i_name = lc_header_content
   i_value = lc_content_type ).

    "Response END
  ENDMETHOD.
ENDCLASS.
