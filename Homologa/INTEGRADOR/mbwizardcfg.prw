#Include "Protheus.ch"
#Include "ApWizard.ch"
#include "TopConn.ch"
#include "RwMake.ch"
#include "TbIconn.ch"

/*******************************************************************************
mbwizardcfg
Wizard para configuração do ambiente MultiBovinos
*******************************************************************************/
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

    Private cMsgSch     := ""
    Private oMGetPg7    := Nil
    Private oBmpDt7     := Nil
    Private oS1Dt8      := Nil
    Private oBrw1Pg7    := Nil

    Private cMsgTab     := ""
    Private cMsgPrw     := ""
    Private cMsgMV1     := ""
    Private cMVNGIN     := ""
    Private cMVNGLI     := ""
    Private cMVPar      := ""
    Private xMVCont     := Nil
    Private cMVDesc     := ""
    Private aMVMB      := {}
    Private aMVNFe      := {}
    Private aMVCTe      := {}

    oTFont := TFont():New('Arial',,-16,.T.)

    //Para que a tela da classe FWWizardControl fique no layout com bordas arredondadas iremos fazer com que a janela do Dialog oculte as bordas e a barra de titulo
    //para isso usaremos os estilos WS_VISIBLE e WS_POPUP
    DEFINE DIALOG oDlg TITLE 'MultiBovinos' PIXEL STYLE nOR(  WS_VISIBLE ,  WS_POPUP )

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
        oNewPag5:SetStepDescription("Config Parâmetros Integrador") //"Config NGINN / NGLIDOS"
        oNewPag5:SetConstruction({|Panel| WizMBPg(Panel,5)})
        oNewPag5:SetNextAction({|| WizMBVld(5)})
        oNewPag5:SetCancelAction({|| .T., oDlg:End()})
        oNewPag5:SetPrevAction({|| .T.})
        oNewPag5:SetPrevTitle("Voltar")
        //Pagina 6
        oNewPag6 := oStepWiz:AddStep("6")
        oNewPag6:SetStepDescription("Config Schedule") //"Config NGINN / NGLIDOS"
        oNewPag6:SetConstruction({|Panel| WizMBPg(Panel,6)})
        oNewPag6:SetNextAction({|| ( .T., WizMBHlp("Finalizada configuração do Integrador do MultiBovinos","C") , oDlg:End() )})
        oNewPag6:SetCancelAction({|| .T., oDlg:End()})
        oNewPag6:SetPrevAction({|| .T.})
        oNewPag6:SetPrevTitle("Voltar")

        oStepWiz:Activate()

        ACTIVATE DIALOG oDlg CENTER

        oStepWiz:Destroy()

Return

