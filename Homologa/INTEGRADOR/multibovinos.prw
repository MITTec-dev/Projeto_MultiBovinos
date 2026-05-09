#INCLUDE "PROTHEUS.CH"

#DEFINE CRLF CHR(13) + CHR(10)

/****************************************************************************************
    {Protheus.doc} MultiBovinos
    @description Classe correspondente as integrações com MULTIBOVINOS, utilizando as APIs 
    disponibilizadas pela empresa.
     - Documentação API: https://docs.timetoknow.apiary.io/#reference/authentication
     - Base URL: https://api.prod.timetoknow.com
    @author    Michihiko Tanimoto
    @since     17/03/2026
****************************************************************************************/
Class MultiBovinos
    Data cURL           As String
    Data cUser          As String
    Data cPassword      As String
    Data cJSonRet       As String
    Data cBody          As String
    Data cPath          As String
    Data cJSonToken     As String
    Data cToken         As String
    Data cError         As String
    Data cPropriedade   As String       //Codigo da propriedade para consulta de integrações (Ex: Grupo_Empresa_Filial, Cargo, etc)
    Data cPassCert	    As String
	Data cCertPath	    As String
	Data cKeyPath		As String
	Data cCACertPath	As String
    Data cID            As String
    Data cRet           As String

    Data nSSL2		    As Integer
	Data nSSL3		    As Integer
	Data nTLS1		    As Integer
	Data nHSM		    As Integer
	Data nVerbose	    As Integer
	Data nBugs		    As Integer
	Data nState	        As Integer

    Data aHeadOut       As Array

    Data oRest          As Object 
    Data oJson          As Object
    Data oJsonRet       As Object

    Method New() Constructor
    Method ClearObj()
    Method GetSSLCache()
    Method Token()
    Method SetPropriedade()
    Method PostCadastros()
    Method GetCadastros()

EndClass

/****************************************************************************************
    {Protheus.doc} New
    @description Metodo construtor da Classe 
****************************************************************************************/
Method New() Class MultiBovinos
    
    ::cURL          := GetNewPar("MB_XMBURLP","https://teste.multbovinos.com/servicos")    //https://www.multbovinos.com/servicos,
    ::cUser         := GetNewPar("MB_XMBCLIE","integracao.default@multbovinos.com.br")
    ::cPassword     := GetNewPar("MB_XMBPASS","testeintegracao@Mbweb")
    //::cDirToken     := GetNewPar("BZ_DIRENAB","\MultiBovinos_token\")
    //::cFileToken    := GetNewPar("BZ_ARQENAB","MultiBovinos_token")
    ::cJSonRet      := ""
    ::cBody         := ""
    ::cPath         := ""
    ::cJSonToken    := ""
    ::cToken        := ""
    ::cError        := ""
    ::cPassCert	    := ""
	::cCertPath	    := "" 
	::cKeyPath		:= "" 
	::cCACertPath	:= ""
    ::cID           := ""
    ::cRet          := "" 

    ::nSSL2		    := 0
	::nSSL3		    := 0
	::nTLS1		    := 3
	::nHSM			:= 0
	::nVerbose		:= 1
	::nBugs		    := 1
	::nState	    := 1
    ::aHeadOut      := {}
    ::oRest         := Nil
    ::oJson         := Nil
    ::oJsonRet      := Nil 

Return Nil 

/****************************************************************************************
    {Protheus.doc} GetSSLCache
    @description Define o uso em memoria da configuração SSL para integrações SIGEP
****************************************************************************************/
Method GetSSLCache() Class MultiBovinos
    Local _lRet 	:= .F.

    // Utiliza configurações SSL via Cache |
    If HTTPSSLClient( ::nSSL2, ::nSSL3, ::nTLS1, ::cPassCert, ::cCertPath, ::cKeyPath, ::nHSM, .F. , ::nVerbose, ::nBugs, ::nState)
    	CoNout("<< GETSSLCACHE >> - INICIADO COM SUCESSO.")
    	_lRet := .T.
    EndIf

Return _lRet 

