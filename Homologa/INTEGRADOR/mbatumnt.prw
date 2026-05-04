#include 'totvs.ch'

/***********************************************************************************/
/*/{Protheus.doc} BZATUZZ0
    @description Grava integração na tabela muro ZZ0 para ser processada pelo BZAPI002 (JOB)
    @type  Static Function
    @author Michihiko Tanimoto
    @since 16/11/2020
/*/
/***********************************************************************************/
User Function mbAtuMnt(_cIdProc,_cChave,_cJson,_cError,_cStZZ0,cFazenda)

    Local _aArea    := GetArea()
    Local _lRet     := .T.
    Local _oMonitor := MBMonitor():New()
    //Default _nOpc   := 3
    
    _oMonitor:cIdProc   := _cIdProc
    _oMonitor:cChave    := _cChave
    _oMonitor:cStatus   := _cStZZ0
    _oMonitor:cJSon     := _cJson
    _oMonitor:nQtdReg   := 1
    _oMonitor:cFazenda  := cFazenda
    _oMonitor:cFunName  := ProcName(2)
    
    If _oMonitor:GrvMonitor()
        _lRet := .T.
    Else
        _lRet := .F.
    EndIf
    RestArea(_aArea)

Return _lRet


/***********************************************************************************
    {Protheus.doc} mbGrvHst
    @description Atualiza historico monitor quando ocorre erro
***********************************************************************************/
User Function mbGrvHst(_cIdProc,_cChave,_cJson,_cError)

    Local _lRet     := .T.
    Local _oMonitor := MBMonitor():New()

    _oMonitor:cIdProc   := _cIdProc
    _oMonitor:cChave    := _cChave
    _oMonitor:cError    := _cError
    _oMonitor:cJSon     := _cJson

    If _oMonitor:GrvHistorico()
        _lRet     := .T.
    Else
        _lRet     := .F.
    EndIf

Return _lRet 

