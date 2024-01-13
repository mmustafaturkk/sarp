CLASS zfi_004_cl_http_banka_je DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF name_mapping,
             abap TYPE abap_compname,
             json TYPE string,
           END OF name_mapping .
    TYPES: name_mappings  TYPE HASHED TABLE OF name_mapping WITH UNIQUE KEY abap,
           tt_bank_kokpit TYPE TABLE OF zfi_004_s_bank_kokpit,
           tt_response    TYPE TABLE OF zfi_000_s_response.

    INTERFACES if_http_service_extension .
    METHODS: json_name_mapping,
      create_accounting_doc IMPORTING it_request  TYPE tt_bank_kokpit
                                      io_proxy    TYPE REF TO zco_journal_entry_create_reque
                            EXPORTING et_response TYPE tt_response,
      create_transfer IMPORTING it_request  TYPE tt_bank_kokpit
                                io_proxy    TYPE REF TO zco_journal_entry_create_reque
                      EXPORTING et_response TYPE tt_response,
      create_arbitrage IMPORTING it_request  TYPE tt_bank_kokpit
                                 io_proxy    TYPE REF TO zco_journal_entry_create_reque
                       EXPORTING et_response TYPE tt_response,
      fill_structures IMPORTING is_request1 TYPE zfi_004_s_bank_kokpit
                                is_request2 TYPE zfi_004_s_bank_kokpit OPTIONAL
                                iv_tra_flg  TYPE abap_boolean OPTIONAL
                      EXPORTING es_request  TYPE zjournal_entry_bulk_create_req.

    DATA: gt_name_mapping   TYPE name_mappings,
          gt_taxcode        TYPE TABLE OF zfi_004_t_taxcod,
          gt_item           TYPE zjournal_entry_create_req_tab3,
          gt_debtor         TYPE zjournal_entry_create_req_tab4,
          gt_producttaxitem TYPE zjournal_entry_create_req_tab2,
          gt_req            TYPE zjournal_entry_create_requ_tab,
          gt_creditor       TYPE zjournal_entry_create_req_tab5,
          gt_response       TYPE TABLE OF zfi_000_s_response.
  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA: lv_error(1)       TYPE c,
          lv_text           TYPE string,
          lc_header_content TYPE string VALUE 'content-type',
          lc_content_type   TYPE string VALUE 'text/json',
*          lt_request        TYPE TABLE OF zfi_004_s_bank_kokpit.
          ls_type_req       TYPE zfi_004_s_bank_kokpit_type.


ENDCLASS.



CLASS zfi_004_cl_http_banka_je IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.
    DATA(lv_req_body) = request->get_text( ).
    DATA(get_method) = request->get_method( ).

    TRY.