/*********************************************************************************
    {Protheus.doc} ClearObj
    @description Método limpa objeto
********************************************************************************/
Method ClearObj(_oObj) Class MultiBovinos
Return FreeObj(_oObj)

/****************************************************************************************
    {Protheus.doc} Token
    @description Metodo obtem Token para integraçao MultiBovinos 
****************************************************************************************/
Method Token() Class MultiBovinos

    Local _lRet   := .T.
    Local _lToken := .T.
    Local bObject := {|| JsonObject():New()}
    Local oJson   := Eval(bObject)
    
    ::GetSSLCache()
    
    // Consulta novo Token |
    If _lToken
        oJson["email"]    := Alltrim(::cUser)
        oJson["password"] := Alltrim(::cPassword)
        ::cJSonToken := oJson:ToJson()
        ::aHeadOut  := {}
        aAdd(::aHeadOut,"Content-Type: application/json" )          // Array contendo parametros de cabeçalho |
        aAdd(::aHeadOut,'User-Agent: Mozilla/5.0 (compatible; Protheus '+GetBuild()+')')    //Adiciona user agente. Obrigatorio a partir de 01/06/2022. Tanimoto 20220509
        ::oRest   := FWRest():New(RTrim(::cURL))                    // Instancia classe FwRest |
        ::oRest:nTimeOut := 600                                     // TimeOut do processo |
        ::oRest:SetPath("/login-integracao/")                       // Metodo a ser enviado | 
        ::oRest:SetPostParams(::cJSonToken)                         // Parametros de Envio |
        If ::oRest:Post(::aHeadOut)                                 // Utiliza metodo POST |
            ::cJSonRet := RTrim(::oRest:GetResult())               // Desesserializa JSON |
            ::oJsonRet := oJson:FromJson(::cJSonRet)
            ::cToken   := "JWT "+Rtrim(oJson:GetJsonObject("token"))
            _lRet      := .T.
        Else
            ::cError    := "Erro ao validar token. Error " + ::oRest:GetLastError()         // Desesserializa JSON |
            _lRet       := .F.
        EndIf
    EndIf
    
    // Limpa Objeto |
    ::ClearObj(oJson)
    ::ClearObj(::oJsonRet)
    ::ClearObj(::oRest)

Return _lRet 

/****************************************************************************************
    {Protheus.doc} CreateUpdateUser (2.6.2)
    @description Metodo para criar ou atualizar usuarios (funcionario) 
****************************************************************************************/
Method SetPropriedade() Class MultiBovinos 
    Local _lRet     := .T.

    If Empty(::cToken)
        _lRet := ::Token()                           // Retorna token conexão |
    EndIf

    If _lRet
        // Array contendo parametros de cabeçalho |
        ::aHeadOut  := {}
        aAdd(::aHeadOut,"Content-Type: application/json" )
        aAdd(::aHeadOut,"Authorization: " + ::cToken)
        aAdd(::aHeadOut,'User-Agent: Mozilla/5.0 (compatible; Protheus '+GetBuild()+')')    //Adiciona user agente. Obrigatorio a partir de 01/06/2022. Tanimoto 20220509
    
        ::oRest   := FWRest():New(RTrim(::cURL))        // Instancia classe FwRest |
        ::oRest:nTimeOut := 600                         // TimeOut do processo |
        ::oRest:SetPath(::cBody+::cPath)                        // Metodo a ser enviado | 
        //::oRest:SetPostParams(::cJSon)                // Parametros de Envio |
    
        If ::oRest:Post(::aHeadOut)     // Utiliza metodo POST |
            ::cJSonRet := RTrim(::oRest:GetResult())   // Desesserializa JSON |
            //::oJsonRet := oJson:FromJson(::cJSonRet)
            //::cID      := Rtrim(oJson:GetJsonObject(::cRet))
            _lRet      := .T.
        Else
            ::cError    := RTrim(::oRest:GetResult())   //"Erro ao obter integracoes. Error " + ::oRest:GetLastError() // Desesserializa JSON |
            _lRet       := .F.
        EndIf
    
        ::ClearObj(::oRest)             // Limpa Objeto |
    EndIf

Return _lRet 

