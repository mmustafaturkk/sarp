CLASS zfi_003_cl_http_musteri_ent DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_service_extension .
  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA: ls_req            TYPE zfi_003_s_header,
          lv_error(1)       TYPE c,
          lv_text           TYPE string,
          es_response       TYPE zfi_000_s_response,
          lc_header_content TYPE string VALUE 'content-type',
          lc_content_type   TYPE string VALUE 'text/json'.
ENDCLASS.



CLASS ZFI_003_CL_HTTP_MUSTERI_ENT IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.
    DATA(lv_req_body) = request->get_text( ).
    DATA(get_method) = request->get_method( ).

    "first deserialize the request
    TRY.
*        xco_cp_json=>data->from_string( lv_req_body )->apply( VALUE #(
*            ( xco_cp_json=>transformation->pascal_case_to_underscore )
*          ) )->write_to( REF #( ls_req ) ).

        CALL METHOD /ui2/cl_json=>deserialize
          EXPORTING
            json         = lv_req_body
            pretty_name  = /ui2/cl_json=>pretty_mode-user_low_case
            assoc_arrays = abap_true
          CHANGING
            data         = ls_req.

      CATCH cx_root INTO DATA(lc_root).
        DATA(lv_message) = lc_root->get_longtext( ).
    ENDTRY.

    TRY.
        DATA(destination) = cl_soap_destination_provider=>create_by_comm_arrangement(
        comm_scenario = 'ZFI_000_CS_JOURNAL_ENTRY'
*         comm_scenario = 'SAP_COM_0002'
*        service_id = 'CO_FINS_JOURNAL_ENTRY_BULK_CRE_SPRX'
*          i_url  = COND string( WHEN sy-mandt EQ '080' THEN 'https://my404873-api.s4hana.cloud.sap/sap/bc/srt/scs_ext/sap/journalentrycreaterequestconfi'
*                                WHEN sy-mandt EQ '100' THEN 'https://my404812-api.s4hana.cloud.sap/sap/bc/srt/scs_ext/sap/journalentrycreaterequestconfi' )
*i_url = 'https://my404812-api.s4hana.cloud.sap/sap/bc/srt/scs_ext/sap/journalentrycreaterequestconfi'
*     service_id     = '<outbound service>'
*     comm_system_id = 'ZMTURK_COM_SYS_OUTBOUND_002'
        ).

        DATA(proxy) = NEW zco_journal_entry_create_reque( destination = destination ).

        DATA: lt_item           TYPE zjournal_entry_create_req_tab3,
              lt_debtor         TYPE zjournal_entry_create_req_tab4,
              lt_producttaxitem TYPE zjournal_entry_create_req_tab2,
              lt_req            TYPE zjournal_entry_create_requ_tab,
              lt_creditor       TYPE zjournal_entry_create_req_tab5.

        LOOP AT ls_req-items INTO DATA(ls_st).
          DATA(ls_item) = VALUE zjournal_entry_create_request9( reference_document_item = ls_st-referencedocumentitem
                                                                glaccount = VALUE zchart_of_accounts_item_code( content = ls_st-glaccount )
                                                                amount_in_transaction_currency = VALUE zamount( currency_code = ls_req-currencycode
                                                                                                                content       = ls_st-amountintransactioncurrency )
                                                                debit_credit_code = ls_st-debitcreditcode
                                                                tax = VALUE zjournal_entry_create_request2( tax_code = VALUE zproduct_taxation_characteris1( content = ls_st-tax-taxcode ) )
                                                                account_assignment = VALUE zjournal_entry_create_request8( profit_center = ls_st-accountassignment-profitcenter
                                                                                                                           cost_center = ls_st-accountassignment-costcenter
                                                                                                                           segment = ls_st-accountassignment-segment
                                                                                                                           functional_area = ls_st-accountassignment-functionalarea )
                                                                profitability_supplement = VALUE zjournal_entry_create_request6( customer = ls_st-profitabilitysupplement-customer )
                                                                assignment_reference = ls_st-assignmentreference
                                                                document_item_text = ls_st-documentitemtext
                                                                 ).

          APPEND ls_item TO lt_item.
          CLEAR ls_item.
        ENDLOOP.

        LOOP AT ls_req-debtoritems INTO DATA(ls_st2).
          DATA(ls_debtor) = VALUE zjournal_entry_create_reques13( debtor = ls_st2-debtor
                                                                 amount_in_transaction_currency = VALUE zamount( currency_code = ls_req-currencycode
                                                                                                                 content       = ls_st2-amountintransactioncurrency )
                                                                 reference_document_item = ls_st2-referencedocumentitem
                                                                 debit_credit_code = ls_st2-debitcreditcode
                                                                 document_item_text = ls_st2-documentitemtext
                                                                 assignment_reference = ls_st2-assignmentreference
                                                                  ).

          APPEND ls_debtor TO lt_debtor.
          CLEAR:ls_debtor.
        ENDLOOP.

        LOOP AT ls_req-producttaxitems INTO DATA(ls_st3).
          DATA(ls_producttaxitem) = VALUE zjournal_entry_create_request3( tax_code = VALUE zproduct_taxation_characteris1( content = ls_st3-taxcode )
                                                                          tax_item_classification = ls_st3-taxitemclassification
                                                                          condition_type = ls_st3-conditiontype
                                                                          amount_in_transaction_currency = VALUE zamount( currency_code = ls_req-currencycode
                                                                                                                          content       = ls_st3-amountintransactioncurrency )
                                                                          debit_credit_code = ls_st3-debitcreditcode
                                                                          tax_base_amount_in_trans_crcy = VALUE zamount( currency_code = ls_req-currencycode
                                                                                                                          content      = ls_st3-taxbaseamountintranscrcy ) ).

          APPEND ls_producttaxitem TO lt_producttaxitem.
          CLEAR:ls_producttaxitem.
        ENDLOOP.

        LOOP AT ls_req-creditoritems INTO DATA(ls_st4).
          DATA(ls_creditor) = VALUE zjournal_entry_create_reques16( creditor = ls_st4-creditor
                                                                 amount_in_transaction_currency = VALUE zamount( currency_code = ls_req-currencycode
                                                                                                                 content       = ls_st4-amountintransactioncurrency )
                                                                 reference_document_item = ls_st4-referencedocumentitem
                                                                 debit_credit_code = ls_st4-debitcreditcode
                                                                 document_item_text = ls_st4-documentitemtext
                                                                 assignment_reference = ls_st4-assignmentreference
                                                                  ).

          APPEND ls_creditor TO lt_creditor.
          CLEAR:ls_creditor.
        ENDLOOP.
        IF ls_req-reversalreferencedocument IS INITIAL.
          DATA(ls_req1) = VALUE zjournal_entry_create_reques18( company_code = ls_req-companycode
                                                                business_transaction_type = ls_req-businesstransactiontype
                                                                accounting_document_type = ls_req-accountingdocumenttype
                                                                created_by_user = ls_req-createdbyuser
                                                                document_date = ls_req-documentdate
                                                                posting_date  = ls_req-postingdate
                                                                original_reference_document_ty = ls_req-originalreferencedocumentty
                                                                tax_determination_date = ls_req-taxdeterminationdate
                                                                reference1in_document_header = ls_req-reference1indocumentheader
                                                                reference2in_document_header = ls_req-reference2indocumentheader
                                                                document_header_text = ls_req-documentheadertext
                                                                document_reference_id = ls_req-documentreferenceid
                                                                item = lt_item
                                                                debtor_item = lt_debtor
                                                                creditor_item = lt_creditor
                                                                product_tax_item = lt_producttaxitem
                                                                exchange_rate = ls_req-exchangerate
                                                                ).
        ELSE.
          ls_req1 = VALUE zjournal_entry_create_reques18( company_code = ls_req-companycode
                                                          business_transaction_type = ls_req-businesstransactiontype
                                                          original_reference_document_ty = ls_req-originalreferencedocumentty
                                                          created_by_user = ls_req-createdbyuser
                                                          reversal_reason = '01'
                                                          reversal_reference_document = |{ ls_req-reversalreferencedocument }{ ls_req-companycode }{ ls_req-documentdate(4) }|
                                                          ).

        ENDIF.

        DATA(ls_msg_head) = VALUE zbusiness_document_message_he2( creation_date_time = ls_req-creationdatetime ).

        DATA(ls_req2) = VALUE zjournal_entry_create_request( journal_entry = ls_req1
                                                             message_header = ls_msg_head ).

        APPEND ls_req2 TO lt_req.


        DATA(ls_req3) = VALUE zjournal_entry_create_reques19( journal_entry_create_request = lt_req
                                                              message_header = ls_msg_head ).

        " fill request
        DATA(request2) = VALUE zjournal_entry_bulk_create_req( journal_entry_bulk_create_requ = ls_req3 ).

        proxy->journal_entry_create_request_c(
          EXPORTING
            input = request2
          IMPORTING
            output = DATA(response2)
        ).

        " handle response
      CATCH cx_soap_destination_error INTO DATA(lo_error).
        " handle error
        es_response-response_code = 500.
        APPEND INITIAL LINE TO es_response-response_messages ASSIGNING FIELD-SYMBOL(<lfs_message>).
        <lfs_message>-message = 'Soap Destination Error'.
      CATCH cx_ai_system_fault INTO DATA(lt_data2).
        es_response-response_code = 500.
        APPEND INITIAL LINE TO es_response-response_messages ASSIGNING <lfs_message>.
        <lfs_message>-message = 'System Fault'.
        " handle error
    ENDTRY.

    LOOP AT response2-journal_entry_bulk_create_conf-journal_entry_create_confirmat INTO DATA(ls_confirmation).
      es_response-accounting_document = ls_confirmation-journal_entry_create_confirmat-accounting_document.

      IF es_response-accounting_document EQ '0000000000'.
        es_response-response_code = 500.
      ELSE.
        es_response-response_code = 200.
      ENDIF.

      LOOP AT ls_confirmation-log-item INTO DATA(ls_log).
        APPEND INITIAL LINE TO es_response-response_messages ASSIGNING <lfs_message>.
        <lfs_message>-message = ls_log-note.
      ENDLOOP.
    ENDLOOP.

    "Response BEG
    "respond with success payload
*    response->set_status( es_response-response_code ).
    response->set_status( 200 ).

    DATA(lv_json_string) = xco_cp_json=>data->from_abap( es_response )->apply( VALUE #(
  ( xco_cp_json=>transformation->underscore_to_pascal_case )
  ) )->to_string( ).

    response->set_text( lv_json_string ).
    response->set_header_field( i_name = lc_header_content
   i_value = lc_content_type ).
  ENDMETHOD.
ENDCLASS.
