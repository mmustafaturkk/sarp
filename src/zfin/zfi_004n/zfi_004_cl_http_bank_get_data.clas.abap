CLASS zfi_004_cl_http_bank_get_data DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_service_extension .
    METHODS: json_name_mapping.
  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA: lc_header_content TYPE string VALUE 'content-type',
          lc_content_type   TYPE string VALUE 'text/json'.

    TYPES: BEGIN OF name_mapping,
             abap TYPE abap_compname,
             json TYPE string,
           END OF name_mapping .
    TYPES: name_mappings TYPE HASHED TABLE OF name_mapping WITH UNIQUE KEY abap .

    DATA: gt_name_mapping TYPE name_mappings.
ENDCLASS.

CLASS zfi_004_cl_http_bank_get_data IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.

*    DELETE FROM zfi_004_t_bnk_lg .
    DATA: ls_request TYPE zfi_004_s_bank_filters.

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

    DATA: lr_bankaccountcurrency   TYPE RANGE OF zfi_004_s_bank_filters-bankaccountcurrency,
          lr_bankaccountcurrency_e TYPE RANGE OF zfi_004_s_bank_filters-bankaccountcurrency,
          lr_company_code          TYPE RANGE OF zfi_004_s_bank_filters-companycode,
          lr_customer              TYPE RANGE OF zfi_004_s_bank_filters-customer,
          lr_customer_e            TYPE RANGE OF zfi_004_s_bank_filters-customer,
          lr_supplier              TYPE RANGE OF zfi_004_s_bank_filters-supplier,
          lr_supplier_e            TYPE RANGE OF zfi_004_s_bank_filters-supplier,
          lr_tra_vkn_tckn          TYPE RANGE OF zfi_004_s_bank_filters-vkn_tckn,
          lr_tra_accounting_date   TYPE RANGE OF zfi_004_s_bank_filters-tra_accounting_date_from,
          lr_document_no           TYPE RANGE OF zfi_004_s_bank_filters-document_no,
          lr_bpfullname_e          TYPE RANGE OF zfi_004_s_bank_filters-bpfullname,
          lr_bank_name_e           TYPE RANGE OF zfi_004_s_bank_filters-bank_name.

    IF ls_request-bankaccountcurrency IS NOT INITIAL.
      lr_bankaccountcurrency   = VALUE #( BASE lr_bankaccountcurrency ( sign = 'I' option = 'EQ' low = ls_request-bankaccountcurrency  ) ).
      lr_bankaccountcurrency_e = VALUE #( BASE lr_bankaccountcurrency_e ( sign = 'E' option = 'EQ' low = ls_request-bankaccountcurrency  ) ).
    ENDIF.

    IF ls_request-companycode IS NOT INITIAL.
      lr_company_code = VALUE #( BASE lr_company_code ( sign = 'I' option = 'EQ' low = ls_request-companycode  ) ).
    ENDIF.

    DATA:lv_numc10 TYPE zfi_004_de_numc10.
    lv_numc10 = ls_request-customer.
*    CONDENSE: lv_Data2 NO-GAPS.
*    lv_Data2 = | { lv_Data2 ALPHA = IN  } |.
*    CONDENSE: lv_Data2 NO-GAPS.

    IF ls_request-customer IS NOT INITIAL.
      lr_customer   = VALUE #( BASE lr_customer ( sign = 'I' option = 'EQ' low = lv_numc10  ) ).
      lr_customer_e = VALUE #( BASE lr_customer_e ( sign = 'E' option = 'EQ' low = lv_numc10  ) ).
    ENDIF.
    CLEAR:lv_numc10.
    lv_numc10 = ls_request-supplier.
