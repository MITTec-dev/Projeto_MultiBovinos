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
    Method PutCadastros()

EndClass

/****************************************************************************************
    {Protheus.doc} New
    @description Metodo construtor da Classe 
****************************************************************************************/
Method New() Class MultiBovinos
    Local cEnvProd := SuperGETMV("MB_XMBENVP",.F.,"CMPKQ0_PROD,CMPKQ0_COMP") //nome dos ambientes de produção
    Local cEnvTest := SuperGETMV("MB_XMBENVT",.F.,"CMPKQ0_DEV2,CMPKQ0_DEV") //nome dos ambientes de testes,desenv
    Local cEnvExec := Upper(Alltrim(GetEnvServer())) //variável de ambiente para identificar ambiente atual, exemplo: TESTE, DESENV, PRODUCAO, etc.

    If cEnvExec $ cEnvProd 
        ::cURL          := GetNewPar("MB_XMBURLP","https://www.multbovinos.com/servicos")
        ::cUser         := GetNewPar("MB_XMBCLIP","integracao.default@multbovinos.com.br")
        ::cPassword     := GetNewPar("MB_XMBPASP","integracao@Mbweb")
    ElseIf cEnvExec $ cEnvTest
        ::cURL          := GetNewPar("MB_XMBURLT","https://teste.multbovinos.com/servicos")
        ::cUser         := GetNewPar("MB_XMBCLIT","integracao.default@multbovinos.com.br")
        ::cPassword     := GetNewPar("MB_XMBPAST","testeintegracao@Mbweb")
    EndIf

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
    https://terminaldeinformacao.com/2024/02/24/formatando-data-e-hora-com-a-fwtimestamp-maratona-advpl-e-tl-255/
****************************************************************************************/
Method Token() Class MultiBovinos
    Local _lRet   := .T.
    Local _lToken := .F.
    Local bObject := {|| JsonObject():New()}
    Local oJson   := Eval(bObject)
    Local aToken  := StrTokArr(SuperGetMV("MB_XMBTOKE",.F.,""),";")//Grava token,aaaammddhhmmss - para reutilização do token enquanto estiver válido, evitando consultas desnecessárias para obtenção de token. O formato da data é utilizado para comparação e validação da validade do token, que tem duração de 24 horas. Tanimoto 20220509
    Local cPrefixo:= Alltrim(SuperGetMV("MB_PFTOKEN",.F.,"JWT")) //Utilizado para validar se o token gravado é realmente um token ou se é uma string vazia, evitando erros de comparação de data quando a variável estiver vazia. Tanimoto 20220509
    
    ::GetSSLCache()

    If Len(aToken)=2    //Tem token gravado, verifica validade do token para reutilização, evitando consultas desnecessárias para obtenção de token. Tanimoto 20220509
        _lToken := Alltrim(FWTimeStamp(1,dDatabase,Time()))>=Alltrim(aToken[2])
    ElseIf Len(aToken)=1    //Nao tem toke gravado
        _lToken := Empty(aToken[1]) 
    EndIf

    // Consulta novo Token |
    If _lToken
        oJson["email"]    := Alltrim(::cUser)
        oJson["password"] := Alltrim(::cPassword)
        ::cJSonToken := oJson:ToJson()
        ::aHeadOut  := {}
        aAdd(::aHeadOut,"Content-Type: application/json" )          // Array contendo parametros de cabeçalho |
        aAdd(::aHeadOut,"Dispositivo: 8" )
        aAdd(::aHeadOut,'User-Agent: Mozilla/5.0 (compatible; Protheus '+GetBuild()+')')    //Adiciona user agente. Obrigatorio a partir de 01/06/2022. Tanimoto 20220509
        ::oRest   := FWRest():New(RTrim(::cURL))                    // Instancia classe FwRest |
        ::oRest:nTimeOut := 600                                     // TimeOut do processo |
        ::oRest:SetPath("/login-integracao/")                       // Metodo a ser enviado | 
        ::oRest:SetPostParams(::cJSonToken)                         // Parametros de Envio |
        If ::oRest:Post(::aHeadOut)                                 // Utiliza metodo POST |
            ::cJSonRet := RTrim(::oRest:GetResult())               // Desesserializa JSON |
            ::oJsonRet := oJson:FromJson(::cJSonRet)
            ::cToken   := cPrefixo+" "+Rtrim(oJson:GetJsonObject("token"))
            PutMV("MB_XMBTOKE",::cToken +";"+ Alltrim(FWTimeStamp(1,dDatabase+1,Time()))) //Grava token com data de validade de 24 horas para reutilização, evitando consultas desnecessárias para obtenção de token.
            _lRet      := .T.
        Else
            ::cError    := "Erro ao validar token. Error " + ::oRest:GetLastError()         // Desesserializa JSON |
            _lRet       := .F.
        EndIf
    Else
        ::cToken := aToken[1] //Utiliza token gravado anteriormente enquanto estiver válido para evitar consultas desnecessárias para obtenção de token.
        _lRet := .T.
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
        aAdd(::aHeadOut,"Dispositivo: 8" )
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
            ::cError    := RTrim(::oRest:GetResult())   
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
    aAdd(::aHeadOut,"Dispositivo: 8" )
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
        ::cError    := "Erro Post: " + ::oRest:GetResult()    //::oRest:GetLastError() // Desesserializa JSON |
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
    aAdd(::aHeadOut,"Dispositivo: 8" )
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
        ::cError    := "Erro Get: " + ::oRest:GetResult()    //::oRest:GetLastError() // Desesserializa JSON |
        _lRet       := .F.
    EndIf

    ::ClearObj(::oRest)             // Limpa Objeto |