/****************************************************************************************
    {Protheus.doc} PostCadastros
    @description Metodo para consumir end-poit de cadastros geral
****************************************************************************************/
Method PostCadastros() Class MultiBovinos 
    Local _lRet     := .T.
    Local oJson     := Nil

    If Empty(::cToken)
        _lRet := ::Token()                           // Retorna token conexão |
    EndIf

    // Array contendo parametros de cabeçalho |
    ::aHeadOut  := {}
    aAdd(::aHeadOut,"Content-Type: application/json" )
    aAdd(::aHeadOut,"Authorization: " + ::cToken)
    aAdd(::aHeadOut,'User-Agent: Mozilla/5.0 (compatible; Protheus '+GetBuild()+')')    //Adiciona user agente. Obrigatorio a partir de 01/06/2022. Tanimoto 20220509

    ::oRest   := FWRest():New(RTrim(::cURL))        // Instancia classe FwRest |
    ::oRest:nTimeOut := 600                         // TimeOut do processo |
    ::oRest:SetPath(::cPath)              // Metodo a ser enviado | 
    ::oRest:SetPostParams(::cBody)                  // Parametros de Envio | body da requisição

    If ::oRest:Post(::aHeadOut)                     // Utiliza metodo POST |
        ::cJSonRet := RTrim(::oRest:GetResult())   // Desesserializa JSON |
        oJson := JsonObject():New()
        oJson:FromJson(::cJSonRet)
        ::cID := oJson:GetJsonObject(::cRet)   // Recupera o ID do cadastro criado/atualizado para retorno, caso haja necessidade de criar outras integrações relacionadas ao mesmo cadastro, como por exemplo, envio de endereço ou contato relacionado a um cadastro de cliente ou fornecedor.
        FreeObj(oJson)
        _lRet      := .T.
    Else
        ::cError    := "Erro ao obter integracoes. Error " + ::oRest:GetResult()    //::oRest:GetLastError() // Desesserializa JSON |
        _lRet       := .F.
    EndIf

    ::ClearObj(::oRest)             // Limpa Objeto |

Return _lRet 


/****************************************************************************************
    {Protheus.doc} GetCadastros
    @description Metodo para consumir end-poit de cadastros geral
****************************************************************************************/
Method GetCadastros() Class MultiBovinos 
    Local _lRet     := .T.
    //Local oJson     := Nil

    If Empty(::cToken)
        _lRet := ::Token()                           // Retorna token conexão |
    EndIf

    // Array contendo parametros de cabeçalho |
    ::aHeadOut  := {}
    aAdd(::aHeadOut,"Content-Type: application/json" )
    aAdd(::aHeadOut,"Authorization: " + ::cToken)
    aAdd(::aHeadOut,'User-Agent: Mozilla/5.0 (compatible; Protheus '+GetBuild()+')')    //Adiciona user agente. Obrigatorio a partir de 01/06/2022. Tanimoto 20220509

    ::oRest   := FWRest():New(RTrim(::cURL))        // Instancia classe FwRest |
    ::oRest:nTimeOut := 600                         // TimeOut do processo |
    ::oRest:SetPath(::cPath)              // Metodo a ser enviado | 
    //::oRest:SetPostParams(::cBody)                  // Parametros de Envio | body da requisição

    If ::oRest:GET(::aHeadOut)                     // Utiliza metodo GET |
        ::cJSonRet := RTrim(::oRest:GetResult())   // Desesserializa JSON |
        //oJson := JsonObject():New()
        //oJson:FromJson(::cJSonRet)
        //::cID := oJson:GetJsonObject(::cRet)   // Recupera o ID do cadastro criado/atualizado para retorno, caso haja necessidade de criar outras integrações relacionadas ao mesmo cadastro, como por exemplo, envio de endereço ou contato relacionado a um cadastro de cliente ou fornecedor.
        //FreeObj(oJson)
        _lRet      := .T.
    Else
        ::cError    := "Erro ao obter integracoes. Error " + ::oRest:GetResult()    //::oRest:GetLastError() // Desesserializa JSON |
        _lRet       := .F.
    EndIf

    ::ClearObj(::oRest)             // Limpa Objeto |

Return _lRet 

