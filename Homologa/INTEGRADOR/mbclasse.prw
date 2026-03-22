#INCLUDE "PROTHEUS.CH"
#INCLUDE "AARRAY.CH"
#INCLUDE "JSON.CH"

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
    //Data cDirToken      As String
    //Data cFileToken     As String
    Data cJSonRet       As String
    Data cJSon          As String
    Data cJSonToken     As String
    Data cToken         As String
    Data cError         As String
    Data cPropri   As String       //Codigo da propriedade para consulta de integrações (Ex: Grupo_Empresa_Filial, Cargo, etc)
    Data cPassCert	    As String
	Data cCertPath	    As String
	Data cKeyPath		As String
	Data cCACertPath	As String

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
    Data oJsonToken     As Object
    Data oJsonRet       As Object

    Method New() Constructor
    Method ClearObj()
    Method GetSSLCache()
    Method Token() 
    Method SetPropriedade(cPropri)
    Method AssignUserToGroup()
    Method RemoveUserfromGroup()
    Method DeleteUserByIdentifier()
    Method AssignProfileOfUser()
    Method RemoveProfileOfUser()
    Method UpdateUserStatus()

EndClass

/****************************************************************************************
    {Protheus.doc} New
    @description Metodo construtor da Classe 
****************************************************************************************/
Method New() Class MultiBovinos
    
    ::cURL          := GetNewPar("MB_XMBURLP","https://www.multbovinos.com/servicos/,https://teste.multbovinos.com/servicos/")
    ::cUser         := GetNewPar("MB_XMBCLIE","integracao.default@multbovinos.com.br")
    ::cPassword     := GetNewPar("MB_XMBPASS","testeintegracao@Mbweb")
    //::cDirToken     := GetNewPar("BZ_DIRENAB","\MultiBovinos_token\")
    //::cFileToken    := GetNewPar("BZ_ARQENAB","MultiBovinos_token")
    ::cJSonRet      := ""
    ::cJSon         := ""
    ::cJSonToken    := ""
    ::cToken        := ""
    ::cError        := ""
    ::cPassCert	    := ""
	::cCertPath	    := "" 
	::cKeyPath		:= "" 
	::cCACertPath	:= ""

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
    ::oJsonToken    := Nil 
    ::oJsonRet      := Nil 

Return Nil 

/****************************************************************************************
    {Protheus.doc} GetSSLCache
    @description Define o uso em memoria da configuração SSL para integrações SIGEP
****************************************************************************************/
Method GetSSLCache() Class MultiBovinos
Local _lRet 	:= .F.

