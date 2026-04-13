#INCLUDE "TOTVS.CH"

/*******************************************************************************************************************************************
    {Protheus.doc} Monitor Integrador Multibonivos
    @description Classe realiza a gravação e atualização do historico de processamento das integrações com o Multibovinos, 
    as integrações são controladas por um processo de monitoramento, onde é gravado o status do processo, os dados enviados e 
    recebidos em JSON, a quantidade de registros processados e a quantidade de tentativas.
    O monitoramento é realizado na tabela ZZ0 - tabela de monitoramento onde é gravado o status do processo, os dados enviados e 
    recebidos em JSON, a quantidade de registros processados e a quantidade de tentativas
    , já a ZZ1 é a tabela de historico onde é gravado 
    o status do processo, os dados enviados e recebidos em JSON, a quantidade de registros processados e a quantidade de tentativas.
    O processo de monitoramento é controlado por um ID do processo e uma chave, onde o ID do processo é o nome da integração 
    e a chave é um identificador unico para cada processo, podendo ser o numero do lote ou o numero do pedido.
    @author    Michihiko Tanimoto
    @since     10/04/2026
*****************************************************************************************************************/
Class MBMonitor

    Data cIdProc        As String
    Data cJSon          As String
    Data cError         As String
    Data cStatus        As String
    Data cSeq           As String
    Data cSeqZZ0        As String
    Data cChave         As String
    Data cFunName       As String
    Data cErrorRet      As String
    Data cFazenda       As String

    Data nTpGrava       As Integer
    Data nTpRet         As Integer
    Data nQtdReg		As Integer
	Data nTentativa	    As Integer

    Method New() Constructor
    Method ValidZZ0() 
    Method ValidZZ1() 
    Method GrvMonitor()
    Method GrvHistorico()

EndClass

/****************************************************************************************
    {Protheus.doc} New
    @description Metodo construtor da Classe 
    @type  Function
****************************************************************************************/
Method New() Class mbMonitor
    
    ::cIdProc       := ""
    ::cJSon         := ""
    ::cError        := ""
    ::cStatus       := ""
    ::cSeq          := ""
    ::cSeqZZ0       := ""
    ::cChave        := ""
    ::cFunName      := ""
    ::cErrorRet     := ""
    ::cFazenda      := ""

    ::nTpGrava      := 0
    ::nTpRet        := 0
    ::nQtdReg       := 0
	::nTentativa    := 0

Return Nil 

/****************************************************************************************
    {Protheus.doc} ValidZZ0
    @description Metodo valida dados da sequencia e tentativa de gravação
    @type  Function
****************************************************************************************/
Method ValidZZ0() Class mbMonitor

    Local _cQuery   := ""
    Local _cAlias   := ""

    //---------+
    // Monitor |
    //---------+
    _cQuery := " SELECT " + CRLF 
    _cQuery += "    COALESCE(MAX(ZZ0_SEQ),'0000') SEQ, " + CRLF 
    _cQuery += "    COALESCE(MAX(ZZ0_TENTAT),0) TENTATIVA " + CRLF 
    _cQuery += " FROM " + CRLF 
    _cQuery += "    " + RetSqlName("ZZ0") + " " + CRLF 
    _cQuery += " WHERE " + CRLF 
    _cQuery += "    ZZ0_FILIAL = '" + xFilial("ZZ0") + "' AND " + CRLF  
    _cQuery += "    ZZ0_CHAVE = '" + ::cChave + "' AND " + CRLF 
    _cQuery += "    ZZ0_ID = '" + ::cIdProc + "' AND " + CRLF 
    _cQuery += "    D_E_L_E_T_ = '' " + CRLF 
    _cQuery += " GROUP BY ZZ0_ID,ZZ0_CHAVE "
    _cAlias := MPSysOpenQuery(_cQuery)

    //::nTpRet:= _cAlias->(TENTATIVA)

    If ::nTpRet == 1        // Incrementa |
        ::cSeqZZ0   := IIF(Empty((_cAlias)->SEQ), "0001", Soma1((_cAlias)->SEQ))
        ::nTentativa:= IIF(Empty((_cAlias)->TENTATIVA), 1, (_cAlias)->TENTATIVA + 1)
    Else                    // Retorna ultima sequencia |
        ::cSeqZZ0   := (_cAlias)->SEQ 
        ::nTentativa:= (_cAlias)->TENTATIVA 
    EndIf

    (_cAlias)->( dbCloseArea() )        // Encerra temporario |

Return Nil 

/****************************************************************************************
    {Protheus.doc} ValidZZ1
    @description Metodo valida dados da sequencia do historico
    @type  Function
****************************************************************************************/
Method ValidZZ1() Class mbMonitor

    Local _cQuery   := ""
    Local _cAlias   := ""

    _cQuery := " SELECT " + CRLF
    _cQuery += "    COALESCE(MAX(ZZ1_SEQ),'0000') SEQ " + CRLF
    _cQuery += " FROM " + CRLF
    _cQuery += "	" + RetSqlName("ZZ1") + " " + CRLF
    _cQuery += " WHERE " + CRLF
    _cQuery += "	ZZ1_FILIAL = '" + xFilial("ZZ1") + "' AND " + CRLF
    _cQuery += "	ZZ1_CHAVE = '" + ::cChave + "' AND " + CRLF
    _cQuery += "	ZZ1_ID = '" + ::cIdProc + "' AND " + CRLF
    _cQuery += "	D_E_L_E_T_ = '' " + CRLF
    _cQuery += " GROUP BY ZZ1_ID,ZZ1_CHAVE " + CRLF

    _cAlias := MPSysOpenQuery(_cQuery)

    If ::nTpRet == 1                // Incrementa |
        ::cSeq      := IIF(Empty((_cAlias)->SEQ), "0001", Soma1((_cAlias)->SEQ))
    Else                            // Retorna ultima sequencia |
        ::cSeq      := (_cAlias)->SEQ
    EndIf

    (_cAlias)->( dbCloseArea() )        // Encerra temporario |