Return _lRet 

/****************************************************************************************
    {Protheus.doc} PutCadastros
    @description Metodo para consumir end-poit de cadastros geral
****************************************************************************************/
Method PutCadastros() Class MultiBovinos 
    Local _lRet     := .T.
    Local oJson     := Nil

    If Empty(::cToken)
        _lRet := ::Token()                           // Retorna token conexão |
    EndIf

    // Array contendo parametros de cabeçalho |
    ::aHeadOut  := {}
    aAdd(::aHeadOut,"Content-Type: application/json" )
    aAdd(::aHeadOut,"Dispositivo: 8" )
    aAdd(::aHeadOut,"Authorization: " + ::cToken)
    aAdd(::aHeadOut,'User-Agent: Mozilla/5.0 (compatible; Protheus '+GetBuild()+')')    //Adiciona user agente. Obrigatorio a partir de 01/06/2022. Tanimoto 20220509

    ::oRest   := FWRest():New(RTrim(::cURL))        // Instancia classe FwRest |
    ::oRest:nTimeOut := 600                         // TimeOut do processo |
    ::oRest:SetPath(::cPath)                        // Metodo a ser enviado | 
    ::oRest:SetPostParams(::cBody)                  // Parametros de Envio | body da requisição

    If ::oRest:Put(::aHeadOut)                     // Utiliza metodo PUT |
        ::cJSonRet := RTrim(::oRest:GetResult())   // Desesserializa JSON |
        oJson := JsonObject():New()
        oJson:FromJson(::cJSonRet)
        ::cID := oJson:GetJsonObject(::cRet)   // Recupera o ID do cadastro criado/atualizado para retorno, caso haja necessidade de criar outras integrações relacionadas ao mesmo cadastro, como por exemplo, envio de endereço ou contato relacionado a um cadastro de cliente ou fornecedor.
        FreeObj(oJson)
        _lRet      := .T.
    Else
        ::cError    := "Erro Put: " + ::oRest:GetResult()    //::oRest:GetLastError() // Desesserializa JSON |
        _lRet       := .F.
    EndIf

    ::ClearObj(::oRest)             // Limpa Objeto |

Return _lRet 
