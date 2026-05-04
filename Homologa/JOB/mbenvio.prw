/*************************************************************************************************************
    mbenvio.prw - Envio de dados para integração com Multibovinos
    Verifica as integrações a serem enviadas para o Multibovinos, buscando os dados nas tabelas do Protheus e 
    gravando as informações na tabela ZZ0, para que o processo de envio do Multibovinos possa ler e enviar as 
    informações para o endpoint correspondente.
    Cadastros serão enviado no mesmo momento, ou seja, se um cadastro de produto for criado e marcado para envio, 
    o processo de envio do Multibovinos irá ler a tabela ZZ0, identificar que existe um cadastro de produto para ser 
    enviado, ler as informações desse cadastro e enviar para o endpoint do Multibovinos. O mesmo processo vale para os 
    demais cadastros.
    Codigo identificador da integracao correspondente ao endepoit Multibovinos:
    0001 - Login integracao
    0002 - Definir Fazenda
    0003 - Grupo Produtos
    0004 - Subgrupo Produtos                                        
    0005 - Unidade Medida
    0006 - Produtos
    0007 - Fornecedores
    0008 - Entrada de Produtos
    0009 - Entrada de Animais
    0010 - Custos
    0011 - Saida de Materiais
    ZZ0_STPROC
    "1"	, "Aguardando processamento"
    "2" , "Retornado sucesso"
    "3" , "Retornado falha - reenvia"
    "4"	, "Analise da falha - parado"

*************************************************************************************************************/
User Function mbenvio()
    Local cQuery := ""
    Local aTabTemp := {}
    Local lRet  := .F.
    Local ln := 0
    Local cJSon :=  ""
    Local cIdProc:= ""
    Local cError := ""
    Local cStZZ0 := ""
    Local cChave := ""
    Local oMultiBV := MultiBovinos():New()
    Local bObject  := {|| JsonObject():New()}
    Local oJson    := Eval(bObject)
    Local oenderecos := Eval(bObject)
    Local otelefones := Eval(bObject)
    Local oemails := Eval(bObject)
    Local aenderecos := {}
    Local atelefones := {}
    Local aemails := {}
    Local cFazenda := Alltrim(Posicione("ZZ2",1,cFilAnt,"ZZ2_FAZENDA"))


    //--------------------------------------------------- SETA PROPRIEDADE PARA INICIAR INTEGRACOES ----------------------------------
    oMultiBV:cPath := "selecione-propriedade/"   //Id do usuario para consulta de propriedades disponiveis. Necessario para o envio do produto, caso haja alguma configuração errada, o retorno será falso e não prosseguirá com o envio dos dados.
    oMultiBV:cBody := "usuario/"+cFazenda+"/"
    //oMultiBV:cRet  := "dados"
    //cID            := oMultiBV:cID
    lRet := oMultiBV:SetPropriedade()
    If lRet //Sucesso, grava o ID no cadastro para não enviar novamente e grava o monitoramento com status de sucesso
        cStZZ0 := "1"      //1=Inclui novo processo na ZZ0
        U_MBAtuMnt("0001",cFilAnt,cJson,cError,cStZZ0,cFazenda)
    Else    //Falha - reenvia
        cStZZ0 := "3"      //3=Retornado falha - reenvia
        U_MBAtuMnt("0001",cFilAnt,cJson,cError,cStZZ0,cFazenda)
        U_MBGRVHST("0001",cFilAnt,cJson,cError)
    EndIf
    //--------------------------------------------------- FIM SETA PROPRIEDADE PARA INICIAR INTEGRACOES ----------------------------------


    //--------------------------------------------------- FORNECEDORES ---------------------------------------------------
    cQuery := "SELECT A2_COD, A2_LOJA, A2_NOME, A2_NREDUZ, A2_END, A2_CEP, A2_CGC, A2_INSCR, A2_TIPO, "
    cQuery += "A2_EST, A2_MUN, A2_PAIS, A2_DDD||A2_TEL TELEFONE, A2_EMAIL, A2_INSCRM, A2_BAIRRO "
    cQuery += "FROM "+RetSqlName("SA2")+" SA2 "
    cQuery += "WHERE SA2.D_E_L_E_T_=' ' "
    cQuery += "AND A2_FILIAL='"+xFilial("SA2")+"' AND A2_XIDMB='' AND A2_XENVMB='1' "
    cQuery := ChangeQuery(cQuery)
    TCSqlToArr(cQuery,@aTabtemp)

    For ln := 1 to Len(aTabTemp)
        If aTabtemp[ln][9]=="F" //Pessoa fisica
            oJson["cpf"] := aTabtemp[ln][7]
        Else
            oJson["cnpj"] := aTabtemp[ln][7]
        EndIf
        oJson["categoria"] := "1"
        oJson["ativo"] := "true"
        //oJson["municipio"] := Rtrim(aTabtemp[ln][11])
        //oJson["estado"] := Rtrim(aTabtemp[ln][10])
        //oJson["pais"] := Rtrim(aTabtemp[ln][12])
        //oJson["origem_informacao"]:= "ERP"
        //oJson["tipo_pessoa"] := Iif(aTabtemp[ln][9]=="J","PJ","PF")
        oJson["nome"] := Rtrim(aTabtemp[ln][4])
        //oJson["razao_social"] := Rtrim(aTabtemp[ln][3])
        //oJson["inscricao_estadual"] := Rtrim(aTabtemp[ln][8])
        //oJson["inscricao_municipal"] := Rtrim(aTabtemp[ln][15])
        ////oJson["rg"] := ""
        ////oJson["data_nascimento"] := "" //precisa ser no formato YYYY-MM-DD, verificar se tem como formatar a data de nascimento do fornecedor nesse formato, ou se é possível criar um campo específico para isso no cadastro do fornecedor
        oJson["codigo_erp"] := aTabtemp[ln][1]+aTabtemp[ln][2]
        otelefones["numero"] :=   Rtrim(aTabtemp[ln][13])
        otelefones["descricao"] := "Telefone 1"
        aadd(atelefones, otelefones)
        oJson["telefones"] := atelefones
        oemails["email"] :=  Rtrim(aTabtemp[ln][14])
        oemails["descricao"] := "Email 1"
        aadd(aemails, oemails)
        oJson["emails"] := aemails
        oenderecos["cep"] := Rtrim(aTabtemp[ln][6])
        oenderecos["logradouro"] := Rtrim(aTabtemp[ln][5])
        oenderecos["numero"] := ""                    
        oenderecos["bairro"] := Rtrim(aTabtemp[ln][16])
        oenderecos["principal"] := "true"
        oenderecos["tipo"] := "1"
        oenderecos["cidade"] := "" 
        aadd(aenderecos, oenderecos)
        oJson["enderecos"] := aenderecos
        cJSon := oJson:ToJson()

        oMultiBV:cBody := cJSon
        oMultiBV:cPath := "contato/"       //Id do endpoint para envio dos fornecedores
        lRet   := oMultiBV:PostCadastros()      //Executa integração e captura retorno para gravar na tabela de monitoramento
        cError := oMultiBV:cError
        cIdProc:= "0007"                        //Cria um fornecedor no MultiBovinos
        cChave := "SA2"+aTabtemp[ln][1]+aTabtemp[ln][2]    //Defini como chave o Alias e o conteudo dos campos de indice
        If lRet //Sucesso, grava o ID no cadastro para não enviar novamente e grava o monitoramento com status de sucesso
            oMultiBV:cRet  := "id"
            cID            := oMultiBV:cID
            dbSelectArea("SA2")
            SA2->(dbSetOrder(1))
            SA2->(dbSeek(aTabtemp[ln][1]+aTabtemp[ln][2]))
            If SA2->(Found())
                RecLock("SA2",.F.)
                SA2->A2_XIDMB := cID   //Marca o registro como enviado, para não enviar novamente
                SA2->(MsUnLock())
            EndIf
            cStZZ0 := "1"      //1=Inclui novo processo na ZZ0
            U_MBAtuMnt(cIdProc,cChave,cJson,cError,cStZZ0,cFazenda)
        Else    //Falha - reenvia
            cStZZ0 := "1"      ///1=Inclui novo processo na ZZ0; 3=Retornado falha - reenvia
            U_MBAtuMnt(cIdProc,cChave,cJson,cError,cStZZ0,cFazenda)
            U_MBGRVHST(cIdProc,cChave,cJson,cError)
        EndIf
        FreeObj(oJson)
    Next
    //--------------------------------------------------- UNIDADE DE MEDIDAS ---------------------------------------------------
    aTabTemp := {}
    ln := 0
    cJSon :=  ""
    cIdProc:= ""
    cError := ""
    cStZZ0 := ""
    cChave := ""
    oJson  := Eval(bObject)
    cQuery := "SELECT AH_UNIMED, AH_XIDMB, AH_DESCPO "
    cQuery += "FROM "+RetSqlName("SB1")+" SB1 "
    cQuery += "INNER JOIN "+RetSqlName("SAH")+" SAH ON AH_FILIAL='"+xFilial("SAH")+"' AND AH_UNIMED=B1_UM AND SAH.D_E_L_E_T_='' "
    cQuery += "WHERE SB1.D_E_L_E_T_=' ' AND B1_XIDMB='' AND B1_XENVMB='1' "
    cQuery += "GROUP BY AH_UNIMED, AH_XIDMB, AH_DESCPO"
    TCSqlToArr(cQuery, @aTabTemp)
    For ln := 1 to Len(aTabTemp)
        oJson["nome"]          := SubStr(aUMedidas[xx][3], 1, 50)  //Nome da unidade de medida
        oJson["abreviatura"]   := SubStr(aUMedidas[xx][2], 1, 10)  //Abreviatura da unidade de medida
        oJson["tipo_unidade"]  := "1"                              //Tipo da unidade de medida, 1-Unidade;2-Peso;3-Volume (Litro);4=Metro (MT)
        oJson["multiplicador"] := 1 
        cJSon := oJson:ToJson()
        oMultiBV:cBody := cJSon
        oMultiBV:cPath := "unidadesmedidas/"    //Id do endpoint para envio dos fornecedores
        lRet   := oMultiBV:PostCadastros()      //Executa integração e captura retorno para gravar na tabela de monitoramento
        cError := oMultiBV:cError
        cIdProc:= "0005"   //Cria uma unidade de medida no MultiBovinos 
        cChave := "SAH"+aTabtemp[ln][1]+aTabtemp[ln][2]    //Defini como chave o Alias e o conteudo dos campos de indice
        If lRet //Sucesso, grava o ID no cadastro para não enviar novamente e grava o monitoramento com status de sucesso
            dbSelectArea("SAH")
            SAH->(dbSetOrder(1))
            SAH->(dbSeek(aTabtemp[ln][1]+aTabtemp[ln][2]))
            If SAH->(Found())
                RecLock("SAH",.F.)
                SAH->AH_XIDMB := ""   //Marca o registro como enviado, para não enviar novamente
                SAH->(MsUnLock())
            EndIf
            cStZZ0 := "1"      //1=Inclui novo processo na ZZ0
            U_MBAtuMnt(cIdProc,cChave,cJson,cError,cStZZ0,cFazenda)
        Else    //Falha - reenvia
            cStZZ0 := "3"      //3=Retornado falha - reenvia
            U_MBAtuMnt(cIdProc,cChave,cJson,cError,cStZZ0,cFazenda)
            U_MBGRVHST(cIdProc,cChave,cJson,cError)
        EndIf
        FreeObj(oJson)
    Next
    //--------------------------------------------------- GRUPOS ---------------------------------------------------
    aTabTemp := {}
    ln := 0
    cJSon :=  ""
    cIdProc:= ""
    cError := ""
    cStZZ0 := ""
    cChave := ""
    cQuery := "SELECT BM_FILIAL, BM_COD, BM_DESC "
    cQuery += "FROM "+RetSqlName("SB1")+" SB1 "
    cQuery += "INNER JOIN "+RetSqlName("SBM")+" SBM ON BM_FILIAL='"+xFilial("SBM")+"' AND B1_GRUPO=BM_COD AND SBM.D_E_L_E_T_='' "
    cQuery += "WHERE SB1.D_E_L_E_T_=' ' AND B1_XIDMB='' AND B1_XENVMB='1' "
    cQuery += "GROUP BY BM_FILIAL, BM_COD, BM_DESC"
    TCSqlToArr(cQuery, @aTabTemp)
    For ln := 1 to Len(aTabTemp)
        //"{\n\t\"nome\": \"AGREGADOS TESTE INTEGRACAO\",\n\t\"ativo\": true,\n\t\"tipo\": 2\n}"
        oJson  := Eval(bObject)
        oJson["nome"]  := SubStr(aUMedidas[xx][2], 1, 50)  //Nome da unidade de medida
        oJson["ativo"] := "true"
        oJson["tipo"]  := 2
        cJSon := oJson:ToJson()
        oMultiBV:cBody := cJSon
        oMultiBV:cPath := "grupomaterial/"   //Id do endpoint para envio dos fornecedores
        lRet   := oMultiBV:PostCadastros()  //Executa integração e captura retorno para gravar na tabela de monitoramento
        cError := oMultiBV:cError
        cIdProc:= "0003"   //Cria um fornecedor no MultiBovinos
        cChave := "SBM"+aTabtemp[ln][1]    //Defini como chave o Alias e o conteudo dos campos de indice
        If lRet //Sucesso, grava o ID no cadastro para não enviar novamente e grava o monitoramento com status de sucesso
            dbSelectArea("SBM")
            SBM->(dbSetOrder(1))
            SBM->(dbSeek(aTabtemp[ln][1]+aTabtemp[ln][2]))
            If SBM->(Found())
                RecLock("SBM",.F.)
                SBM->BM_XIDMB := ""   //Marca o registro como enviado, para não enviar novamente
                SBM->(MsUnLock())
            EndIf
            cStZZ0 := "1"      //1=Inclui novo processo na ZZ0
            U_MBAtuMnt(cIdProc,cChave,cJson,cError,cStZZ0,cFazenda)
        Else    //Falha - reenvia
            cStZZ0 := "3"      //3=Retornado falha - reenvia
            U_MBAtuMnt(cIdProc,cChave,cJson,cError,cStZZ0,cFazenda)
            U_MBGRVHST(cIdProc,cChave,cJson,cError)
        EndIf
        FreeObj(oJson)
    Next

    //--------------------------------------------------- SUBGRUPOS ---------------------------------------------------
    aTabTemp := {}
    ln := 0
    cJSon :=  ""
    cIdProc:= ""
    cError := ""
    cStZZ0 := ""
    cChave := ""
    cQuery := "ZZ3_COD, ZZ3_DESC "
    cQuery += "FROM "+RetSqlName("SB1")+" SB1 "
    cQuery += "INNER JOIN "+RetSqlName("ZZ3")+" ZZ3 ON ZZ3_FILIAL='"+xFilial("ZZ3")+"' AND ZZ3_COD=B1_XSGRUPO AND ZZ3.D_E_L_E_T_='' "
    cQuery += "WHERE SB1.D_E_L_E_T_=' ' AND B1_XIDMB='' AND B1_XENVMB='1' "
    cQuery += "GROUP BY ZZ3_COD, ZZ3_DESC"
    TCSqlToArr(cQuery, @aTabTemp)
    For ln := 1 to Len(aTabTemp)
        //"{\n    \"nome\": \"FUNGICIDAS TESTE INTEGRACAO\",\n    \"grupo_material\": null\n}"
        oJson  := Eval(bObject)
        oJson["nome"]          := SubStr(aUMedidas[xx][3], 1, 50)  //Nome da unidade de medida
        oJson["grupo_material"]:= "null"    //SubStr(aUMedidas[xx][2], 1, 10)  //Abreviatura da unidade de medida
        cJSon := oJson:ToJson()
        oMultiBV:cBody := cJSon
        oMultiBV:cPath := "subgrupomaterial/"   //Id do endpoint para envio dos subgrupos
        lRet   := oMultiBV:PostCadastros()      //Executa integração e captura retorno para gravar na tabela de monitoramento
        cError := oMultiBV:cError
        cIdProc:= "0004"   //Cria um SUBGRUPO de produto no MultiBovinos
        cChave := "ZZ3"+aTabtemp[ln][1]    //Defini como chave o Alias e o conteudo dos campos de indice
        If lRet //Sucesso, grava o ID no cadastro para não enviar novamente e grava o monitoramento com status de sucesso
            dbSelectArea("ZZ3")
            ZZ3->(dbSetOrder(1))
            ZZ3->(dbSeek(aTabtemp[ln][1]+aTabtemp[ln][2]))
            If ZZ3->(Found())
                RecLock("ZZ3",.F.)
                ZZ3->ZZ3_XIDMB := ""   //Marca o registro como enviado, para não enviar novamente
                ZZ3->(MsUnLock())
            EndIf
            cStZZ0 := "1"      //1=Inclui novo processo na ZZ0
            U_MBAtuMnt(cIdProc,cChave,cJson,cError,cStZZ0,cFazenda)
        Else    //Falha - reenvia
            cStZZ0 := "3"      //3=Retornado falha - reenvia
            U_MBAtuMnt(cIdProc,cChave,cJson,cError,cStZZ0,cFazenda)
            U_MBGRVHST(cIdProc,cChave,cJson,cError)
        EndIf
        FreeObj(oJson)
    Next

    //--------------------------------------------------- PRODUTOS ---------------------------------------------------
    aTabTemp := {}
    ln := 0
    cJSon :=  ""
    cIdProc:= ""
    cError := ""
    cStZZ0 := ""
    cChave := ""
    cQuery := "SELECT B1_COD, B1_DESC, BM_XIDMB, ZZ3_XIDMB, AH_XIDMB "
    cQuery += "FROM "+RetSqlName("SB1")+" SB1 "
    cQuery += "INNER JOIN "+RetSqlName("SAH")+" SAH ON AH_FILIAL='"+xFilial("SAH")+"' AND AH_UNIMED=B1_UM AND SAH.D_E_L_E_T_='' "
    cQuery += "INNER JOIN "+RetSqlName("SBM")+" SBM ON BM_FILIAL='"+xFilial("SBM")+"' AND B1_GRUPO=BM_COD AND SBM.D_E_L_E_T_='' "
    cQuery += "INNER JOIN "+RetSqlName("ZZ3")+" ZZ3 ON ZZ3_FILIAL='"+xFilial("ZZ3")+"' AND ZZ3_COD=B1_XSGRUPO AND ZZ3.D_E_L_E_T_='' "
    cQuery += "WHERE SB1.D_E_L_E_T_=' ' AND B1_XIDMB='' AND B1_XENVMB='1' AND AH_XIDMB<>'' AND ZZ3_XIDMB<>'' "
    TCSqlToArr(cQuery, @aTabTemp)
    For ln := 1 to Len(aTabTemp)
        //"{\n\n    \"nome\": \"ACETAN TESTE INTEGRACAO\",\n    \"abreviatura\": \"ACETAN TTT\",\n    \"codigo_material\": null,\n    \"fabricante\": null,\n    \"preco_custo_material\": 0.0,\n    \"codigo_fabricante\": null,\n    \"grupo_material\": -2,\n    \"subgrupo_material\": -9,\n    \"unidade_medida_compra\": 7,\n    \"unidade_medida_uso\": 7,\n    \"unidade_medida_venda_transf\": 7,\n    \"preco_medio_compra\": 1.74435028248588,\n    \"consumo_diario_recomendado\": null,\n    \"estoque_minimo\": null,\n    \"observacoes\": null,\n    \"tipo_dose\": 1,\n    \"dose_por_peso\": 1.5,\n    \"peso_para_dose\": 1.3,\n    \"ativo\": true\n}"
        oJson  := Eval(bObject)
        oJson["nome"]           := SubStr(aUMedidas[ln][2], 1, 50)  //Nome da unidade de medida
        oJson["abreviatura"]    := SubStr(aUMedidas[ln][1], 1, 15)  //Nome da unidade de medida
        oJson["codigo_material"]  := "null"
        oJson["fabricante"]  := "null"
        oJson["preco_custo_material"]  := "0.0"
        oJson["codigo_fabricante"]  := "null"
        oJson["grupo_material"]  := aUMedidas[ln][3]        //BM_XIDMB
        oJson["subgrupo_material"]  := aUMedidas[ln][4]     //ZZ3_XIDMB
        oJson["unidade_medida_compra"]  := aUMedidas[ln][5] //AH_XIDMB
        oJson["unidade_medida_uso"]  := aUMedidas[ln][5] //AH_XIDMB
        oJson["unidade_medida_venda_transf"]  := aUMedidas[ln][5] //AH_XIDMB
        oJson["preco_medio_compra"]  := "0.00"
        oJson["consumo_diario_recomendado"]  := "null"
        oJson["estoque_minimo"]  := "null"
        oJson["observacoes"]  := "null"
        oJson["tipo_dose"]  := "0.0"
        oJson["dose_por_peso"]  := "0.0"
        oJson["peso_para_dose"]  := "0.0"
        oJson["ativo"]  := "true"
        cJSon := oJson:ToJson()

        oMultiBV:cBody := cJSon
        oMultiBV:cPath := "materiais/"      //Id do endpoint para envio dos produtos
        lRet   := oMultiBV:PostCadastros()  //Executa integração e captura retorno para gravar na tabela de monitoramento
        cError := oMultiBV:cError
        cIdProc:= "0006"   //Cria um fornecedor no MultiBovinos
        cChave := "SB1"+aTabtemp[ln][1]    //Defini como chave o Alias e o conteudo dos campos de indice
        If lRet //Sucesso, grava o ID no cadastro para não enviar novamente e grava o monitoramento com status de sucesso
            dbSelectArea("SB1")
            SB1->(dbSetOrder(1))
            SB1->(dbSeek(aTabtemp[ln][1]+aTabtemp[ln][2]))
            If SB1->(Found())
                RecLock("SB1",.F.)
                SB1->B1_XIDMB := ""   //Marca o registro como enviado, para não enviar novamente
                SB1->(MsUnLock())
            EndIf
            cStZZ0 := "1"      //1=Inclui o processo na ZZ0 como finalizado
            U_MBAtuMnt(cIdProc,cChave,cJson,cError,cStZZ0,cFazenda)
        Else    //Falha - reenvia
            cStZZ0 := "3"      //3=Retornado falha - reenvia
            U_MBAtuMnt(cIdProc,cChave,cJson,cError,cStZZ0,cFazenda)
            U_MBGRVHST(cIdProc,cChave,cJson,cError)
        EndIf
        FreeObj(oJson)
    Next
