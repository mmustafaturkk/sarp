CLASS zfi_004_bank_get_data DEFINITION PUBLIC FINAL CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES : if_oo_adt_classrun.
    METHODS : constructor,
      instance_method.
    CLASS-METHODS : class_constructor,
      static_method.
ENDCLASS.



CLASS ZFI_004_BANK_GET_DATA IMPLEMENTATION.


  METHOD class_constructor.
    "Method Code
  ENDMETHOD.


  METHOD constructor.
    "Method Code
  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.
    "Method Code

    DATA: lt_bank_data TYPE TABLE OF  zfi_004_s_bank_kokpit.
*    I_HouseBankAccountLinkage

    "Log tablosundan veri çekilir
    SELECT number_of_tra,
           company_code,
           acc_iban,
           tra_amount,
           tra_description,
           tra_transaction_type,
           tra_type_name,
           tra_sender_identity_number AS vkn_tckn,
           tra_opponent_iban,
           tra_accounting_date
    FROM zfi_004_t_bnk_lg
    INTO TABLE @DATA(lt_bank_log).
"#EC CI_NOWHERE.

    "1.Satır için
    SELECT hbal~iban,
           hbal~housebank,
           hbal~housebankaccount,
           hbal~bankaccountinternalid,
           hbal~bankaccountcurrency,
           hbal~bankname
    FROM @lt_bank_log AS log
    INNER JOIN i_housebankaccountlinkage AS hbal ON hbal~iban EQ log~acc_iban
    INTO TABLE @DATA(lt_hbal).

    "2.Satır için
    SELECT hbal~iban AS oppenent_iban,
           hbal~housebank AS housebank_2,
           hbal~housebankaccount AS housebankaccount_2,
           hbal~bankaccountinternalid AS bankaccountinternalid_2,
           hbal~bankname AS bankname_2
    FROM @lt_bank_log AS log
    INNER JOIN i_housebankaccountlinkage AS hbal ON hbal~iban EQ log~tra_opponent_iban
    INTO TABLE @DATA(lt_hbal_2).



    SELECT customer AS businesspartner,
           'C' AS type
    FROM @lt_bank_log AS log
    INNER JOIN i_customercompany AS ctm ON ctm~customer    EQ log~vkn_tckn
                                       AND ctm~companycode EQ log~company_code
*    inner join  I_BusinessPartnerBank as bpb on  bpb~IBAN eq log~acc_iban
    INTO TABLE @DATA(lt_bp).


    SELECT supplier AS businesspartner,
           'S' AS type
    FROM @lt_bank_log AS log
    INNER JOIN i_suppliercompany AS spl ON spl~supplier    EQ log~vkn_tckn
                                       AND spl~companycode EQ log~company_code
    APPENDING TABLE @lt_bp.

    SELECT businesspartner,
           iban
       FROM @lt_bank_log AS log
       INNER JOIN  i_businesspartnerbank AS bpb ON bpb~iban EQ log~acc_iban
       INTO TABLE @DATA(lt_bpartbank).

    LOOP AT lt_bank_log INTO DATA(ls_bank_log).




      READ TABLE lt_hbal INTO DATA(ls_hbal) WITH KEY iban = ls_bank_log-acc_iban.
      IF sy-subrc EQ 0.

      ENDIF.




      "Supplier Customer
      DATA(lv_lines) = REDUCE i( INIT x = 0 FOR wa IN lt_bp WHERE ( businesspartner = ls_bank_log-vkn_tckn ) NEXT x = x + 1 ).
      IF lv_lines > 1.

        LOOP AT lt_bp INTO DATA(ls_bp) WHERE businesspartner = ls_bank_log-vkn_tckn.
          READ TABLE lt_bpartbank INTO DATA(ls_bpartbank) WITH KEY iban            = ls_bank_log-acc_iban
                                                                   businesspartner = ls_bp-businesspartner.
          IF sy-subrc EQ 0.
            CASE ls_bp-type.
              WHEN 'C'.  DATA(lv_customer) = ls_bp-businesspartner.
              WHEN 'S'.  DATA(lv_supplier) = ls_bp-businesspartner.
            ENDCASE.
          ENDIF.
        ENDLOOP.
      ELSEIF lv_lines EQ 0.


        READ TABLE lt_bpartbank INTO ls_bpartbank WITH KEY iban = ls_bank_log-acc_iban.
        IF sy-subrc EQ 0.
          READ TABLE lt_bp INTO ls_bp WITH KEY businesspartner = ls_bank_log-vkn_tckn.
          IF sy-subrc EQ 0.
            CASE ls_bp-type.
              WHEN 'C'.  lv_customer = ls_bp-businesspartner.
              WHEN 'S'.  lv_supplier = ls_bp-businesspartner.
            ENDCASE.
          ENDIF.
        ENDIF.

      ENDIF.



      IF ( lv_customer EQ ls_bank_log-company_code OR lv_supplier EQ ls_bank_log-company_code ).

        READ TABLE lt_hbal_2 INTO DATA(ls_hbal_2) WITH KEY oppenent_iban = ls_bank_log-tra_opponent_iban.

      ENDIF.


      lt_bank_data = VALUE #( BASE lt_bank_data (  number_of_tra           = ls_bank_log-number_of_tra
                                                   company_code            = ls_bank_log-company_code
                                                   acc_iban                = ls_bank_log-acc_iban
                                                   housebank               = ls_hbal-housebank
                                                   housebankaccount        = ls_hbal-housebankaccount
                                                   bankaccountinternalid   = ls_hbal-bankaccountinternalid
                                                   tra_amount              = ls_bank_log-tra_amount
                                                   bankaccountcurrency     = ls_hbal-bankaccountcurrency
                                                   tra_description         = ls_bank_log-tra_description
                                                   tra_transaction_type    = ls_bank_log-tra_transaction_type
                                                   tra_type_name           = ls_bank_log-tra_type_name
                                                   customer                = lv_customer
                                                   supplier                = lv_supplier
                                                   vkn_tckn                = ls_bank_log-vkn_tckn
                                                   tra_opponent_iban       = ls_bank_log-tra_opponent_iban
                                                   housebank_2             = ls_hbal_2-housebank_2
                                                   housebankaccount_2      = ls_hbal_2-housebankaccount_2
                                                   bankaccountinternalid_2 = ls_hbal_2-bankaccountinternalid_2
*                                                   cost_center
*                                                   profit_center
*                                                   tax
*                                                   document_no
                                                   ) ).
      CLEAR: lv_customer, lv_supplier,
             ls_hbal, ls_hbal_2,
             ls_bpartbank, ls_bp, ls_bank_log.
    ENDLOOP.


  ENDMETHOD.


  METHOD instance_method.
    "Method Code
  ENDMETHOD.


  METHOD static_method.
    "Method Code
  ENDMETHOD.
ENDCLASS.