*    CONDENSE: ls_request-supplier NO-GAPS.
*    ls_request-supplier = | { ls_request-supplier ALPHA = IN  } |.
*    CONDENSE: ls_request-supplier NO-GAPS.

    IF ls_request-supplier IS NOT INITIAL.
      lr_supplier   = VALUE #( BASE lr_supplier ( sign = 'I' option = 'EQ' low = lv_numc10 ) ).
      lr_supplier_e = VALUE #( BASE lr_supplier_e ( sign = 'E' option = 'EQ' low = lv_numc10  ) ).
    ENDIF.

    IF ls_request-vkn_tckn IS NOT INITIAL.
      lr_tra_vkn_tckn = VALUE #( BASE lr_tra_vkn_tckn ( sign = 'I' option = 'EQ' low = ls_request-vkn_tckn  ) ).
    ENDIF.

    IF ls_request-tra_accounting_date_from IS NOT INITIAL AND ls_request-tra_accounting_date_to IS NOT INITIAL.
      lr_tra_accounting_date = VALUE #( BASE lr_tra_accounting_date
                                      ( sign = 'I' option = 'BT' low  = ls_request-tra_accounting_date_from
                                                                 high = ls_request-tra_accounting_date_to  ) ).
    ELSEIF ls_request-tra_accounting_date_from IS NOT INITIAL OR ls_request-tra_accounting_date_to IS NOT INITIAL.

      lr_tra_accounting_date = VALUE #( BASE lr_tra_accounting_date
                                      ( sign = 'I' option = 'EQ' low  = COND #( WHEN ls_request-tra_accounting_date_from IS NOT INITIAL
                                                                                THEN ls_request-tra_accounting_date_from
                                                                                ELSE ls_request-tra_accounting_date_to ) ) ).
    ENDIF.

    IF ls_request-document_no IS NOT INITIAL.
      lr_document_no = VALUE #( BASE lr_document_no ( sign = 'I' option = 'EQ' low = ls_request-document_no ) ).
    ENDIF.

    IF ls_request-bpfullname IS NOT INITIAL.
      lr_bpfullname_e = VALUE #( BASE lr_bpfullname_e ( sign = 'E' option = 'CP' low = |*{ ls_request-bpfullname }*| ) ).
    ENDIF.

    IF ls_request-bank_name IS NOT INITIAL.
      lr_bank_name_e = VALUE #( BASE lr_bank_name_e ( sign = 'E' option = 'EQ' low = ls_request-bank_name ) ).
    ENDIF.
    DATA: lt_bank_data TYPE TABLE OF  zfi_004_s_bank_kokpit.
*    I_HouseBankAccountLinkage