Return

//entrada_material
//"{\n\t\"propriedade\": 55080,\n\t\"documento\": \"10\",\n\t\"data\": \"2020-06-24T03:00:00.000Z\",\n\t\"forma_pagamento\": 2082,\n\t\"contato\": 944375,\n\t\"responsavel\": 944375,\n\t\"valor_desconto\": 10.0,\n\t\"percentual_desconto\": 20,\n\t\"conta_imposto\": null,\n\t\"valor_imposto\": 0,\n\t\"documento_frete\": null,\n\t\"valor_frete\": 0,\n\t\"fornecedor_frete\": null,\n\t\"forma_pagamento_frete\": null,\n\t\"valor_total\": 50,\n\t\"valor_pagamento\": 40,\n\t\"itens\": [\n\t\t{\n\t\t\t\"produto\": 275226,\n\t\t\t\"quantidade\": 2,\n\t\t\t\"valor_unitario\": 12.5,\n\t\t\t\"valor_total\": 25,\n\t\t\t\"valor_desconto\": 2.50,\n\t\t\t\"percentual_desconto\": 5.00,\n\t\t\t\"valor_final\": 20,\n\t\t\t\"valor_frete\": 0.00,\n\t\t\t\"observacao\": null\n\t\t},\n\t\t{\n\t\t\t\"produto\": 275217,\n\t\t\t\"quantidade\": 2,\n\t\t\t\"valor_unitario\": 12.5,\n\t\t\t\"valor_total\": 25,\n\t\t\t\"valor_desconto\": 2.50,\t\n\t\t\t\"percentual_desconto\": 5.00,\n\t\t\t\"valor_final\": 20,\n\t\t\t\"valor_frete\": 0.00,\n\t\t\t\"observacao\": \"teste\"\n\t\t}\n\t]\n}"

/*
    cQuery := "SELECT B1_COD, B1_DESC, B1_UM, B1_XSGRUPO, "
    cQuery += "AH_UNIMED, AH_XIDMB, AH_DESCPO, "
    cQuery += "ZZ3_COD "
    cQuery += "FROM "+RetSqlName("SB1")+" SB1 "
    cQuery += "INNER JOIN "+RetSqlName("SAH")+" SAH ON AH_FILIAL='"+xFilial("SAH")+"' AND AH_UNIMED=B1_UM AND SAH.D_E_L_E_T_='' "
    cQuery += "INNER JOIN "+RetSqlName("ZZ3")+" ZZ3 ON ZZ3_FILIAL='"+xFilial("ZZ3")+"' AND ZZ3_COD=B1_XSGRUPO AND ZZ3.D_E_L_E_T_='' "
    cQuery += "WHERE SB1.D_E_L_E_T_=' ' AND B1_XIDMB='' AND B1_XENVMB='1' "
*/