Return Nil 

/****************************************************************************************
    {Protheus.doc} GrvMonitor
    @description Realiza a gravação monitor de processamento
    @type  Function
****************************************************************************************/
Method GrvMonitor() Class mbMonitor

    Local _aArea    := GetArea()
    Local _lRet     := .T.
    Local _lGrava   := .F.
    //Local _cIDENABLEY  := GetNewPar("BZ_XENABID","0017|0018|0019|0020|0021|0022|0023")

    If ::cStatus=="1"           //Pelo status passado está incluíndo um novo processo de integração Protheus-->Multibovinos
                                //preciso buscar a proxima sequencia disponivel deste processo+chave
        ::nTpRet    := 1        //Dentro da VALIDZZ0 o valor 1=incrementa novo processo; 2=atualiza e traz o ultimo ja existente e retorna valor de tentativas
        ::ValidZZ0()            //retorna a proxima sequencia deste processo+chave
        _lGrava     := .T.      //Flag indicando novo registro na ZZ0
        ::nTentativa:= 0        //Preciso forcar a quantidade de tentativas pois a validZZ0 retorna a quantidade do ultima sequencia do processo+chave
    Else                        //Alteracao
                                //Forca a Atualização do registro ja existente na ZZ0
        ::nTpRet  := 2          //Dentro da VALIDZZ0 o valor 1=incrementa novo processo; 2=atualiza e traz o ultimo ja existente e retorna valor de tentativas
        _lGrava   := .F.        //Flag Indicando autalizaçao de registro na ZZ0
        dbSelectArea("ZZ0")
        ZZ0->( dbSetOrder(1) )
        ZZ0->( dbSeek(xFilial("ZZ0") + PadR(::cIdProc,TamSx3("ZZ0_ID")[1]) + PadR(::cChave,TamSx3("ZZ0_CHAVE")[1]) + PadR(::cSeqZZ0,TamSx3("ZZ0_SEQ")[1])) )
        ::nTentativa :=  ZZ0->ZZ0_TENTAT + 1    //Incremento o numero de tentativas
    EndIf

    If _lGrava
        RecLock("ZZ0",_lGrava)
        ZZ0->ZZ0_FILIAL := xFilial("ZZ0")
        ZZ0->ZZ0_ID     := ::cIdProc
        ZZ0->ZZ0_CHAVE  := ::cChave
        ZZ0->ZZ0_SEQ    := ::cSeqZZ0
        ZZ0->ZZ0_DTINC  := Date()
        ZZ0->ZZ0_HRINC  := Time()
        ZZ0->ZZ0_JSON   := ::cJSon
        ZZ0->ZZ0_DTPINI := Nil
        ZZ0->ZZ0_HRPINI := ""
        ZZ0->ZZ0_DTPFIM := Nil 
        ZZ0->ZZ0_HRPFIM := ""
        ZZ0->ZZ0_STPROC := ::cStatus
        ZZ0->ZZ0_TENTAT := ::nTentativa
        ZZ0->ZZ0_QTDREG := ::nQtdReg
        ZZ0->ZZ0_ERPFUN := ::cFunName
        ZZ0->ZZ0_FAZEND := ::cFazenda
        ZZ0->( MsUnLock() )
    Else 
        RecLock("ZZ0",_lGrava)
        ZZ0->ZZ0_DTPINI := Date()
        ZZ0->ZZ0_HRPINI := Time()
        ZZ0->ZZ0_DTPFIM := Date()
        ZZ0->ZZ0_HRPFIM := Time()
        ZZ0->ZZ0_STPROC := ::cStatus
        ZZ0->ZZ0_TENTAT := ::nTentativa //Tanimoto 21/12/2020. Inclui para atualizar o numero de tentaivas
        ZZ0->( MsUnLock() )
    EndIf

    RestArea(_aArea)
Return _lRet 

/****************************************************************************************
    {Protheus.doc} GrvHistorico 
    @description Realiza a gravação historico de processamento
    @type  Function
****************************************************************************************/
Method GrvHistorico() Class mbMonitor

    Local _aArea    := GetArea()
    Local _lRet     := .T.

    dbSelectArea("ZZ1")             // Seleciona tabela monitor |
    ZZ1->( dbSetOrder(1) )

    ::nTpRet    := 2
    ::ValidZZ0()        // Retorna sequencia ZZ0 |

    ::nTpRet    := 1
    ::ValidZZ1()       // Valida sequencia ZZ1 |

    RecLock("ZZ1",.T.)
    ZZ1->ZZ1_FILIAL := xFilial("ZZ1")
    ZZ1->ZZ1_ID     := ::cIdProc
    ZZ1->ZZ1_CHAVE  := ::cChave
    ZZ1->ZZ1_ZZ0SEQ := ::cSeqZZ0
    ZZ1->ZZ1_SEQ    := ::cSeq
    ZZ1->ZZ1_DTHIST := Date()
    ZZ1->ZZ1_HRHIST := Time()
    ZZ1->ZZ1_JSON   := ::cJSon
    ZZ1->ZZ1_ERRO   := ::cError
    ZZ1->( MsUnLock() )

    RestArea(_aArea)

Return _lRet
