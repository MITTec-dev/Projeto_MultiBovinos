#INCLUDE "TOTVS.CH"
#INCLUDE "AARRAY.CH"
#INCLUDE "JSON.CH"
/************************************************************************************************
************************************************************************************************/
User Function testemb()
    Local _oMultiBV := MultiBovinos():New()
    Local bObject := {|| JsonObject():New()}
    Local oJson   := Eval(bObject)
    Local xx        := 0
    Local _lRet     := .T.
    Local cQuery    := ""
    Local _cJson    := ""
    Local aUMedidas := {}

    dbSelectArea("ZZ1")
    ZZ1->(dbSetOrder(1))
    ZZ1->(dbSeek(cEmpAnt+cFilAnt))

    _oMultiBV:cJSon := "usuario/"+Alltrim(ZZ1->ZZ1_FAZEND)+"/selecione-propriedade/"   //Id do usuario para consulta de propriedades disponiveis. Necessario para o envio do produto, caso haja alguma configuração errada, o retorno será falso e não prosseguirá com o envio dos dados.
    _lRet := _oMultiBV:SetPropriedade()         //Seta a propriedade para o envio, caso haja alguma configuração errada, o retorno será falso e não prosseguirá com o envio dos dados.

    If _lRet
        cQuery := ""
        cQuery += "SELECT AH_FILIAL, AH_UNIMED, AH_DESCPO FROM "+RetSqlName("SAH")+" SAH WHERE AH_FILIAL='"+xFilial("SAH")+"' AND SAH.D_E_L_E_T_='' AND AH_XENVMB='S'"
        cQuery := ChangeQuery(cQuery)
        TCSqlToArr(cQuery, @aUMedidas)
        If Len(aUMedidas) > 0
            For xx := 1 to Len(aUMedidas)
                oJson["nome"]          := SubStr(aUMedidas[xx][3], 1, 50)  //Nome da unidade de medida
                oJson["abreviatura"]   := SubStr(aUMedidas[xx][2], 1, 10)  //Abreviatura da unidade de medida
                oJson["tipo_unidade"]  := "1"                              //Tipo da unidade de medida, 1-Unidade;2-Peso;3-Volume (Litro);4=Metro (MT)
                oJson["multiplicador"] := 1 
            Next
            _cJson := oJson:ToJson(_aaArray)      //Transforma o array em JSON
            _oMultiBV:cJSon := _cJson
            _lRet := _oMultiBV:UnidadesMedidas()   //Envia os dados para o endpoint, caso haja alguma configuração errada, o retorno será falso e não prosseguirá com o envio dos dados.
        EndIf
    EndIf
            
    FreeObj(oJson)

Return

/*
{
    "nome": "ARROBA TESTE INTEGRACAO",
    "abreviatura": "@",
    "tipo_unidade": 2
}
*/
