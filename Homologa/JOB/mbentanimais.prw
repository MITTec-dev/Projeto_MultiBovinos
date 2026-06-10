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
    Local aTabEntrada := {}
    Local ln := 0
    Local cIdProc:= ""
    Local cError := ""
    Local cStZZ0 := ""
    Local cChave := ""
    Local cRefer := ""
    Local lRet := .F.
    Local cJson := ""
    Local cJsonRet := ""
    Local oMultiBV := MultiBovinos():New()
    Local bObject  := {|| JsonObject():New()}
    Local oJson    := Nil
    //Local lLogEmail := SuperGETMV("MB_MBLOGEML",.F.,.F.) //Flag para envio de email em caso de erro na integração, 1 para enviar email e 0 para não enviar.
    Local cFazenda := Alltrim(Posicione("ZZ2",1,cFilAnt,"ZZ2_FAZENDA"))
    //Local lIsBlind := IsBlind()
    Local dDataIni := SuperGETMV("MB_XMBDTAIN",.F.,CTOD("01/01/2026"))
    Local cTESANIMAIS := FormatIN(SuperGETMV("MB_XMBTESA",.F.,"001,003,022"),",")            //Lista de TES para entrada de animais, separados por virgula e entre aspas simples, exemplo: 'TES1','TES2','TES3'
    Local cCFOANIMAIS := FormatIN(SuperGETMV("MB_XMBCFOA",.F.,"1101,2101,1102,2102,1451,2451"),",")    //Lista de CFOP para entrada de animais, separados por virgula e entre aspas simples, exemplo: 'TES1','TES2','TES3'

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

    //----------- PRIMEIRO VERIFICA TODOS OS FORNECEDORES E TRANSPORTADORAS QUE POSSUEM ENTRADA DE ANIMAIS, PARA INTEGRAR COM O MB, PARA EVITAR ERROS DE INTEGRAÇÃO ---------------------------
    aTabTemp := {}
    ln := 0
    cQuery := ""
    cQuery += "SELECT F1_FILIAL FILIAL, F1_FORNECE FORNECE, F1_LOJA LOJA " + CRLF
    cQuery += "FROM "+RetSqlName("SF1")+" SF1 " + CRLF
    cQuery += "INNER JOIN "+RetSqlName("SA2")+" SA2 ON A2_FILIAL='"+xFilial("SA2")+"' AND A2_COD=F1_FORNECE AND A2_LOJA=F1_LOJA AND SA2.D_E_L_E_T_=' ' " + CRLF
    cQuery += "INNER JOIN "+RetSqlName("SD1")+" SD1 ON SD1.D1_FILIAL = F1_FILIAL AND SD1.D1_DOC = F1_DOC AND SD1.D1_SERIE = F1_SERIE AND SD1.D1_FORNECE = F1_FORNECE AND SD1.D1_LOJA = F1_LOJA AND SD1.D_E_L_E_T_ = ' ' " + CRLF
    //cQuery += "INNER JOIN "+RetSqlName("SF8")+" SF8 ON F8_FILIAL=F1_FILIAL AND F8_NFORIG=F1_DOC AND F8_SERORIG=F1_SERIE AND F8_FORNECE=F1_FORNECE AND F1_LOJA=F8_LOJA AND SF8.D_E_L_E_T_=' ' " + CRLF
    cQuery += "WHERE SF1.D_E_L_E_T_=' ' AND F1_FILIAL='"+xFilial("SF1")+"' AND A2_XIDMB='' AND F1_XIDMB='' " + CRLF //NAO FOI ENVIADO PARA O MB AINDA
    cQuery += "AND F1_DTDIGIT>='"+DtoS(dDataIni)+"' "  + CRLF
    cQuery += "AND D1_TES IN "+cTESANIMAIS+" "  + CRLF
    cQuery += "AND D1_CF IN "+cCFOANIMAIS+" "  + CRLF
    cQuery += "GROUP BY F1_FILIAL, F1_FORNECE, F1_LOJA " + CRLF
    cQuery += "UNION " + CRLF
    cQuery += "SELECT F1_FILIAL FILIAL, F8_TRANSP FORNECE, F8_LOJTRAN LOJA " + CRLF
    cQuery += "FROM "+RetSqlName("SF1")+" SF1 " + CRLF
    cQuery += "INNER JOIN "+RetSqlName("SD1")+" SD1 ON SD1.D1_FILIAL = F1_FILIAL AND SD1.D1_DOC = F1_DOC AND SD1.D1_SERIE = F1_SERIE AND SD1.D1_FORNECE = F1_FORNECE AND SD1.D1_LOJA = F1_LOJA AND SD1.D_E_L_E_T_ = ' ' " + CRLF
    cQuery += "INNER JOIN "+RetSqlName("SF8")+" SF8 ON F8_FILIAL=F1_FILIAL AND F8_NFORIG=F1_DOC AND F8_SERORIG=F1_SERIE AND F8_FORNECE=F1_FORNECE AND F1_LOJA=F8_LOJA AND SF8.D_E_L_E_T_=' ' " + CRLF
    cQuery += "INNER JOIN "+RetSqlName("SA2")+" SA2 ON A2_FILIAL='"+xFilial("SA2")+"' AND A2_COD=F8_TRANSP AND A2_LOJA=F8_LOJTRAN AND SA2.D_E_L_E_T_=' ' " + CRLF
    cQuery += "WHERE SF1.D_E_L_E_T_=' ' AND F1_FILIAL='"+xFilial("SF1")+"' AND A2_XIDMB='' AND F1_XIDMB=''  " + CRLF //NAO FOI ENVIADO PARA O MB AINDA
    cQuery += "AND F1_DTDIGIT>='"+DtoS(dDataIni)+"' "  + CRLF
    cQuery += "AND D1_TES IN "+cTESANIMAIS+" "  + CRLF
    cQuery += "AND D1_CF IN "+cCFOANIMAIS+" "  + CRLF
    cQuery += "GROUP BY F1_FILIAL, F8_TRANSP, F8_LOJTRAN " + CRLF
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
    If Len(aTabTemp)>0
        U_MBENVIO()   //Executa o envio dos fornecedores e transportadoras para o MB, para garantir que estão com os dados atualizados no MB antes de enviar as entradas de animais, para evitar erros de integração.
    EndIf

    //--------------------------------------------------- BUSCA A ENTRADA PELA ORDEM DE SERVIÇO QUE É ACHAVE DA DANFE -----------------------------------
    aTabTemp := {}
    ln := 0
    cJSon :=  ""
    cJsonRet := ""
    cIdProc:= ""
    cError := ""
    cStZZ0 := ""
    cChave := ""
    cRefer := ""
    cQuery := ""

    cQuery += "SELECT " + CRLF
    cQuery += "F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_FRETE, F1_DESPESA, F1_CHVNFE, " + CRLF
    //cQuery += "SD1.D1_TES, SD1.D1_CF, " + CRLF
    cQuery += "AGR.D1_DOC DOC_AGR, AGR.D1_SERIE SERIE_AGR, SA2.A2_XIDMB, 
    cQuery += "CASE WHEN F8_TIPO='F' THEN TRA.A2_XIDMB ELSE '' END AS FORFRETE," + CRLF
    cQuery += "CASE WHEN F8_TIPO='D' THEN TRA.A2_XIDMB ELSE '' END AS FORDESPESA, " + CRLF
    cQuery += "SUM(SD1.D1_TOTAL) TOTAL_NF, SUM(AGR.D1_TOTAL) TOTAL_AGR," + CRLF
    cQuery += "CASE WHEN F8_TIPO='F' THEN SUM(AGR.D1_TOTAL) ELSE 0.00 END AS FRETE_AGR," + CRLF
    cQuery += "CASE WHEN F8_TIPO='D' THEN SUM(AGR.D1_TOTAL) ELSE 0.00 END AS DESPE_AGR " + CRLF
    cQuery += "FROM "+RetSqlName("SF1")+" SF1" + CRLF
    cQuery += "INNER JOIN "+RetSqlName("SD1")+" SD1 ON SD1.D1_FILIAL = F1_FILIAL AND SD1.D1_DOC = F1_DOC AND SD1.D1_SERIE = F1_SERIE AND SD1.D1_FORNECE = F1_FORNECE AND SD1.D1_LOJA = F1_LOJA AND SD1.D_E_L_E_T_ = ' ' " + CRLF
    cQuery += "FULL JOIN "+RetSqlName("SF8")+" SF8 ON F8_FILIAL=F1_FILIAL AND F8_NFORIG=F1_DOC AND F8_SERORIG=F1_SERIE AND F8_FORNECE=F1_FORNECE AND F1_LOJA=F8_LOJA AND SF8.D_E_L_E_T_=' ' " + CRLF
    cQuery += "INNER JOIN "+RetSqlName("SD1")+" AGR ON AGR.D1_FILIAL=F8_FILIAL AND AGR.D1_DOC=F8_NFDIFRE AND AGR.D1_SERIE=F8_SEDIFRE AND AGR.D1_FORNECE=F8_TRANSP AND AGR.D1_LOJA=F8_LOJTRAN AND AGR.D_E_L_E_T_=' ' " + CRLF
    cQuery += "INNER JOIN "+RetSqlName("SA2")+" SA2 ON SA2.A2_FILIAL='"+xFilial("SA2")+"' AND SA2.A2_COD=F1_FORNECE AND SA2.A2_LOJA=F1_LOJA AND SA2.D_E_L_E_T_=' ' " + CRLF
    cQuery += "INNER JOIN "+RetSqlName("SA2")+" TRA ON TRA.A2_FILIAL='"+xFilial("SA2")+"' AND TRA.A2_COD=F8_TRANSP AND TRA.A2_LOJA=F8_LOJTRAN AND TRA.D_E_L_E_T_=' ' " + CRLF
    cQuery += "WHERE SF1.D_E_L_E_T_=' ' " + CRLF
    cQuery += "AND F1_FILIAL='"+xFilial("SF1")+"' AND SA2.A2_XIDMB<>'' AND TRA.A2_XIDMB<>'' AND F1_XIDMB='' "  + CRLF //Busca somente os fornecedores que possuem o campo de integração preenchido, para evitar enviar fornecedores que não estão configurados para integração e gerar erros no processo.
    cQuery += "AND F1_DTDIGIT>='"+DtoS(dDataIni)+"' "  + CRLF
    cQuery += "AND SD1.D1_TES IN "+cTESANIMAIS+" "  + CRLF
    cQuery += "AND SD1.D1_CF IN "+cCFOANIMAIS+" "  + CRLF
    cQuery += "AND AGR.D1_TOTAL>0.00 " + CRLF
    cQuery += "GROUP BY F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_FRETE, F1_DESPESA, F1_CHVNFE, SD1.D1_TES, SD1.D1_CF, AGR.D1_DOC, AGR.D1_SERIE, SA2.A2_XIDMB, TRA.A2_XIDMB, F8_TIPO" + CRLF
    cQuery := ChangeQuery(cQuery)
    TCSqlToArr(cQuery,@aTabtemp)

    //--------------------------------------------------- BUSCA A ENTRADA PELA ORDEM DE SERVIÇO QUE É ACHAVE DA DANFE -----------------------------------
            
    For ln := 1 to Len(aTabTemp)
        oJson := Eval(bObject)   //Cria o objeto
        oJson["propriedade"] := cFazenda
        oJson["ordem_servico"] := aTabTemp[ln][8]  //Assumindo que a chave da DANFE está na 12ª coluna
        cJSon := oJson:ToJson()
        
        oMultiBV:cBody := cJSon
        oMultiBV:cPath := "entrada/obtenha/"   //Id do endpoint para envio dos subgrupos
        lRet   := oMultiBV:PostCadastros()      //Executa integração e captura retorno para gravar na tabela de monitoramento
        cError := oMultiBV:cError
        If lRet //Sucesso, grava o ID no cadastro para não enviar novamente e grava o monitoramento com status de suces
            cJson  := oMultiBV:cJSonRet   
            oJson := Eval(bObject)
            oJson:FromJson(cJSon)
            aTabEntrada := oJson:GetJsonObject("dados")
            FreeObj(oJson)
            oJson := Eval(bObject)   //Cria o objeto
            oJson["data_aquisicao"] := aTabEntrada[1]["data_aquisicao"] //Data da aquisição do animal, que pode ser diferente da data de entrada, e é a data que deve ser considerada para controle de custos no MB
            oJson["documento"] := aTabEntrada[1]["documento"] //Número da nota fiscal de entrada dos animais, que é o documento que deve ser considerado para controle de custos no MB
            oJson["fornecedor"] := aTabEntrada[1]["fornecedor"]
            oJson["fornecedor_frete"] := Val(aTabTemp[ln][11])
            oJson["fornecedor_outras_despesas"] := Val(aTabTemp[ln][12])
            oJson["total_animais"] := aTabEntrada[1]["total_animais"]
            oJson["valor_frete"] := aTabTemp[ln][16]
            oJson["valor_compra"] := aTabTemp[ln][14]
            oJson["valor_outros"] := aTabTemp[ln][17]
            oJson["sexo"] := aTabEntrada[1]["sexo"]
            oJson["quantidade_animais"] := aTabEntrada[1]["quantidade_animais"]
            oJson["raca"] := aTabEntrada[1]["raca"]
            oJson["tipo_animal"] := aTabEntrada[1]["tipo_animal"]
            oJson["tipo"] := aTabEntrada[1]["tipo"]
            oJson["proprietario"] := aTabEntrada[1]["proprietario"]
            cJSon := oJson:ToJson()

            oMultiBV:cBody := cJSon
            oMultiBV:cPath := "entrada/"+cValToChar(aTabEntrada[1]["id"])+"/"       //Id do documento
            //oMultiBV:cRet  := "id"
            lRet   := oMultiBV:PutCadastros()      //Executa integração e captura retorno para gravar na tabela de monitoramento
            cError := oMultiBV:cError
            cIdProc:= "0009"                        //Entrada Animais
            cChave := aTabtemp[ln][1]+aTabtemp[ln][2]+aTabtemp[ln][3]+aTabtemp[ln][4]+aTabtemp[ln][5]    //Defini como chave o Alias e o conteudo dos campos de indice
            cRefer := "SF1"+cChave
            If lRet //Sucesso, grava o ID no cadastro para não enviar novamente e grava o monitoramento com status de sucesso
                cID := oMultiBV:cID
                cJsonRet := oMultiBV:cJSonRet
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
                cStZZ0 := "1"      ///1=Inclui novo processo na ZZ0; 3=Retornado falha - reenvia
                U_MBAtuMnt(cIdProc,cRefer,cJson,cError,cStZZ0,cFazenda)
                U_MBGRVHST(cIdProc,cRefer,cJson,cError)
            EndIf
            FreeObj(oJson)
        Else
            cStZZ0 := "1"      ///1=Inclui novo processo na ZZ0; 3=Retornado falha - reenvia
            U_MBAtuMnt(cIdProc,cRefer,cJson,cError,cStZZ0,cFazenda)
            U_MBGRVHST(cIdProc,cRefer,cJson,cError)
        EndIf    
    Next

Return

