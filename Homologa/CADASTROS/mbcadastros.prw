/*************************************************************************
    Funcoes diversas de Castros necessarios para a integração com 
    o MultiBovinos
    https://tdn.totvs.com/display/public/framework/AxCadastro
*************************************************************************/
User Function mbTabIntegra()
    AxCadastro("ZZ0","Integracoes MultiBovinos")
Return

User Function mbTabPropri()
    Local aEmpresas := {}
    Local xx    := 0

    //Carga de empresas para tabela de propriedades
    aEmpresas := FWLoadSM0()
    /*
    "M0_CODIGO",;    //Posição [1]
    "M0_CODFIL",;    //Posição [2]
    "M0_NOMECOM",;   //Posição [3]
    "M0_CGC",;       //Posição [4]
    "M0_INSCM",;     //Posição [5]
    "M0_CIDENT",;    //Posição [6]
    "M0_ESTENT",;    //Posição [7]
    "M0_ENDENT",;    //Posição [8]
    "M0_BAIRENT",;   //Posição [9]
    "M0_CEPENT",;    //Posição [10]
    "M0_COMPENT",;   //Posição [11]
    "M0_TEL";        //Posição [12]
    */
    For xx := 1 to Len(aEmpresas)
        dbSelectArea("ZZ2")
        ZZ2->(dbSetOrder(1))    //Filial + Fazenda
        ZZ2->(dbSeek(aEmpresas[xx][2]))
        If !Found()
            RecLock("ZZ2",.T.)
            ZZ2->ZZ2_FILIAL := aEmpresas[xx][2]
            ZZ2->ZZ2_FAZEND := ""
            MsUnLock()
        EndIf
    Next
    AxCadastro("ZZ2","Propriedades MultiBovinos")
Return

User Function mbTabSubgrupo()
    AxCadastro("ZZ3","Subgrupo MultiBovinos")
Return
