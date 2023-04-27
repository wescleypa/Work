CREATE OR REPLACE PROCEDURE ROOT."SP_CON_ALTLOTE" 
(
    Pcdusuari  IN NUMBER  
  , Pnratendi  IN VARCHAR2
  , Pdslote    IN VARCHAR2
  , Pcdprodut  IN VARCHAR2
  , Pcdtomado  IN VARCHAR2
  , Pcdempres  IN VARCHAR2
  , Pcdresarm  IN VARCHAR2
  , Pcdgrures  IN VARCHAR2
  , Pnrseqven  IN VARCHAR2
  , Pnfremessa IN VARCHAR2
  , PsnExcel   IN VARCHAR2
  , startList  IN NUMBER
  , endList    IN NUMBER
) AS
  extraWhere clob;
  extraJoin  clob;
  sqlBegin   clob;
  PtpPerfil  char(1);
  Pcursor SYS_REFCURSOR;

BEGIN
  extraWhere := ' ';
  extraJoin  := ' ';
  sqlBegin   := ' ';
 
  IF Pnratendi IS NOT NULL
  THEN
    extraWhere := extraWhere || ' AND W001.NRATENDI IN (' || Pnratendi || ')';
  END IF;

  IF Pdslote IS NOT NULL
  THEN
    extraWhere := extraWhere || ' AND W003.DSLOTE IN (''' || Pdslote || ''')';
  END IF;

  IF Pcdprodut IS NOT NULL
  THEN
    extraWhere := extraWhere || ' AND W005.CDPRODUT IN (' || Pcdprodut || ')';
  END IF;

  IF Pcdtomado IS NOT NULL
  THEN
    extraWhere := extraWhere || ' AND W001.CDTOMADO IN (' || Pcdtomado || ')';
  END IF;

  IF Pcdempres IS NOT NULL
  THEN
    extraWhere := extraWhere || ' AND W001.CDEMPRES IN (' || Pcdempres || ')';
  END IF;

  IF Pcdresarm IS NOT NULL
  THEN
    extraWhere := extraWhere || ' AND W001.CDRESARM IN (' || Pcdresarm || ')';
  END IF;

  IF Pcdgrures IS NOT NULL
  THEN
    extraWhere := extraWhere || ' AND G001.CDGRURES IN (' || Pcdgrures || ')';
  END IF;

  IF Pnrseqven IS NOT NULL
  THEN
    extraWhere := extraWhere || ' AND W003.NRSEQVEN IN (' || Pnrseqven || ')';
  END IF;

  IF Pnfremessa IS NOT NULL
  THEN
    extraWhere := extraWhere || ' AND W003.NRREMESSA IN (' || Pnfremessa || ')';
  END IF;
             
  SP_CON_PerfilUsuario(pCdUsuari, PtpPerfil);
             
  CASE 
  WHEN PtpPerfil = 'S' THEN
    extraWhere := extraWhere || ' AND S001.CDUSUARI = ' || Pcdusuari || '';
  WHEN PtpPerfil = 'T' THEN
    extraJoin  := extraJoin  || ' INNER JOIN S012 S012 ON (S012.CDUSUARI = S001.CDUSUARI)';
    extraWhere := extraWhere || ' AND S001.CDUSUARI = ' || Pcdusuari || '';
    extraWhere := extraWhere || ' AND G007.NRRADCNP = S012.CJTOMADO';
    extraWhere := extraWhere || ' AND G001.CDGRURES = S012.CDGRURES';
  WHEN PtpPerfil IN ('I', 'N') THEN
    extraJoin  := extraJoin  || ' INNER JOIN S013 S013 ON (S013.CDUSUARI = S001.CDUSUARI)';
    extraWhere := extraWhere || ' AND S001.CDUSUARI = ' || Pcdusuari ||'';
    extraWhere := extraWhere || ' AND S013.CDGRURES = G001.CDGRURES';
  WHEN Ptpperfil IN ('O', 'L') THEN
    extraJoin  := extraJoin  || ' INNER JOIN S005 S005 ON (S005.CDUSUARI = S001.CDUSUARI)';
    extraJoin  := extraJoin  || ' INNER JOIN S013 S013 ON (S013.CDUSUARI = S013.CDUSUARI)';
    extraWhere := extraWhere || ' S001.CDUSUARI = ' || Pcdusuari || '';
    extraWhere := extraWhere || ' S005.CDEMPRES = S004.CDEMPRES';
    extraWhere := extraWhere || ' S001.CDGRURES = S013.CDGRURES';
  WHEN PtpPerfil = 'V' THEN
    extraJoin  := extraJoin  || ' INNER JOIN S029 S029 ON (S029.CDUSUARI = S001.CDUSUARI)';
    extraWhere := extraWhere || ' AND S001.CDUSUARI = ' || Pcdusuari ||'';
    extraWhere := extraWhere || ' AND (G007.NRRADCNP = S029.CJTOMRTV OR
                                       G007.CJTOMADO = S029.CJTOMRTV)';
    extraWhere := extraWhere || ' AND G001.CDGRURES = S029.CDGRURES'  ;
  WHEN PtpPerfil = 'P' THEN
    extraJoin  := extraJoin  || ' INNER JOIN S005 S005 ON (S005.CDUSUARI = S001.CDUSUARI)';
    extraWhere := extraWhere || ' AND S001.CDUSUARI = ' || Pcdusuari ||'';
    extraWhere := extraWhere || ' AND S005.CDUSUARI = S004.CDEMPRES';
  ELSE NULL;
  END CASE ;

  sqlBegin := '
  SELECT (COUNT(*) OVER ()) AS COUNT, 
    temp.*
    FROM (
      SELECT
          W005.IDW005
        , W001.NRATENDI
        , TO_CHAR(W005.DTOPERAC, ''DD/MM/YYYY HH24:MI:SS'') AS DTOPERAC
        , W005.CDUSUARI
        , G003.DSREFFAB
        , G003.CDPROSAP
        , G003.DSPRODUT 
        , W003.NRSEQITE
        , W003.DSLOTORI
        , W003.DSLOTANT
        , W003.DSLOTE
        , W003.QTPRODUT
        , TO_CHAR(W003.DTFABR  , ''DD/MM/YYYY'') AS DTFABR
        , TO_CHAR(W003.DTVENCTO, ''DD/MM/YYYY'') AS DTVENCTO
        , G007.RSTOMADO
        , G007.CJTOMADO
        , G007.IETOMADO
        , G001.CJRESARM
        , G001.IERESARM
        , W001.IDERPTOM
      FROM W005 W005

      LEFT JOIN W001 W001 ON (W001.NRATENDI = W005.NRATEORI OR W001.NRATENDI = W005.NRATEDES)
      LEFT JOIN W003 W003 ON (W003.NRATENDI = W005.NRATEORI OR W003.NRATENDI = W005.NRATEDES OR (
        W003.DSLOTORI = W005.DSLOTORI OR W003.DSLOTE = W005.DSLOTDES)
      )
      LEFT JOIN G003 G003 ON G003.CDPRODUT = W005.CDPRODUT
      LEFT JOIN G007 G007 ON G007.CDTOMADO = W001.CDTOMADO
      LEFT JOIN G001 G001 ON G001.CDRESARM = W001.CDRESARM
      LEFT JOIN S001 S001 ON S001.CDUSUARI = ' || Pcdusuari || '
      ' || extraJoin  || '
      WHERE S001.CDUSUARI = ' || Pcdusuari || '
      ' || extraWhere || '
      GROUP BY 
          W005.IDW005
        , W001.NRATENDI
        , W005.DTOPERAC
        , W005.CDUSUARI
        , G003.DSREFFAB
        , G003.CDPROSAP
        , G003.DSPRODUT 
        , W003.NRSEQITE
        , W003.DSLOTORI
        , W003.DSLOTANT
        , W003.DSLOTE
        , W003.QTPRODUT
        , W003.DTFABR
        , W003.DTVENCTO
        , G007.RSTOMADO
        , G007.CJTOMADO
        , G007.IETOMADO
        , G001.CJRESARM
        , G001.IERESARM
        , W001.IDERPTOM
      ORDER BY W005.DTOPERAC DESC
    ) temp';
    
   	IF PsnExcel = 'S' THEN
      OPEN Pcursor FOR sqlBegin;
    ELSE
      sqlBegin := sqlBegin || ' Offset :NrRegIni rows Fetch next :NrRegFin rows only';
      OPEN Pcursor FOR sqlBegin USING startList, endList;
   	END IF;
   
    DBMS_OUTPUT.PUT_LINE(sqlBegin); 
    DBMS_SQL.RETURN_RESULT(Pcursor);

END SP_CON_ALTLOTE;