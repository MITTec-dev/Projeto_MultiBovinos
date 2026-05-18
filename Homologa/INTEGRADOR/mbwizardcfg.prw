#Include "Protheus.ch"
#Include "ApWizard.ch"
#include "TopConn.ch"
#include "RwMake.ch"
#include "TbIconn.ch"

/*/{Protheus.doc} mbwizardcfg
Wizard para configuração do ambiente MultiBovinos

@author Rafael Duram Santos
@since 21/10/2013
/*/

User Function mbwizardcfg()  

Private oOK 	    := LoadBitmap(GetResources(),'NGBIOALERTA_02.png')
Private oNO 	    := LoadBitmap(GetResources(),'NGBIOALERTA_03.png')
Private oYE         := LoadBitmap(GetResources(),'NGBIOALERTA_01.png')
Private oDlg        := Nil
Private oPanelWiz   := Nil
Private oStepWiz    := Nil
Private oNewPag1    := Nil
Private oNewPag2    := Nil
Private oNewPag3    := Nil
Private oNewPag4    := Nil
Private oNewPag5    := Nil
Private oNewPag6    := Nil
Private oBrw1Pg2    := Nil 
Private oBrw1Pg3    := Nil
Private oBrw1Pg4    := Nil
Private oBrw1Pg6    := Nil
Private oBrw2Pg6    := Nil
Private oBrw3Pg6    := Nil
Private oG1Pg6      := Nil
Private oG2Pg6      := Nil
Private oMGetPg6    := Nil
Private oGrp1Pg6    := Nil
Private oGrp2Pg6    := Nil
Private oGrp3Pg6    := Nil
Private cMsgTab     := ""
Private cMsgPrw     := ""
Private cMsgMV1     := ""
Private cMVNGIN     := ""
Private cMVNGLI     := ""
Private cMVPar      := ""
Private xMVCont     := Nil
Private cMVDesc     := ""
Private cGMVNGI     := Space(50)
Private cGMVNGL     := Space(50)
Private aMVGer      := {}
Private aMVNFe      := {}
Private aMVCTe      := {}

oTFont := TFont():New('Arial',,-16,.T.)