*        xco_cp_json=>data->from_string( lv_req_body )->apply( VALUE #(
*            ( xco_cp_json=>transformation->underscore_to_pascal_case )
*          ) )->write_to( REF #( ls_req ) ).
*         xco_cp_json=>data->from_string( lv_req_body )->write_to( REF #( ls_req ) ).

        DATA: lo_data    TYPE REF TO data.

        json_name_mapping( ).

        CALL METHOD /ui2/cl_json=>deserialize
          EXPORTING
            json          = lv_req_body
            pretty_name   = /ui2/cl_json=>pretty_mode-user_low_case
            name_mappings = CORRESPONDING #( gt_name_mapping )
            assoc_arrays  = abap_true
          CHANGING
            data          = ls_type_req.

      CATCH cx_root INTO DATA(lc_root).
        DATA(lv_message) = lc_root->get_longtext( ).
    ENDTRY.

    TRY.
        DATA(destination) = cl_soap_destination_provider=>create_by_comm_arrangement(
        comm_scenario = 'ZFI_000_CS_JOURNAL_ENTRY'
        ).

        DATA(proxy) = NEW zco_journal_entry_create_reque( destination = destination ).

        CLEAR:gt_taxcode.
        SELECT * FROM zfi_004_t_taxcod INTO TABLE @gt_taxcode.
                                                       "#EC CI_NOWHERE.
        ""İşlem ayrımına göre method ayrımı yapılacak
        CASE ls_type_req-type.
          WHEN 'MUH'.
            create_accounting_doc(
            EXPORTING
              it_request  = ls_type_req-requests
              io_proxy    = proxy
            IMPORTING
              et_response = gt_response
          ).
          WHEN 'VIR'.
            create_transfer(
              EXPORTING
                it_request  = ls_type_req-requests
                io_proxy    = proxy
              IMPORTING
                et_response = gt_response
            ).
          WHEN 'ARB'.
            create_arbitrage(
              EXPORTING
                it_request  = ls_type_req-requests
                io_proxy    = proxy
              IMPORTING
                et_response = gt_response
            ).
        ENDCASE.


      CATCH cx_soap_destination_error INTO DATA(lo_error).
        " handle error
        APPEND INITIAL LINE TO gt_response ASSIGNING FIELD-SYMBOL(<lfs_response>).
        <lfs_response>-response_code = 500.
        APPEND INITIAL LINE TO <lfs_response>-response_messages ASSIGNING FIELD-SYMBOL(<lfs_message>).
        <lfs_message>-message = 'Soap Destination Error'.
        <lfs_message>-message_type = 'E'.
      CATCH cx_ai_system_fault INTO DATA(lt_data2).
        APPEND INITIAL LINE TO gt_response ASSIGNING <lfs_response>.
        <lfs_response>-response_code = 500.
        <lfs_message>-message_type = 'E'.
        APPEND INITIAL LINE TO <lfs_response>-response_messages ASSIGNING <lfs_message>.
        <lfs_message>-message = 'System Fault'.
        <lfs_message>-message_type = 'E'.
        " handle error
    ENDTRY.

*    DATA(lv_json_string) = xco_cp_json=>data->from_abap( lt_response )->apply( VALUE #(
*( xco_cp_json=>transformation->underscore_to_pascal_case )
*) )->to_string( ).

    TRY.
        CALL METHOD /ui2/cl_json=>serialize
          EXPORTING
            data         = gt_response
            pretty_name  = /ui2/cl_json=>pretty_mode-camel_case
            assoc_arrays = abap_true
          RECEIVING
            r_json       = DATA(lv_json_string).

      CATCH cx_root INTO lc_root.
        lv_message = lc_root->get_longtext( ).
    ENDTRY.

    response->set_text( lv_json_string ).
    response->set_header_field( i_name = lc_header_content
   i_value = lc_content_type ).
  ENDMETHOD.


  METHOD json_name_mapping.
    gt_name_mapping = VALUE #( ( abap = 'GUID_TRA'                json = 'guidTra'  )
                               ( abap = 'NUMBER_OF_TRA'           json = 'numberOfTra'  )
                               ( abap = 'COMPANY_CODE'            json = 'companyCode'  )
                               ( abap = 'ACC_IBAN'                json = 'accIban'  )
                               ( abap = 'TRA_ACCOUNTING_DATE'     json = 'traAccountingDate'  )
                               ( abap = 'HOUSEBANK'               json = 'housebank'  )
                               ( abap = 'HOUSEBANKACCOUNT'        json = 'housebankaccount'  )
                               ( abap = 'BANKACCOUNTINTERNALID'   json = 'bankaccountinternalid'  )
                               ( abap = 'BANKNAME'                json = 'bankname'  )
                               ( abap = 'BANKNUMBER'              json = 'banknumber'  )
                               ( abap = 'TRA_AMOUNT'              json = 'traAmount'  )
                               ( abap = 'BANKACCOUNTCURRENCY'     json = 'bankaccountcurrency'  )
                               ( abap = 'TRA_DESCRIPTION'         json = 'traDescription'  )
                               ( abap = 'TRA_TRANSACTION_TYPE'    json = 'traTransactionType'  )
                               ( abap = 'TRA_TYPE_NAME'           json = 'traTypeName'  )
                               ( abap = 'CUSTOMER'                json = 'customer'  )
                               ( abap = 'SUPPLIER'                json = 'supplier'  )
                               ( abap = 'BPFULLNAME'              json = 'bpfullname'  )
                               ( abap = 'VKN_TCKN'                json = 'vknTckn'  )
                               ( abap = 'TRA_OPPONENT_IBAN'       json = 'traOpponentIban'  )
                               ( abap = 'TRA_OPPONENT_TITLE'      json = 'traOpponentTitle'  )
                               ( abap = 'TRA_OPPONENT_TAXNO'      json = 'traOpponentTaxno'  )
                               ( abap = 'HOUSEBANK_2'             json = 'housebank2'  )
                               ( abap = 'HOUSEBANKACCOUNT_2'      json = 'housebankaccount2'  )
                               ( abap = 'BANKACCOUNTINTERNALID_2' json = 'bankaccountinternalid2'  )
                               ( abap = 'BANKNAME_2'              json = 'bankname2'  )
                               ( abap = 'BANKNUMBER_2'            json = 'banknumber2'  )
                               ( abap = 'COST_CENTER'             json = 'costCenter'  )
                               ( abap = 'PROFIT_CENTER'           json = 'profitCenter'  )
                               ( abap = 'TAX'                     json = 'tax'  )
                               ( abap = 'DOCUMENT_NO'             json = 'documentNo'  )
                               ( abap = 'SPECIAL_GL_CODE'         json = 'specialGlCode')
                               ( abap = 'EXCHANGE_RATE'           json = 'exchangeRate')
                               ( abap = 'ITEMS'                   json = 'items')
                               ( abap = 'ITEM_NO'                 json = 'itemNo')
                               ( abap = 'GL_ACCOUNT'              json = 'glAccount')
                               ( abap = 'AMOUNT'                  json = 'amount')
                               ( abap = 'BANK_CURRENCY'           json = 'bankCurrency')
                               ( abap = 'REQUESTS'                json = 'requests')
                               ( abap = 'TYPE'                    json = 'type')
                               ( abap = 'VOYAGE_INFO'             json = 'voyageInfo') ).


  ENDMETHOD.


  METHOD create_accounting_doc.
    DATA: lv_item_no     TYPE zfi_004_de_item_no,
          lv_cal_tax_amt TYPE zfi_004_de_tra_amount,
          lv_tax_amount  TYPE zfi_004_de_tra_amount.

    SELECT
      houseb~glaccount,
      houseb~housebank,
      houseb~housebankaccount
      FROM @it_request AS it
      LEFT JOIN zfi_004_dd_housebankaccountlin AS houseb ON houseb~glaccount EQ it~bankaccountinternalid_2
      INTO TABLE @DATA(lt_linkage).

    LOOP AT it_request INTO DATA(ls_req).
      CLEAR:gt_item, gt_debtor, gt_creditor, gt_producttaxitem.

      IF ls_req-document_no IS NOT INITIAL.
        APPEND INITIAL LINE TO gt_response ASSIGNING FIELD-SYMBOL(<lfs_response>).
        <lfs_response>-response_code = 500.
        APPEND INITIAL LINE TO <lfs_response>-response_messages ASSIGNING FIELD-SYMBOL(<lfs_message>).
        <lfs_message>-message      = |Muhasebe belge numarası { ls_req-document_no ALPHA = OUT } olan satır bir daha işlenemez.|.
        <lfs_message>-message_type = 'E'.
        CONTINUE.
      ENDIF.

      IF ls_req-accounted IS NOT INITIAL.
        APPEND INITIAL LINE TO gt_response ASSIGNING <lfs_response>.
        <lfs_response>-response_code = 500.
        APPEND INITIAL LINE TO <lfs_response>-response_messages ASSIGNING <lfs_message>.
        <lfs_message>-message      = |Dışarıdan muhasebeleşen satır işlenemez.|.
        <lfs_message>-message_type = 'E'.
        CONTINUE.
      ENDIF.

      DATA(ls_item) = VALUE zjournal_entry_create_request9( reference_document_item = '0000000001'
                                                            glaccount = VALUE zchart_of_accounts_item_code( content = ls_req-bankaccountinternalid )
                                                            amount_in_transaction_currency = VALUE zamount( currency_code = ls_req-bankaccountcurrency
                                                                                                            content       = ls_req-tra_amount )
                                                            debit_credit_code = COND #( WHEN ls_req-tra_amount < 0 THEN 'H'
                                                                                        ELSE 'S' )
