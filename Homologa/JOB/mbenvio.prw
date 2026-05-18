#include "totvs.ch"
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
    Local cRefer := ""
    Local oMultiBV := MultiBovinos():New()
    Local bObject  := {|| JsonObject():New()}
    Local oJson    := Nil
    Local oenderecos := Eval(bObject)
    Local otelefones := Eval(bObject)
    Local oemails := Eval(bObject)
    Local aenderecos := {}
    Local atelefones := {}
    Local aemails := {}
    Local cFazenda := Alltrim(Posicione("ZZ2",1,cFilAnt,"ZZ2_FAZENDA"))
    Local lIsBlind := IsBlind()
    //Local lLogEmail := SuperGETMV("MV_MBLOGEML",.F.,.F.) //Flag para envio de email em caso de erro na integração, 1 para enviar email e 0 para não enviar.


    //--------------------------------------------------- SETA PROPRIEDADE PARA INICIAR INTEGRACOES ----------------------------------
    cIdProc:= "0001"     //Seta propriedade
    cRefer := cFilAnt
    oMultiBV:cPath := "selecione-propriedade/"   //Id do usuario para consulta de propriedades disponiveis. Necessario para o envio do produto, caso haja alguma configuração errada, o retorno será falso e não prosseguirá com o envio dos dados.
    oMultiBV:cBody := "usuario/"+cFazenda+"/"
    //oMultiBV:cRet  := "dados"
    //cID            := oMultiBV:cID
    lRet := oMultiBV:SetPropriedade()
    If lRet //Sucesso, grava o ID no cadastro para não enviar novamente e grava o monitoramento com status de sucesso
        cStZZ0 := "1"      //1=Inclui novo processo na ZZ0
        U_MBAtuMnt(cIdProc,cRefer,cJson,cError,cStZZ0,cFazenda)
    Else    //Falha - reenvia
        cStZZ0 := "3"      //3=Retornado falha - reenvia
        U_MBAtuMnt(cIdProc,cRefer,cJson,cError,cStZZ0,cFazenda)
        U_MBGRVHST(cIdProc,cRefer,cJson,cError)
    EndIf
    //--------------------------------------------------- FIM SETA PROPRIEDADE PARA INICIAR INTEGRACOES ----------------------------------


    //--------------------------------------------------- FORNECEDORES ---------------------------------------------------
    cQuery := "SELECT A2_COD, A2_LOJA, A2_NOME, A2_NREDUZ, A2_END, A2_CEP, A2_CGC, A2_INSCR, A2_TIPO, "
    cQuery += "A2_EST, A2_MUN, A2_PAIS, A2_DDD||A2_TEL TELEFONE, A2_EMAIL, A2_INSCRM, A2_BAIRRO, A2_COD_MUN "
    cQuery += "FROM "+RetSqlName("SA2")+" SA2 "
    cQuery += "WHERE SA2.D_E_L_E_T_=' ' "
    cQuery += "AND A2_FILIAL='"+xFilial("SA2")+"' AND A2_XIDMB='' AND A2_XENVMB='1' "
    cQuery := ChangeQuery(cQuery)
    TCSqlToArr(cQuery,@aTabtemp)

    For ln := 1 to Len(aTabTemp)
        oJson := Eval(bObject)   //Cria o objeto
        If aTabtemp[ln][9]=="F" //Pessoa fisica
            oJson["cpf"] := aTabtemp[ln][7]
        Else
            oJson["cnpj"] := aTabtemp[ln][7]
        EndIf
        oJson["categoria"] := "1"
        oJson["ativo"] := .T.
        oJson["municipio"] := Rtrim(aTabtemp[ln][11])
        oJson["estado"] := Rtrim(aTabtemp[ln][10])
        //oJson["pais"] := Rtrim(aTabtemp[ln][12])
        oJson["origem_informacao"]:= "ERP"
        oJson["tipo_pessoa"] := Iif(aTabtemp[ln][9]=="J","PJ","PF")
        oJson["nome"] := Rtrim(aTabtemp[ln][4])
        oJson["razao_social"] := Rtrim(aTabtemp[ln][3])
        oJson["inscricao_estadual"] := Rtrim(aTabtemp[ln][8])
        oJson["inscricao_municipal"] := Rtrim(aTabtemp[ln][15])
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
        oenderecos["logradouro"] := Rtrim(TrataEnd(aTabtemp[ln][5],"L")) //TrataEnd para retirar o complemento do endereço e deixar apenas o logradouro, visto que o endpoint do Multibovinos tem campos separados para logradouro e complemento, e o campo de complemento é opcional, então para evitar erros de integração por conta do tamanho do campo de logradouro, optei por retirar o complemento do campo de logradouro e deixar apenas o nome da rua, avenida, etc no campo de logradouro, e caso haja a necessidade de enviar o complemento, seria necessário criar um campo específico para isso no cadastro do fornecedor.
        oenderecos["numero"] := TrataEnd(aTabtemp[ln][5],"N")
        oenderecos["bairro"] := Rtrim(aTabtemp[ln][16])
        oenderecos["principal"] := .T.
        oenderecos["tipo"] := "1"
        oenderecos["cidade"] := Right(aTabtemp[ln][17],3) 
        aadd(aenderecos, oenderecos)
        oJson["enderecos"] := aenderecos
        cJSon := oJson:ToJson()

        oMultiBV:cBody := cJSon
        oMultiBV:cPath := "contato/"       //Id do endpoint para envio dos fornecedores
        oMultiBV:cRet  := "id"
        lRet   := oMultiBV:PostCadastros()      //Executa integração e captura retorno para gravar na tabela de monitoramento
        cError := oMultiBV:cError
        cIdProc:= "0007"                        //Cria um fornecedor no MultiBovinos
        cChave := xFilial("SA2")+aTabtemp[ln][1]+aTabtemp[ln][2]    //Defini como chave o Alias e o conteudo dos campos de indice
        cRefer := "SA2"+cChave
        If lRet //Sucesso, grava o ID no cadastro para não enviar novamente e grava o monitoramento com status de sucesso
            cID := oMultiBV:cID
            dbSelectArea("SA2")
            SA2->(dbSetOrder(1))
            SA2->(dbSeek(cChave))
            If SA2->(Found())
                RecLock("SA2",.F.)
                SA2->A2_XIDMB := cValToChar(cID)   //Marca o registro como enviado, para não enviar novamente
                SA2->(MsUnLock())
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

    //--------------------------------------------------- UNIDADE DE MEDIDAS ---------------------------------------------------
    aTabTemp := {}
    ln := 0
    cJSon :=  ""
    cIdProc:= ""
    cError := ""
    cStZZ0 := ""
    cRefer := ""
    cChave := ""
    oJson  := Eval(bObject)
    cQuery := "SELECT AH_UNIMED, AH_XIDMB, AH_DESCPO "
    cQuery += "FROM "+RetSqlName("SB1")+" SB1 "
    cQuery += "INNER JOIN "+RetSqlName("SAH")+" SAH ON AH_FILIAL='"+xFilial("SAH")+"' AND AH_UNIMED=B1_UM AND SAH.D_E_L_E_T_='' "
    cQuery += "WHERE SB1.D_E_L_E_T_=' ' AND B1_XIDMB='' AND B1_XENVMB='1' AND AH_XIDMB='' "
    cQuery += "GROUP BY AH_UNIMED, AH_XIDMB, AH_DESCPO"
    cQuery := ChangeQuery(cQuery)
    TCSqlToArr(cQuery, @aTabTemp)
    For ln := 1 to Len(aTabTemp)
        oJson := Eval(bObject)   //Cria o objeto
        oJson["nome"]          := SubStr(aTabTemp[ln][3], 1, 50)  //Nome da unidade de medida
        oJson["abreviatura"]   := SubStr(aTabTemp[ln][1], 1, 10)  //Abreviatura da unidade de medida
        oJson["tipo_unidade"]  := "1"                              //Tipo da unidade de medida, 1-Unidade;2-Peso;3-Volume (Litro);4=Metro (MT)
        oJson["multiplicador"] := 1 
        cJSon := oJson:ToJson()
        oMultiBV:cBody := cJSon
        oMultiBV:cPath := "unidadesmedidas/"    //Id do endpoint para envio dos fornecedores
        oMultiBV:cRet  := "id"
        lRet   := oMultiBV:PostCadastros()      //Executa integração e captura retorno para gravar na tabela de monitoramento
        cError := oMultiBV:cError
        cIdProc:= "0005"   //Cria uma unidade de medida no MultiBovinos 
        cChave := xFilial("SAH")+aTabtemp[ln][1]    //Defini como chave o Alias e o conteudo dos campos de indice
        cRefer := "SAH"+cChave
        If lRet //Sucesso, grava o ID no cadastro para não enviar novamente e grava o monitoramento com status de sucesso
            cID := oMultiBV:cID
            dbSelectArea("SAH")
            SAH->(dbSetOrder(1))
            SAH->(dbSeek(cChave))
            If SAH->(Found())
                RecLock("SAH",.F.)
                SAH->AH_XIDMB := cValToChar(cID)
                SAH->(MsUnLock())
            EndIf
            cStZZ0 := "1"      //1=Inclui novo processo na ZZ0
            U_MBAtuMnt(cIdProc,cRefer,cJson,cError,cStZZ0,cFazenda)
        Else    //Falha - reenvia
            cStZZ0 := "3"      //3=Retornado falha - reenvia
            U_MBAtuMnt(cIdProc,cRefer,cJson,cError,cStZZ0,cFazenda)
            U_MBGRVHST(cIdProc,cRefer,cJson,cError)
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
    cRefer := ""
    cQuery := "SELECT BM_GRUPO, BM_DESC "
    cQuery += "FROM "+RetSqlName("SB1")+" SB1 "
    cQuery += "INNER JOIN "+RetSqlName("SBM")+" SBM ON BM_FILIAL='"+xFilial("SBM")+"' AND B1_GRUPO=BM_GRUPO AND SBM.D_E_L_E_T_='' "
    cQuery += "WHERE SB1.D_E_L_E_T_=' ' AND B1_XIDMB='' AND B1_XENVMB='1' AND BM_XIDMB='' "
    cQuery += "GROUP BY BM_FILIAL, BM_GRUPO, BM_DESC"
    cQuery := ChangeQuery(cQuery)
    TCSqlToArr(cQuery, @aTabTemp)
    For ln := 1 to Len(aTabTemp)
        oJson  := Eval(bObject)
        oJson["nome"]  := SubStr(aTabTemp[ln][2], 1, 50)  //Nome da unidade de medida
        oJson["ativo"] := "true"
        oJson["tipo"]  := 2
        cJSon := oJson:ToJson()
        oMultiBV:cBody := cJSon
        oMultiBV:cPath := "grupomaterial/"   //Id do endpoint para envio dos fornecedores
        oMultiBV:cRet  := "id"
        lRet   := oMultiBV:PostCadastros()  //Executa integração e captura retorno para gravar na tabela de monitoramento
        cError := oMultiBV:cError
        cIdProc:= "0003"   //Cria um fornecedor no MultiBovinos
        cChave := xFilial("SBM")+aTabtemp[ln][1]    //Defini como chave o Alias e o conteudo dos campos de indice
        cRefer := "SBM"+cChave
        If lRet //Sucesso, grava o ID no cadastro para não enviar novamente e grava o monitoramento com status de suce
            cID := oMultiBV:cID
            dbSelectArea("SBM")
            SBM->(dbSetOrder(1))
            SBM->(dbSeek(cChave))
            If SBM->(Found())
                RecLock("SBM",.F.)
                SBM->BM_XIDMB := cValToChar(cID)   //Marca o registro como enviado, para não enviar novamente
                SBM->(MsUnLock())
            EndIf
            cStZZ0 := "1"      //1=Inclui novo processo na ZZ0
            U_MBAtuMnt(cIdProc,cRefer,cJson,cError,cStZZ0,cFazenda)
        Else    //Falha - reenvia
            cStZZ0 := "3"      //3=Retornado falha - reenvia
            U_MBAtuMnt(cIdProc,cRefer,cJson,cError,cStZZ0,cFazenda)
            U_MBGRVHST(cIdProc,cRefer,cJson,cError)
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
    cRefer := ""
    cQuery := ""

    oMultiBV:cPath := "subgrupomaterial/"   //Id do endpoint para envio dos subgrupos
    lRet   := oMultiBV:GetCadastros()      //Executa integração e captura retorno para gravar na tabela de monitoramento
    cError := oMultiBV:cError
    If lRet //Sucesso, grava o ID no cadastro para não enviar novamente e grava o monitoramento com status de suces
        cJson  := oMultiBV:cJSonRet   
        oJson := Eval(bObject)
        oJson:FromJson(cJSon)
        aTabTemp := oJson:GetJsonObject("results") //Recupera o grupo do material para enviar junto com o subgrupo, visto que o endpoint do Multibovinos necessita do ID do grupo para criar o subgrupo, e como o grupo e o subgrupo estão sendo criado no mesmo processo, preciso recuperar o ID do grupo para enviar junto com o subgrupo.
        For ln := 1 to Len(aTabTemp)
            //oJsonIt := Eval(bObject)
            //oJsonIt:FromJson(ToJson(aTabTemp[ln]))
            dbSelectArea("ZZ3")
            ZZ3->(dbSetOrder(1))
            ZZ3->(dbSeek(xFilial("ZZ3")+Padr(cValToChar(aTabTemp[ln]["id"]),TamSx3("ZZ3_COD")[1])))
            If ZZ3->(!Found())
                RecLock("ZZ3",.T.)
                Replace ZZ3_FILIAL  With xFilial("ZZ3") 
                Replace ZZ3_COD     With cValToChar(aTabTemp[ln]["id"])
                Replace ZZ3_DESC    With aTabTemp[ln]["nome"]
                ZZ3->(MsUnLock())
            EndIf
        Next
        FreeObj(oJson)
    EndIf
 
    //--------------------------------------------------- PRODUTOS ---------------------------------------------------
    aTabTemp := {}
    ln := 0
    cJSon :=  ""
    cIdProc:= ""
    cError := ""
    cStZZ0 := ""
    cChave := ""
    cRefer := ""
    cQuery := "SELECT B1_COD, B1_DESC, BM_XIDMB, ZZ3_COD, AH_XIDMB "
    cQuery += "FROM "+RetSqlName("SB1")+" SB1 "
    cQuery += "INNER JOIN "+RetSqlName("SAH")+" SAH ON AH_FILIAL='"+xFilial("SAH")+"' AND AH_UNIMED=B1_UM AND SAH.D_E_L_E_T_='' "
    cQuery += "INNER JOIN "+RetSqlName("SBM")+" SBM ON BM_FILIAL='"+xFilial("SBM")+"' AND B1_GRUPO=BM_GRUPO AND SBM.D_E_L_E_T_='' "
    cQuery += "INNER JOIN "+RetSqlName("ZZ3")+" ZZ3 ON ZZ3_FILIAL='"+xFilial("ZZ3")+"' AND ZZ3_COD=B1_XSGRUPO AND ZZ3.D_E_L_E_T_='' "
    cQuery += "WHERE SB1.D_E_L_E_T_=' ' AND B1_XIDMB='' AND B1_XENVMB='1' AND BM_XIDMB<>'' AND AH_XIDMB<>'' "
    cQuery := ChangeQuery(cQuery)
    TCSqlToArr(cQuery, @aTabTemp)
    For ln := 1 to Len(aTabTemp)
        oJson  := Eval(bObject)
        oJson["nome"]           := SubStr(aTabTemp[ln][2], 1, 50)  //Nome da unidade de medida
        oJson["abreviatura"]    := SubStr(aTabTemp[ln][1], 1, 15)  //Codigo do produto no ERP
        oJson["codigo_material"]  := Alltrim(aTabTemp[ln][1])  //Nome da unidade de medida
        //oJson["fabricante"]  := ""
        //oJson["preco_custo_material"]  := 0.0
        //oJson["codigo_fabricante"]  := ""
        oJson["grupo_material"]  := Alltrim(aTabTemp[ln][3])                     //BM_XIDMB
        oJson["subgrupo_material"]  := Alltrim(aTabTemp[ln][4])                  //B1_XSGRUPO
        oJson["unidade_medida_compra"]  := Alltrim(aTabTemp[ln][5])              //AH_XIDMB
        oJson["unidade_medida_uso"]  := Alltrim(aTabTemp[ln][5])                 //AH_XIDMB
        oJson["unidade_medida_venda_transf"]  := Alltrim(aTabTemp[ln][5])        //AH_XIDMB
        //oJson["preco_medio_compra"]  := 0.00
        //oJson["consumo_diario_recomendado"]  := 0.00
        //oJson["estoque_minimo"]  := 0.00
        //oJson["observacoes"]  := ""
        //oJson["tipo_dose"]  := 0.0
        //oJson["dose_por_peso"]  := "0.0"
        //oJson["peso_para_dose"]  := "0.0"
        oJson["ativo"]  := .T.
        oJson["origem_informacao"]:= "ERP"
        oJson["codigo_erp"] := Alltrim(aTabTemp[ln][1])
        cJSon := oJson:ToJson()

        oMultiBV:cBody := cJSon
        oMultiBV:cPath := "materiais/"      //Id do endpoint para envio dos produtos
        oMultiBV:cRet  := "id"
        lRet   := oMultiBV:PostCadastros()  //Executa integração e captura retorno para gravar na tabela de monitoramento
        cError := oMultiBV:cError
        cIdProc:= "0006"   //Cria um fornecedor no MultiBovinos
        cChave := xFilial("SB1")+aTabtemp[ln][1]    //Defini como chave o Alias e o conteudo dos campos de indice
        cRefer := "SB1"+cChave
        If lRet //Sucesso, grava o ID no cadastro para não enviar novamente e grava o monitoramento com status de sucesso
            cID := oMultiBV:cID
            dbSelectArea("SB1")
            SB1->(dbSetOrder(1))
            SB1->(dbSeek(cChave))
            If SB1->(Found())
                RecLock("SB1",.F.)
                SB1->B1_XIDMB := cValToChar(cID)   //Marca o registro como enviado, para não enviar novamente
                SB1->(MsUnLock())
            EndIf
            cStZZ0 := "1"      //1=Inclui o processo na ZZ0 como finalizado
            U_MBAtuMnt(cIdProc,cRefer,cJson,cError,cStZZ0,cFazenda)
        Else    //Falha - reenvia
            cStZZ0 := "3"      //3=Retornado falha - reenvia
            U_MBAtuMnt(cIdProc,cRefer,cJson,cError,cStZZ0,cFazenda)
            U_MBGRVHST(cIdProc,cRefer,cJson,cError)
        EndIf
        FreeObj(oJson)
    Next
Return