//Para que a tela da classe FWWizardControl fique no layout com bordas arredondadas iremos fazer com que a janela do Dialog oculte as bordas e a barra de titulo
//para isso usaremos os estilos WS_VISIBLE e WS_POPUP
DEFINE DIALOG oDlg TITLE STR0001 PIXEL STYLE nOR(  WS_VISIBLE ,  WS_POPUP ) //'MultiBovinos'
    
    oDlg:nWidth := 1150
    oDlg:nHeight := 620

    oPanelWiz:= tPanel():New(0,0,"",oDlg,,,,,,300,150)
    oPanelWiz:Align := CONTROL_ALIGN_ALLCLIENT

    //Instancia a classe FWWizard
    oStepWiz:= FWWizardControl():New(oPanelWiz)
    oStepWiz:ActiveUISteps()

    // Pagina 1
    oNewPag1 := oStepWiz:AddStep("1")
    oNewPag1:SetStepDescription("Boas Vindas") //"Boas Vindas"
    oNewPag1:SetConstruction({|Panel| WizMBPg(Panel,1)})
    oNewPag1:SetNextAction({||.T.})
    oNewPag1:SetCancelAction({|| .T., oDlg:End()})

    //Pagina 2
    oNewPag2 := oStepWiz:AddStep("2")
    oNewPag2:SetStepDescription("Tabelas e Estrutura") //"Tabelas e Estrutura"
    oNewPag2:SetConstruction({|Panel| WizMBPg(Panel,2)})
    oNewPag2:SetNextAction({|| WizMBVld(2)})
    oNewPag2:SetCancelAction({|| .T., oDlg:End()})
    oNewPag2:SetPrevAction({|| .T.})
    oNewPag2:SetPrevTitle("Voltar") //"Voltar"

    //Pagina 3
    oNewPag3 := oStepWiz:AddStep("3")
    oNewPag3:SetStepDescription("Programas") //"Programas"
    oNewPag3:SetConstruction({|Panel| WizMBPg(Panel,3)})
    oNewPag3:SetNextAction({|| WizMBVld(3)})
    oNewPag3:SetCancelAction({|| .T., oDlg:End()})
    oNewPag3:SetPrevAction({|| .T.})
    oNewPag3:SetPrevTitle("Voltar") //"Voltar" 

    //Pagina 4
    oNewPag4 := oStepWiz:AddStep("4")
    oNewPag4:SetStepDescription("Parâmetros Multibovinos") //"Parâmetros Colaboração"
    oNewPag4:SetConstruction({|Panel| WizMBPg(Panel,4)})
    oNewPag4:SetNextAction({|| WizMBVld(4)})
    oNewPag4:SetCancelAction({|| .T., oDlg:End()})
    oNewPag4:SetPrevAction({|| .T.})
    oNewPag4:SetPrevTitle("Voltar") //"Voltar" 

    //Pagina 5
    oNewPag5 := oStepWiz:AddStep("5")
    oNewPag5:SetStepDescription("Config NGINN / NGLIDOS") //"Config NGINN / NGLIDOS"
    oNewPag5:SetConstruction({|Panel| WizMBPg(Panel,5)})
    oNewPag5:SetNextAction({|| WizMBVld(5)})
    oNewPag5:SetCancelAction({|| .T., oDlg:End()})
    oNewPag5:SetPrevAction({|| .T.})
    oNewPag5:SetPrevTitle("Voltar") //"Voltar"

    //Pagina 6
    oNewPag6 := oStepWiz:AddStep("6")
    oNewPag6:SetStepDescription("Config MV's Multibovinos") //"Config MV's Colaboração"
    oNewPag6:SetConstruction({|Panel| WizMBPg(Panel,6)})
    oNewPag6:SetNextAction({|| ( .T., WizMBHlp("Finalizada configuração MultiBovinos","C") , oDlg:End() )}) 
    oNewPag6:SetCancelAction({|| ( .T., oDlg:End() )})
    oNewPag6:SetPrevAction({|| .T.})
    oNewPag6:SetPrevTitle("Voltar") //"Voltar"

    oStepWiz:Activate()

    ACTIVATE DIALOG oDlg CENTER

    oStepWiz:Destroy()

Return

/*/{Protheus.doc} WizMBPg
Wizard - Dados das paginas para configuração do MultiBovinos

@param  oPanel  Painel de dados
@param  nPage   Pagina do painel

@author rodrigo.mpontes
@since 21/10/2013
/*/

Static Function WizMBPg(oPanel,nPage)

Local cDesc1    := ""
Local aTabelas  := {}
Local aFontes   := {}
Local aMVImp    := {}
Local aHdTab    := {}
Local aTamTab   := {}

If nPage == 1 
    cDesc1 := "Boas Vindas" + ": " + CRLF + CRLF + "Essa ferramenta tem a finalidade de facilitar a configuração do MultiBovinos"
    oS1Pg1 := TSay():New(10,10,{|| cDesc1 },oPanel,,oTFont,,,,.T.,,,500,100)

    oS2Pg1 := TSay():New(080,10,{|| "Links Recomendados:" },oPanel,,oTFont,,,,.T.,,,100,50)
    oS2Pg1 := TSay():New(100,10,{|| "Guia de Referência - MultiBovinos" },oPanel,,oTFont,,,,.T.,,,500,50)
    oS2Pg1:blClicked := {|| WizMBOpen("https://")}
    oS2Pg1:nClrText  := CLR_BLUE
    /*
    oS3Pg1 := TSay():New(120,10,{|| "Expedição Contínua Compras" },oPanel,,oTFont,,,,.T.,,,500,50)
    oS3Pg1:blClicked := {|| WizMBOpen("https://tdn.totvs.com/pages/releaseview.action?pageId=522011099")}
    oS3Pg1:nClrText  := CLR_BLUE

    oS4Pg1 := TSay():New(140,10,{|| "Expedição Contínua TSS (ColAutoRead)" },oPanel,,oTFont,,,,.T.,,,500,50)
    oS4Pg1:blClicked := {|| WizMBOpen("https://tdn.totvs.com/pages/releaseview.action?pageId=525010692")}
    oS4Pg1:nClrText  := CLR_BLUE
    */