*                                                                tax = VALUE zjournal_entry_create_request2( tax_code = VALUE zproduct_taxation_characteris1( content = ls_req-tax ) )
                                                            document_item_text = ls_req-tra_description
                                                            account_assignment = VALUE zjournal_entry_create_request8( profit_center = ls_req-profit_center
                                                                                                                       cost_center = ls_req-cost_center )
                                                            house_bank = ls_req-housebank
                                                            house_bank_account = ls_req-housebankaccount

                                                                                                                       "Netlik yok segment = ls_st-accountassignment-segment
                                                                                                                      "Netlik yok functional_area = ls_st-accountassignment-functionalarea )
                                                            "Netlik yok profitability_supplement = VALUE zjournal_entry_create_request6( customer = ls_st-profitabilitysupplement-customer )
                                                             ).

      APPEND ls_item TO gt_item.
      CLEAR ls_item.

      IF ls_req-items IS INITIAL.
        IF ls_req-tax IS NOT INITIAL.
          READ TABLE gt_taxcode INTO DATA(ls_taxcode) WITH KEY tax_code = ls_req-tax.
          IF sy-subrc EQ 0.
            lv_tax_amount = ls_req-tra_amount / ( 1 + ( ls_taxcode-percent / 100 ) ).
            lv_cal_tax_amt = ls_req-tra_amount - lv_tax_amount.
            DATA(ls_producttaxitem) = VALUE zjournal_entry_create_request3( tax_code = VALUE zproduct_taxation_characteris1( content = ls_req-tax )
                                                        reference_document_item = '0000000002'
                                                        tax_item_classification = ls_taxcode-tax_type
                                                        condition_type = ls_taxcode-move_type
                                                        amount_in_transaction_currency = VALUE zamount( currency_code = ls_req-bankaccountcurrency
                                                                                                        content       = lv_cal_tax_amt )
                                                        debit_credit_code = ls_taxcode-debit_credit
                                                        tax_base_amount_in_trans_crcy = VALUE zamount( currency_code = ls_req-bankaccountcurrency
                                                                                                       content       = lv_tax_amount ) ).

            APPEND ls_producttaxitem TO gt_producttaxitem.
            CLEAR:ls_producttaxitem.
          ENDIF.
        ELSE.

          lv_tax_amount = ls_req-tra_amount.

        ENDIF.

        IF ls_req-customer IS NOT INITIAL AND ls_req-supplier IS NOT INITIAL.
          APPEND INITIAL LINE TO gt_response ASSIGNING <lfs_response>.
          <lfs_response>-response_code = 500.
          APPEND INITIAL LINE TO <lfs_response>-response_messages ASSIGNING <lfs_message>.
          <lfs_message>-message      = 'Satıcı ve müşteri aynı anda dolu olmamalıdır.'.
          <lfs_message>-message_type = 'E'.
          CONTINUE.
        ELSEIF ls_req-customer IS NOT INITIAL.
          DATA(ls_debtor) = VALUE zjournal_entry_create_reques13( debtor = ls_req-customer
                                                                 amount_in_transaction_currency = VALUE zamount( currency_code = ls_req-bankaccountcurrency
                                                                                                                 content       = ( -1 * lv_tax_amount ) )
                                                                 reference_document_item = '0000000002'
                                                                 debit_credit_code = COND #( WHEN ( -1 * lv_tax_amount ) < 0 THEN 'H'
                                                                                             ELSE 'S' )
                                                                 document_item_text = ls_req-tra_description
                                                                 down_payment_terms = VALUE zjournal_entry_create_reques11( special_glcode = ls_req-special_gl_code
                                                                                                                            tax_code = VALUE zproduct_taxation_characteris1( content = ls_req-tax ) ) ).

          APPEND ls_debtor TO gt_debtor.
          CLEAR:ls_debtor.
        ELSEIF ls_req-supplier IS NOT INITIAL.
          DATA(ls_creditor) = VALUE zjournal_entry_create_reques16( creditor = ls_req-supplier
                                                                 amount_in_transaction_currency = VALUE zamount( currency_code = ls_req-bankaccountcurrency
                                                                                                                 content       = ( -1 * lv_tax_amount ) )
                                                                 reference_document_item = '0000000002'
                                                                 debit_credit_code = COND #( WHEN ( -1 * lv_tax_amount ) < 0 THEN 'H'
                                                                                             ELSE 'S' )
                                                                 document_item_text = ls_req-tra_description
                                                                 down_payment_terms = VALUE zjournal_entry_create_reques10( special_glcode = ls_req-special_gl_code
                                                                                                                            tax_code = VALUE zproduct_taxation_characteris1( content = ls_req-tax ) ) ).

          APPEND ls_creditor TO gt_creditor.
          CLEAR:ls_creditor.
        ELSEIF ls_req-bankaccountinternalid_2 IS NOT INITIAL.
*          IF ls_req-bankaccountinternalid_2(3) EQ '102'.
*            APPEND INITIAL LINE TO gt_response ASSIGNING <lfs_response>.
*            <lfs_response>-response_code = 500.
*            APPEND INITIAL LINE TO <lfs_response>-response_messages ASSIGNING <lfs_message>.
*            <lfs_message>-message      = 'Karşıt hesap 102 ile başlayamaz. Lütfen arbitraj veya virman butonunu kullanınız'.
*            <lfs_message>-message_type = 'E'.
*            CONTINUE.
*          ELSE.

          IF ls_req-bankaccountinternalid_2(3) EQ '102'.

            READ TABLE lt_linkage INTO DATA(ls_linkage) WITH KEY glaccount = ls_req-bankaccountinternalid_2.
            IF sy-subrc EQ 0.
              DATA(lv_house_bank)         = ls_linkage-housebank.
              DATA(lv_house_bank_account) = ls_linkage-housebankaccount.
            ENDIF.
          ENDIF.
          APPEND VALUE zjournal_entry_create_request9( glaccount = VALUE zchart_of_accounts_item_code( content = ls_req-bankaccountinternalid_2 )
                                                       amount_in_transaction_currency = VALUE zamount( currency_code = ls_req-bankaccountcurrency
                                                                                                       content       = ( -1 * lv_tax_amount ) )
                                                       reference_document_item = '0000000002'
                                                       debit_credit_code = COND #( WHEN ( -1 * lv_tax_amount ) < 0 THEN 'H'
                                                                                               ELSE 'S' )
                                                       document_item_text = ls_req-tra_description
                                                       account_assignment = VALUE zjournal_entry_create_request8( profit_center = ls_req-profit_center
                                                                                                                         cost_center = ls_req-cost_center )
                                                       tax = VALUE zjournal_entry_create_request2( tax_code = VALUE zproduct_taxation_characteris1( content = ls_req-tax ) )
                                                       house_bank = COND #( WHEN lv_house_bank IS NOT INITIAL THEN lv_house_bank )
                                                       house_bank_account = COND #( WHEN lv_house_bank_account IS NOT INITIAL THEN lv_house_bank_account ) ) TO gt_item.
