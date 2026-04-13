User Function mbenvio()
    Local cQuery := ""
    Local aTabTemp := {}
    Local ln := 0
    Local cJSon :=  ""
    Local cIdProc:= ""
    Local cError := ""
    Local cStZZ0 := ""
    Local cChave := ""
    Local bObject := {|| JsonObject():New()}
    Local oJson   := Eval(bObject)
    Local cFazenda := Posicione("ZZ2",xFilial("ZZ2")+cFilAnt)


    cQuery := "SELECT A2_COD, A2_LOJA, A2_NOME, A2_NREDUZ, A2_END, A2_CEP, A2_CGC, A2_INSCR, A2_TIPO, "
    cQuery += "A2_EST, A2_MUNIC, A2_PAIS, A2_TELEFONE, A2_EMAIL, A2_INSCMUN, "
    cQuery += "FROM "+RetSqlName("SA2")+" SA2 "
    cQuery += "WHERE SA2.D_E_L_E_T_=' ' "
    cQuery += "AND A2_FILIAL='"+xFilial("SA2")+"' AND A2_XIDMB='' AND A2_XENVMB='1' "
    //--INNER JOIN ZZ2010 ZZ2 ON ZZ2_FILIAL='' AND ZZ2_CODFIL='' AND ZZ2.D_E_L_E_T_=''
    TCSqlToArr(cQuery, aTabtemp)

    /*{
    	"cpf": "",
    	"cnpj": "03.573.330/0001-64",
    	"municipio": "",
    	"estado": "",
    	"pais": "",
    	"dados_telefones": [],
    	"dados_emails": [],
    	"dados_enderecos": [],
    	"origem_informacao": "ERP",
    	"tipo_pessoa": "PJ",
    	"nome": "1000 MARCAS",
    	"razao_social": null,
    	"inscricao_estadual": null,
    	"inscricao_municipal": null,
    	"rg": null,
    	"data_nascimento": null,
    	"codigo_erp": null,
    	"telefones": [],
    	"emails": [],
    	"enderecos": []
    }*/
    For ln := 1 to Len(aTabTemp)
        oJson["cpf"] := Iif(aTabtemp[ln][9]==??,aTabtemp[ln][7],"")
        oJson["cnpj"] := Iif(aTabtemp[ln][9]==??,aTabtemp[ln][7],"")
        oJson["municipio"] := aTabtemp[ln][11]
        oJson["estado"] := aTabtemp[ln][10]
        oJson["pais"] := aTabtemp[ln][12]
        oJson["dados_telefones"] := Eval(bObject)
        oJson["dados_emails"] := Eval(bObject)
        oJson["dados_enderecos"] := Eval(bObject)
        oJson["origem_informacao"]: "ERP"
        oJson["tipo_pessoa"] := Iif(aTabtemp[ln][9]==??,"PJ","PF")
        oJson["nome"] := aTabtemp[ln][4]
        oJson["razao_social"] := aTabtemp[ln][3]
        oJson["inscricao_estadual"] := aTabtemp[ln][8]
        oJson["inscricao_municipal"] := aTabtemp[ln][15]
        oJson["rg"] := 
        oJson["data_nascimento"] := 
        oJson["codigo_erp"] := aTabtemp[ln][1]+aTabtemp[ln][2]
        oJson["telefones"] := Eval(bObject)
        oJson["emails"] := Eval(bObject)
        oJson["enderecos"] := Eval(bObject) 
        
        cJSon := oJson:ToJson()
        cIdProc:= "0017"   //Cria o usuario na plataforma
        cError := ""
        cStZZ0 := "1"      //1=Inclui novo processo na ZZ0
        cChave := "SA2"+aTabtemp[ln][1]+aTabtemp[ln][2]    //Defini como chave o Alias e o conteudo dos campos de indice
        
        //Funcão para gravar nova integração na tabela ZZ0  
        MBAtuMnt(cIdProc,cChave,cJson,cError,cStZZ0,cFazenda)
    Next

    aTabTemp := {}
    ln := 0
    cJSon :=  ""
    cIdProc:= ""
    cError := ""
    cStZZ0 := ""
    cChave := ""
    
    cQuery := "SELECT B1_COD, B1_DESC, B1_UM, B1_XSGRUPO, "
    cQuery += "AH_UNIMED, AH_XIDMB, AH_DESCPO, "
    cQuery += "ZZ3_COD "
    cQuery += "FROM "+RetSqlName("SB1")+" SB1 "
    cQuery += "INNER JOIN "+RetSqlName("SAH")+" SAH ON AH_FILIAL='"+xFilial("SAH")+"' AND AH_UNIMED=B1_UM AND SAH.D_E_L_E_T_='' "
    cQuery += "INNER JOIN "+RetSqlName("ZZ3")+" ZZ3 ON ZZ3_FILIAL='"+xFilial("ZZ3")+"' AND ZZ3_COD=B1_XSGRUPO AND ZZ3.D_E_L_E_T_='' "
    cQuery += "WHERE SB1.D_E_L_E_T_=' ' AND B1_XIDMB='' AND B1_XENVMB='1' "


    /*
    {
    
        "nome": "ACETAN TESTE INTEGRACAO",
        "abreviatura": "ACETAN TTT",
        "codigo_material": null,
        "fabricante": null,
        "preco_custo_material": 0.0,
        "codigo_fabricante": null,
        "grupo_material": -2,
        "subgrupo_material": -9,
        "unidade_medida_compra": 7,
        "unidade_medida_uso": 7,
        "unidade_medida_venda_transf": 7,
        "preco_medio_compra": 1.74435028248588,
        "consumo_diario_recomendado": null,
        "estoque_minimo": null,
        "observacoes": null,
        "tipo_dose": 1,
        "dose_por_peso": 1.5,
        "peso_para_dose": 1.3,
        "ativo": true
    }
    */

    For ln := 1 to Len(aTabTemp)
    Next


    //Envio de cadastros
    cQuery := ""
    cQuery += "SELECT AH_FILIAL, AH_UNIMED, AH_DESCPO FROM "+RetSqlName("SAH")+" SAH WHERE AH_FILIAL='"+xFilial("SAH")+"' AND SAH.D_E_L_E_T_='' AND AH_XENVMB='S'"
    cQuery := ChangeQuery(cQuery)
    TCSqlToArr(cQuery, @aUMedidas)

    cQuery := ""
    cQuery += "SELECT BM_FILIAL, BM_COD, BM_DESC FROM "+RetSqlName("SBM")+" SBM WHERE BM_FILIAL='"+xFilial("SBM")+"' AND SBM.D_E_L_E_T_='' AND BM_XENVMB='S'"
    cQuery := ChangeQuery(cQuery)
    TCSqlToArr(cQuery, @aGrupos)

    cQuery := ""
    cQuery += "SELECT ZZ0_FILIAL, ZZ0_COD, ZZ0_DESC FROM "+RetSqlName("ZZ0")+" ZZ0 WHERE ZZ0_FILIAL='"+xFilial("ZZ0")+"' AND ZZ0.D_E_L_E_T_=''"
    cQuery := ChangeQuery(cQuery)
    TCSqlToArr(cQuery, @aSubGrupos)

    cQuery := ""
    cQuery += "SELECT B1_FILIAL, B1_COD, B1_DESC, B1_UM, B1_GRUPO, B1_XSGRUPO FROM "+RetSqlName("SB1")+" SB1 WHERE B1_FILIAL='"+xFilial("SB1")+"' AND SB1.D_E_L_E_T_='' AND B1_XENVMB='S' "
    cQuery := ChangeQuery(cQuery)
    TCSqlToArr(cQuery, @aProdutos)

    cQuery := ""
    cQuery += "SELECT A2_FILIAL, A2_COD, A2_NOME FROM "+RetSqlName("SA2")+" SA2 WHERE A2_FILIAL='"+xFilial("SA2")+"' AND SA2.D_E_L_E_T_='' AND A2_XENVMB='S' "
    cQuery := ChangeQuery(cQuery)
    TCSqlToArr(cQuery, @aFornecedores)

Return
