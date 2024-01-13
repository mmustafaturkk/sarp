CLASS zcl_fi_002_http_bank DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_service_extension .
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA: ls_req            TYPE zfi_002_s_header,
          lv_error(1)       TYPE c,
          lv_text           TYPE string,
          es_response       TYPE zfi_000_s_response,
          lc_header_content TYPE string VALUE 'content-type',
          lc_content_type   TYPE string VALUE 'text/json'.
ENDCLASS.



CLASS ZCL_FI_002_HTTP_BANK IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.
    DATA(lv_req_body) = request->get_text( ).
    DATA(get_method) = request->get_method( ).

    "first deserialize the request
    TRY.
        xco_cp_json=>data->from_string( lv_req_body )->apply( VALUE #(
            ( xco_cp_json=>transformation->pascal_case_to_underscore )
          ) )->write_to( REF #( ls_req ) ).
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

        DATA: lt_item         TYPE zjournal_entry_create_req_tab3,
              lt_debtor       TYPE zjournal_entry_create_req_tab4,
              lt_creditor     TYPE zjournal_entry_create_req_tab5,
              lt_tax          TYPe zjournal_entry_create_req_tab2,
              lt_withhold_tax TYPE zjournal_entry_create_req_tab1,
              lt_req          TYPE zjournal_entry_create_requ_tab.

        CASE ls_req-requesttype.
          WHEN 'MUS_TAH'.
            LOOP AT ls_req-items INTO DATA(ls_st).
              DATA(ls_item) = VALUE ZJOURNAL_ENTRY_CREATE_REQUEST9(  glaccount = VALUE zchart_of_accounts_item_code( content = ls_st-glaccount )
                                                                    amount_in_transaction_currency = VALUE zamount( currency_code = 'TRY'
                                                                                                                    content       = ls_st-amountintransactioncurrency )
                                                                    house_bank = ls_st-housebank
                                                                    house_bank_account = ls_st-housebankaccount
                                                                    debit_credit_code = ls_st-debitcreditcode
                                                                     ).

              APPEND ls_item TO lt_item.
              CLEAR ls_item.
            ENDLOOP.

            LOOP AT ls_req-debtoritems INTO DATA(ls_st2).
              DATA(ls_debtor) = VALUE ZJOURNAL_ENTRY_CREATE_REQUES13( debtor = ls_st2-debtor
                                                                     amount_in_transaction_currency = VALUE zamount( currency_code = 'TRY'
                                                                                                                     content       = ls_st2-amountintransactioncurrency )
                                                                     reference_document_item = ls_st2-referencedocumentitem
                                                                     debit_credit_code = ls_st2-debitcreditcode
                                                                     document_item_text = ls_st2-documentitemtext
                                                                      ).

              APPEND ls_debtor TO lt_debtor.
              CLEAR:ls_debtor.
            ENDLOOP.

*        DATA(ls_creditor) = VALUE zjournal_entry_create_reques43( creditor = '0036300001'
*                                                                  amount_in_transaction_currency = VALUE zamount2( currency_code = 'TRY'
*                                                                                                                   content       = 1000 )
*                                                                  reference_document_item = 'TEST'
*                                                                   ).
*
*
*        APPEND ls_creditor TO lt_creditor.

*        DATA(ls_tax) = VALUE zjournal_entry_create_reques56( tax_code = VALUE zproduct_taxation_characteris4( content = 'A1' )
*                                                             amount_in_transaction_currency = VALUE zamount2( currency_code = 'TRY'
*                                                                                                              content       = 1000 )
*                                                             tax_base_amount_in_trans_crcy = VALUE zamount2( currency_code = 'TRY'
*                                                                                                              content       = 10 )
*                                                             reference_document_item = 'TEST' ).
*
*        APPEND ls_tax TO lt_tax.
**                                                                     ).
*        DATA(ls_withold_tax) = VALUE zjournal_entry_create_reques58( withholding_tax_code = 'A1'
*                                                                     withholding_tax_type = 'A1'
*                                                                     reference_document_item = 'TEST'
*                                                                     tax_base_amount_in_trans_crcy = VALUE zamount2( currency_code = 'TRY'
**                                                                                                                     content       = ls_data-taxbaseamountisnetamount
*                                                                                                                      content      = 10 )
*                                                                     ).
*
*        APPEND ls_withold_tax TO lt_withhold_tax.

            DATA(ls_req1) = VALUE zjournal_entry_create_reques18( company_code = ls_req-companycode
                                                                  business_transaction_type = ls_req-businesstransactiontype
                                                                  accounting_document_type = ls_req-accountingdocumenttype
                                                                  created_by_user = ls_req-createdbyuser
                                                                  document_date = ls_req-documentdate
                                                                  posting_date  = ls_req-postingdate
                                                                  original_reference_document_ty = ls_req-originalreferencedocumentty
                                                                  item = lt_item
                                                                  debtor_item = lt_debtor
                                                                  ).
          WHEN 'BANK_VIR'.
            CLEAR:ls_st.
            LOOP AT ls_req-items INTO ls_st.
              ls_item = VALUE ZJOURNAL_ENTRY_CREATE_REQUEST9(  glaccount = VALUE zchart_of_accounts_item_code( content = ls_st-glaccount )
                                                                    amount_in_transaction_currency = VALUE zamount( currency_code = 'TRY'
                                                                                                                    content       = ls_st-amountintransactioncurrency )
                                                                    house_bank = ls_st-housebank
                                                                    house_bank_account = ls_st-housebankaccount
                                                                    debit_credit_code = ls_st-debitcreditcode
                                                                     ).

              APPEND ls_item TO lt_item.
              CLEAR ls_item.
            ENDLOOP.

            ls_req1 = VALUE zjournal_entry_create_reques18( company_code = ls_req-companycode
                                                                  business_transaction_type = ls_req-businesstransactiontype
                                                                  accounting_document_type = ls_req-accountingdocumenttype
                                                                  created_by_user = ls_req-createdbyuser
                                                                  document_date = ls_req-documentdate
                                                                  posting_date  = ls_req-postingdate
                                                                  original_reference_document_ty = ls_req-originalreferencedocumentty
                                                                  item = lt_item
                                                                  ).

          WHEN 'SAT_ODE'.
            CLEAR:ls_st.
            LOOP AT ls_req-items INTO ls_st.
              ls_item = VALUE ZJOURNAL_ENTRY_CREATE_REQUEST9(  glaccount = VALUE zchart_of_accounts_item_code( content = ls_st-glaccount )
                                                                    amount_in_transaction_currency = VALUE zamount( currency_code = 'TRY'
                                                                                                                    content       = ls_st-amountintransactioncurrency )
                                                                    house_bank = ls_st-housebank
                                                                    house_bank_account = ls_st-housebankaccount
                                                                    debit_credit_code = ls_st-debitcreditcode
                                                                     ).

              APPEND ls_item TO lt_item.
              CLEAR ls_item.
            ENDLOOP.

            LOOP AT ls_req-creditoritems INTO DATA(ls_st3).
              DATA(ls_creditor) = VALUE ZJOURNAL_ENTRY_CREATE_REQUES16( creditor = ls_st3-creditor
                                                                     amount_in_transaction_currency = VALUE zamount( currency_code = 'TRY'
                                                                                                                     content       = ls_st3-amountintransactioncurrency )
                                                                     reference_document_item = ls_st3-referencedocumentitem
                                                                     debit_credit_code = ls_st3-debitcreditcode
                                                                     document_item_text = ls_st3-documentitemtext
                                                                      ).

              APPEND ls_creditor TO lt_creditor.
              CLEAR:ls_creditor.
            ENDLOOP.

            ls_req1 = VALUE zjournal_entry_create_reques18( company_code = ls_req-companycode
                                                                  business_transaction_type = ls_req-businesstransactiontype
                                                                  accounting_document_type = ls_req-accountingdocumenttype
                                                                  created_by_user = ls_req-createdbyuser
                                                                  document_date = ls_req-documentdate
                                                                  posting_date  = ls_req-postingdate
                                                                  original_reference_document_ty = ls_req-originalreferencedocumentty
                                                                  item = lt_item
                                                                  creditor_item = lt_creditor
                                                                  ).

        ENDCASE.



        DATA(ls_msg_head) = VALUE zbusiness_document_message_he2( creation_date_time = ls_req-creationdatetime ).

        DATA(ls_req2) = VALUE ZJOURNAL_ENTRY_CREATE_REQUEST( journal_entry = ls_req1
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
    response->set_status( es_response-response_code ).

    DATA(lv_json_string) = xco_cp_json=>data->from_abap( es_response )->apply( VALUE #(
  ( xco_cp_json=>transformation->underscore_to_pascal_case )
  ) )->to_string( ).

    response->set_text( lv_json_string ).
    response->set_header_field( i_name = lc_header_content
   i_value = lc_content_type ).

  ENDMETHOD.
ENDCLASS.