*    lr_tra_accounting_date = VALUE #( BASE lr_tra_accounting_date
*                                          ( sign = 'I' option = 'GE' low  = '20240101'  ) ).

    IF ls_request-document_no_filled IS INITIAL.
      "Log tablosundan veri çekilir
      SELECT guid_tra,
             number_of_tra,
             company_code,
             acc_iban,
             tra_amount,
             CASE WHEN tra_description_edit IS NOT INITIAL AND tra_description_edit IS NOT NULL THEN tra_description_edit
                  ELSE tra_description END AS tra_description,
             tra_transaction_type,
             tra_type_name,
             CASE WHEN tra_opponent_taxno_edit IS NOT INITIAL AND tra_opponent_taxno_edit IS NOT NULL THEN tra_opponent_taxno_edit
                  ELSE tra_opponent_taxno END AS vkn_tckn,
             tra_opponent_iban,
             CASE WHEN tra_accounting_date_edit IS NOT INITIAL AND tra_accounting_date_edit IS NOT NULL THEN tra_accounting_date_edit
                  ELSE tra_accounting_date END AS tra_accounting_date,
             customer_edit,
             supplier_edit,
             tra_opponent_title,
             tra_opponent_taxno,
             tra_vms_transaction_type,
             tra_mt940transaction_type,
             document_no,
             voyage_info
      FROM zfi_004_t_bnk_lg
      WHERE company_code        IN @lr_company_code
        AND tra_opponent_taxno  IN @lr_tra_vkn_tckn
        AND tra_accounting_date IN @lr_tra_accounting_date
        AND document_no         IN @lr_document_no
        AND tra_accounting_date GE '20240101'
      INTO TABLE @DATA(lt_bank_log).
    ELSE.
      SELECT guid_tra,
             number_of_tra,
             company_code,
             acc_iban,
             tra_amount,
             CASE WHEN tra_description_edit IS NOT INITIAL AND tra_description_edit IS NOT NULL THEN tra_description_edit
                  ELSE tra_description END AS tra_description,
             tra_transaction_type,
             tra_type_name,
             CASE WHEN tra_opponent_taxno_edit IS NOT INITIAL AND tra_opponent_taxno_edit IS NOT NULL THEN tra_opponent_taxno_edit
                  ELSE tra_opponent_taxno END AS vkn_tckn,
             tra_opponent_iban,
             CASE WHEN tra_accounting_date_edit IS NOT INITIAL AND tra_accounting_date_edit IS NOT NULL THEN tra_accounting_date_edit
                  ELSE tra_accounting_date END AS tra_accounting_date,
             customer_edit,
             supplier_edit,
             tra_opponent_title,
             tra_opponent_taxno,
             tra_vms_transaction_type,
             tra_mt940transaction_type,
             document_no,
             voyage_info
      FROM zfi_004_t_bnk_lg
      WHERE company_code        IN @lr_company_code
        AND tra_opponent_taxno  IN @lr_tra_vkn_tckn
        AND tra_accounting_date IN @lr_tra_accounting_date
        AND document_no         IN @lr_document_no
        AND document_no         IS NOT INITIAL
        AND tra_accounting_date GE '20240101'
      INTO TABLE @lt_bank_log.
    ENDIF.

    "1.Satır için
    SELECT hbal~iban,
           hbal~housebank,
           hbal~housebankaccount,
           hbal~glaccount AS bankaccountinternalid,
           hbal~bankaccountcurrency,
           hbal~bankname,
           hbal~banknumber,
           text~housebankaccountdescription
    FROM @lt_bank_log AS log
    INNER JOIN zfi_004_dd_housebankaccountlin AS hbal ON hbal~iban EQ log~acc_iban
                                                     AND hbal~iban IS NOT INITIAL
                                                     AND hbal~iban IS NOT NULL
    LEFT JOIN  i_housebankaccounttext AS text ON text~language         EQ 'T'
                                             AND text~companycode      EQ hbal~companycode
                                             AND text~housebank        EQ hbal~housebank
                                             AND text~housebankaccount EQ hbal~housebankaccount
    WHERE bankaccountcurrency IN @lr_bankaccountcurrency
    INTO TABLE @DATA(lt_hbal).
    "Binary search
    SORT lt_hbal BY iban.

    "2.Satır için
    SELECT hbal~iban AS oppenent_iban,
           hbal~housebank AS housebank_2,
           hbal~housebankaccount AS housebankaccount_2,
           hbal~glaccount AS bankaccountinternalid_2,
           hbal~bankname AS bankname_2,
           hbal~banknumber AS banknumber_2,
           text~housebankaccountdescription
    FROM @lt_bank_log AS log
    INNER JOIN zfi_004_dd_housebankaccountlin AS hbal ON hbal~iban EQ log~tra_opponent_iban
                                                     AND hbal~iban IS NOT INITIAL
                                                     AND hbal~iban IS NOT NULL
    LEFT JOIN  i_housebankaccounttext AS text ON text~language         EQ 'T'
                                             AND text~companycode      EQ hbal~companycode
                                             AND text~housebank        EQ hbal~housebank
                                             AND text~housebankaccount EQ hbal~housebankaccount
     WHERE bankaccountcurrency IN @lr_bankaccountcurrency
    INTO TABLE @DATA(lt_hbal_2).
    "Binary search
    SORT lt_hbal_2 BY oppenent_iban.

    SELECT cust~customer AS businesspartner,
           'C' AS type,
           cust~customerfullname AS bpfullname,
           ctm~customer,
           cust~taxnumber2
    FROM @lt_bank_log AS log
    INNER JOIN zfi_004_dd_customer AS cust ON cust~taxnumber2 EQ log~vkn_tckn
    LEFT OUTER JOIN zfi_004_dd_customercompany AS ctm ON ctm~customer    EQ cust~customer
                                                     AND ctm~companycode EQ log~company_code