//-------------------------------------+
// Utiliza configurações SSL via Cache |
//-------------------------------------+
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
//Local _cLine    := ""
Local _lRet     := .T.
Local _lToken   := .T.
//Local _nLine    := 0
//----------------+
// Cria diretorio | 
//----------------+
//MakeDir(::cDirToken)
//--------------------+
// Usa SSL temporario | 
//--------------------+
::GetSSLCache()
//-----------------+
// Diretorio Token |
//-----------------+
/*
If File(::cDirToken + ::cFileToken + ".json")
    _cLine := Alltrim(MemoRead( ::cDirToken + ::cFileToken + ".json" ))
    _nLine := MLCount( _cLine )
    ::cJSonToken := ""
    For _nX := 1 To _nLine
        ::cJSonToken += MemoLine( _cLine, , _nX )
    Next _nX
    ::oJsonToken := FromJson(::cJSonToken)          // Transforma Objeto em JSON |
    If !Empty(::oJsonToken[#"access_token"]) .And. ( Left(Time(),5) > SubStr(::oJsonToken[#"expires_in"],12,5)  .Or. Date() > sTod(StrTran(SubStr(::oJsonToken[#"expires_in"],1,10),"-","")))
        _lToken     := .T.
        ::ClearObj(::oJsonToken)                    // Limpa Objeto |
    Else
        ::cToken    := RTrim(::oJsonToken[#"access_token"])
        _lToken     := .F.
    EndIf
EndIf
*/
// Consulta novo Token |
If _lToken
    ::cJSonToken := "clientKey=" + ::cUser + "&secret=" + ::cPassword
    ::aHeadOut  := {}
    aAdd(::aHeadOut,"Content-Type: application/json" )      // Array contendo parametros de cabeçalho |
    aAdd(::aHeadOut,'User-Agent: Mozilla/5.0 (compatible; Protheus '+GetBuild()+')')    //Adiciona user agente. Obrigatorio a partir de 01/06/2022. Tanimoto 20220509

    ::oRest   := FWRest():New(RTrim(::cURL))                // Instancia classe FwRest |
    ::oRest:nTimeOut := 600                                 // TimeOut do processo |
    ::oRest:SetPath("/api/v1/token"+ "?" + ::cJSonToken)    // Metodo a ser enviado | 
    ::oRest:SetPostParams(::cJSonToken)                     // Parametros de Envio |
    If ::oRest:Post(::aHeadOut)                             // Utiliza metodo POST |
        ::cJSonRet	:= RTrim(::oRest:GetResult())           // Desesserializa JSON |
        ::oJsonRet  := FromJson(::cJSonRet)
        ::cToken    := RTrim(::oJsonRet[#"access_token"])
        /*
        _cTimeIni := Time()
        _cTimeFim := IncTime( Time() , 0 , 0 , Val(::oJsonRet[#"expires_in"]))
        _cExpire := FWTimeStamp(3,Date(),Time()+Val(::oJsonRet[#"expires_in"])) //Fotmato UTC aaaa-mm-ddThh:mm:ss (Soment pega a hora local e coloca neste formato)
        ::oJsonRet[#"expires_in"] := _cExpire   //Grava a data e hora final de validade do TOKEN para consulta futura da validade
        MemoWrite(::cDirToken + ::cFileToken + ".json",::cJSonRet)                      // Grava JSON Token |
        */
        _lRet       := .T.
    Else
        ::cError    := "Erro ao validar token. Error " + ::oRest:GetLastError()         // Desesserializa JSON |
        _lRet       := .F.
    EndIf
EndIf

// Limpa Objeto |
::ClearObj(::oJsonToken)
::ClearObj(::oJsonRet)
::ClearObj(::oRest)

Return _lRet 

/****************************************************************************************
    {Protheus.doc} CreateUpdateUser (2.6.2)
    @description Metodo para criar ou atualizar usuarios (funcionario) 
****************************************************************************************/
Method SetPropriedade(cPropri) Class MultiBovinos 
Local _lRet     := .T.

::Token()                           // Retorna token conexão | 

// Array contendo parametros de cabeçalho |
::aHeadOut  := {}
aAdd(::aHeadOut,"Content-Type: application/json" )
aAdd(::aHeadOut,"Authorization: Bearer " + ::cToken)
aAdd(::aHeadOut,'User-Agent: Mozilla/5.0 (compatible; Protheus '+GetBuild()+')')    //Adiciona user agente. Obrigatorio a partir de 01/06/2022. Tanimoto 20220509

::oRest   := FWRest():New(RTrim(::cURL))        // Instancia classe FwRest |
::oRest:nTimeOut := 600                         // TimeOut do processo |
::oRest:SetPath("/api/v2/users")                // Metodo a ser enviado | 
//::oRest:SetPostParams(::cJSon)                  // Parametros de Envio |

If ::oRest:Put(::aHeadOut,::cJSon)              // Utiliza metodo POST |
    ::cJSonRet	:= RTrim(::oRest:GetResult())   // Desesserializa JSON |
    _lRet       := .T.
Else
    ::cError    := RTrim(::oRest:GetResult())   //"Erro ao obter integracoes. Error " + ::oRest:GetLastError() // Desesserializa JSON |
    _lRet       := .F.
EndIf

::ClearObj(::oRest)             // Limpa Objeto |
/*{
  "message": "Created successfully",
  "id": "24677386803"
}*/
Return _lRet 

/****************************************************************************************
    {Protheus.doc} AssignUserToGroup (2.3.3)
    @description Metodo para associar o usuario de um grupo (Grupo_Empresa_filial) 
****************************************************************************************/
Method AssignUserToGroup() Class MultiBovinos 
Local _lRet     := .T.

::Token()                           // Retorna token conexão | 

// Array contendo parametros de cabeçalho |
::aHeadOut  := {}
aAdd(::aHeadOut,"Content-Type: application/json" )
aAdd(::aHeadOut,"Authorization: Bearer " + ::cToken)
aAdd(::aHeadOut,'User-Agent: Mozilla/5.0 (compatible; Protheus '+GetBuild()+')')    //Adiciona user agente. Obrigatorio a partir de 01/06/2022. Tanimoto 20220509

::oRest   := FWRest():New(RTrim(::cURL))        // Instancia classe FwRest |
::oRest:nTimeOut := 600                         // TimeOut do processo |
::oRest:SetPath("/api/v1/groups" + ::cJSon)         // Metodo a ser enviado | 
//::oRest:SetPostParams(::cJSon)                  // Parametros de Envio |

If ::oRest:Post(::aHeadOut)                     // Utiliza metodo POST |
    ::cJSonRet	:= RTrim(::oRest:GetResult())   // Desesserializa JSON |
    _lRet       := .T.
Else
    ::cError    := "Erro ao obter integracoes. Error " + ::oRest:GetLastError() // Desesserializa JSON |
    _lRet       := .F.
EndIf

::ClearObj(::oRest)             // Limpa Objeto |

Return _lRet 

/****************************************************************************************
    {Protheus.doc} RemoveUserfromGroup (2.3.4)
    @description Metodo para remover o usuario de um grupo (Grupo_Empresa_filial) 
****************************************************************************************/
Method RemoveUserfromGroup() Class MultiBovinos 
Local _lRet     := .T.

::Token()                           // Retorna token conexão | 

// Array contendo parametros de cabeçalho |
::aHeadOut  := {}
aAdd(::aHeadOut,"Content-Type: application/json" )
aAdd(::aHeadOut,"Authorization: Bearer " + ::cToken)
aAdd(::aHeadOut,'User-Agent: Mozilla/5.0 (compatible; Protheus '+GetBuild()+')')    //Adiciona user agente. Obrigatorio a partir de 01/06/2022. Tanimoto 20220509

::oRest   := FWRest():New(RTrim(::cURL))        // Instancia classe FwRest |
::oRest:nTimeOut := 600                         // TimeOut do processo |
::oRest:SetPath("/api/v1/groups" + ::cJSon)         // Metodo a ser enviado | 
//::oRest:SetPostParams(::cJSon)                  // Parametros de Envio |

If ::oRest:Delete(::aHeadOut)                     // Utiliza metodo POST |
    ::cJSonRet	:= RTrim(::oRest:GetResult())   // Desesserializa JSON |
    _lRet       := .T.
Else
    ::cError    := "Erro ao obter integracoes. Error " + ::oRest:GetLastError() // Desesserializa JSON |
    _lRet       := .F.
EndIf

::ClearObj(::oRest)             // Limpa Objeto |

Return _lRet 

/****************************************************************************************
    {Protheus.doc} DeleteUserByIdentifier (2.6.10)
    @description Metodo para deletar usuarios pelo ID
****************************************************************************************/
Method DeleteUserByIdentifier() Class MultiBovinos 
Local _lRet     := .T.

::Token()                           // Retorna token conexão | 

// Array contendo parametros de cabeçalho |
::aHeadOut  := {}
aAdd(::aHeadOut,"Content-Type: application/json" )
aAdd(::aHeadOut,"Authorization: Bearer " + ::cToken)
aAdd(::aHeadOut,'User-Agent: Mozilla/5.0 (compatible; Protheus '+GetBuild()+')')    //Adiciona user agente. Obrigatorio a partir de 01/06/2022. Tanimoto 20220509

::oRest   := FWRest():New(RTrim(::cURL))        // Instancia classe FwRest |
::oRest:nTimeOut := 600                         // TimeOut do processo |
::oRest:SetPath("/api/v2/users" + ::cJSon)         // Metodo a ser enviado | 
//::oRest:SetPostParams(::cJSon)                  // Parametros de Envio |

If ::oRest:Delete(::aHeadOut)                     // Utiliza metodo POST |
    ::cJSonRet	:= RTrim(::oRest:GetResult())   // Desesserializa JSON |
    _lRet       := .T.
Else
    ::cError    := "Erro ao obter integracoes. Error " + ::oRest:GetLastError() // Desesserializa JSON |
    _lRet       := .F.
EndIf

::ClearObj(::oRest)             // Limpa Objeto |

Return _lRet 

/****************************************************************************************
    {Protheus.doc} AssignProfileOfUser (2.5.4)
    @description Metodo para associar o usuario a um cargo (profile)
****************************************************************************************/
Method AssignProfileOfUser() Class MultiBovinos 
Local _lRet     := .T.

::Token()                           // Retorna token conexão | 

// Array contendo parametros de cabeçalho |
::aHeadOut  := {}
aAdd(::aHeadOut,"Content-Type: application/json" )
aAdd(::aHeadOut,"Authorization: Bearer " + ::cToken)
aAdd(::aHeadOut,'User-Agent: Mozilla/5.0 (compatible; Protheus '+GetBuild()+')')    //Adiciona user agente. Obrigatorio a partir de 01/06/2022. Tanimoto 20220509

::oRest   := FWRest():New(RTrim(::cURL))        // Instancia classe FwRest |
::oRest:nTimeOut := 600                         // TimeOut do processo |
::oRest:SetPath("/api/v2/userProfiles" + ::cJSon)         // Metodo a ser enviado | 
//::oRest:SetPostParams(::cJSon)                  // Parametros de Envio |

If ::oRest:Put(::aHeadOut)                     // Utiliza metodo POST |
    ::cJSonRet	:= RTrim(::oRest:GetResult())   // Desesserializa JSON |
    _lRet       := .T.
Else
    ::cError    := "Erro ao obter integracoes. Error " + ::oRest:GetLastError() // Desesserializa JSON |
    _lRet       := .F.
EndIf

::ClearObj(::oRest)             // Limpa Objeto |

Return _lRet 

/****************************************************************************************
    {Protheus.doc} RemoteProfileOfUser (2.5.5)
    @description Metodo para remover o usuario a um cargo (profile)
****************************************************************************************/
Method RemoveProfileOfUser() Class MultiBovinos 
Local _lRet     := .T.

::Token()                           // Retorna token conexão | 

// Array contendo parametros de cabeçalho |
::aHeadOut  := {}
aAdd(::aHeadOut,"Content-Type: application/json" )
aAdd(::aHeadOut,"Authorization: Bearer " + ::cToken)
aAdd(::aHeadOut,'User-Agent: Mozilla/5.0 (compatible; Protheus '+GetBuild()+')')    //Adiciona user agente. Obrigatorio a partir de 01/06/2022. Tanimoto 20220509

::oRest   := FWRest():New(RTrim(::cURL))        // Instancia classe FwRest |
::oRest:nTimeOut := 600                         // TimeOut do processo |
::oRest:SetPath("/api/v2/userProfiles" + ::cJSon)         // Metodo a ser enviado | 
//::oRest:SetPostParams(::cJSon)                  // Parametros de Envio |

If ::oRest:Delete(::aHeadOut)                     // Utiliza metodo POST |
    ::cJSonRet	:= RTrim(::oRest:GetResult())   // Desesserializa JSON |
    _lRet       := .T.
Else
    ::cError    := "Erro ao obter integracoes. Error " + ::oRest:GetLastError() // Desesserializa JSON |
    _lRet       := .F.
EndIf

::ClearObj(::oRest)             // Limpa Objeto |

Return _lRet 

/****************************************************************************************
    {Protheus.doc} UpdateUserStatus (2.6.9)
    @description Metodo para atualizar o status do funcionario false=desligado
****************************************************************************************/
Method UpdateUserStatus() Class MultiBovinos 
Local _lRet     := .T.

::Token()                           // Retorna token conexão | 

// Array contendo parametros de cabeçalho |
::aHeadOut  := {}
aAdd(::aHeadOut,"Content-Type: application/json" )
aAdd(::aHeadOut,"Authorization: Bearer " + ::cToken)
aAdd(::aHeadOut,'User-Agent: Mozilla/5.0 (compatible; Protheus '+GetBuild()+')')    //Adiciona user agente. Obrigatorio a partir de 01/06/2022. Tanimoto 20220509

::oRest   := FWRest():New(RTrim(::cURL))        // Instancia classe FwRest |
::oRest:nTimeOut := 600                         // TimeOut do processo |
::oRest:SetPath("/api/v2/users" + ::cJSon)         // Metodo a ser enviado | 
//::oRest:SetPostParams(::cJSon)                  // Parametros de Envio |

If ::oRest:Put(::aHeadOut)                     // Utiliza metodo POST |
    ::cJSonRet	:= RTrim(::oRest:GetResult())   // Desesserializa JSON |
    _lRet       := .T.
Else
    ::cError    := "Erro ao obter integracoes. Error " + ::oRest:GetLastError() // Desesserializa JSON |
    _lRet       := .F.
EndIf

::ClearObj(::oRest)             // Limpa Objeto |

Return _lRet 