Elseif nPage == 2 
    aTabelas := WizMBTab()
    aHdTab    := {"Ok","Tabela","Descrição"} 
    aTamTab   := {1,10,200}
    cDesc1 := "Finalidade de validar tabelas e campos do MultiBovinos"
    oS1Pg2 := TSay():New(10,10,{|| cDesc1 },oPanel,,oTFont,,,,.T.,,,600,100)

    oBrw1Pg2 	:= TWBrowse():New(70,10,290,125,,aHdTab,aTamTab,oPanel,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
	oBrw1Pg2:SetArray(aTabelas)
	oBrw1Pg2:bLine	:= { || {   Iif(aTabelas[oBrw1Pg2:nAt,1]==1,oOK,Iif(aTabelas[oBrw1Pg2:nAt,1]==2,oNO,oYE)),;
							    aTabelas[oBrw1Pg2:nAt,2],;
                                aTabelas[oBrw1Pg2:nAt,3]}}

    oMGetPg2 := tMultiget():new( 70, 310, {| u | if( pCount() > 0, cMsgTab := u, cMsgTab ) },oPanel, 220, 125, , , , , , .T. )
Elseif nPage == 3
    aFontes := WizMBPrw()
    aHdTab    := {"Ok","Programas","Responsavel","Data OK","Data Ambiente"} //"Ok"#"Programas"#"Responsavel"#"Data OK"#"Data Ambiente"
    aTamTab   := {1,80,40,60,60}
    cDesc1 := "Descrição" + ': ' + CRLF + CRLF + "Finalidade de validar programas do MultiBovinos"
    oS1Pg3 := TSay():New(10,10,{|| cDesc1 },oPanel,,oTFont,,,,.T.,,,600,100)

    oBrw1Pg3 	:= TWBrowse():New(70,10,290,125,,aHdTab,aTamTab,oPanel,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
	oBrw1Pg3:SetArray(aFontes)
	oBrw1Pg3:bLine	:= { || {   Iif(aFontes[oBrw1Pg3:nAt,1]==1,oOK,Iif(aFontes[oBrw1Pg3:nAt,1]==2,oNO,oYE)),;
							    aFontes[oBrw1Pg3:nAt,2],;
                                aFontes[oBrw1Pg3:nAt,3],;
                                aFontes[oBrw1Pg3:nAt,4],;
                                aFontes[oBrw1Pg3:nAt,5]}}

    oMGetPg3 := tMultiget():new( 70, 310, {| u | if( pCount() > 0, cMsgPrw := u, cMsgPrw ) },oPanel, 220, 125, , , , , , .T. )
Elseif nPage == 4
    aMVImp  := WizMBMV("Col")
    aHdTab  := {"Ok","Parâmetro","Descrição"} //"Ok"#"Parâmetro"#"Descrição"
    aTamTab := {1,60,100}
    cDesc1 := "Descrição" + ': ' + CRLF + CRLF + "Finalidade de validar parâmetros do MultiBovinos"
    oS1Pg4 := TSay():New(10,10,{|| cDesc1 },oPanel,,oTFont,,,,.T.,,,600,100)

    oBrw1Pg4 	:= TWBrowse():New(70,10,290,125,,aHdTab,aTamTab,oPanel,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
	oBrw1Pg4:SetArray(aMVImp)
	oBrw1Pg4:bLine	:= { || {   Iif(aMVImp[oBrw1Pg4:nAt,1]==1,oOK,Iif(aMVImp[oBrw1Pg4:nAt,1]==2,oNO,oYE)),;
							    aMVImp[oBrw1Pg4:nAt,2],;
                                aMVImp[oBrw1Pg4:nAt,3]}}

    oMGetPg4 := tMultiget():new( 70, 310, {| u | if( pCount() > 0, cMsgMV1 := u, cMsgMV1 ) },oPanel, 220, 125, , , , , , .T. )
Elseif nPage == 5
    cMVNGIN	:= SuperGetMV("MV_NGINN",.F.,Space(50))
    If !Empty(cMVNGIN)
        cGMVNGI := cMVNGIN + Space(50)
    Endif
    cMVNGLI	:= SuperGetMV("MV_NGLIDOS",.F.,Space(50))
    If !Empty(cMVNGLI)
        cGMVNGL := cMVNGLI + Space(50)
    Endif

    cDesc1 := "Descrição" + ': ' + CRLF + CRLF + "Definir caminho de onde serão importados os XML (Parâmetros)" + CRLF +; //"Descrição"#"Definir caminho de onde serão importados os XML (Parâmetros)"
			 "Obs: o caminho deve estar dentro do DATA do Protheus." 
    oS1Pg5 := TSay():New(10,10,{|| cDesc1 },oPanel,,oTFont,,,,.T.,,,600,100)

    oS2Pg5 := TSay():New(80,10,{|| "MV_NGINN: "},oPanel,,oTFont,,,,.T.,,,80,20)
	oG1Pg5 := TGet():New(78,120,{|u|If(PCount()==0,cGMVNGI,cGMVNGI := u ) },oPanel,200,20,"@!",,,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"cGMVNGI",,,,)
	
	oS3Pg5 := TSay():New(110,10,{|| "MV_NGLIDOS: "},oPanel,,oTFont,,,,.T.,,,80,20)
    oG2Pg5 := TGet():New(108,120,{|u|If(PCount()==0,cGMVNGL,cGMVNGL := u ) },oPanel,200,20,"@!",,,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"cGMVNGL",,,,)

    oS4Pg5 := TSay():New(150,10,{|| "Documentação: Estrutura de pastas" },oPanel,,oTFont,,,,.T.,,,500,50) //"Documentação: Estrutura de pastas"
    oS4Pg5:blClicked := {|| WizMBOpen("https://tdn.totvs.com/pages/releaseview.action?pageId=271662259")}
    oS4Pg5:nClrText  := CLR_BLUE
Elseif nPage == 6
    aMVGer  := WizMBMV("Ger")
    aMVNfe  := WizMBMV("Nfe")
    aMVCte  := WizMBMV("Cte") 
    
    aHdTab    := {"Parâmetro","Conteudo","Descrição"} //"Parâmetro"#"Conteudo"#"Descrição"
    aTamTab   := {40,20,100}

    //Geral
    oGrp1Pg6:= TGroup():New(05,05,100,185,STR0028,oPanel,,,.T.) //'Geral'
	oBrw1Pg6 	:= TWBrowse():New(15,10,170,80,,aHdTab,aTamTab,oGrp1Pg6,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
	oBrw1Pg6:SetArray(aMVGer)
	oBrw1Pg6:bLine	:= { || {   aMVGer[oBrw1Pg6:nAt,1],;
							    aMVGer[oBrw1Pg6:nAt,2],;
                                aMVGer[oBrw1Pg6:nAt,3]}}  
    oBrw1Pg6:bChange := {|| WizMBAtuMV(oBrw1Pg6,oBrw1Pg6:nAt,oG1Pg6,oG2Pg6,oMGetPg6)}

    //NFe
    oGrp2Pg6:= TGroup():New(05,195,100,380,STR0029,oPanel,,,.T.) //'NFe'
	oBrw2Pg6 	:= TWBrowse():New(15,200,175,80,,aHdTab,aTamTab,oGrp2Pg6,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
	oBrw2Pg6:SetArray(aMVNFe)
	oBrw2Pg6:bLine	:= { || {   aMVNFe[oBrw2Pg6:nAt,1],;
							    aMVNFe[oBrw2Pg6:nAt,2],;
                                aMVNFe[oBrw2Pg6:nAt,3]}}
    oBrw2Pg6:bChange := {|| WizMBAtuMV(oBrw2Pg6,oBrw2Pg6:nAt,oG1Pg6,oG2Pg6,oMGetPg6)}
    
    //CTe
    oGrp3Pg6:= TGroup():New(05,385,100,570,STR0030,oPanel,,,.T.) //'CTe'
	oBrw3Pg6 	:= TWBrowse():New(15,390,175,80,,aHdTab,aTamTab,oGrp3Pg6,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
	oBrw3Pg6:SetArray(aMVCte)
	oBrw3Pg6:bLine	:= { || {   aMVCte[oBrw3Pg6:nAt,1],;
							    aMVCte[oBrw3Pg6:nAt,2],;
                                aMVCte[oBrw3Pg6:nAt,3]}} 
    oBrw3Pg6:bChange := {|| WizMBAtuMV(oBrw3Pg6,oBrw3Pg6:nAt,oG1Pg6,oG2Pg6,oMGetPg6)}
				
	oS2Pg6 := TSay():New(110,010,{|| STR0022 + ": "},oPanel,,oTFont,,,,.T.,,,80,20) //"Parâmetro"
	oG1Pg6 := TGet():New(108,075,{|u|If(PCount()==0,cMVPar,cMVPar := u ) },oPanel,100,20,"@!",,,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"cMVPar",,,,)
    oG1Pg6:bWhen := {|| .F.}
	
	oS3Pg6 := TSay():New(140,010,{|| STR0027 + ": "},oPanel,,oTFont,,,,.T.,,,80,20) //"Conteudo"
	oG2Pg6 := TGet():New(138,075,{|u|If(PCount()==0,xMVCont,xMVCont := u ) },oPanel,100,20,,,,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"xMVCont",,,,)

    oS4Pg6 := TSay():New(110,180,{|| STR0016 + ": "},oPanel,,oTFont,,,,.T.,,,80,20) //"Descrição"
	oMGetPg6 := tMultiget():new(108, 245, {| u | if( pCount() > 0, cMVDesc := u, cMVDesc ) },oPanel, 320, 085, , , , , , .T. )
	
    oBtPg6 := TBrowseButton():New( 140,180,STR0031,oPanel, {|| WizMBSaveMV({oBrw1Pg6,oBrw2Pg6,oBrw3Pg6})},40,20,,,.F.,.T.,.F.,,.F.,,,) //'Salvar'
    oBtPg6:SetColor( CLR_WHITE, rgb(9, 123, 152)) 
Endif

Return

/*/{Protheus.doc} WizMBVld
Wizard - MultiBovinos
Validações das paginas

@param  nPage   Pagina a ser validada

@author rodrigo.mpontes 
@since 21/10/2013
/*/

Static Function WizMBVld(nPage)

Local lRet      := .T.
Local nI        := 0
Local cMsg      := ""
Local cOpc      := "" // B-Bloqueio / A-Aviso

If nPage == 2
    For nI := 1 To Len(oBrw1Pg2:aArray)
        If oBrw1Pg2:aArray[nI,1] == 2
            lRet := .F.
            cMsg := STR0032 + CRLF + STR0033 //"Possui tabelas inexistente e/ou invalidas em seu ambiente. "#"Favor verificar seu ambiente"
            cOpc := "B"
            Exit
        Endif
    Next nI
Elseif nPage == 3
    For nI := 1 To Len(oBrw1Pg3:aArray)
        If oBrw1Pg3:aArray[nI,1] == 2
            lRet := .F.
            cMsg := STR0034 + CRLF + STR0033 //"Possui fontes inexistente em seu ambiente. "#"Favor verificar seu ambiente"
            cOpc := "B"
            Exit
        Elseif oBrw1Pg3:aArray[nI,1] == 3
            lRet := .F.
            cMsg := STR0035 + CRLF + STR0036 //"Possui fontes desatualizados em seu ambiente. "#"MultiBovinos pode não funcionar corretamente. Deseja Prosseguir?"
            cOpc := "A"
            Exit
        Endif
    Next nI
Elseif nPage  == 4
    For nI := 1 To Len(oBrw1Pg4:aArray)
        If oBrw1Pg4:aArray[nI,1] == 2
            lRet := .F.
            cMsg := STR0037 + CRLF + STR0033 //"Possui parâmetros inexistente em seu ambiente. "#"Favor verificar seu ambiente"
            cOpc := "B"
            Exit
        Endif
    Next nI
Elseif nPage  == 5
    If Empty(cGMVNGI) .Or. Empty(cGMVNGL)
        lRet := .F.
        cMsg := STR0038 + CRLF + STR0039 //"Parâmetro MV_NGINN e/ou MV_NGLIDOS não foram preenchidos."#"Favor preencher parâmetros"
        cOpc := "B"
    Endif

    If lRet
        PutMV("MV_IMPXML"   ,.F.)
    	PutMV("MV_NGINN"    ,cGMVNGI)
    	PutMV("MV_NGLIDOS"  ,cGMVNGL)
    Endif
Endif

If !lRet .And. !Empty(cMsg)
    lRet := WizMBHlp(cMsg,cOpc)
Endif

Return lRet

/*/{Protheus.doc} WizMBHlp
Wizard - MultiBovinos
Avisos do wizard

@param  cMsg   Mensagem a ser exibida
@param  cOpc   B-Bloqueio / A-Aviso    

@author rodrigo.mpontes 
@since 21/10/2013
/*/

Static Function WizMBHlp(cMsg,cOpc)

Local lRet      := .F.
Local aOpc    := {}
Local nOpc      := 0

If cOpc == "B" .Or. cOpc == "C"
    aOpc := {STR0014} //"Ok"
Elseif cOpc == "A"
    aOpc := {"Sim","Não"} //"Sim"#"Não"
Endif

nOpc := Aviso("Atenção",cMsg,aOpc) //

If cOpc == "A"
    If nOpc == 1
        lRet := .T.
    Endif
Elseif cOpc == "C"
    lRet := .T.
Endif

Return lRet

/*/{Protheus.doc} WizMBTab
Wizard - MultiBovinos
Validação das tabelas/estrutura

@author rodrigo.mpontes 
@since 21/10/2013
/*/

Static Function WizMBTab()

Local aTabVer   := {{"CKO",;
                     {"CKO_ARQUIV","CKO_XMLRET","CKO_FLAG","CKO_CODEDI","CKO_CODERR","CKO_FILPRO","CKO_EMPPRO","CKO_CNPJIM","CKO_MSGERR",;
                     "CKO_DOC","CKO_NOMFOR","CKO_SERIE","CKO_CHVDOC","CKO_ORIGEM"}},;
                     {"SDS",;
                     {"DS_DOC","DS_SERIE","DS_FORNEC","DS_LOJA","DS_NOMEFOR","DS_CNPJ","DS_TIPO","DS_ESPECI","DS_EMISSA","DS_FORMUL","DS_EST",;
                     "DS_ARQUIVO","DS_CHAVENF","DS_UFDESTR","DS_MUDESTR","DS_MUORITR","DS_UFORITR"}},;
                     {"SDT",;
                     {"DT_ITEM","DT_COD","DT_PRODFOR","DT_DESCFOR","DT_FORNEC","DT_LOJA","DT_DOC","DT_SERIE","DT_CNPJ","DT_QUANT","DT_VUNIT",;
                     "DT_PEDIDO","DT_ITEMPC","DT_NFORI","DT_SERIORI","DT_ITEMORI","DT_TES","DT_LOTE","DT_DTVALID","DT_LOCAL","DT_CHVNFO",;
                     "DT_UM","DT_SEGUM","DT_QTSEGUM","DT_CLASFIS"}}}

Local aTabRet   := {}
Local nI        := 0
Local cMsgEst   := ""

For nI := 1 To Len(aTabVer)
    cMsgTab += "Tabela: " + ": " + aTabVer[nI,1] + CRLF //
    cMsgEst := ""
    If ChkFile(aTabVer[nI,1])
        If aTabVer[nI,1] == "CKO"
            If RetSqlName("CKO") <> "CKOCOL"
                cMsgTab += "[ERROR].......... " + STR0043 + CRLF + CRLF + CRLF + CRLF //"Tabela: inexistente e/ou diferente de CKOCOL no ambiente"
                aAdd(aTabRet,{2,aTabVer[nI,1],FwSX2Util():GetX2Name(aTabVer[nI,1])})
            Else
                cMsgTab += "[OK]............. " + "Tabela: OK"  + CRLF //
                cMsgEst := WizMBEst(aTabVer[nI,1],aTabVer[nI,2]) + CRLF + CRLF + CRLF
                cMsgTab += cMsgEst
                aAdd(aTabRet,{Iif("WARNING" $ cMsgEst,3,1),aTabVer[nI,1],FwSX2Util():GetX2Name(aTabVer[nI,1])})
            Endif
        Else
            cMsgTab += "[OK]............. " + "Tabela: OK" + CRLF
            cMsgEst := WizMBEst(aTabVer[nI,1],aTabVer[nI,2]) + CRLF + CRLF + CRLF
            cMsgTab += cMsgEst
            aAdd(aTabRet,{Iif("WARNING" $ cMsgEst,3,1),aTabVer[nI,1],FwSX2Util():GetX2Name(aTabVer[nI,1])}) 
        Endif
    Else
        cMsgTab += "[ERROR].......... " + "Tabela: inexistente no ambiente" + CRLF + CRLF + CRLF + CRLF
        aAdd(aTabRet,{2,aTabVer[nI,1],FwSX2Util():GetX2Name(aTabVer[nI,1])})
    Endif
Next nI

Return aTabRet

/*/{Protheus.doc} WizMBEst
Wizard - MultiBovinos
Validação das estrutura da tabela

@author rodrigo.mpontes 
@since 21/10/2013
/*/

Static Function WizMBEst(cTab,aEstTab)

Local aAllCpo   := FWSX3Util():GetAllFields( cTab ,.T.)
Local cMsgRet   := ""
Local nI        := 0
Local cMsg      := ""

For nI := 1 To Len(aEstTab)
    nPos := aScan(aAllCpo,{|x| AllTrim(x) == AllTrim(aEstTab[nI])})
    If nPos == 0
        cMsg += " | " + aEstTab[nI]
    Endif
Next nI

If !Empty(cMsg)
    cMsg := SubStr(cMsg,4,Len(cMsg))
    cMsgRet += "[WARNING]........ " + "Estrutura: " + cMsg + " campo(s) inexistente(s) no ambiente"
Else
    cMsgRet += "[OK]............. " + "Estrutura: " + "OK"
Endif

Return cMsgRet

/*/{Protheus.doc} WizMBPrw
Wizard - MultiBovinos
Validação do binario e fontes

@author rodrigo.mpontes 
@since 21/10/2013
/*/

Static Function WizMBPrw() 

Local aPrwVer   := {{"MBMONITR.PRW","01/06/2026","CFG"},;
                    {"MATUMNT.PRW","01/06/2026","CFG"},;
                    {"MBENVIO.PRW","01/06/2026","CFG"},;
                    {"MBMATERIAIS.PRW","01/06/2026","CFG"},;
                    {"MULTIBOVINOS.PRW","01/06/2026","CFG"}}
Local aPrwRet   := {}
Local nI        := 0
Local aDados    := {}
Local cDtTime   := ""
Local cDtTRpo   := ""

For nI := 1 To Len(aPrwVer)
    
    cMsgPrw += "Fonte: " + aPrwVer[nI,1] + CRLF
    cDtTime := aPrwVer[nI,2]
    
    aDados := GetApoInfo(aPrwVer[nI,1])

    If Len(aDados) > 0
        cDtTRpo := DtoC(aDados[4])
        
        If CtoD(cDtTRpo) < CtoD(cDtTime)
            cMsgPrw += "[WARNING]........ " + "Fonte: " + "Desatualizado" + CRLF + CRLF 
            aAdd(aPrwRet,{3,aPrwVer[nI,1],aPrwVer[nI,3],cDtTime,cDtTRpo}) 
        Else
            cMsgPrw += "[OK]............. " + "Fonte: " + "OK" + CRLF + CRLF
            aAdd(aPrwRet,{1,aPrwVer[nI,1],aPrwVer[nI,3],cDtTime,cDtTRpo}) 
        Endif
    Else
        cMsgPrw += "[ERROR].......... " + "Fonte: " + "inexistente no ambiente" + CRLF + CRLF
        aAdd(aPrwRet,{2,aPrwVer[nI,1],aPrwVer[nI,3],cDtTime,""})
    Endif
    
Next nI

Return aPrwRet

/*/{Protheus.doc} WizMBMV
Wizard - MultiBovinos
Validação dos parametros

@param  cOpc    Tipo dos parametros
                    Col - MultiBovinos
                    Ger - Geral - MultiBovinos
                    NFe - NFe - MultiBovinos
                    CTe - CTe - MultiBovinos

@author rodrigo.mpontes 
@since 21/10/2013
/*/

Static Function WizMBMV(cOpc)

Local aMVVer    := {}
Local aMVRet    := {}
Local aAux      := {}
Local nI        := 0
Local cMsg      := ""
Local cDescMV   := ""
Local xConteudo := Nil

If cOpc == "Col" //MultiBovinos
    aMVVer := {"MV_COMCOL1","MV_COMCOL2","MV_COMCOL3","MV_MSGCOL","MV_FILREP","MV_XMLCFPC","MV_XMLCFBN","MV_XMLCFDV","MV_XMLCFND","MV_XMLCFNO",;
                "MV_CTECLAS","MV_XMLPFCT","MV_XMLTECT","MV_XMLCPCT","MV_COLVCHV","MV_VLRCTE"}
Elseif cOpc == "Ger" //Geral
    aMVVer := {"MV_COMCOL1","MV_COMCOL2","MV_COMCOL3","MV_MSGCOL","MV_FILREP"}
Elseif cOpc == "Nfe"
    aMVVer := {"MV_XMLCFPC","MV_XMLCFBN","MV_XMLCFDV","MV_XMLCFND","MV_XMLCFNO"}
Elseif cOpc == "Cte"
    aMVVer := {"MV_CTECLAS","MV_XMLPFCT","MV_XMLTECT","MV_XMLCPCT","MV_COLVCHV","MV_VLRCTE"}
Endif

dbSelectArea( "SX6" )
SX6->( dbSetOrder( 1 ) )

For nI := 1 To Len(aMVVer)
    cMsg += "Parâmetro: " + aMVVer[nI] + CRLF //"Parâmetro: "
    cDescMV := ""
    
    If FWSX6Util():ExistsParam( aMVVer[nI] )
        If SX6->( MsSeek( FwxFilial("SX6") + aMVVer[nI] ) )
            cDescMV     := AllTrim(X6Descric()) + " " + AllTrim(X6Desc1()) + " " + AllTrim(X6Desc2())
            xConteudo	:= X6Conteud()

            cMsg += "[OK]............. " + "Parâmetro: " + "OK" + CRLF + CRLF //#"OK"
            aAdd(aMVRet,{1,aMVVer[nI],cDescMV,xConteudo}) 
        Endif
    Else
        cMsg += "[ERROR].......... " + "Parâmetro: " + "inexistente no ambiente" + CRLF + CRLF //"Parâmetro: "#"inexistente no ambiente"
        aAdd(aMVRet,{2,aMVVer[nI],cDescMV})
    Endif
Next nI

If cOpc == "Col"
    cMsgMV1 := cMsg
Endif

If cOpc == "Ger" .Or. cOpc == "Nfe" .Or. cOpc == "Cte"
    For nI := 1 To Len(aMVRet)
        aAdd(aAux,{aMVRet[nI,2],aMVRet[nI,4],aMVRet[nI,3]})
    Next nI

    If Len(aAux) > 0
        aMVRet := aAux
    Endif
Endif

Return aMVRet

/*/{Protheus.doc} WizMBAtuMV
Wizard - MultiBovinos
Refresh Parametros

@author rodrigo.mpontes 
@since 21/10/2013
/*/

Static Function WizMBAtuMV(oObj,nLinha,oObjG1,oObjG2,oObjM1)

cMVPar  := oObj:aArray[nLinha,1]
xMVCont := oObj:aArray[nLinha,2]
cMVDesc := oObj:aArray[nLinha,3]

oObjG1:Refresh()
oObjG2:Refresh()
oObjM1:Refresh()

Return

/*/{Protheus.doc} WizMBSaveMV
Wizard - MultiBovinos
Atualizar parametros MV

@author rodrigo.mpontes 
@since 21/10/2013
/*/

Static Function WizMBSaveMV(aObj)

Local nPos  := 0
Local nI    := 0
Local oObj  := Nil

PutMV(cMVPar,xMVCont)

For nI := 1 To Len(aObj)
    oObj := aObj[nI]

    nPos := aScan(oObj:aArray,{|x| AllTrim(x[1]) == AllTrim(cMVPar)})
    If nPos > 0
        oObj:aArray[nPos,2] := xMVCont
        oObj:Refresh()
    Endif
Next nI

Return .T.

/*/{Protheus.doc} WizMBOpen
Wizard - MultiBovinos
Abrir link

@author rodrigo.mpontes 
@since 21/10/2013
/*/

Static Function WizMBOpen(cLink)

ShellExecute("Open", cLink, "", "", 1)

Return
