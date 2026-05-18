#include "totvs.ch"
/*************************************************************************************************************
    mbentanimais.prw - Movimentação Entrada de Animais para integração com Multibovinos. 
    Envia os valores da nota fiscal de entrada dos animais para controle dos custos no MB
    {
    	"documento": "20200824",
        "fornecedor": 955020,
        "fornecedor_frete": 955020,
        "fornecedor_outras_despesas": 955020,
    	"total_animais": 1,
    	"valor_frete": 1,
    	"valor_compra": 1,
    	"valor_outros": 1
    }
*************************************************************************************************************/
User Function mbentanimais()
    Local cQuery := ""
    Local aTabTemp := {}
    Local ln := 0
    Local cIdProc:= ""
    Local cError := ""
    Local cStZZ0 := ""
    Local cChave := ""
    Local cRefer := ""
    Local lRet := .F.
    Local cJson := ""
    Local oMultiBV := MultiBovinos():New()
    Local bObject  := {|| JsonObject():New()}
    Local oJson    := Nil
    Local lLogEmail := SuperGETMV("MV_MBLOGEML",.F.,.F.) //Flag para envio de email em caso de erro na integração, 1 para enviar email e 0 para não enviar.
    Local cFazenda := Alltrim(Posicione("ZZ2",1,cFilAnt,"ZZ2_FAZENDA"))
    Local lIsBlind := IsBlind()
    Local cTESANIMAIS := SuperGETMV("MV_MBTESANI",.F.,"001,002,003") //Lista de TES para entrada de animais, separados por virgula e entre aspas simples, exemplo: 'TES1','TES2','TES3'

    //--------------------------------------------------- SETA PROPRIEDADE PARA INICIAR INTEGRACOES ----------------------------------
    cIdProc:= "0001"     //Seta propriedade
    cRefer := cFilAnt
    oMultiBV:cPath := "selecione-propriedade/"   //Id do usuario para consulta de propriedades disponiveis. Necessario para o envio do produto, caso haja alguma configuração errada, o retorno será falso e não prosseguirá com o envio dos dados.
    oMultiBV:cBody := "usuario/"+cFazenda+"/"
    lRet := oMultiBV:SetPropriedade()
    If lRet 
        cStZZ0 := "1"      //1=Inclui novo processo na ZZ0
        U_MBAtuMnt(cIdProc,cRefer,cJson,cError,cStZZ0,cFazenda)
    Else    //Falha - reenvia
        cStZZ0 := "3"      //3=Retornado falha - reenvia
        U_MBAtuMnt(cIdProc,cRefer,cJson,cError,cStZZ0,cFazenda)
        U_MBGRVHST(cIdProc,cRefer,cJson,cError)
    EndIf
    //--------------------------------------------------- FIM SETA PROPRIEDADE PARA INICIAR INTEGRACOES ----------------------------------

    //--------------------------------------------------- FORNECEDORES ---------------------------------------------------
    cQuery := "SELECT F1_FILIAL 1_FILIAL, F1_DOC 2_DOC, F1_SERIE 3_SERIE, F1_FORNECE 4_FORNECE, F1_LOJA 5_LOJA, A2_XIDMB 6_XIDMB, "  + CRLF
    cQuery := "F1_VALBRUT 7_VALBRUT, F1_VALMERC 8_VALMERC, F1_FRETE 9_FRETE, F1_DESPESA 10_DESPESA, SUM(D1_QUANT) 11_QTDANIMAIS " + CRLF
    cQuery += "FROM "+RetSqlName("SF1")+" SF1 "  + CRLF
    cQuery += "INNER JOIN "+RetSqlName("SA2")+" SA2 ON A2_FILIAL = F1_FILIAL AND A2_COD = F1_FORNECE AND A2_LOJA = F1_LOJA AND SA2.D_E_L_E_T_ = ' ' "  + CRLF
    cQuery += "INNER JOIN "+RetSqlName("SD1")+" SD1 ON D1_FILIAL = F1_FILIAL AND D1_DOC = F1_DOC AND D1_SERIE = F1_SERIE AND D1_FORNECE = F1_FORNECE AND D1_LOJA = F1_LOJA AND SD1.D_E_L_E_T_ = ' ' "  + CRLF
    //INNER JOIN SB1010 SB1 ON B1_FILIAL = F1_FILIAL AND B1_COD = D1_COD AND SB1.D_E_L_E_T_ = ' '  + CRLF
    cQuery += "WHERE SF1.D_E_L_E_T_=' ' "  + CRLF
    cQuery += "AND F1_FILIAL='"+xFilial("SF1")+"' AND A2_XIDMB<>'' AND F1_XIDMB='' "  + CRLF //Busca somente os fornecedores que possuem o campo de integração preenchido, para evitar enviar fornecedores que não estão configurados para integração e gerar erros no processo.
    cQuery += "AND F1_DTDIGIT='"+DtoS(dDatabase)+"' "  + CRLF
    cQuery += "AND D1_TES IN ("+cTESANIMAIS+") "  + CRLF
    cQuery += "GROUP BY F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, A2_XIDMB, F1_LOJA, F1_VALBRUT, F1_VALMERC, F1_FRETE, F1_DESPESA "
    cQuery := ChangeQuery(cQuery)
    TCSqlToArr(cQuery,@aTabtemp)

    For ln := 1 to Len(aTabTemp)
        oJson := Eval(bObject)   //Cria o objeto
        oJson["documento"] := Val(aTabtemp[ln][2])
        oJson["fornecedor"] := Val(aTabtemp[ln][6])
        //oJson["fornecedor_frete"] := Rtrim(aTabtemp[ln][?])
        //oJson["fornecedor_outras_despesas"] := Rtrim(aTabtemp[ln][?])
        oJson["total_animais"]:= Val(aTabtemp[ln][11])
        oJson["valor_frete"] := Val(aTabtemp[ln][9])
        oJson["valor_compra"] := Val(aTabtemp[ln][7])
        oJson["valor_outros"] := Val(aTabtemp[ln][10])
        cJSon := oJson:ToJson()

        oMultiBV:cBody := cJSon
        oMultiBV:cPath := "entrada/"+Alltrim(aTabtemp[ln][2])       //Id do endpoint para envio dos fornecedores
        oMultiBV:cRet  := "id"
        lRet   := oMultiBV:PostCadastros()      //Executa integração e captura retorno para gravar na tabela de monitoramento
        cError := oMultiBV:cError
        cIdProc:= "0009"                        //Entrada Animais
        cChave := aTabtemp[ln][1]+aTabtemp[ln][2]+aTabtemp[ln][3]+aTabtemp[ln][4]+aTabtemp[ln][5]    //Defini como chave o Alias e o conteudo dos campos de indice
        cRefer := "SF1"+cChave
        If lRet //Sucesso, grava o ID no cadastro para não enviar novamente e grava o monitoramento com status de sucesso
            cID := oMultiBV:cID
            dbSelectArea("SF1")
            SF1->(dbSetOrder(1))
            SF1->(dbSeek(cChave))
            If SF1->(Found())
                RecLock("SF1",.F.)
                SF1->F1_XIDMB := cValToChar(cID)   //Marca o registro como enviado, para não enviar novamente
                SF1->(MsUnLock())
            EndIf
            cStZZ0 := "1"      //1=Inclui novo processo na ZZ0
            U_MBAtuMnt(cIdProc,cRefer,cJson,cError,cStZZ0,cFazenda)
        Else    //Falha - reenvia
            cStZZ0 := "1"      ///1=Inclui novo processo na ZZ0; 3=Retornado falha - reenvia
            U_MBAtuMnt(cIdProc,cRefer,cJson,cError,cStZZ0,cFazenda)
            U_MBGRVHST(cIdProc,cRefer,cJson,cError)
        EndIf
        FreeObj(oJson)
    Next

Return