*          ENDIF.
        ELSE.
          APPEND INITIAL LINE TO gt_response ASSIGNING <lfs_response>.
          <lfs_response>-response_code = 500.
          APPEND INITIAL LINE TO <lfs_response>-response_messages ASSIGNING <lfs_message>.
          <lfs_message>-message      = 'Satıcı, müşteri veya karşıt hesap boşsa kayıt atılamaz.'.
          <lfs_message>-message_type = 'E'.
          CONTINUE.
        ENDIF.


      ELSE.

        DATA(lv_total) = REDUCE #( INIT x = 0 FOR wa IN ls_req-items NEXT x = wa-amount + x ).
        IF abs( lv_total ) NE abs( ls_req-tra_amount ).
          APPEND INITIAL LINE TO gt_response ASSIGNING <lfs_response>.
          <lfs_response>-response_code = 500.
          APPEND INITIAL LINE TO <lfs_response>-response_messages ASSIGNING <lfs_message>.
          <lfs_message>-message      = 'Kalem toplamları ana toplama eşit olmak zorundadır.'.
          <lfs_message>-message_type = 'E'.
          CONTINUE.
        ENDIF.

        CLEAR:lv_item_no.
        LOOP AT ls_req-items INTO DATA(ls_item_inner).
          lv_item_no = ls_item_inner-item_no + 1.
          IF ls_item_inner-tax IS NOT INITIAL.
            READ TABLE gt_taxcode INTO ls_taxcode WITH KEY tax_code = ls_item_inner-tax.
            IF sy-subrc EQ 0.
              CLEAR:lv_tax_amount.
              lv_tax_amount = ls_item_inner-amount / ( 1 + ( ls_taxcode-percent / 100 ) ).
              lv_cal_tax_amt = ls_item_inner-amount - lv_tax_amount.
              ls_producttaxitem = VALUE zjournal_entry_create_request3( tax_code = VALUE zproduct_taxation_characteris1( content = ls_item_inner-tax )
                                                                        tax_item_classification = ls_taxcode-tax_type
                                                                        condition_type = ls_taxcode-move_type
                                                                        reference_document_item = |{ lv_item_no ALPHA = IN }|
                                                                        amount_in_transaction_currency = VALUE zamount( currency_code = ls_item_inner-bank_currency
                                                                                                                        content       = lv_cal_tax_amt )
                                                                        debit_credit_code = ls_taxcode-debit_credit
                                                                        tax_base_amount_in_trans_crcy = VALUE zamount( currency_code = ls_item_inner-bank_currency
                                                                                                                       content       = lv_tax_amount ) ).

              APPEND ls_producttaxitem TO gt_producttaxitem.
              CLEAR:ls_producttaxitem.
            ENDIF.
          ELSE.

            lv_tax_amount = ls_item_inner-amount.

          ENDIF.
          ls_item = VALUE zjournal_entry_create_request9( reference_document_item = |{ lv_item_no ALPHA = IN }|
                                                          glaccount = VALUE zchart_of_accounts_item_code( content = ls_item_inner-gl_account )
                                                          amount_in_transaction_currency = VALUE zamount( currency_code = ls_item_inner-bank_currency
                                                                                                          content       = lv_tax_amount )
                                                          debit_credit_code = COND #( WHEN lv_tax_amount < 0 THEN 'H'
                                                                                      ELSE 'S' )
                                                          account_assignment = VALUE zjournal_entry_create_request8( profit_center = ls_item_inner-profit_center
                                                                                                                     cost_center = ls_item_inner-cost_center )
                                                          tax = VALUE zjournal_entry_create_request2( tax_code = VALUE zproduct_taxation_characteris1( content = ls_item_inner-tax ) )

                                                                                                                           "Netlik yok segment = ls_st-accountassignment-segment
                                                                                                                          "Netlik yok functional_area = ls_st-accountassignment-functionalarea )
                                                                "Netlik yok profitability_supplement = VALUE zjournal_entry_create_request6( customer = ls_st-profitabilitysupplement-customer )
                                                                 ).

          APPEND ls_item TO gt_item.
          CLEAR ls_item.
        ENDLOOP.

      ENDIF.

      DATA(ls_req1) = VALUE zjournal_entry_create_reques18( original_reference_document_ty = 'BKPFF'
                                                            business_transaction_type      = 'RFBU'
                                                            accounting_document_type = COND #( WHEN ls_req-customer IS NOT INITIAL THEN 'DZ'
                                                                                               WHEN ls_req-supplier IS NOT INITIAL THEN 'KZ'
                                                                                               ELSE 'SA')
                                                            company_code = ls_req-company_code
                                                            created_by_user = sy-uname
                                                            tax_determination_date = ls_req-tra_accounting_date
                                                            document_date = ls_req-tra_accounting_date
                                                            posting_date  = ls_req-tra_accounting_date
                                                          "Açık konu  tax_determination_date = ls_req-taxdeterminationdate
                                                            item = gt_item
                                                            debtor_item = gt_debtor
                                                            creditor_item = gt_creditor
                                                            product_tax_item = gt_producttaxitem
                                                            document_header_text = ls_req-number_of_tra
                                                            exchange_rate = ls_req-exchange_rate
                                                            reference1in_document_header = ls_req-voyage_info
                                                            ).

      GET TIME STAMP FIELD DATA(lv_date_time).
      DATA(ls_msg_head) = VALUE zbusiness_document_message_he2( creation_date_time = lv_date_time ).

      DATA(ls_req2) = VALUE zjournal_entry_create_request( journal_entry = ls_req1
                                                           message_header = ls_msg_head ).

      APPEND ls_req2 TO gt_req.


      DATA(ls_req3) = VALUE zjournal_entry_create_reques19( journal_entry_create_request = gt_req
                                                            message_header = ls_msg_head ).

      " fill request
      DATA(request2) = VALUE zjournal_entry_bulk_create_req( journal_entry_bulk_create_requ = ls_req3 ).

      TRY.
          io_proxy->journal_entry_create_request_c(
            EXPORTING
              input = request2
            IMPORTING
              output = DATA(response2)
          ).
        CATCH cx_ai_system_fault INTO DATA(lt_data2).
          APPEND INITIAL LINE TO gt_response ASSIGNING <lfs_response>.
          <lfs_response>-response_code = 500.
          <lfs_message>-message_type = 'E'.
      ENDTRY.
      " handle response

      APPEND INITIAL LINE TO gt_response ASSIGNING <lfs_response>.
      LOOP AT response2-journal_entry_bulk_create_conf-journal_entry_create_confirmat INTO DATA(ls_confirmation).
        <lfs_response>-accounting_document = ls_confirmation-journal_entry_create_confirmat-accounting_document.

        IF <lfs_response>-accounting_document EQ '0000000000'.
          <lfs_response>-response_code = 500.
        ELSE.
          <lfs_response>-response_code = 200.

          UPDATE zfi_004_t_bnk_lg SET document_no              = @<lfs_response>-accounting_document,
                                      tra_description_edit     = @ls_req-tra_description,
                                      tra_accounting_date_edit = @ls_req-tra_accounting_date,
                                      tra_opponent_taxno_edit  = @ls_req-tra_opponent_taxno,
                                      supplier_edit            = @ls_req-supplier,
                                      customer_edit            = @ls_req-customer,
                                      voyage_info              = @ls_req-voyage_info,
                                      local_last_changed_by    = @sy-uname,
                                      local_last_changed_at    = @lv_date_time
                                  WHERE guid_tra               = @ls_req-guid_tra.
          IF sy-subrc EQ 0.
            COMMIT WORK.
          ENDIF.

          IF ls_req-items IS NOT INITIAL.
            DATA lt_bnk_it TYPE TABLE OF zfi_004_t_bnk_it.
            lt_bnk_it = CORRESPONDING #( ls_req-items ).
            MODIFY zfi_004_t_bnk_it FROM TABLE @lt_bnk_it.
          ENDIF.
        ENDIF.

        LOOP AT ls_confirmation-log-item INTO DATA(ls_log).
          APPEND INITIAL LINE TO <lfs_response>-response_messages ASSIGNING <lfs_message>.
          <lfs_message>-message = ls_log-note.
          CASE <lfs_response>-response_code.
            WHEN 500.
              <lfs_message>-message_type = 'E'.
            WHEN 200.
              <lfs_message>-message_type = 'S'.
          ENDCASE.
        ENDLOOP.
      ENDLOOP.

      CLEAR: response2, request2, ls_req3, ls_req2, gt_req, ls_msg_head, ls_req1.
    ENDLOOP.
  ENDMETHOD.


  METHOD create_arbitrage.

    DATA(lv_line) = lines( it_request ).
    IF lv_line NE 2.
      APPEND INITIAL LINE TO gt_response ASSIGNING FIELD-SYMBOL(<lfs_response>).
      <lfs_response>-response_code = 500.
      APPEND INITIAL LINE TO <lfs_response>-response_messages ASSIGNING FIELD-SYMBOL(<lfs_message>).
      <lfs_message>-message      = 'Arbitraj işlemi için lütfen 2 satır seçiniz.'.
      <lfs_message>-message_type = 'E'.
      EXIT.
    ENDIF.

    READ TABLE it_request INTO DATA(ls_request1) INDEX 1.
    READ TABLE it_request INTO DATA(ls_request2) INDEX 2.
    IF ( ls_request1-bankaccountinternalid NE ls_request2-bankaccountinternalid )
    AND ( abs( ls_request1-tra_amount ) NE abs( ls_request2-tra_amount ) )
    AND ( ls_request1-bankaccountcurrency NE ls_request2-bankaccountcurrency ).

      fill_structures(
          EXPORTING
            is_request1 = ls_request1
            is_request2 = ls_request2
          IMPORTING
            es_request = DATA(ls_pro_req)
        ).
      TRY.
          io_proxy->journal_entry_create_request_c(
            EXPORTING
              input = ls_pro_req
            IMPORTING
              output = DATA(response2)
          ).
        CATCH cx_ai_system_fault INTO DATA(lt_data2).
          APPEND INITIAL LINE TO gt_response ASSIGNING <lfs_response>.
          <lfs_response>-response_code = 500.
          <lfs_message>-message_type = 'E'.
      ENDTRY.

      GET TIME STAMP FIELD DATA(lv_date_time).

      APPEND INITIAL LINE TO gt_response ASSIGNING <lfs_response>.
      LOOP AT response2-journal_entry_bulk_create_conf-journal_entry_create_confirmat INTO DATA(ls_confirmation).
        <lfs_response>-accounting_document = ls_confirmation-journal_entry_create_confirmat-accounting_document.

        IF <lfs_response>-accounting_document EQ '0000000000'.
          <lfs_response>-response_code = 500.
        ELSE.
          <lfs_response>-response_code = 200.

          UPDATE zfi_004_t_bnk_lg SET document_no              = @<lfs_response>-accounting_document,
                                      tra_description_edit     = @ls_request1-tra_description,
                                      tra_accounting_date_edit = @ls_request1-tra_accounting_date,
                                      tra_opponent_taxno_edit  = @ls_request1-tra_opponent_taxno,
                                      supplier_edit            = @ls_request1-supplier,
                                      customer_edit            = @ls_request1-customer,
                                      voyage_info              = @ls_request1-voyage_info,
                                      local_last_changed_by    = @sy-uname,
                                      local_last_changed_at    = @lv_date_time
                                  WHERE guid_tra               = @ls_request1-guid_tra.
          IF sy-subrc EQ 0.
            COMMIT WORK.
          ENDIF.
          DATA(lv_flag) = 'X'.
        ENDIF.

        LOOP AT ls_confirmation-log-item INTO DATA(ls_log).
          APPEND INITIAL LINE TO <lfs_response>-response_messages ASSIGNING <lfs_message>.
          <lfs_message>-message = ls_log-note.
          CASE <lfs_response>-response_code.
            WHEN 500.
              <lfs_message>-message_type = 'E'.
            WHEN 200.
              <lfs_message>-message_type = 'S'.
          ENDCASE.
        ENDLOOP.
      ENDLOOP.

      IF lv_flag EQ 'X'.
        CLEAR: ls_pro_req,gt_item,gt_producttaxitem,gt_req.
        fill_structures(
            EXPORTING
              is_request1 = ls_request2
              is_request2 = ls_request1
              iv_tra_flg  = lv_flag
            IMPORTING
              es_request = ls_pro_req
          ).

        CLEAR:response2.
        TRY.
            io_proxy->journal_entry_create_request_c(
              EXPORTING
                input = ls_pro_req
              IMPORTING
                output = response2
            ).
          CATCH cx_ai_system_fault INTO lt_data2.
            APPEND INITIAL LINE TO gt_response ASSIGNING <lfs_response>.
            <lfs_response>-response_code = 500.
            <lfs_message>-message_type = 'E'.
        ENDTRY.

        CLEAR: lv_date_time.
        GET TIME STAMP FIELD lv_date_time.

        APPEND INITIAL LINE TO gt_response ASSIGNING <lfs_response>.
        LOOP AT response2-journal_entry_bulk_create_conf-journal_entry_create_confirmat INTO ls_confirmation.
          <lfs_response>-accounting_document = ls_confirmation-journal_entry_create_confirmat-accounting_document.

          IF <lfs_response>-accounting_document EQ '0000000000'.
            <lfs_response>-response_code = 500.
          ELSE.
            <lfs_response>-response_code = 200.

            UPDATE zfi_004_t_bnk_lg SET document_no              = @<lfs_response>-accounting_document,
                                        tra_description_edit     = @ls_request2-tra_description,
                                        tra_accounting_date_edit = @ls_request2-tra_accounting_date,
                                        tra_opponent_taxno_edit  = @ls_request2-tra_opponent_taxno,
                                        supplier_edit            = @ls_request2-supplier,
                                        customer_edit            = @ls_request2-customer,
                                        voyage_info              = @ls_request2-voyage_info,
                                        local_last_changed_by    = @sy-uname,
                                        local_last_changed_at    = @lv_date_time
                                    WHERE guid_tra               = @ls_request2-guid_tra.
            IF sy-subrc EQ 0.
              COMMIT WORK.
            ENDIF.
          ENDIF.

          LOOP AT ls_confirmation-log-item INTO ls_log.
            APPEND INITIAL LINE TO <lfs_response>-response_messages ASSIGNING <lfs_message>.
            <lfs_message>-message = ls_log-note.
            CASE <lfs_response>-response_code.
              WHEN 500.
                <lfs_message>-message_type = 'E'.
              WHEN 200.
                <lfs_message>-message_type = 'S'.
            ENDCASE.
          ENDLOOP.
        ENDLOOP.

      ENDIF.

    ELSE.
      APPEND INITIAL LINE TO gt_response ASSIGNING <lfs_response>.
      <lfs_response>-response_code = 500.
      APPEND INITIAL LINE TO <lfs_response>-response_messages ASSIGNING <lfs_message>.
      <lfs_message>-message      = 'Seçilen 2 kayıt arbitraj işlemi için uygun değildir.'.
      <lfs_message>-message_type = 'E'.
      EXIT.
    ENDIF.

  ENDMETHOD.


  METHOD create_transfer.

    DATA(lv_line) = lines( it_request ).
    IF lv_line NE 2.
      APPEND INITIAL LINE TO gt_response ASSIGNING FIELD-SYMBOL(<lfs_response>).
      <lfs_response>-response_code = 500.
      APPEND INITIAL LINE TO <lfs_response>-response_messages ASSIGNING FIELD-SYMBOL(<lfs_message>).
      <lfs_message>-message      = 'Virman işlemi için lütfen 2 satır seçiniz.'.
      <lfs_message>-message_type = 'E'.
      EXIT.
    ENDIF.

    READ TABLE it_request INTO DATA(ls_request1) INDEX 1.
    READ TABLE it_request INTO DATA(ls_request2) INDEX 2.
    IF ( ls_request1-tra_amount + ls_request2-tra_amount EQ 0 )
    AND ( ls_request1-bankaccountinternalid EQ ls_request2-bankaccountinternalid_2 )
    AND ( ls_request1-bankaccountinternalid_2 EQ ls_request2-bankaccountinternalid )
    AND ( ls_request1-company_code EQ ls_request2-company_code ).
      fill_structures(
        EXPORTING
          is_request1 = ls_request1
        IMPORTING
          es_request = DATA(ls_pro_req)
      ).
      TRY.
          io_proxy->journal_entry_create_request_c(
            EXPORTING
              input = ls_pro_req
            IMPORTING
              output = DATA(response2)
          ).
        CATCH cx_ai_system_fault INTO DATA(lt_data2).
          APPEND INITIAL LINE TO gt_response ASSIGNING <lfs_response>.
          <lfs_response>-response_code = 500.
          <lfs_message>-message_type = 'E'.
      ENDTRY.
      " handle response

      GET TIME STAMP FIELD DATA(lv_date_time).

      APPEND INITIAL LINE TO gt_response ASSIGNING <lfs_response>.
      LOOP AT response2-journal_entry_bulk_create_conf-journal_entry_create_confirmat INTO DATA(ls_confirmation).
        <lfs_response>-accounting_document = ls_confirmation-journal_entry_create_confirmat-accounting_document.

        IF <lfs_response>-accounting_document EQ '0000000000'.
          <lfs_response>-response_code = 500.
        ELSE.
          <lfs_response>-response_code = 200.

          UPDATE zfi_004_t_bnk_lg SET document_no              = @<lfs_response>-accounting_document,
                                      tra_description_edit     = @ls_request1-tra_description,
                                      tra_accounting_date_edit = @ls_request1-tra_accounting_date,
                                      tra_opponent_taxno_edit  = @ls_request1-tra_opponent_taxno,
                                      supplier_edit            = @ls_request1-supplier,
                                      customer_edit            = @ls_request1-customer,
                                      voyage_info              = @ls_request1-voyage_info,
                                      local_last_changed_by    = @sy-uname,
                                      local_last_changed_at    = @lv_date_time
                                  WHERE guid_tra               = @ls_request1-guid_tra.

          UPDATE zfi_004_t_bnk_lg SET document_no              = @<lfs_response>-accounting_document,
                                      tra_description_edit     = @ls_request2-tra_description,
                                      tra_accounting_date_edit = @ls_request2-tra_accounting_date,
                                      tra_opponent_taxno_edit  = @ls_request2-tra_opponent_taxno,
                                      supplier_edit            = @ls_request2-supplier,
                                      customer_edit            = @ls_request2-customer,
                                      voyage_info              = @ls_request2-voyage_info,
                                      local_last_changed_by    = @sy-uname,
                                      local_last_changed_at    = @lv_date_time
                                  WHERE guid_tra               = @ls_request2-guid_tra.
          IF sy-subrc EQ 0.
            COMMIT WORK.
          ENDIF.