*    LEFT OUTER JOIN zfi_004_dd_customer AS cust  ON cust~customer EQ ctm~customer
*    inner join  I_BusinessPartnerBank as bpb on  bpb~IBAN eq log~acc_iban
    WHERE log~vkn_tckn IS NOT INITIAL
      AND log~vkn_tckn IS NOT NULL
    INTO TABLE @DATA(lt_bp).

    SELECT supp~supplier AS businesspartner,
           'S' AS type,
           supp~supplierfullname AS bpfullname,
           spl~supplier,
           supp~taxnumber2
    FROM @lt_bank_log AS log
    INNER JOIN zfi_004_dd_supplier AS supp ON supp~taxnumber2 EQ log~vkn_tckn
    LEFT OUTER JOIN zfi_004_dd_suppliercompany  AS spl ON spl~supplier   EQ log~vkn_tckn
                                                      AND spl~companycode EQ log~company_code
    WHERE log~vkn_tckn IS NOT INITIAL
      AND log~vkn_tckn IS NOT NULL
    APPENDING TABLE @lt_bp.
    "Binary search
    SORT lt_bp BY taxnumber2.

    SELECT businesspartner,
           iban
       FROM @lt_bank_log AS log
       INNER JOIN zfi_004_dd_businesspartnerbank AS bpb ON bpb~iban EQ log~tra_opponent_iban
                                                       AND bpb~iban IS NOT INITIAL
                                                       AND bpb~iban IS NOT NULL
       INTO TABLE @DATA(lt_bpartbank).
    "Binary search
    SORT lt_bpartbank BY iban businesspartner.
