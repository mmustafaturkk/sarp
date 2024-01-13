CLASS lhc_zr_fi_000_t_uspass DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR zr_fi_000_t_uspass RESULT result.

    METHODS createbase64 FOR DETERMINE ON MODIFY
      IMPORTING keys FOR zr_fi_000_t_uspass~createbase64.

ENDCLASS.

CLASS lhc_zr_fi_000_t_uspass IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD createbase64.

    DATA: utility TYPE REF TO cl_web_http_utility.
    CREATE OBJECT utility.

    READ ENTITIES OF zr_fi_000_t_uspass  IN LOCAL MODE
             ENTITY zr_fi_000_t_uspass
                FIELDS ( entbase64 )
                WITH CORRESPONDING #( keys )
             RESULT DATA(lt_user_pass)
             FAILED DATA(failed).

    LOOP AT lt_user_pass ASSIGNING FIELD-SYMBOL(<lfs_user_pass>).

      IF <lfs_user_pass>-entuser IS NOT INITIAL AND <lfs_user_pass>-entpass IS NOT INITIAL.
        DATA(lv_str) = |{ <lfs_user_pass>-entuser }:{ <lfs_user_pass>-entpass }|.
        TRY.
            CALL METHOD utility->encode_utf8
              EXPORTING
                unencoded = lv_str
              RECEIVING
                encoded   = DATA(lv_xstring).
          CATCH cx_web_http_conversion_failed.

        ENDTRY.

        TRY.
            CALL METHOD utility->encode_x_base64
              EXPORTING
                unencoded = lv_xstring
              RECEIVING
                encoded   = DATA(lv_base64).
          CATCH cx_web_http_conversion_failed.

        ENDTRY.

        <lfs_user_pass>-entbase64 = lv_base64.

      ENDIF.

    ENDLOOP.

    MODIFY ENTITIES OF zr_fi_000_t_uspass IN LOCAL MODE
       ENTITY zr_fi_000_t_uspass
         UPDATE FIELDS ( entbase64 )
         WITH CORRESPONDING #( lt_user_pass ).

  ENDMETHOD.

ENDCLASS.