*          DATA(lv_flag) = 'X'.
        ENDIF.

        LOOP AT ls_confirmation-log-item INTO DATA(ls_log).
          APPEND INITIAL LINE TO <lfs_response>-response_messages ASSIGNING <lfs_message>.
          <lfs_message>-message = ls_log-note.
          CASE <lfs_response>-response_code.
            WHEN 500.
              <lfs_message>-message_type = 'E'.
            WHEN 200.
              <lfs_message>-message_type = 'S'.
          ENDCASE.
        ENDLOOP.
      ENDLOOP.

*      IF lv_flag EQ 'X'.
*        CLEAR: ls_pro_req,gt_item,gt_producttaxitem,gt_req.
*        fill_structures(
*            EXPORTING
*              is_request = ls_request2
*            IMPORTING
*              es_request = ls_pro_req
*          ).
*
*        CLEAR:response2.
*        TRY.
*            io_proxy->journal_entry_create_request_c(
*              EXPORTING
*                input = ls_pro_req
*              IMPORTING
*                output = response2
*            ).
*          CATCH cx_ai_system_fault INTO lt_data2.
*            APPEND INITIAL LINE TO gt_response ASSIGNING <lfs_response>.
*            <lfs_response>-response_code = 500.
*            <lfs_message>-message_type = 'E'.
*        ENDTRY.
*
*        CLEAR: lv_date_time.
*        GET TIME STAMP FIELD lv_date_time.
*
*        APPEND INITIAL LINE TO gt_response ASSIGNING <lfs_response>.
*        LOOP AT response2-journal_entry_bulk_create_conf-journal_entry_create_confirmat INTO ls_confirmation.
*          <lfs_response>-accounting_document = ls_confirmation-journal_entry_create_confirmat-accounting_document.
*
*          IF <lfs_response>-accounting_document EQ '0000000000'.
*            <lfs_response>-response_code = 500.
*          ELSE.
*            <lfs_response>-response_code = 200.
*
*            UPDATE zfi_004_t_bnk_lg SET document_no              = @<lfs_response>-accounting_document,
*                                        tra_description_edit     = @ls_request2-tra_description,
*                                        tra_accounting_date_edit = @ls_request2-tra_accounting_date,
*                                        tra_opponent_taxno_edit  = @ls_request2-tra_opponent_taxno,
*                                        supplier_edit            = @ls_request2-supplier,
*                                        customer_edit            = @ls_request2-customer,
*                                        local_last_changed_by    = @sy-uname,
*                                        local_last_changed_at    = @lv_date_time
*                                    WHERE guid_tra               = @ls_request2-guid_tra.
*            IF sy-subrc EQ 0.
*              COMMIT WORK.
*            ENDIF.
*          ENDIF.
*
*          LOOP AT ls_confirmation-log-item INTO ls_log.
*            APPEND INITIAL LINE TO <lfs_response>-response_messages ASSIGNING <lfs_message>.
*            <lfs_message>-message = ls_log-note.
*            CASE <lfs_response>-response_code.
*              WHEN 500.
*                <lfs_message>-message_type = 'E'.
*              WHEN 200.
*                <lfs_message>-message_type = 'S'.
*            ENDCASE.
*          ENDLOOP.
*        ENDLOOP.
*
*      ENDIF.

    ELSE.
      APPEND INITIAL LINE TO gt_response ASSIGNING <lfs_response>.
      <lfs_response>-response_code = 500.
      APPEND INITIAL LINE TO <lfs_response>-response_messages ASSIGNING <lfs_message>.
      <lfs_message>-message      = 'Seçilen 2 kayıt virman işlemi için uygun değildir.'.
      <lfs_message>-message_type = 'E'.
      EXIT.
    ENDIF.

  ENDMETHOD.


  METHOD fill_structures.
    IF is_request1-bankaccountinternalid_2 IS NOT INITIAL.
      SELECT SINGLE
      housebank,
      housebankaccount
      FROM zfi_004_dd_housebankaccountlin
      WHERE glaccount EQ @is_request1-bankaccountinternalid_2
      INTO @DATA(ls_linkage).
    ENDIF.

    DATA: lv_cal_tax_amt TYPE zfi_004_de_tra_amount,
          lv_tax_amount  TYPE zfi_004_de_tra_amount.

    DATA(ls_item) = VALUE zjournal_entry_create_request9( reference_document_item = '0000000001'
                                                          glaccount = VALUE zchart_of_accounts_item_code( content = is_request1-bankaccountinternalid )
                                                          amount_in_transaction_currency = VALUE zamount( currency_code = is_request1-bankaccountcurrency
                                                                                                          content       = is_request1-tra_amount )
                                                          amount_in_company_code_currenc = VALUE zamount( currency_code = COND #( WHEN is_request2 IS NOT INITIAL AND is_request2-bankaccountcurrency EQ 'TRY' THEN is_request2-bankaccountcurrency )
                                                                                                          content       = COND #( WHEN is_request2 IS NOT INITIAL AND is_request2-bankaccountcurrency EQ 'TRY' THEN
                                                                                                                          COND #( WHEN is_request1-tra_amount < 0 AND is_request2-tra_amount < 0 THEN is_request2-tra_amount
                                                                                                                                  WHEN is_request1-tra_amount < 0 AND is_request2-tra_amount > 0 THEN ( -1 ) * is_request2-tra_amount
                                                                                                                                  WHEN is_request1-tra_amount > 0 AND is_request2-tra_amount > 0 THEN is_request2-tra_amount
                                                                                                                                  WHEN is_request1-tra_amount > 0 AND is_request2-tra_amount < 0 THEN ( -1 ) * is_request2-tra_amount ) ) )
                                                          amount_in_free_defined_currenc = VALUE zamount( currency_code = COND #( WHEN is_request2 IS NOT INITIAL
                                                                                                                          AND ( is_request2-bankaccountcurrency NE 'TRY' AND is_request2-bankaccountcurrency NE 'EUR' )
                                                                                                                          THEN is_request2-bankaccountcurrency )
                                                                                                          content       = COND #( WHEN is_request2 IS NOT INITIAL
                                                                                                                          AND ( is_request2-bankaccountcurrency NE 'TRY' AND is_request2-bankaccountcurrency NE 'EUR' ) THEN
                                                                                                                          COND #( WHEN is_request1-tra_amount < 0 AND is_request2-tra_amount < 0 THEN is_request2-tra_amount
                                                                                                                                  WHEN is_request1-tra_amount < 0 AND is_request2-tra_amount > 0 THEN ( -1 ) * is_request2-tra_amount
                                                                                                                                  WHEN is_request1-tra_amount > 0 AND is_request2-tra_amount > 0 THEN is_request2-tra_amount
                                                                                                                                  WHEN is_request1-tra_amount > 0 AND is_request2-tra_amount < 0 THEN ( -1 ) * is_request2-tra_amount ) ) )
                                                          amount_in_group_currency = VALUE zamount( currency_code = COND #( WHEN is_request2 IS NOT INITIAL
                                                                                                                          AND is_request2-bankaccountcurrency EQ 'EUR'
                                                                                                                          THEN is_request2-bankaccountcurrency )
                                                                                                          content       = COND #( WHEN is_request2 IS NOT INITIAL
                                                                                                                          AND is_request2-bankaccountcurrency EQ 'EUR' THEN
                                                                                                                          COND #( WHEN is_request1-tra_amount < 0 AND is_request2-tra_amount < 0 THEN is_request2-tra_amount
                                                                                                                                  WHEN is_request1-tra_amount < 0 AND is_request2-tra_amount > 0 THEN ( -1 ) * is_request2-tra_amount
                                                                                                                                  WHEN is_request1-tra_amount > 0 AND is_request2-tra_amount > 0 THEN is_request2-tra_amount
                                                                                                                                  WHEN is_request1-tra_amount > 0 AND is_request2-tra_amount < 0 THEN ( -1 ) * is_request2-tra_amount ) ) )
                                                          debit_credit_code = COND #( WHEN is_request1-tra_amount < 0 THEN 'H'
                                                                                          ELSE 'S' )
