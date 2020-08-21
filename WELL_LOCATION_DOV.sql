DROP VIEW PBC_PROJ.WELL_LOCATION_DOV;

CREATE OR REPLACE FORCE VIEW PBC_PROJ.WELL_LOCATION_DOV
(
   UWI,
   WELL_NAME,
   LAT_DMS,
   LONG_DMS,
   ORIGINAL_X_LONGITUDE,
   ORIGINAL_Y_LATITUDE,
   ORIGINAL_CRS,
   SHAPE
)
   BEQUEATH DEFINER
AS
   SELECT name AS UWI,
          source AS Well_Name,
          CAST (NULL AS VARCHAR2 (64)) LAT_DMS,
          CAST (NULL AS VARCHAR2 (64)) LONG_DMS,
          ORIGINAL_X_Longitude,
          Original_Y_Latitude,
          CAST (Original_Source AS NUMBER) Original_CRS,
          DECODE (
             TO_NUMBER (original_source),
             29849, sde.st_transform (
                       Sde.St_Point (ORIGINAL_X_LONGITUDE,
                                     original_y_latitude,
                                     TO_NUMBER (original_source)),
                       4326,
                       1228),
             4326, sde.St_Transform (
                      Sde.St_Point (ORIGINAL_X_LONGITUDE,
                                    original_y_latitude,
                                    4326),
                      4326),
             NULL)
             shape
     FROM PBC_PROJ.POSITION;


CREATE OR REPLACE TRIGGER PBC_PROJ.Well_Location_DOV_INI
   INSTEAD OF INSERT
   ON PBC_PROJ.WELL_LOCATION_DOV
   FOR EACH ROW
DECLARE
   v_degree_symbol   VARCHAR2 (10) := CHR (176);
   v_minute_symbol   VARCHAR2 (10) := CHR (39);
   v_second_symbol   VARCHAR2 (10) := CHR (34);
   v_deg             NUMBER;
   v_min             NUMBER;
   v_sec             NUMBER;
   v_lat             NUMBER;
   v_long            NUMBER;
   v_direction       VARCHAR2 (5);
BEGIN
   IF :NEW.LONG_DMS IS NOT NULL AND :NEW.LAT_DMS IS NOT NULL
   THEN
      v_deg :=
         TO_NUMBER (
            TRIM (
               SUBSTR (:NEW.LAT_DMS,
                       0,
                       INSTR (:NEW.LAT_DMS, v_degree_symbol) - 1)));
      v_min :=
         TO_NUMBER (
            TRIM (
               SUBSTR (
                  :NEW.LAT_DMS,
                  INSTR (:NEW.LAT_DMS, v_degree_symbol) + 1,
                    INSTR (:NEW.LAT_DMS, v_minute_symbol)
                  - INSTR (:NEW.LAT_DMS, v_degree_symbol)
                  - 1)));
      v_sec :=
         TO_NUMBER (
            TRIM (
               SUBSTR (
                  :NEW.LAT_DMS,
                  INSTR (:NEW.LAT_DMS, v_minute_symbol) + 1,
                    INSTR (:NEW.LAT_DMS, v_second_symbol)
                  - INSTR (:NEW.LAT_DMS, v_minute_symbol)
                  - 1)));
      v_direction :=
         TRIM (
            SUBSTR (:NEW.LAT_DMS, INSTR (:NEW.LAT_DMS, v_second_symbol) + 1));

      v_lat := v_deg + v_min / 60 + v_sec / 3600;

      IF v_direction = 'S'
      THEN
         v_lat := v_lat * (-1);
      END IF;

      v_deg :=
         TO_NUMBER (
            TRIM (
               SUBSTR (:NEW.LONG_DMS,
                       0,
                       INSTR (:NEW.LONG_DMS, v_degree_symbol) - 1)));
      v_min :=
         TO_NUMBER (
            TRIM (
               SUBSTR (
                  :NEW.LONG_DMS,
                  INSTR (:NEW.LONG_DMS, v_degree_symbol) + 1,
                    INSTR (:NEW.LONG_DMS, v_minute_symbol)
                  - INSTR (:NEW.LONG_DMS, v_degree_symbol)
                  - 1)));
      v_sec :=
         TO_NUMBER (
            TRIM (
               SUBSTR (
                  :NEW.LONG_DMS,
                  INSTR (:NEW.LONG_DMS, v_minute_symbol) + 1,
                    INSTR (:NEW.LONG_DMS, v_second_symbol)
                  - INSTR (:NEW.LONG_DMS, v_minute_symbol)
                  - 1)));
      v_direction :=
         TRIM (
            SUBSTR (:NEW.LONG_DMS,
                    INSTR (:NEW.LONG_DMS, v_second_symbol) + 1));

      v_long := v_deg + v_min / 60 + v_sec / 3600;

      IF v_direction = 'W'
      THEN
         v_long := v_long * (-1);
      END IF;
      
   ELSE
   
        v_long := :NEW.ORIGINAL_X_LONGITUDE;
        v_lat := :NEW.ORIGINAL_Y_LATITUDE;
   END IF;



   INSERT INTO position (name,
                         source,
                         original_source,
                         produced_by,
                         REMARKS,
                         ORIGINAL_X_LONGITUDE,
                         ORIGINAL_Y_LATITUDE)
        VALUES (:NEW.UWI,
                :NEW.WELL_NAME,
                :NEW.ORIGINAL_CRS,
                NULL,
                NULL,
                v_long,
                v_lat);
END;
/
