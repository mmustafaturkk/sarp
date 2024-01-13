CLASS zfi_cl_004_http_bank_reversal DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_service_extension .
    METHODS: json_name_mapping.
  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA: lv_error(1)       TYPE c,
          lv_text           TYPE string,
          lt_response       TYPE TABLE OF zfi_000_s_response,
          lc_header_content TYPE string VALUE 'content-type',
          lc_content_type   TYPE string VALUE 'text/json',
          lt_request        TYPE TABLE OF zfi_004_s_bank_reversal.

    TYPES: BEGIN OF name_mapping,
             abap TYPE abap_compname,
             json TYPE string,
           END OF name_mapping .
    TYPES: name_mappings TYPE HASHED TABLE OF name_mapping WITH UNIQUE KEY abap .

    DATA: gt_name_mapping TYPE name_mappings.
ENDCLASS.



CLASS ZFI_CL_004_HTTP_BANK_REVERSAL IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.
    DATA: lt_req TYPE zjournal_entry_create_requ_tab.

    DATA(lv_req_body) = request->get_text( ).
    DATA(get_method) = request->get_method( ).

    TRY.
        DATA: lo_data    TYPE REF TO data.

        json_name_mapping( ).

        CALL METHOD /ui2/cl_json=>deserialize
          EXPORTING
            json          = lv_req_body
            pretty_name   = /ui2/cl_json=>pretty_mode-user_low_case
            name_mappings = CORRESPONDING #( gt_name_mapping )
            assoc_arrays  = abap_true
          CHANGING
            data          = lt_request.

      CATCH cx_root INTO DATA(lc_root).
        DATA(lv_message) = lc_root->get_longtext( ).
    ENDTRY.

    TRY.
        DATA(destination) = cl_soap_destination_provider=>create_by_comm_arrangement(
        comm_scenario = 'ZFI_000_CS_JOURNAL_ENTRY'
        ).

        DATA(proxy) = NEW zco_journal_entry_create_reque( destination = destination ).

        LOOP AT lt_request INTO DATA(ls_req).
          IF ls_req-accounting_document IS INITIAL.
            APPEND INITIAL LINE TO lt_response ASSIGNING FIELD-SYMBOL(<lfs_response>).
            <lfs_response>-response_code = 500.
            APPEND INITIAL LINE TO <lfs_response>-response_messages ASSIGNING FIELD-SYMBOL(<lfs_message>).
            <lfs_message>-message = 'Muhasebe belgesi oluşturulmadan ters kayıt işlemi yapılamamaktadır.'.
            <lfs_message>-message_type = 'E'.
            CONTINUE.
          ENDIF.
          DATA(ls_req1) = VALUE zjournal_entry_create_reques18( original_reference_document_ty = 'BKPFF'
                                                                business_transaction_type = 'RFBU'
                                                                reversal_reason = '01'
                                                                reversal_reference_document = |{ ls_req-accounting_document }{ ls_req-company_code }{ ls_req-accounting_date(4) }|
                                                                company_code = ls_req-company_code
                                                                created_by_user = sy-uname
                                                                ).

          GET TIME STAMP FIELD DATA(lv_date_time).
          DATA(ls_msg_head) = VALUE zbusiness_document_message_he2( creation_date_time = lv_date_time ).

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

          APPEND INITIAL LINE TO lt_response ASSIGNING <lfs_response>.
          LOOP AT response2-journal_entry_bulk_create_conf-journal_entry_create_confirmat INTO DATA(ls_confirmation).
            <lfs_response>-accounting_document = ls_confirmation-journal_entry_create_confirmat-accounting_document.

            IF <lfs_response>-accounting_document EQ '0000000000'.
              <lfs_response>-response_code = 500.
            ELSE.
              <lfs_response>-response_code = 200.

              UPDATE zfi_004_t_bnk_lg SET document_no              = @space,
                                          tra_description_edit     = @ls_req-tra_description,
                                          tra_accounting_date_edit = @ls_req-accounting_date,
                                          tra_opponent_taxno_edit  = @ls_req-tra_opponent_taxno,
                                          supplier_edit            = @ls_req-supplier,
                                          customer_edit            = @ls_req-customer,
                                          local_last_changed_by    = @sy-uname,
                                          local_last_changed_at    = @lv_date_time
                                      WHERE guid_tra               = @ls_req-guid_tra.
              IF sy-subrc EQ 0.
                COMMIT WORK.
              ENDIF.

              DELETE FROM zfi_004_t_bnk_lg WHERE guid_tra = @ls_req-guid_tra.
              IF sy-subrc EQ 0.
                COMMIT WORK.
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

          CLEAR: response2, request2, ls_req3, ls_req2, lt_req, ls_msg_head, ls_req1.
        ENDLOOP.

      CATCH cx_soap_destination_error INTO DATA(lo_error).
        " handle error
        APPEND INITIAL LINE TO lt_response ASSIGNING <lfs_response>.
        <lfs_response>-response_code = 500.
        APPEND INITIAL LINE TO <lfs_response>-response_messages ASSIGNING <lfs_message>.
        <lfs_message>-message = 'Soap Destination Error'.
        <lfs_message>-message_type = 'E'.
      CATCH cx_ai_system_fault INTO DATA(lt_data2).
        APPEND INITIAL LINE TO lt_response ASSIGNING <lfs_response>.
        <lfs_response>-response_code = 500.
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
            data         = lt_response
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
    gt_name_mapping = VALUE #( ( abap = 'GUID_TRA'            json = 'guidTra' )
                               ( abap = 'ACCOUNTING_DOCUMENT' json = 'documentNo'  )
                               ( abap = 'COMPANY_CODE'        json = 'companyCode'  )
                               ( abap = 'ACCOUNTING_DATE'     json = 'traAccountingDate' )
                               ( abap = 'CUSTOMER'            json = 'customer'  )
                               ( abap = 'SUPPLIER'            json = 'supplier'  )
                               ( abap = 'TRA_OPPONENT_TAXNO'  json = 'traOpponentTaxno'  )
                               ( abap = 'TRA_DESCRIPTION'     json = 'traDescription'  ) ).
  ENDMETHOD.
ENDCLASS.