*                                                                tax = VALUE zjournal_entry_create_request2( tax_code = VALUE zproduct_taxation_characteris1( content = ls_req-tax ) )
                                                              document_item_text = is_request1-tra_description
                                                              account_assignment = VALUE zjournal_entry_create_request8( profit_center = is_request1-profit_center
                                                                                                                         cost_center = is_request1-cost_center )
                                                              house_bank = is_request1-housebank
                                                              house_bank_account = is_request1-housebankaccount

                                                                                                                         "Netlik yok segment = ls_st-accountassignment-segment
                                                                                                                        "Netlik yok functional_area = ls_st-accountassignment-functionalarea )
                                                              "Netlik yok profitability_supplement = VALUE zjournal_entry_create_request6( customer = ls_st-profitabilitysupplement-customer )
                                                               ).

    APPEND ls_item TO gt_item.
    CLEAR ls_item.

    IF is_request1-tax IS NOT INITIAL.
      READ TABLE gt_taxcode INTO DATA(ls_taxcode) WITH KEY tax_code = is_request1-tax.
      IF sy-subrc EQ 0.
        lv_tax_amount =  is_request1-tra_amount / ( 1 + ( ls_taxcode-percent / 100 ) ).
        lv_cal_tax_amt = is_request1-tra_amount - lv_tax_amount.
        DATA(ls_producttaxitem) = VALUE zjournal_entry_create_request3( tax_code = VALUE zproduct_taxation_characteris1( content = is_request1-tax )
                                                    reference_document_item = '0000000002'
                                                    tax_item_classification = ls_taxcode-tax_type
                                                    condition_type = ls_taxcode-move_type
                                                    amount_in_transaction_currency = VALUE zamount( currency_code = is_request1-bankaccountcurrency
                                                                                                    content       = lv_cal_tax_amt )
                                                    debit_credit_code = ls_taxcode-debit_credit
                                                    tax_base_amount_in_trans_crcy = VALUE zamount( currency_code = is_request1-bankaccountcurrency
                                                                                                   content       = lv_tax_amount ) ).

        APPEND ls_producttaxitem TO gt_producttaxitem.
        CLEAR:ls_producttaxitem.
      ENDIF.
    ELSE.

      lv_tax_amount = is_request1-tra_amount.

    ENDIF.

    APPEND VALUE zjournal_entry_create_request9( glaccount = VALUE zchart_of_accounts_item_code( content = COND #( WHEN is_request2 IS NOT INITIAL THEN '8990002001'
                                                                                                                   ELSE is_request1-bankaccountinternalid_2 ) )
                                                 amount_in_transaction_currency = VALUE zamount( currency_code = is_request1-bankaccountcurrency
                                                                                                 content       = ( -1 * lv_tax_amount ) )
                                                 amount_in_company_code_currenc = VALUE zamount( currency_code = COND #( WHEN is_request2 IS NOT INITIAL AND is_request2-bankaccountcurrency EQ 'TRY' THEN is_request2-bankaccountcurrency )
                                                                                                 content       = COND #( WHEN is_request2 IS NOT INITIAL AND is_request2-bankaccountcurrency EQ 'TRY' THEN
                                                                                                                 COND #( WHEN lv_tax_amount < 0 AND is_request2-tra_amount < 0 THEN ( -1 ) * is_request2-tra_amount
                                                                                                                         WHEN lv_tax_amount < 0 AND is_request2-tra_amount > 0 THEN is_request2-tra_amount
                                                                                                                         WHEN lv_tax_amount > 0 AND is_request2-tra_amount > 0 THEN ( -1 ) * is_request2-tra_amount
                                                                                                                         WHEN lv_tax_amount > 0 AND is_request2-tra_amount < 0 THEN is_request2-tra_amount ) ) )
                                                 amount_in_free_defined_currenc =  VALUE zamount( currency_code = COND #( WHEN is_request2 IS NOT INITIAL
                                                                                                                  AND ( is_request2-bankaccountcurrency NE 'TRY' AND is_request2-bankaccountcurrency NE 'EUR' )
                                                                                                                  THEN is_request2-bankaccountcurrency )
                                                                                                  content       = COND #( WHEN is_request2 IS NOT INITIAL
                                                                                                                  AND ( is_request2-bankaccountcurrency NE 'TRY' AND is_request2-bankaccountcurrency NE 'EUR' ) THEN
                                                                                                                  COND #( WHEN lv_tax_amount < 0 AND is_request2-tra_amount < 0 THEN ( -1 ) * is_request2-tra_amount
                                                                                                                          WHEN lv_tax_amount < 0 AND is_request2-tra_amount > 0 THEN is_request2-tra_amount
                                                                                                                          WHEN lv_tax_amount > 0 AND is_request2-tra_amount > 0 THEN ( -1 ) * is_request2-tra_amount
                                                                                                                          WHEN lv_tax_amount > 0 AND is_request2-tra_amount < 0 THEN is_request2-tra_amount ) ) )
                                                 amount_in_group_currency = VALUE zamount( currency_code = COND #( WHEN is_request2 IS NOT INITIAL AND is_request2-bankaccountcurrency EQ 'EUR' THEN is_request2-bankaccountcurrency )
                                                                                                 content       = COND #( WHEN is_request2 IS NOT INITIAL AND is_request2-bankaccountcurrency EQ 'EUR' THEN
                                                                                                                 COND #( WHEN lv_tax_amount < 0 AND is_request2-tra_amount < 0 THEN ( -1 ) * is_request2-tra_amount
                                                                                                                         WHEN lv_tax_amount < 0 AND is_request2-tra_amount > 0 THEN is_request2-tra_amount
                                                                                                                         WHEN lv_tax_amount > 0 AND is_request2-tra_amount > 0 THEN ( -1 ) * is_request2-tra_amount
                                                                                                                         WHEN lv_tax_amount > 0 AND is_request2-tra_amount < 0 THEN is_request2-tra_amount ) ) )
                                                 reference_document_item = '0000000002'
                                                 debit_credit_code = COND #( WHEN ( -1 * lv_tax_amount ) < 0 THEN 'H'
                                                                                         ELSE 'S' )
                                                 document_item_text = is_request1-tra_description
                                                 account_assignment = VALUE zjournal_entry_create_request8( profit_center = is_request1-profit_center
                                                                                                            cost_center = is_request1-cost_center )
                                                 tax = VALUE zjournal_entry_create_request2( tax_code = VALUE zproduct_taxation_characteris1( content = is_request1-tax ) )
                                                 house_bank = COND #( WHEN is_request1-housebank_2 IS INITIAL THEN ls_linkage-housebank
                                                                      ELSE is_request1-housebank_2 )
                                                 house_bank_account = COND #( WHEN is_request1-housebankaccount_2 IS INITIAL THEN ls_linkage-housebankaccount
                                                                              ELSE is_request1-housebankaccount_2 ) ) TO gt_item.

    DATA(ls_req1) = VALUE zjournal_entry_create_reques18( original_reference_document_ty = 'BKPFF'
                                                            business_transaction_type      = 'RFBU'
                                                            accounting_document_type = COND #( WHEN is_request1-customer IS NOT INITIAL THEN 'DZ'
                                                                                               WHEN is_request1-supplier IS NOT INITIAL THEN 'KZ'
                                                                                               ELSE 'SA')
                                                            company_code = is_request1-company_code
                                                            created_by_user = sy-uname
                                                            tax_determination_date = is_request1-tra_accounting_date
                                                            document_date = is_request1-tra_accounting_date
                                                            posting_date  = is_request1-tra_accounting_date
                                                          "Açık konu  tax_determination_date = ls_req-taxdeterminationdate
                                                            item = gt_item
                                                            debtor_item = gt_debtor
                                                            creditor_item = gt_creditor
                                                            product_tax_item = gt_producttaxitem
                                                            document_header_text = is_request1-number_of_tra
                                                            exchange_rate = is_request1-exchange_rate
                                                            reference1in_document_header = is_request1-voyage_info
                                                            ).

    GET TIME STAMP FIELD DATA(lv_date_time).
    DATA(ls_msg_head) = VALUE zbusiness_document_message_he2( creation_date_time = lv_date_time ).

    DATA(ls_req2) = VALUE zjournal_entry_create_request( journal_entry = ls_req1
                                                         message_header = ls_msg_head ).

    APPEND ls_req2 TO gt_req.


    DATA(ls_req3) = VALUE zjournal_entry_create_reques19( journal_entry_create_request = gt_req
                                                          message_header = ls_msg_head ).

    " fill request
    es_request = VALUE zjournal_entry_bulk_create_req( journal_entry_bulk_create_requ = ls_req3 ).
  ENDMETHOD.
ENDCLASS.