*    DATA(lt_bpartbank_buff) = lt_bpartbank[].
*    SORT lt_bpartbank_buff BY businesspartner.

    SELECT bnk_mt~company_code,
           bnk_mt~tra_vms_transaction_type,
           bnk_mt~tra_transaction_type,
           bnk_mt~tra_mt940transaction_type,
           bnk_mt~cost_center,
           bnk_mt~gl_account,
           bnk_mt~tax_code
    FROM @lt_bank_log AS log
    INNER JOIN zfi_004_t_bnk_mt AS bnk_mt ON bnk_mt~company_code             EQ log~company_code
                                        AND bnk_mt~tra_vms_transaction_type  EQ log~tra_vms_transaction_type
                                        AND bnk_mt~tra_transaction_type      EQ log~tra_transaction_type
                                        AND bnk_mt~tra_mt940transaction_type EQ log~tra_mt940transaction_type
    INTO TABLE @DATA(lt_bnk_mt).
    "Binary search
    SORT lt_bnk_mt BY company_code tra_vms_transaction_type tra_transaction_type tra_mt940transaction_type.

    SELECT businesspartner, searchterm1
     FROM i_businesspartner
     WHERE searchterm1 IS NOT INITIAL AND searchterm1 IS NOT NULL
    INTO TABLE @DATA(lt_business_partner).

    ""Search term ile business partner bulduktan sonra cari tanım için gerekli olan select
    SELECT cust~customer AS businesspartner,
           'C' AS type,
           cust~customerfullname AS bpfullname
    FROM zfi_004_dd_customer AS cust
    INTO TABLE @DATA(lt_bp_buff).
                                                       "#EC CI_NOWHERE.

    SELECT supp~supplier AS businesspartner,
           'S' AS type,
           supp~supplierfullname AS bpfullname
    FROM zfi_004_dd_supplier AS supp
    APPENDING TABLE @lt_bp_buff.
                                                       "#EC CI_NOWHERE.

    SORT lt_bp_buff BY businesspartner.

    LOOP AT lt_bank_log INTO DATA(ls_bank_log).

      READ TABLE lt_hbal INTO DATA(ls_hbal) WITH KEY iban = ls_bank_log-acc_iban BINARY SEARCH.
      IF sy-subrc EQ 0.

      ENDIF.

      "Supplier Customer
      DATA(lv_lines) = REDUCE i( INIT x = 0 FOR wa IN lt_bp WHERE ( taxnumber2 = ls_bank_log-vkn_tckn ) NEXT x = x + 1 ).
      IF lv_lines > 1.

        LOOP AT lt_bp INTO DATA(ls_bp) WHERE taxnumber2 = ls_bank_log-vkn_tckn.
          READ TABLE lt_bpartbank INTO DATA(ls_bpartbank) WITH KEY iban            = ls_bank_log-tra_opponent_iban
                                                                   businesspartner = ls_bp-businesspartner
                                                                   BINARY SEARCH.
          IF sy-subrc EQ 0.
            CASE ls_bp-type.
              WHEN 'C'.
                DATA(lv_customer) = ls_bp-businesspartner.
                DATA(lv_bpfullname) = ls_bp-bpfullname.
              WHEN 'S'.
                DATA(lv_supplier) = ls_bp-businesspartner.
                lv_bpfullname = ls_bp-bpfullname.
            ENDCASE.
          ENDIF.
        ENDLOOP.

      ELSEIF lv_lines EQ 1.

        READ TABLE lt_bp INTO ls_bp WITH KEY taxnumber2 = ls_bank_log-vkn_tckn BINARY SEARCH.
        IF sy-subrc EQ 0.
          CASE ls_bp-type.
            WHEN 'C'.
              lv_customer = ls_bp-businesspartner.
              lv_bpfullname = ls_bp-bpfullname.
            WHEN 'S'.
              lv_supplier = ls_bp-businesspartner.
              lv_bpfullname = ls_bp-bpfullname.
          ENDCASE.
        ENDIF.

      ELSEIF lv_lines EQ 0.

        READ TABLE lt_bpartbank INTO ls_bpartbank WITH KEY iban = ls_bank_log-tra_opponent_iban BINARY SEARCH.
        IF sy-subrc EQ 0.
          READ TABLE lt_bp INTO ls_bp WITH KEY taxnumber2 = ls_bank_log-vkn_tckn BINARY SEARCH.
          IF sy-subrc EQ 0.
            CASE ls_bp-type.
              WHEN 'C'.
                lv_customer = ls_bp-businesspartner.
                lv_bpfullname = ls_bp-bpfullname.
              WHEN 'S'.
                lv_supplier = ls_bp-businesspartner.
                lv_bpfullname = ls_bp-bpfullname.
            ENDCASE.
          ENDIF.
        ENDIF.

      ENDIF.


      IF ( lv_customer EQ ls_bank_log-company_code OR lv_supplier EQ ls_bank_log-company_code ).

        READ TABLE lt_hbal_2 INTO DATA(ls_hbal_2) WITH KEY oppenent_iban = ls_bank_log-tra_opponent_iban BINARY SEARCH.

      ELSEIF lv_customer EQ space AND lv_supplier EQ space .

        "Burayı bir kontrol et yanlış çalışıyor olabilir.
        DATA(lt_business_partner_buff) = lt_business_partner[].
        DELETE lt_business_partner_buff WHERE NOT searchterm1 CS ls_bank_log-tra_description.

        DATA(lv_count) = lines( lt_business_partner_buff[] ).

        DATA(lv_condense_desc) = ls_bank_log-tra_description.

        CONDENSE lv_condense_desc NO-GAPS.

        LOOP AT lt_business_partner INTO DATA(ls_business_partner).
          IF lv_condense_desc CS ls_business_partner-searchterm1.
            lv_count += 1.
            DATA(lv_businesspartner) = ls_business_partner-businesspartner.
          ENDIF.
        ENDLOOP.

        IF lv_count > 1.
          CLEAR: lv_count.
        ELSE.

          "  READ TABLE lt_bpartbank INTO ls_bpartbank WITH KEY  businesspartner = lv_businesspartner BINARY SEARCH.
*          READ TABLE lt_bpartbank_buff INTO ls_bpartbank WITH KEY  businesspartner = lv_businesspartner BINARY SEARCH.
          "Burada lt_bp den okuma ihtiyacı doğdu çünkü bpartbank tablosu log tablosundaki ibanlar ile ilişkili olan bir tablo.
