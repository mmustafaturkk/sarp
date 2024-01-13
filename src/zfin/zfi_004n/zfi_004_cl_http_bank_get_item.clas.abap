CLASS zfi_004_cl_http_bank_get_item DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF name_mapping,
             abap TYPE abap_compname,
             json TYPE string,
           END OF name_mapping .
    TYPES: name_mappings TYPE HASHED TABLE OF name_mapping WITH UNIQUE KEY abap .

    INTERFACES if_http_service_extension .
    METHODS: json_name_mapping.

    DATA: gt_name_mapping TYPE name_mappings.
  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA: lv_error(1)       TYPE c,
          lv_text           TYPE string,
          lc_header_content TYPE string VALUE 'content-type',
          lc_content_type   TYPE string VALUE 'text/json',
          lt_response       TYPE TABLE OF zfi_004_s_bank_item,
          ls_request        TYPE zfi_004_s_bank_item,
          lt_table          TYPE TABLE OF zfi_004_t_bnk_it.
ENDCLASS.



CLASS ZFI_004_CL_HTTP_BANK_GET_ITEM IMPLEMENTATION.


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
            data          = ls_request.

      CATCH cx_root INTO DATA(lc_root).
        DATA(lv_message) = lc_root->get_longtext( ).
    ENDTRY.
*
*    lt_table = VALUE #( ( guid_tra = '5DED7812E2E51EDEA59FC3D2574832AB'
*                                               item_no  = '000001'
*                                               gl_account = '1000000000'
*                                               cost_center = 'DEPO'
*                                               tax = 'V1'
*                                               amount = 1000
*                                               bankaccountcurrency = 'TRY' )
*                        ( guid_tra = '5DED7812E2E51EDEA59FC3D2574832AB'
*                                               item_no  = '000002'
*                                               gl_account = '1000000001'
*                                               cost_center = 'DEPO'
*                                               tax = 'V1'
*                                               amount = 3000
*                                               bankaccountcurrency = 'TRY')  ).
*
*    INSERT zfi_004_t_bnk_it FROM TABLE @lt_table.
*    COMMIT WORK.

    SELECT
    guid_tra,
    item_no,
    gl_account,
    cost_center,
    profit_center,
    tax,
    special_gl_code,
    amount,
    bank_currency
    FROM zfi_004_t_bnk_it
    WHERE guid_tra EQ @ls_request-guid_tra
    INTO TABLE @lt_response.

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
*   i_value = lc_content_type ).
   i_value = 'application/json' ).

  ENDMETHOD.


  METHOD json_name_mapping.
    gt_name_mapping = VALUE #( ( abap = 'GUID_TRA'                json = 'guidTra'  ) ).


  ENDMETHOD.
ENDCLASS.
