#include "totvs.ch"
/*************************************************************************************************************
    mbentprodutos.prw - Movimentação Entrada de Produtos para integração com Multibovinos. 
    Envia os valores da nota fiscal de entrada dos produtos para controle dos custos no MB
    {
	"propriedade": 55080,
	"documento": "10",
	"data": "2020-06-24T03:00:00.000Z",
	"forma_pagamento": 2082,
	"contato": 944375,
	"responsavel": 944375,
	"valor_desconto": 10.0,
	"percentual_desconto": 20,
	"conta_imposto": null,
	"valor_imposto": 0,
	"documento_frete": null,
	"valor_frete": 0,
	"fornecedor_frete": null,
	"forma_pagamento_frete": null,
	"valor_total": 50,
	"valor_pagamento": 40,
	"itens": [
		{
			"produto": 275226,
			"quantidade": 2,
			"valor_unitario": 12.5,
			"valor_total": 25,
			"valor_desconto": 2.50,
			"percentual_desconto": 5.00,
			"valor_final": 20,
			"valor_frete": 0.00,
			"observacao": null
		},
		{
			"produto": 275217,
			"quantidade": 2,
			"valor_unitario": 12.5,
			"valor_total": 25,
			"valor_desconto": 2.50,	
			"percentual_desconto": 5.00,
			"valor_final": 20,
			"valor_frete": 0.00,
			"observacao": "teste"
		}
	]
    }
*************************************************************************************************************/
User Function mbentprodutos()
    Local cQuery := ""
    Local aTabTemp := {}
    Local aItens := {}
    Local ln := 0
    Local cIdProc := ""
    Local cError := ""
    Local cStZZ0 := ""
    Local cChave := ""
    Local cRefer := ""
    Local lRet := .F.
    Local cJson := ""
    Local cJsonRet := ""
    Local oMultiBV := MultiBovinos():New()
    Local bObject := {|| JsonObject():New()}
    Local oJson := Nil
    Local oItem := Nil
    Local cQSF1 := GetNextAlias()
    //Local lLogEmail := SuperGETMV("MB_MBLOGEML",.F.,.F.) //Flag para envio de email em caso de erro na integração, 1 para enviar email e 0 para não enviar.
    Local cFazenda := Alltrim(Posicione("ZZ2",1,cFilAnt,"ZZ2_FAZENDA"))
    //Local lIsBlind := IsBlind()
    Local dDataIni := SuperGETMV("MB_XMBDTAIN",.F.,CTOD("01/01/2026"))
    Local dDataFin := dDatabase-(SuperGETMV("MB_XMBQDFIN",.F.,1))
    Local cTESPRODUTOS := FormatIN(SuperGETMV("MB_XMBTESP",.F.,"001,003,022"),",")            //Lista de TES para entrada de produtos, separados por virgula e entre aspas simples, exemplo: 'TES1','TES2','TES3'
    Local cCFOPRODUTOS := FormatIN(SuperGETMV("MB_XMBCFOP",.F.,"1101,2101,1102,2102,1451,2451"),",")    //Lista de CFOP para entrada de produtos, separados por virgula e entre aspas simples, exemplo: 'TES1','TES2','TES3'

    //--------------------------------------------------- SETA PROPRIEDADE PARA INICIAR INTEGRACOES ----------------------------------
    cIdProc:= "0001"
    cRefer := cFilAnt
    oMultiBV:cPath := "selecione-propriedade/"   //Id do usuario para consulta de propriedades disponiveis. Necessario para o envio do produto, caso haja alguma configuração errada, o retorno será falso e não prosseguirá com o envio dos dados.
    oMultiBV:cBody := "usuario/"+cFazenda+"/"
    lRet := oMultiBV:SetPropriedade()
    If lRet
        cJsonRet := oMultiBV:cJsonRet
        cStZZ0 := "1"      //1=Inclui novo processo na ZZ0
        U_MBAtuMnt(cIdProc,cRefer,cJson,cJsonRet,cStZZ0,cFazenda)
    Else
        cStZZ0 := "3"      //3=Retornado falha - reenvia
        U_MBAtuMnt(cIdProc,cRefer,cJson,cError,cStZZ0,cFazenda)
        U_MBGRVHST(cIdProc,cRefer,cJson,cError)
        Return
    EndIf
    //--------------------------------------------------- FIM SETA PROPRIEDADE PARA INICIAR INTEGRACOES ----------------------------------

    //----------- VERIFICA TODOS OS FORNECEDORES E TRANSPORTADORAS QUE POSSUEM ENTRADA DE MATERIAIS ---------------------------
    aTabTemp := {}
    ln := 0
    cQuery := ""
    cQuery += "SELECT SF1.F1_FILIAL FILIAL, SF1.F1_FORNECE FORNECE, SF1.F1_LOJA LOJA " + CRLF
    cQuery += "FROM "+RetSqlName("SF1")+" SF1 " + CRLF
    cQuery += "INNER JOIN "+RetSqlName("SA2")+" SA2 ON A2_FILIAL='"+xFilial("SA2")+"' AND A2_COD=SF1.F1_FORNECE AND A2_LOJA=SF1.F1_LOJA AND SA2.D_E_L_E_T_=' ' " + CRLF
    cQuery += "INNER JOIN "+RetSqlName("SD1")+" SD1 ON SD1.D1_FILIAL = SF1.F1_FILIAL AND SD1.D1_DOC = SF1.F1_DOC AND SD1.D1_SERIE = SF1.F1_SERIE AND SD1.D1_FORNECE = SF1.F1_FORNECE AND SD1.D1_LOJA = SF1.F1_LOJA AND SD1.D_E_L_E_T_ = ' ' " + CRLF
    cQuery += "WHERE SF1.D_E_L_E_T_=' ' AND SF1.F1_FILIAL='"+xFilial("SF1")+"' AND A2_XIDMB='' AND SF1.F1_XIDMB='' " + CRLF //NAO FOI ENVIADO PARA O MB AINDA
    cQuery += "AND SF1.F1_DTDIGIT BETWEEN '"+DtoS(dDataIni)+"' AND '"+DtoS(dDataFin)+"' "  + CRLF
    cQuery += "AND SD1.D1_TES IN "+cTESPRODUTOS+" "  + CRLF
    cQuery += "AND SD1.D1_CF IN "+cCFOPRODUTOS+" "  + CRLF
    cQuery += "GROUP BY SF1.F1_FILIAL, SF1.F1_FORNECE, SF1.F1_LOJA " + CRLF
    cQuery += "UNION " + CRLF
    cQuery += "SELECT SF1.F1_FILIAL FILIAL, SF8.F8_TRANSP FORNECE, SF8.F8_LOJTRAN LOJA " + CRLF
    cQuery += "FROM "+RetSqlName("SF1")+" SF1 " + CRLF
    cQuery += "INNER JOIN "+RetSqlName("SD1")+" SD1 ON SD1.D1_FILIAL = SF1.F1_FILIAL AND SD1.D1_DOC = SF1.F1_DOC AND SD1.D1_SERIE = SF1.F1_SERIE AND SD1.D1_FORNECE = SF1.F1_FORNECE AND SD1.D1_LOJA = SF1.F1_LOJA AND SD1.D_E_L_E_T_ = ' ' " + CRLF
    cQuery += "INNER JOIN "+RetSqlName("SF8")+" SF8 ON F8_FILIAL=SF1.F1_FILIAL AND F8_NFORIG=SF1.F1_DOC AND F8_SERORIG=SF1.F1_SERIE AND F8_FORNECE=SF1.F1_FORNECE AND SF1.F1_LOJA=F8_LOJA AND SF8.D_E_L_E_T_=' ' " + CRLF
    cQuery += "INNER JOIN "+RetSqlName("SA2")+" SA2 ON A2_FILIAL='"+xFilial("SA2")+"' AND A2_COD=SF8.F8_TRANSP AND A2_LOJA=SF8.F8_LOJTRAN AND SA2.D_E_L_E_T_=' ' " + CRLF
    cQuery += "WHERE SF1.D_E_L_E_T_=' ' AND SF1.F1_FILIAL='"+xFilial("SF1")+"' AND A2_XIDMB='' AND SF1.F1_XIDMB=''  " + CRLF //NAO FOI ENVIADO PARA O MB AINDA
    cQuery += "AND SF1.F1_DTDIGIT BETWEEN '"+DtoS(dDataIni)+"' AND '"+DtoS(dDataFin)+"' "  + CRLF
    cQuery += "AND SD1.D1_TES IN "+cTESPRODUTOS+" "  + CRLF
    cQuery += "AND SD1.D1_CF IN "+cCFOPRODUTOS+" "  + CRLF
    cQuery += "GROUP BY SF1.F1_FILIAL, SF8.F8_TRANSP, SF8.F8_LOJTRAN " + CRLF
    cQuery += "ORDER BY FILIAL, FORNECE, LOJA " + CRLF
    cQuery := ChangeQuery(cQuery)
    TCSqlToArr(cQuery,@aTabtemp)
    For ln := 1 to Len(aTabTemp)
        dbSelectArea("SA2")
        SA2->(dbSetOrder(1))
        SA2->(dbSeek(xFilial("SA2")+aTabTemp[ln][2]+aTabTemp[ln][3]))
        If SA2->(Found())
            RecLock("SA2",.F.)
            SA2->A2_XENVMB := "1"   //Marca o fornecedor para integrar com MB
            SA2->(MsUnLock())
        EndIf
    Next
    //------------------------------------- VERIFICA SE TEM PRODUTOS DAS NOTAS QUE NAO ESTAO INTEGRADOS COM O MB, PARA INTEGRAR ANTES DE ENVIAR AS NOTAS DE ENTRADA DE PRODUTOS, PARA EVITAR ERROS DE INTEGRAÇÃO ---------------------------
    aTabTemp := {}
    cQuery := ""
    cQuery += "SELECT SD1.D1_COD " + CRLF
    cQuery += "FROM "+RetSqlName("SF1")+" SF1 " + CRLF
    cQuery += "INNER JOIN "+RetSqlName("SD1")+" SD1 ON SD1.D1_FILIAL = SF1.F1_FILIAL AND SD1.D1_DOC = SF1.F1_DOC AND SD1.D1_SERIE = SF1.F1_SERIE AND SD1.D1_FORNECE = SF1.F1_FORNECE AND SD1.D1_LOJA = SF1.F1_LOJA AND SD1.D_E_L_E_T_ = ' '  " + CRLF
    cQuery += "INNER JOIN "+RetSqlName("SB1")+" SB1 ON B1_COD=SD1.D1_COD AND SB1.D_E_L_E_T_=' ' " + CRLF
    cQuery += "INNER JOIN "+RetSqlName("SA2")+" SA2 ON SA2.A2_COD=SF1.F1_FORNECE AND SA2.A2_LOJA=SF1.F1_LOJA AND SA2.D_E_L_E_T_=' '  " + CRLF
    cQuery += "WHERE SF1.D_E_L_E_T_=' '  " + CRLF
    cQuery += "AND SF1.F1_FILIAL='"+xFilial("SF1")+"' "
    cQuery += "AND SF1.F1_TIPO='N' "
    cQuery += "AND SF1.F1_DTDIGIT BETWEEN '"+DtoS(dDataIni)+"' AND '"+DtoS(dDataFin)+"' " + CRLF
    cQuery += "AND SD1.D1_CF IN "+cCFOPRODUTOS+" " + CRLF
    cQuery += "AND SD1.D1_TES IN "+cTESPRODUTOS+" " + CRLF
    cQuery += "AND SB1.B1_XIDMB='' " + CRLF
    cQuery += "GROUP BY SD1.D1_COD " + CRLF
    cQuery := ChangeQuery(cQuery)
    TCSqlToArr(cQuery,@aTabtemp)
    For ln := 1 to Len(aTabTemp)
        dbSelectArea("SB1")
        SB1->(dbSetOrder(1))
        SB1->(dbSeek(xFilial("SB1")+aTabTemp[ln][1]))
        If SB1->(Found())
            RecLock("SB1",.F.)
            SB1->B1_XENVMB := "1"   //Marca o produto para integrar com MB
            SB1->(MsUnLock())
        EndIf
    Next
    //If Len(aTabTemp)>0
        U_MBENVIO()   //Executa o envio dos fornecedores e transportadoras para o MB, para garantir que estão com os dados atualizados no MB antes de enviar as entradas de animais, para evitar erros de integração.
    //EndIf
    //----------- FIM PRIMEIRO VERIFICA TODOS OS FORNECEDORES, TRANSPORTADORAS E PRODUTOS ---------------------------

    //----------- DEPOIS VERIFICA AS ENTRADAS DE PRODUTOS PARA INTEGRAR COM O MB ---------------------------
    //--------------------------------------------------- BUSCA AS NOTAS DE ENTRADA -----------------------------------
    aTabTemp := {}
    ln := 0
    cJSon :=  ""
    cJSonRet := ""
    cIdProc:= ""
    cError := ""
    cStZZ0 := ""
    cChave := ""
    cRefer := ""
    cQuery := ""

    cQuery += "SELECT " + CRLF
    cQuery += "SF1.F1_FILIAL, SF1.F1_DOC, SF1.F1_SERIE, SF1.F1_FORNECE, SF1.F1_LOJA, SF1.F1_DTDIGIT, SF1.F1_VALIPI, SF1.F1_FRETE, SF1.F1_DESPESA, SF1.F1_CHVNFE, SF1.F1_VALBRUT, SF1.F1_VALMERC, SF1.F1_DESCONT, SA2.A2_XIDMB, SB1.B1_XIDMB, " + CRLF
    cQuery += "SD1.D1_COD, SD1.D1_ITEM, SD1.D1_QUANT, SD1.D1_VUNIT, SD1.D1_TOTAL, SD1.D1_VALFRE, SD1.D1_VALDESC, SD1.D1_VALIPI,  " + CRLF
    cQuery += "SUM(CMP.F1_VALBRUT) FRETE_CMP " + CRLF
    cQuery += "FROM "+RetSqlName("SF1")+" SF1 " + CRLF
    cQuery += "INNER JOIN "+RetSqlName("SD1")+" SD1 ON SD1.D1_FILIAL = SF1.F1_FILIAL AND SD1.D1_DOC = SF1.F1_DOC AND SD1.D1_SERIE = SF1.F1_SERIE AND SD1.D1_FORNECE = SF1.F1_FORNECE AND SD1.D1_LOJA = SF1.F1_LOJA AND SD1.D_E_L_E_T_ = ' '  " + CRLF
    cQuery += "INNER JOIN "+RetSqlName("SB1")+" SB1 ON B1_COD=SD1.D1_COD AND SB1.D_E_L_E_T_=' ' " + CRLF
    cQuery += "INNER JOIN "+RetSqlName("SA2")+" SA2 ON SA2.A2_COD=SF1.F1_FORNECE AND SA2.A2_LOJA=SF1.F1_LOJA AND SA2.D_E_L_E_T_=' '  " + CRLF
    cQuery += "FULL JOIN "+RetSqlName("SF8")+" SF8 ON F8_FILIAL=SF1.F1_FILIAL AND F8_NFORIG=SF1.F1_DOC AND F8_SERORIG=SF1.F1_SERIE AND F8_FORNECE=SF1.F1_FORNECE AND SF1.F1_LOJA=F8_LOJA AND SF8.D_E_L_E_T_=' '  " + CRLF
    cQuery += "FULL JOIN "+RetSqlName("SF1")+" CMP ON CMP.F1_FILIAL=F8_FILIAL AND CMP.F1_DOC=F8_NFDIFRE AND CMP.F1_SERIE=F8_SEDIFRE AND CMP.F1_FORNECE=F8_TRANSP AND CMP.F1_LOJA=F8_LOJTRAN AND CMP.D_E_L_E_T_=' ' " + CRLF
    cQuery += "WHERE SF1.D_E_L_E_T_=' '  " + CRLF
    cQuery += "AND SF1.F1_FILIAL='"+xFilial("SF1")+"' AND SF1.F1_DTDIGIT BETWEEN '"+DtoS(dDataIni)+"' AND '"+DtoS(dDataFin)+"' " + CRLF
    cQuery += "AND SD1.D1_CF IN "+cCFOPRODUTOS+" " + CRLF
    cQuery += "AND SD1.D1_TES IN "+cTESPRODUTOS+" " + CRLF
    cQuery += "AND SF1.F1_TIPO='N' AND SF1.F1_XIDMB=' ' " + CRLF
    cQuery += "AND SA2.A2_XIDMB<>'' AND SB1.B1_XIDMB<>'' " + CRLF
    cQuery += "GROUP BY SF1.F1_FILIAL, SF1.F1_DOC, SF1.F1_SERIE, SF1.F1_FORNECE, SF1.F1_LOJA, SF1.F1_DTDIGIT, SF1.F1_VALIPI, SF1.F1_FRETE, SF1.F1_DESPESA, SF1.F1_CHVNFE, SF1.F1_VALBRUT, SF1.F1_VALMERC, SF1.F1_DESCONT, SA2.A2_XIDMB, SB1.B1_XIDMB, " + CRLF
    cQuery += "SD1.D1_COD, SD1.D1_ITEM, SD1.D1_QUANT, SD1.D1_VUNIT, SD1.D1_TOTAL, SD1.D1_VALFRE, SD1.D1_VALDESC, SD1.D1_VALIPI " + CRLF
    cQuery += "ORDER BY F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, D1_ITEM"
    cQuery := ChangeQuery(cQuery)
    //TCSqlToArr(cQuery,@aTabtemp)
    dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),cQSF1,.T.,.T.)

    TCSetField(cQSF1,"F1_DTDIGIT","D",08,00)
    TCSetField(cQSF1,"F1_VALIPI","N",TamSX3("F1_VALIPI")[1] ,TamSX3("F1_VALIPI")[2])
    TCSetField(cQSF1,"F1_FRETE","N",TamSX3("F1_FRETE")[1] ,TamSX3("F1_FRETE")[2])
    TCSetField(cQSF1,"F1_DESPESA","N",TamSX3("F1_DESPESA")[1],TamSX3("F1_DESPESA")[2])
    TCSetField(cQSF1,"F1_VALBRUT","N",TamSX3("F1_VALBRUT")[1],TamSX3("F1_VALBRUT")[2])
    TCSetField(cQSF1,"D1_QUANT","N",TamSX3("D1_QUANT")[1] ,TamSX3("D1_QUANT")[2])
    TCSetField(cQSF1,"D1_VUNIT","N",TamSX3("D1_VUNIT")[1],TamSX3("D1_VUNIT")[2])
    TCSetField(cQSF1,"D1_TOTAL","N",TamSX3("D1_TOTAL")[1],TamSX3("D1_TOTAL")[2])
    TCSetField(cQSF1,"D1_VALFRE","N",TamSX3("D1_VALFRE")[1],TamSX3("D1_VALFRE")[2])
    TCSetField(cQSF1,"D1_VALDESC","N",TamSX3("D1_VALDESC")[1],TamSX3("D1_VALDESC")[2])
    TCSetField(cQSF1,"FRETE_CMP","N",TamSX3("F1_FRETE")[1] ,TamSX3("F1_FRETE")[2])

    dbSelectArea(cQSF1)
    (cQSF1)->(dbGotop())
    While (cQSF1)->(!eof())
        cChave := (cQSF1)->F1_FILIAL+(cQSF1)->F1_DOC+(cQSF1)->F1_SERIE+(cQSF1)->F1_FORNECE+(cQSF1)->F1_LOJA
        oJson := Eval(bObject)   //Cria o objeto
        oJson["propriedade"] := cFazenda
        oJson["contato"] := (cQSF1)->A2_XIDMB
        oJson["documento"] := (cQSF1)->F1_DOC
        oJson["data"] := FWTimeStamp(3,(cQSF1)->F1_DTDIGIT, Time())// Converte para o formato XML (YYYY-MM-DDThh:mm:ss) // O parâmetro 3 indica o padrão ISO 8601
        //oJson["forma_pagamento"] := ""//2082
        //oJson["contato"] := ""//944375
        //oJson["responsavel"] := ""//944375
        //oJson["valor_desconto"] := 0.00
        //oJson["percentual_desconto"] := 0.00 
        //oJson["conta_imposto"] := ""
        oJson["valor_imposto"] := (cQSF1)->F1_VALIPI
        //oJson["documento_frete"] := ""
        oJson["valor_frete"] := (cQSF1)->FRETE_CMP
        //oJson["fornecedor_frete"] := ""//(cQSF1)->FORFRETE
        //oJson["forma_pagamento_frete"] := ""
        oJson["valor_total"] := (cQSF1)->F1_VALBRUT
        oJson["valor_pagamento"] := (cQSF1)->F1_VALBRUT
        While (cQSF1)->F1_FILIAL+(cQSF1)->F1_DOC+(cQSF1)->F1_SERIE+(cQSF1)->F1_FORNECE+(cQSF1)->F1_LOJA=cChave
            oItem := Eval(bObject)
            oItem["numero"] := (cQSF1)->D1_ITEM
            oItem["produto"] := (cQSF1)->B1_XIDMB
            oItem["quantidade"] := (cQSF1)->D1_QUANT
            oItem["valor_unitario"] := (cQSF1)->D1_VUNIT
            oItem["valor_total"] := (cQSF1)->D1_TOTAL
            //oItem["valor_desconto"] := 0.00
            //oItem["percentual_desconto"] := 0.00
            oItem["valor_final"] := (cQSF1)->D1_TOTAL
            oItem["valor_frete"] := (cQSF1)->D1_VALFRE
            oItem["observacao"] := ""
            aadd(aItens,oItem)
            FreeObj(oItem)
            dbSelectArea(cQSF1)
            (cQSF1)->(dbSkip())
        End
        oJson["itens"] := aItens
        cJSon := oJson:ToJson()
        oMultiBV:cBody := cJSon
        oMultiBV:cPath := "entradamaterial/"   //Id do endpoint para envio dos subgrupos
        lRet   := oMultiBV:PostCadastros()      //Executa integração e captura retorno para gravar na tabela de monitoramento
        cError := oMultiBV:cError
        cIdProc:= "0008"                        //Entrada Animais
        //cChave := aTabtemp[ln][1]+aTabtemp[ln][2]+aTabtemp[ln][3]+aTabtemp[ln][4]+aTabtemp[ln][5]    //Defini como chave o Alias e o conteudo dos campos de indice
        cRefer := "SF1"+cChave
        If lRet //Sucesso, grava o ID no cadastro para não enviar novamente e grava o monitoramento com status de sucesso
            cJsonRet := oMultiBV:cJSonRet
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
            U_MBAtuMnt(cIdProc,cRefer,cJson,cJsonRet,cStZZ0,cFazenda)
        Else    //Falha - reenvia
            cStZZ0 := "3"      ///1=Inclui novo processo na ZZ0; 3=Retornado falha - reenvia
            U_MBAtuMnt(cIdProc,cRefer,cJson,cError,cStZZ0,cFazenda)
            U_MBGRVHST(cIdProc,cRefer,cJson,cError)
        EndIf
        FreeObj(oJson)
        dbSelectArea(cQSF1)
    End
    (cQSF1)->(DbCloseArea())
Return