*          READ TABLE lt_bp_buff INTO DATA(ls_bp_buff) WITH KEY  businesspartner = lv_businesspartner BINARY SEARCH.
*          IF sy-subrc EQ 0.
*            CASE ls_bp-type.
*              WHEN 'C'.
*                lv_customer   = ls_bp_buff-businesspartner.
*                lv_bpfullname = ls_bp_buff-bpfullname.
*              WHEN 'S'.
*                lv_supplier   = ls_bp_buff-businesspartner.
*                lv_bpfullname = ls_bp_buff-bpfullname.
*            ENDCASE.
*          ENDIF.

          "Read table yerine loop a ihtiyaç duyuldu. Sebebi search term ile bulunan bp hem supplier hem customer olabilir.
          LOOP AT lt_bp_buff INTO DATA(ls_bp_buff) WHERE businesspartner = lv_businesspartner.
            CASE ls_bp_buff-type.
              WHEN 'C'.
                lv_customer   = ls_bp_buff-businesspartner.
                lv_bpfullname = ls_bp_buff-bpfullname.
              WHEN 'S'.
                lv_supplier   = ls_bp_buff-businesspartner.
                lv_bpfullname = ls_bp_buff-bpfullname.
            ENDCASE.
          ENDLOOP.
        ENDIF.

        IF lv_customer EQ space AND lv_supplier EQ space .

          READ TABLE lt_bnk_mt INTO DATA(ls_bnk_mt) WITH KEY company_code              = ls_bank_log-company_code
                                                             tra_vms_transaction_type  = ls_bank_log-tra_vms_transaction_type
                                                             tra_transaction_type      = ls_bank_log-tra_transaction_type
                                                             tra_mt940transaction_type = ls_bank_log-tra_mt940transaction_type BINARY SEARCH.
          IF sy-subrc EQ 0.
            DATA(lv_bankaccountinternalid_2) = ls_bnk_mt-gl_account.
            DATA(lv_cost_center)             = ls_bnk_mt-cost_center.
            DATA(lv_tax)                     = ls_bnk_mt-tax_code.
          ENDIF.
        ENDIF.

      ENDIF.

*      IF ls_bank_log-tra_amount < 0 AND
*      ( ( ls_bank_log-customer_edit IS INITIAL AND lv_customer IS INITIAL ) AND
*        ( ls_bank_log-supplier_edit IS NOT INITIAL OR lv_supplier IS NOT INITIAL ) AND
*        ( ls_hbal_2-bankaccountinternalid_2 IS INITIAL AND lv_bankaccountinternalid_2 IS INITIAL ) ).
*        DATA(lv_accounted) = 'F110-Otomatik ödeme ile kaydı atılmıştır.'.
*      ENDIF.

      lt_bank_data = VALUE #( BASE lt_bank_data (  guid_tra                = ls_bank_log-guid_tra
                                                   number_of_tra           = ls_bank_log-number_of_tra
                                                   company_code            = ls_bank_log-company_code
                                                   acc_iban                = ls_bank_log-acc_iban
                                                   housebank               = ls_hbal-housebank
                                                   housebankaccount        = ls_hbal-housebankaccount
                                                   bankaccountinternalid   = ls_hbal-bankaccountinternalid
*                                                   bankname                = ls_hbal-bankname
                                                   bankname                = ls_hbal-housebankaccountdescription
                                                   banknumber              = ls_hbal-banknumber
                                                   tra_amount              = ls_bank_log-tra_amount
                                                   bankaccountcurrency     = ls_hbal-bankaccountcurrency
                                                   tra_description         = ls_bank_log-tra_description
                                                   tra_transaction_type    = ls_bank_log-tra_transaction_type
                                                   tra_type_name           = ls_bank_log-tra_type_name
                                                   tra_accounting_date     = ls_bank_log-tra_accounting_date
                                                   customer                = COND #( WHEN ls_bank_log-customer_edit IS NOT INITIAL THEN ls_bank_log-customer_edit
                                                                                     ELSE lv_customer )
                                                   supplier                = COND #( WHEN ls_bank_log-supplier_edit IS NOT INITIAL THEN ls_bank_log-supplier_edit
                                                                                     ELSE lv_supplier )
                                                   bpfullname              = lv_bpfullname
                                                   vkn_tckn                = ls_bank_log-vkn_tckn
                                                   tra_opponent_iban       = ls_bank_log-tra_opponent_iban
                                                   tra_opponent_title      = ls_bank_log-tra_opponent_iban
                                                   tra_opponent_taxno      = ls_bank_log-tra_opponent_taxno
                                                   housebank_2             = ls_hbal_2-housebank_2
                                                   housebankaccount_2      = ls_hbal_2-housebankaccount_2
                                                   bankaccountinternalid_2 = COND #( WHEN lv_bankaccountinternalid_2 IS NOT INITIAL
                                                                                     THEN lv_bankaccountinternalid_2
                                                                                     ELSE ls_hbal_2-bankaccountinternalid_2 )
