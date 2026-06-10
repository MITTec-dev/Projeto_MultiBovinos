#include "totvs.ch"
/*************************************************************************************************************
    mbmateriais.prw - Movimentaçao de Materiais para integração com Multibovinos
    {
    	"data": "2019-10-07",
    	"propriedade":"35506",
    	"tipo_saida": 20
    }
    Retorno
    D3_DOC="id"
    D3_COD="produto"
    D3_QUANT="qtd"
    D3_CUSTO="valor_total"
    D3_DATA="data"
    D3_OBS="movimentacao_material_texto"
*************************************************************************************************************/
User Function mbmaterial(dData,cTipo)
    Local cQuery := ""
    Local aTabTemp := {}
    Local aTabItens := {}
    Local aItem    := {}
    Local aItPos   := {}
    Local aCab     := {}
    Local ln := 0
    Local it := 0
    Local cIdProc:= ""
    Local cError := ""
    Local cStZZ0 := ""
    Local cChave := ""
    Local cRefer := ""
    Local lRet := .F.
    Local cDocum := ""
    Local cProduto := ""
    Local cLocal := ""
    Local cUnid := ""
    Local cJson := ""
    Local cJsonRet := ""
    Local nQtd := 0
    Local nVTot := 0
    Local dDtmov := Ctod("  /  /  ")
    Local cObs := ""
    Local oMultiBV := MultiBovinos():New()
    Local bObject  := {|| JsonObject():New()}
    Local oJson    := Nil
    Local cTMRQ := SuperGETMV("MB_MBTMRQ",.F.,"501")  //Tipo de movimento do estoque de requisicao com custo
    Local cTMDV := SuperGETMV("MB_MBTMDV",.F.,"001")  //Tipo de movimento do estoque de devolucao com custo
    Local lLogEmail := SuperGETMV("MB_MBLOGEML",.F.,.F.) //Flag para envio de email em caso de erro na integração, 1 para enviar email e 0 para não enviar.
    Local cFazenda := Alltrim(Posicione("ZZ2",1,cFilAnt,"ZZ2_FAZENDA"))
    Local lTemErro := .F.   //Gerou erro.log grava somente uma vez pois o log fica acumulado
    Local lIsBlind := IsBlind()

    Private lMsErroAuto := .F.
    Private lMsHelpAuto :=.T.

    Default dData := dDatabase
    Default cTipo := "20" //20=Saida, 10=Entrada   

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

    //--------------------------------------------------- MOVIMENTAÇÃO DE MATERIAIS/SAIDA ---------------------------------------------------
    aTabTemp := {}
    ln := 0
    it := 0
    cJSon :=  ""
    cJSonRet := ""
    cIdProc:= "0011"     //Materiais saida
    cError := ""
    cStZZ0 := "1"       //Inclusao na ZZ0
    cChave := ""
    cRefer := ""
    cQuery := ""
    cDocum := ""

    oJson  := Eval(bObject)
    oJson["data"]  := Substr(Dtos(dData),1,4)+"-"+Substr(Dtos(dData),5,2)+"-"+Substr(Dtos(dData),7,2)
    oJson["propriedade"] := cFazenda
    oJson["tipo_saida"]  := Val(cTipo)
    cJSon := oJson:ToJson()
    oMultiBV:cBody := cJSon
    oMultiBV:cPath := "movimentacaomaterial/buscar-saidas/"   //Id do endpoint para envio dos subgrupos
    lRet   := oMultiBV:PostCadastros()      //Executa integração e captura retorno para gravar na tabela de monitoramento
    cError := oMultiBV:cError
    If lRet //Sucesso, grava o ID no cadastro para não enviar novamente e grava o monitoramento com status de suces
        cJson  := oMultiBV:cJSonRet
        cJsonRet := cJson
        oJson := Eval(bObject)
        oJson:FromJson(cJSon)
        aTabTemp := oJson:GetJsonObject("dados") //Recupera o grupo do material para enviar junto com o subgrupo, visto que o endpoint do Multibovinos necessita do ID do grupo para criar o subgrupo, e como o grupo e o subgrupo estão sendo criado no mesmo processo, preciso recuperar o ID do grupo para enviar junto com o subgrupo.
        For ln := 1 to Len(aTabTemp)
            cDocum := cValToChar(aTabTemp[ln]["id"])    //PADL(aTabTemp[ln]["documento"],9,"0")
            aTabItens := aTabTemp[ln]["itens"]
            dDtmov   := dDatabase //Ctod(aTabTemp[ln]["data_texto"])
            dbSelectArea("SD3")
            SD3->(DbSetOrder(1))
            SD3->(DbSeek(xFilial("SD3")+cDocum))
            If !Found() //Verifica se já incluiu o documento, para não incluir novamente
                For it := 1 to Len(aTabItens)
                    aItem := {}
                    dbSelectArea("SB1")
                    SB1->(DbOrderNickName("IDMB")) // B1_FILIAL + B1_COD
                    SB1->(dbSeek(xFilial("SB1") + PadR(cValToChar(aTabItens[it]["produto"]),TamSX3("B1_XIDMB")[1])))
                    If SB1->(Found())
                        cProduto := SB1->B1_COD //aTabItens[it]["produto"]
                        cLocal   := SB1->B1_LOCPAD
                        cUnid    := SB1->B1_UM
                        nQtd     := Val(aTabItens[it]["qtd"])
                        nVTot    := Val(aTabItens[it]["valor_total"])
                        cObs     := aTabItens[it]["movimentacao_material_texto"]
                        //dbSelectArea("SB2")
                        //SB2->(dbSetOrder(1))
                        //SB2->(dbSeek(xFilial("SB2")+cProduto+cLocal))
                        //nSaldo := SaldoSB2()
                        aItem    := {{"D3_COD"  , cProduto    , NIL},;   // C digo do produto
                                     {"D3_UM"   , cUnid       , NIL},;       // Unidade de medida
                                     {"D3_QUANT", nQtd        , NIL},;     // Quantidade do item
                                     {"D3_OBS"  , cObs        , NIL},;     // Observacao
                                     {"D3_LOCAL", cLocal      , NIL}}     // Local de estoque
                                     //{"D3_CUSTO1", nVTot       , NIL},;     // Custo total do item
                        aAdd(aItPos,aItem)
                    EndIf
                Next

                If Len(aItPos)>0
                    aCab := {{"D3_DOC"    , cDocum                    , NIL},; // N mero do documento (gerado automaticamente) NextNumero("SD3", 2, "D3_DOC", .T.)
                             {"D3_TM"     , Iif(cTipo="20",cTMRQ,cTMDV) , NIL},; // Tipo de movimento
                             {"D3_CC"     , Space(TamSx3("D3_CC")[1]) , NIL},; // Centro de custo (vazio)
                             {"D3_EMISSAO", dDtmov                    , NIL}}  // Data de emiss o (data atual)
                    MsExecAuto({|x, y, z| MATA241(x, y, z)}, aCab, aItPos, 3)

                    If lMsErroAuto
                        If !lIsBlind
                            MostraErro()
                        EndIf
                        lTemErro := .T.
                    Else
                        cChave := xFilial("SD3")+cDocum    //Defini como chave o Alias e o conteudo dos campos de indice
                        cRefer := "SD3"+cChave
                        U_MBAtuMnt(cIdProc,cRefer,cJson,cJsonRet,cStZZ0,cFazenda)
                    EndIf
                EndIf
            EndIf
        Next
        If lTemErro
            cError := MemoRead( AllTrim( NomeAutoLog() ) )  // Lê o conteúdo do log
            U_MBAtuMnt(cIdProc,cRefer,cJson,cJsonRet,cStZZ0,cFazenda)
            U_MBGRVHST(cIdProc,cRefer,cJson,cError)
            If lLogEmail
                EnviaEmail("Erro na integração de movimentação de materiais", "Ocorreu um erro na integração de movimentação de materiais. Segue o log do erro: "+cError, cFazenda)
            EndIf
            lTemErro := .F.
        EndIf
    Else    //Falha - reenvia
        U_MBAtuMnt(cIdProc,cRefer,cJson,cJsonRet,cStZZ0,cFazenda)
        U_MBGRVHST(cIdProc,cRefer,cJson,cError)
    EndIf

    FreeObj(oJson)

Return
