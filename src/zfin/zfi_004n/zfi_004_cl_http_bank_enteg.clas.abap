CLASS zfi_004_cl_http_bank_enteg DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_service_extension .
  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA: lt_req            TYPE TABLE OF zfi_004_s_request,
          lv_error(1)       TYPE c,
          lv_text           TYPE string,
          ls_response       TYPE zfi_004_s_response,
          lc_header_content TYPE string VALUE 'content-type',
          lc_content_type   TYPE string VALUE 'text/json',
          lt_log            TYPE TABLE OF zfi_004_t_bnk_lg,
          lt_modify         TYPE TABLE OF zfi_004_t_bnk_lg.
ENDCLASS.



CLASS zfi_004_cl_http_bank_enteg IMPLEMENTATION.

  METHOD if_http_service_extension~handle_request.
    DATA: lv_tra_ids        TYPE string,
          lv_tra_ids_modify TYPE string.
    DATA(lv_req_body) = request->get_text( ).
    DATA(get_method) = request->get_method( ).

    TRY.
*        xco_cp_json=>data->from_string( lv_req_body )->apply( VALUE #(
*            ( xco_cp_json=>transformation->underscore_to_pascal_case )
*          ) )->write_to( REF #( ls_req ) ).
*         xco_cp_json=>data->from_string( lv_req_body )->write_to( REF #( ls_req ) ).

        DATA: lo_data    TYPE REF TO data.

        CALL METHOD /ui2/cl_json=>deserialize
          EXPORTING
            json         = lv_req_body
            pretty_name  = /ui2/cl_json=>pretty_mode-user_low_case
            assoc_arrays = abap_true
          CHANGING
            data         = lt_req.

      CATCH cx_root INTO DATA(lc_root).
        DATA(lv_message) = lc_root->get_longtext( ).
    ENDTRY.
    "deneme
    DATA(lo_generator) = cl_uuid_factory=>create_system_uuid(  ).

    SELECT log~* FROM zfi_004_t_bnk_lg AS log
    INNER JOIN @lt_req AS lt ON log~tra_id EQ lt~tra_id
    INTO TABLE @DATA(lt_banka).

    SORT lt_banka BY tra_id.

    LOOP AT lt_req INTO DATA(ls_req).
      READ TABLE lt_banka INTO DATA(ls_banka) WITH KEY tra_id = ls_req-tra_id BINARY SEARCH.
      IF sy-subrc EQ 0.
        IF ls_banka-document_no IS NOT INITIAL.
          IF lv_tra_ids IS INITIAL.
            lv_tra_ids = |{ ls_req-tra_id }|.
          ELSE.
            lv_tra_ids = lv_tra_ids && |,{ ls_req-tra_id }|.
          ENDIF.
          CONTINUE.
        ELSE.
          APPEND INITIAL LINE TO lt_modify ASSIGNING FIELD-SYMBOL(<lfs_modify>).
          <lfs_modify> = CORRESPONDING #( ls_req ).
          <lfs_modify>-guid_tra = ls_banka-guid_tra.
          <lfs_modify>-tra_accounting_date = |{ ls_req-tra_accounting_date(4) }{ ls_req-tra_accounting_date+5(2) }{ ls_req-tra_accounting_date+8(2) }|.
          <lfs_modify>-tra_accounting_time = |{ ls_req-tra_accounting_date+11(2) }{ ls_req-tra_accounting_date+14(2) }{ ls_req-tra_accounting_date+17(2) }|.
          GET TIME STAMP FIELD DATA(lv_date_time).
          <lfs_modify>-local_last_changed_at = lv_date_time.
          <lfs_modify>-local_last_changed_by = sy-uname.
          IF lv_tra_ids_modify IS INITIAL.
            lv_tra_ids_modify = |{ ls_req-tra_id }|.
          ELSE.
            lv_tra_ids_modify = lv_tra_ids_modify && |,{ ls_req-tra_id }|.
          ENDIF.
          CONTINUE.
        ENDIF.
      ENDIF.

      APPEND INITIAL LINE TO lt_log ASSIGNING FIELD-SYMBOL(<lfs_log>).

      <lfs_log> = CORRESPONDING #( ls_req ).
      TRY.
          <lfs_log>-guid_tra = lo_generator->create_uuid_x16( ).
        CATCH cx_uuid_error.
      ENDTRY.
      <lfs_log>-mandt = sy-mandt.
      <lfs_log>-tra_accounting_date = |{ ls_req-tra_accounting_date(4) }{ ls_req-tra_accounting_date+5(2) }{ ls_req-tra_accounting_date+8(2) }|.
      <lfs_log>-tra_accounting_time = |{ ls_req-tra_accounting_date+11(2) }{ ls_req-tra_accounting_date+14(2) }{ ls_req-tra_accounting_date+17(2) }|.
      GET TIME STAMP FIELD lv_date_time.
      <lfs_log>-local_created_at = lv_date_time.
      <lfs_log>-local_created_by = sy-uname.
    ENDLOOP.

    IF lt_log IS NOT INITIAL.
      TRY.
          INSERT zfi_004_t_bnk_lg FROM TABLE @lt_log.
          IF sy-subrc EQ 0.
            ls_response-response_code = 200.
            APPEND INITIAL LINE TO ls_response-response_messages ASSIGNING FIELD-SYMBOL(<lfs_message>).
            <lfs_message>-message = 'Kayıtlar log tablosuna başarılı bir şekilde kaydedildi.'.
            IF lv_tra_ids IS NOT INITIAL.
              APPEND INITIAL LINE TO ls_response-response_messages ASSIGNING <lfs_message>.
              <lfs_message>-message = 'İlgili tra_id değerleri tabloda bulunmaktadır ve muhasebeleştirilmiştir; ' && lv_tra_ids.
            ENDIF.
          ELSE.
            ls_response-response_code = 500.
            APPEND INITIAL LINE TO ls_response-response_messages ASSIGNING <lfs_message>.
            <lfs_message>-message = 'Kayıtlar log tablosuna kaydedilirken hata alındı.'.
          ENDIF.

        CATCH cx_root INTO DATA(lo_root).
          ls_response-response_code = 500.
          APPEND INITIAL LINE TO ls_response-response_messages ASSIGNING <lfs_message>.
          <lfs_message>-message = lo_root->get_longtext(  ).
      ENDTRY.
    ELSE.
      IF lv_tra_ids IS NOT INITIAL.
        ls_response-response_code = 500.
        APPEND INITIAL LINE TO ls_response-response_messages ASSIGNING <lfs_message>.
        <lfs_message>-message = 'İlgili tra_id değerleri tabloda bulunmaktadır ve muhasebeleştirilmiştir; ' && lv_tra_ids.
      ENDIF.
    ENDIF.

    IF lt_modify IS NOT INITIAL.
      TRY.
          MODIFY zfi_004_t_bnk_lg FROM TABLE @lt_modify.
          IF sy-subrc EQ 0.
            ls_response-response_code = 200.
            IF lv_tra_ids_modify IS NOT INITIAL.
              APPEND INITIAL LINE TO ls_response-response_messages ASSIGNING <lfs_message>.
              <lfs_message>-message = 'İlgili tra_id değerleri tabloda güncellenmiştir; ' && lv_tra_ids_modify.
            ENDIF.
          ELSE.
            ls_response-response_code = 500.
            APPEND INITIAL LINE TO ls_response-response_messages ASSIGNING <lfs_message>.
            <lfs_message>-message = 'Güncelleme işlemi yapılamadı.'.
          ENDIF.
        CATCH cx_root INTO lo_root.
          ls_response-response_code = 500.
          APPEND INITIAL LINE TO ls_response-response_messages ASSIGNING <lfs_message>.
          <lfs_message>-message = lo_root->get_longtext(  ).
      ENDTRY.
    ENDIF.

    response->set_status( 200 ).

    DATA(lv_json_string) = xco_cp_json=>data->from_abap( ls_response )->apply( VALUE #(
  ( xco_cp_json=>transformation->underscore_to_pascal_case )
  ) )->to_string( ).

    response->set_text( lv_json_string ).
    response->set_header_field( i_name = lc_header_content
   i_value = lc_content_type ).


  ENDMETHOD.
ENDCLASS.