/*******************************************************************************
    Dados das paginas para configuração do Integrador do MultiBovinos
*******************************************************************************/
Static Function WizMBPg(oPanel,nPage)
    Local cDesc1    := ""
    Local aTabelas  := {}
    Local aFontes   := {}
    Local aSchedule := {}
    Local aMVImp    := {}
    Local aHdTab    := {}
    Local aTamTab   := {}
    Local cLink     := SuperGetMV("MB_XLNKREF",.F.,"https://multsoft.agr.br/o-multbovinos/")

    If nPage == 1
        cDesc1 := "Boas Vindas" + ": " + CRLF + CRLF + "Essa ferramenta tem a finalidade de facilitar a configuração do Integrador do ERP com o MultiBovinos"
        oS1Pg1 := TSay():New(10,10,{|| cDesc1 },oPanel,,oTFont,,,,.T.,,,500,100)

        oS2Pg1 := TSay():New(080,10,{|| "Link Recomendado:" },oPanel,,oTFont,,,,.T.,,,100,50)
        oS2Pg1 := TSay():New(100,10,{|| "Guia de Referência - MultiBovinos" },oPanel,,oTFont,,,,.T.,,,500,50)
        oS2Pg1:blClicked := {|| WizMBOpen(cLink)}
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
        cDesc1 := "Finalidade de validar tabelas e campos necessários para o Integrador do MultiBovinos"
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
        cDesc1 := "Descrição" + ': ' + CRLF + CRLF + "Finalidade de validar programas do Integrador do MultiBovinos"
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
        aMVImp  := WizMBMV("MB",nPage)
        aHdTab  := {"Ok","Parâmetro","Descrição"} //"Ok"#"Parâmetro"#"Descrição"
        aTamTab := {1,60,100}
        cDesc1 := "Descrição" + ': ' + CRLF + CRLF + "Finalidade de validar parâmetros do Integrador do MultiBovinos"
        oS1Pg4 := TSay():New(10,10,{|| cDesc1 },oPanel,,oTFont,,,,.T.,,,600,100)

        oBrw1Pg4 	:= TWBrowse():New(70,10,290,125,,aHdTab,aTamTab,oPanel,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
    	oBrw1Pg4:SetArray(aMVImp)
    	oBrw1Pg4:bLine	:= { || {   Iif(aMVImp[oBrw1Pg4:nAt,1]==1,oOK,Iif(aMVImp[oBrw1Pg4:nAt,1]==2,oNO,oYE)),;
    							    aMVImp[oBrw1Pg4:nAt,2],;
                                    aMVImp[oBrw1Pg4:nAt,3]}}

        oMGetPg4 := tMultiget():new( 70, 310, {| u | if( pCount() > 0, cMsgMV1 := u, cMsgMV1 ) },oPanel, 220, 125, , , , , , .T. )
    Elseif nPage == 5
        aMVMB  := WizMBMV("MB",nPage)

        aHdTab    := {"Parâmetro","Conteudo","Descrição"}
        aTamTab   := {40,20,100}

        oGrp1Pg6:= TGroup():New(05,05,100,555,'MultiBovinos',oPanel,,,.T.)
    	oBrw1Pg6:= TWBrowse():New(15,10,540,80,,aHdTab,aTamTab,oGrp1Pg6,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
    	oBrw1Pg6:SetArray(aMVMB)
    	oBrw1Pg6:bLine	:= { || {aMVMB[oBrw1Pg6:nAt,2],;
                                 aMVMB[oBrw1Pg6:nAt,4],;
                                 aMVMB[oBrw1Pg6:nAt,3]}}  
        oBrw1Pg6:bChange := {|| WizMBAtuMV(oBrw1Pg6,oBrw1Pg6:nAt,oG1Pg6,oG2Pg6,oMGetPg6)}

    	oS2Pg6 := TSay():New(110,010,{|| "Parâmetro" + ": "},oPanel,,oTFont,,,,.T.,,,80,20)
    	oG1Pg6 := TGet():New(108,075,{|u|If(PCount()==0,cMVPar,cMVPar := u ) },oPanel,100,20,"@!",,,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"cMVPar",,,,)
        oG1Pg6:bWhen := {|| .F.}
    
    	oS3Pg6 := TSay():New(140,010,{|| "Conteudo" + ": "},oPanel,,oTFont,,,,.T.,,,80,20) //"Conteudo"
    	oG2Pg6 := TGet():New(138,075,{|u|If(PCount()==0,xMVCont,xMVCont := u ) },oPanel,100,20,,,,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"xMVCont",,,,)

        oS4Pg6 := TSay():New(110,180,{|| "Descrição" + ": "},oPanel,,oTFont,,,,.T.,,,80,20) //"Descrição"
    	oMGetPg6 := tMultiget():new(108, 245, {| u | if( pCount() > 0, cMVDesc := u, cMVDesc ) },oPanel, 320, 085, , , , , , .T. )
    
        oBtPg6 := TBrowseButton():New( 140,180,'Salvar',oPanel, {|| WizMBSaveMV({oBrw1Pg6,oBrw2Pg6,oBrw3Pg6})},40,20,,,.F.,.T.,.F.,,.F.,,,) 
        oBtPg6:SetColor( CLR_WHITE, rgb(9, 123, 152)) 
    Elseif nPage == 6
        aSchedule := WizImpSched()
        IncSched(aSchedule)

		aHdTab  := {"Ok","Rotina","Descrição da Rotina"}
		aTamTab := {1,60,100}
        If totvs.framework.smartschedule.startSchedule.smartSchedIsRunning()
            oBmpDt7 := TBitmap():New(008, 110, 260, 184, "NGBIOALERTA_02", NIL, .T., oPanel, {|| .T. }, NIL, .F., .F., NIL, NIL, .F., NIL, .T., NIL, .F.)
            oS1Dt8 := TSay():New(10,125,{|| "Em Execução"},oPanel,,oTFont,,,,.T.,,,180,150)
        Else
            oBmpDt7 := TBitmap():New(008, 110, 260, 184, "NGBIOALERTA_03", NIL, .T., oPanel, {|| .T. }, NIL, .F., .F., NIL, NIL, .F., NIL, .T., NIL, .F.)
            oS1Dt8 := TSay():New(10,125,{|| "Parado"},oPanel,,oTFont,,,,.T.,,,180,150)
        Endif
        oBrw1Pg7 := TWBrowse():New(50,05,298,125,,aHdTab,aTamTab,oPanel,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
        oBrw1Pg7:SetArray(aSchedule)
        oBrw1Pg7:bLine	:= { || {If(aSchedule[oBrw1Pg7:nAt,1],oOK,oNO),;
                                    aSchedule[oBrw1Pg7:nAt,2],;
                                    aSchedule[oBrw1Pg7:nAt,3]}}
        oMGetPg7 := tMultiget():New( 50, 310, {| u | if( pCount() > 0, cMsgSch := u, cMsgSch ) },oPanel, 220, 125, , , , , , .T. )
    Endif

Return

/*******************************************************************************
    Validações das paginas
    Wizard - MultiBovinos
*******************************************************************************/
Static Function WizMBVld(nPage)
    Local lRet      := .T.
    Local nI        := 0
    Local cMsg      := ""
    Local cOpc      := "" // B-Bloqueio / A-Aviso

    If nPage == 2
        For nI := 1 To Len(oBrw1Pg2:aArray)
            If oBrw1Pg2:aArray[nI,1] == 2
                lRet := .F.
                cMsg := "Possui tabelas inexistente e/ou invalidas em seu ambiente. " + CRLF + "Favor verificar seu ambiente"
                cOpc := "B"
                Exit
            Endif
        Next nI
    Elseif nPage == 3
        For nI := 1 To Len(oBrw1Pg3:aArray)
            If oBrw1Pg3:aArray[nI,1] == 2
                lRet := .F.
                cMsg := "Possui fontes inexistente em seu ambiente. " + CRLF + "Favor verificar seu ambiente"
                cOpc := "B"
                Exit
            Elseif oBrw1Pg3:aArray[nI,1] == 3
                lRet := .F.
                cMsg := "Possui fontes desatualizados em seu ambiente. " + CRLF + "A Integração com MultiBovinos pode não funcionar corretamente. Deseja Prosseguir?"
                cOpc := "A"
                Exit
            Endif
        Next nI
    Elseif nPage  == 4
        For nI := 1 To Len(oBrw1Pg4:aArray)
            If oBrw1Pg4:aArray[nI,1] == 2
                lRet := .F.
                //cMsg := "Possui parâmetros inexistente em seu ambiente. " + CRLF + "Favor verificar seu ambiente"
                cMsg := "Possui parâmetros inexistente em seu ambiente. " + CRLF + "A Integração com MultiBovinos pode não funcionar corretamente. Deseja Prosseguir?"
                cOpc := "A"
                Exit
            Endif
        Next nI
    Elseif nPage  == 5
    Elseif nPage  == 6
    Endif

    If !lRet .And. !Empty(cMsg)
        lRet := WizMBHlp(cMsg,cOpc)
    Endif

Return lRet

/*******************************************************************************
    Wizard - MultiBovinos
    Avisos do wizard
*******************************************************************************/
Static Function WizMBHlp(cMsg,cOpc)
    Local lRet      := .F.
    Local aOpc    := {}
    Local nOpc      := 0

    If cOpc == "B" .Or. cOpc == "C"
        aOpc := {"Ok"}
    Elseif cOpc == "A"
        aOpc := {"Sim","Não"} //"Sim"#"Não"
    Endif

    nOpc := Aviso("Atenção",cMsg,aOpc) 

    If cOpc == "A"
        If nOpc == 1
            lRet := .T.
        Endif
    Elseif cOpc == "C"
        lRet := .T.
    Endif

Return lRet

/*******************************************************************************
    Validação das tabelas/estrutura
    Wizard - MultiBovinos
*******************************************************************************/
Static Function WizMBTab()
    Local aTabVer   := {{"SA2",{"A2_XENVMB","A2_XIDMB"}},;
                        {"SAH",{"AH_XIDMB"}},;
                        {"SB1",{"B1_XENVMB","B1_XSGRUPO","B1_XIDMB"}},;
                        {"SBM",{"BM_XIDMB"}},;
                        {"SF1",{"F1_XIDMB"}},;
                        {"ZZ0",{"ZZ0_FILIAL","ZZ0_ID","ZZ0_CHAVE","ZZ0_SEQ","ZZ0_DTINC","ZZ0_HRINC","ZZ0_JSON","ZZ0_DTPINI","ZZ0_HRPINI","ZZ0_DTPFIM","ZZ0_HRPFIM","ZZ0_STPROC","ZZ0_TENTAT","ZZ0_FAZEND","ZZ0_JSONRE"}},;
                        {"ZZ1",{"ZZ1_FILIAL","ZZ1_ID","ZZ1_CHAVE","ZZ1_ZZ0SEQ","ZZ1_SEQ","ZZ1_DTHIST","ZZ1_HRHIST","ZZ1_JSON","ZZ1_ERRO"}},;
                        {"ZZ2",{"ZZ2_FILIAL","ZZ2_FAZEND","ZZ2_NOME"}},;
                        {"ZZ3",{"ZZ3_FILIAL","ZZ3_COD","ZZ3_DESC"}}}

    Local aTabRet   := {}
    Local nI        := 0
    Local cMsgEst   := ""

    For nI := 1 To Len(aTabVer)
        cMsgTab += "Tabela: " + ": " + aTabVer[nI,1] + CRLF //
        cMsgEst := ""
        If ChkFile(aTabVer[nI,1])
            cMsgTab += "[OK]............. " + "Tabela: OK" + CRLF
            cMsgEst := WizMBEst(aTabVer[nI,1],aTabVer[nI,2]) + CRLF + CRLF + CRLF
            cMsgTab += cMsgEst
            aAdd(aTabRet,{Iif("WARNING" $ cMsgEst,3,1),aTabVer[nI,1],FwSX2Util():GetX2Name(aTabVer[nI,1])}) 
        Else
            cMsgTab += "[ERROR].......... " + "Tabela: inexistente no ambiente" + CRLF + CRLF + CRLF + CRLF
            aAdd(aTabRet,{2,aTabVer[nI,1],FwSX2Util():GetX2Name(aTabVer[nI,1])})
        Endif
    Next nI

Return aTabRet

/*******************************************************************************
    Validação das estrutura da tabela
    Wizard - MultiBovinos
*******************************************************************************/
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

/*******************************************************************************
    Wizard - MultiBovinos
    Validação do binario e fontes
*******************************************************************************/
Static Function WizMBPrw() 
    Local aPrwVer   := {{"MBMONITOR.PRW","01/04/2026","CFG"},;
                        {"MBATUMNT.PRW","01/04/2026","CFG"},;
                        {"MBCADASTROS.PRW","01/04/2026","CFG"},;
                        {"MBENVIO.PRW","01/04/2026","CFG"},;
                        {"MBMATERIAIS.PRW","01/04/2026","CFG"},;
                        {"MBENTANIMAIS.PRW","01/04/2026","CFG"},;
                        {"MBENTPRODUTOS.PRW","01/04/2026","CFG"},;
                        {"MBENVIO.PRW","01/04/2026","CFG"},;
                        {"MULTIBOVINOS.PRW","01/04/2026","CFG"}}
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

/*******************************************************************************
    Wizard - MultiBovinos
    Validação dos parametros
*******************************************************************************/
Static Function WizMBMV(cOpc,nPage)
    Local aMVVer    := {}
    Local aMVRet    := {}
    //Local aAux      := {}
    Local nI        := 0
    Local cMsg      := ""
    Local cDescMV   := ""
    Local xConteudo := Nil

    If cOpc == "MB" //MultiBovinos
        aMVVer := {"MB_PFTOKEN","MB_XMBCFOA","MB_XMBCFOP","MB_XMBCLIP","MB_XMBCLIT","MB_XMBDTAI","MB_XMBENVP","MB_XMBENVT",;
        "MB_XMBPASP","MB_XMBPAST","MB_XMBQDFI","MB_XMBTESA","MB_XMBTESP","MB_XMBTOKE","MB_XMBURLP","MB_XMBURLT","MB_XLNKREF"}
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
        ElseIf nPage==4
            cMsg += "[ERROR].......... " + "Parâmetro: " + "inexistente no ambiente" + CRLF + CRLF //"Parâmetro: "#"inexistente no ambiente"
            aAdd(aMVRet,{2,aMVVer[nI],cDescMV,""})
        Endif
    Next nI

    If cOpc == "MB"
        cMsgMV1 := cMsg
    Endif

Return aMVRet

/******************************************************************************
    Refresh Parametros
    Wizard - MultiBovinos
*******************************************************************************/
Static Function WizMBAtuMV(oObj,nLinha,oObjG1,oObjG2,oObjM1)
    cMVPar  := oObj:aArray[nLinha,2]
    cMVDesc := oObj:aArray[nLinha,3]
    xMVCont := oObj:aArray[nLinha,4]

    oObjG1:Refresh()
    oObjG2:Refresh()
    oObjM1:Refresh()

Return

/******************************************************************************
    Atualizar parametros MV
    Wizard - MultiBovinos
*******************************************************************************/
Static Function WizMBSaveMV(oObj)
    Local nPos  := 0
    Local nI    := 1

    PutMV(cMVPar,xMVCont)

    nPos := aScan(oObj[nI]:aArray,{|x| AllTrim(x[2]) == AllTrim(cMVPar)})
    If nPos > 0
        oObj[nI]:aArray[nPos,4] := xMVCont
        oObj[nI]:Refresh()
    Endif

Return .T.

/******************************************************************************
    Funcao Estatica - WizMBOpen
    Descrição: Responsável por abrir os links do Wizard
    Wizard - MultiBovinos
*******************************************************************************/

Static Function WizMBOpen(cLink)

ShellExecute("Open", cLink, "", "", 1)

Return
/*******************************************************************************
    Funcao Estatica - incSched
    Descrição: Responsável por incluir os processos no Schedule do Protheus
********************************************************************************/
Static Function IncSched(aSchedule)
    Local nX        := 0
    Local oSchedule := Nil

    oSchedule := totvs.protheus.backoffice.com.general.schedule():new()

    If  !( oSchedule:lLibVersion ) .or.  !( oSchedule:lUsrAdmin )
        lStsSched := .F.
        cMsgSch := oSchedule:cMsgError
    Else
        For nX := 1 to len(aSchedule)
            If !aSchedule[nX,6]
                oSchedule := totvs.protheus.backoffice.com.general.schedule():new()
                oSchedule:createSched(aSchedule[nX,5])
                lStsSched := oSchedule:lInsert
                If !(lStsSched)
                    Exit
                Endif
            Endif
        Next nX		
    Endif
Return

/*******************************************************************************
    Funcao Estatica - WizImpSched
    Descrição: Responsável por incluir os processos no Schedule do Protheus
********************************************************************************/
Static Function WizImpSched()
    Local aAux	    := {}
    Local aRet	    := {}
    Local nX	    := 0
    Local nAddAgend := 0
    Local lTemAgend
    Local lCadAgend := .F.
    //Local aSM0Grp   := { FWAllFilial( , , cEmpAnt, .F.)[1] }
    Local aSM0Fil   := {}
    Local aParam    := {}
    Local aGrpComp  := {}
    /*
    aParam   := {  "MBENTANIMAIS"      ,;  // setRoutine
                    nModulo             ,;  // setModule
                    "000000"            ,;  // setUser
                    "Envia atualização dos custos de Entrada de Animais para o MultiBovinos",;
                    .T.                 ,;  // setRecurrence
                    {'D', , 1, 0, }     ,;  // setPeriod
                    {'M', 10, , , }     ,;  // setFrequency
                    .T.                 ,;  // setDiscard
                    .T.                 ,;  // setManageable
                    {{ cEmpAnt, aSM0Grp }},; 
                    { DATE(),TIME() }    ;   // setFirstExecution
                }
    AADD(aAux,{'MBENTANIMAIS',"Envia atualização dos custos de Entrada de Animais para o MultiBovinos",aParam})

    aParam  := {    "MBENTPRODUTOS"       ,;  // setRoutine
                    nModulo             ,;  // setModule
                    "000000"            ,;  // setUser
                    "Envia entrada de Produtos pelas notas de Entradas para o MultiBovinos",;
                    .T.                 ,;  // setRecurrence
                    {'D', , 1, 0, }     ,;  // setPeriod
                    {'M', 20, , , }     ,;  // setFrequency
                    .T.                 ,;  // setDiscard
                    .T.                 ,;  // setManageable
                    {{ cEmpAnt, aSM0Grp }},; 
                    { DATE(),TIME() }   ;   // setFirstExecution
                }
    AADD(aAux,{'MBENTPRODUTOS',"Envia entrada de Produtos pelas notas de Entradas para o MultiBovinos",aParam})

    aParam  := {    "MBENVIO"           ,;  // setRoutine
                    nModulo             ,;  // setModule
                    "000000"            ,;  // setUser
                    "Envio dos cadastros para o MultiBovinos",;
                    .T.                 ,;  // setRecurrence
                    {'D', , 1, 0, }     ,;  // setPeriod
                    {'M', 30, , , }     ,;  // setFrequency
                    .T.                 ,;  // setDiscard
                    .T.                 ,;  // setManageable
                    {{ cEmpAnt, aSM0Grp }} ,; 
                    { DATE(),TIME() }   ;   // setFirstExecution
                }
    AADD(aAux,{'MBENVIO',"Envio dos cadastros para o MultiBovinos",aParam})

    aParam  := {    "MBMATERIAIS"           ,;  // setRoutine
                    nModulo             ,;  // setModule
                    "000000"            ,;  // setUser
                    "Recepcao das movimentacoes de materiais no MultiBovinos para o estoque do ERP",;
                    .T.                 ,;  // setRecurrence
                    {'D', , 1, 0, }     ,;  // setPeriod
                    {'M', 30, , , }     ,;  // setFrequency
                    .T.                 ,;  // setDiscard
                    .T.                 ,;  // setManageable
                    {{ cEmpAnt, aSM0Grp }} ,; 
                    { DATE(),TIME() }   ;   // setFirstExecution
                }
    AADD(aAux,{'MBMATERIAIS',"Recepcao das movimentacoes de materiais no MultiBovinos para o estoque do ERP",aParam})
    */

    aGrpComp := FWAllGrpCompany()
    aSM0Fil  := {}
    aEval(aGrpComp,{|x| aadd(aSM0Fil, { x, FWAllFilial( , , x, .F.) }) })
    /*
    aParam  := {    "SCHEDCOMCOL"       ,;  // setRoutine
                    nModulo             ,;  // setModule
                    "000000"            ,;  // setUser
                    "Rotina para efetuar a leitura dos XML's na tabela CKO e importar ao monitor (Tabelas SDS e SDT)."             ,;  // setDescription
                    .T.                 ,;  // setRecurrence
                    {'D', , 1, 0, }     ,;  // setPeriod
                    {'M', 20, , , }     ,;  // setFrequency
                    .T.                 ,;  // setDiscard
                    .T.                 ,;  // setManageable
                    aSM0Fil             ,; 
                    { DATE(),TIME() }   ;   // setFirstExecution
                }
    AADD(aAux,{'SCHEDCOMCOL',"Rotina para efetuar a leitura dos XML's na tabela CKO e importar ao monitor (Tabelas SDS e SDT).",aParam})	// 
    */
    aParam   := {  "MBENTANIMAIS"      ,;  // setRoutine
                    nModulo             ,;  // setModule
                    "000000"            ,;  // setUser
                    "Envia atualização dos custos de Entrada de Animais para o MultiBovinos",;
                    .T.                 ,;  // setRecurrence
                    {'D', , 1, 0, }     ,;  // setPeriod
                    {'M', 10, , , }     ,;  // setFrequency
                    .T.                 ,;  // setDiscard
                    .T.                 ,;  // setManageable
                    aSM0Fil             ,; 
                    { DATE(),TIME() }    ;   // setFirstExecution
                }
    AADD(aAux,{'MBENTANIMAIS',"Envia atualização dos custos de Entrada de Animais para o MultiBovinos",aParam})

    aParam  := {    "MBENTPRODUTOS"       ,;  // setRoutine
                    nModulo             ,;  // setModule
                    "000000"            ,;  // setUser
                    "Envia entrada de Produtos pelas notas de Entradas para o MultiBovinos",;
                    .T.                 ,;  // setRecurrence
                    {'D', , 1, 0, }     ,;  // setPeriod
                    {'M', 20, , , }     ,;  // setFrequency
                    .T.                 ,;  // setDiscard
                    .T.                 ,;  // setManageable
                    aSM0Fil             ,; 
                    { DATE(),TIME() }   ;   // setFirstExecution
                }
    AADD(aAux,{'MBENTPRODUTOS',"Envia entrada de Produtos pelas notas de Entradas para o MultiBovinos",aParam})

    aParam  := {    "MBENVIO"           ,;  // setRoutine
                    nModulo             ,;  // setModule
                    "000000"            ,;  // setUser
                    "Envio dos cadastros para o MultiBovinos",;
                    .T.                 ,;  // setRecurrence
                    {'D', , 1, 0, }     ,;  // setPeriod
                    {'M', 30, , , }     ,;  // setFrequency
                    .T.                 ,;  // setDiscard
                    .T.                 ,;  // setManageable
                    aSM0Fil             ,; 
                    { DATE(),TIME() }   ;   // setFirstExecution
                }
    AADD(aAux,{'MBENVIO',"Envio dos cadastros para o MultiBovinos",aParam})

    aParam  := {    "MBMATERIAIS"           ,;  // setRoutine
                    nModulo             ,;  // setModule
                    "000000"            ,;  // setUser
                    "Recepcao das movimentacoes de materiais no MultiBovinos para o estoque do ERP",;
                    .T.                 ,;  // setRecurrence
                    {'D', , 1, 0, }     ,;  // setPeriod
                    {'M', 30, , , }     ,;  // setFrequency
                    .T.                 ,;  // setDiscard
                    .T.                 ,;  // setManageable
                    aSM0Fil             ,; 
                    { DATE(),TIME() }   ;   // setFirstExecution
                }
    AADD(aAux,{'MBMATERIAIS',"Recepcao das movimentacoes de materiais no MultiBovinos para o estoque do ERP",aParam})

    For nX := 1 to len(aAux)
        lTemAgend := !Empty(FWSchdByFunction(aAux[nX][1]))
        If lTemAgend
            nAddAgend++
        Endif
    Next nX
    If Len(aAux) > nAddAgend
        lCadAgend := .T.
    Endif
    For nX := 1 to len(aAux)
        lTemAgend := !Empty(FWSchdByFunction(aAux[nX][1]))
        AADD(aRet,{ if( lTemAgend,.T.,.F.), aAux[nX][1], aAux[nX][2], lCadAgend, aAux[nX][3], lTemAgend })
    Next nX

Return aRet