*                                                   bankname_2              = ls_hbal_2-bankname_2
                                                   bankname_2              = ls_hbal_2-housebankaccountdescription
                                                   banknumber_2            = ls_hbal_2-banknumber_2
                                                   cost_center             = lv_cost_center
*                                                   profit_center
                                                   tax                     = lv_tax
                                                   document_no             = ls_bank_log-document_no
*                                                   accounted               = lv_accounted
                                                   "" Bu alanın eklenmesinin sebebi bankaların isminden filtrelenmek istemesi.
                                                   bank_desc               = ls_hbal-bankname
                                                   "" Sefer bilgileri eklenmesi
                                                   voyage_info             = ls_bank_log-voyage_info
                                                   ) ).

      IF  lr_bankaccountcurrency_e[] IS NOT INITIAL
      OR lr_customer_e[] IS NOT INITIAL
      OR lr_supplier_e[] IS NOT INITIAL
      OR lr_bpfullname_e[] IS NOT INITIAL
      OR lr_bank_name_e[] IS NOT INITIAL.
        DELETE lt_bank_data WHERE bankaccountcurrency   IN lr_bankaccountcurrency_e
                              AND customer              IN lr_customer_e
                              AND supplier              IN lr_supplier_e
                              AND bpfullname            IN lr_bpfullname_e
                              AND bank_desc             IN lr_bank_name_e.
      ENDIF.

      CLEAR: lv_customer, lv_supplier, lv_bpfullname,
      ls_hbal, ls_hbal_2,
      ls_bpartbank, ls_bp, ls_bank_log,
      lv_bankaccountinternalid_2, lv_cost_center, lv_tax, lv_businesspartner."lv_accounted

    ENDLOOP.

    IF ls_request-accounted IS INITIAL.
      DELETE lt_bank_data WHERE accounted IS NOT INITIAL.
    ENDIF.


*    DATA(lv_json_string) = xco_cp_json=>data->from_abap( lt_bank_data )->apply( VALUE #( ( xco_cp_json=>transformation->underscore_to_pascal_case )
*                       ) )->to_string( ).

*    SORT lt_bank_data BY document_no DESCENDING.

    TRY.
        CALL METHOD /ui2/cl_json=>serialize
          EXPORTING
            data         = lt_bank_data
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
    CLEAR:gt_name_mapping.
    gt_name_mapping = VALUE #( ( abap = 'COMPANY_CODE'             json = 'companyCode'  )
                               ( abap = 'BANKACCOUNTCURRENCY'      json = 'bankaccountcurrency'  )
                               ( abap = 'CUSTOMER'                 json = 'customer'  )
                               ( abap = 'SUPPLIER'                 json = 'supplier'  )
                               ( abap = 'VKN_TCKN'                 json = 'vknTckn'  )
                               ( abap = 'TRA_ACCOUNTING_DATE_TO'   json = 'tra_accounting_date_to')
                               ( abap = 'TRA_ACCOUNTING_DATE_FROM' json = 'tra_accounting_date_from')
                               ( abap = 'DOCUMENT_NO'              json = 'documentNo')
                               ( abap = 'DOCUMENT_NO_FILLED'       json = 'isDocumentNoFilled')
                               ( abap = 'ACCOUNTED'                json = 'isAccountedFilled')
                               ( abap = 'BPFULLNAME'               json = 'bpfullname')
                               ( abap = 'BANK_NAME'                json = 'bankAccount') ).
  ENDMETHOD.
ENDCLASS.
