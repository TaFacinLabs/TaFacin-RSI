// Indicador TaFacinRSI 2.6 By: Maromba Trader

// Data de validade: 31/12/2025
const
    DATA_VALIDADE = 1251231; // Formato: 1AAMMDD (1 + Ano com 2 dígitos + Mês + Dia)
    
    // DevMode
    TAMANHO_MARCADOR = 7;         // Tamanho do marcador visual
    MOSTRAR_LINHAS_RSI = false;    // Mostrar linhas RSI 
    MOSTRAR_LINHAS_ADX = false;    // Mostrar linhas ADX
    MOSTRAR_TODOS_AVISOS = true; // Mostrar avisos em todos os candles
    
    // Constantes para as linhas do logo
    LOGO_VALIDO_ID = 10;          // ID para logo quando o indicador é válido
    LOGO_EXPIRADO_ID = 11;        // ID para logo quando o indicador está expirado
    LOGO_EDT_ID = 12;             // ID para texto Edt
    
    // IDs para estudos separados
    ESTUDO_RSI_ID = 100;          // ID para o estudo do RSI
    ESTUDO_ADX_ID = 200;          // ID para o estudo do ADX

INPUT
    // ==================== BLOCOS DE BACKTESTING ====================
    
    // ---------- BLOCO RSI ----------
    // RSI Principal
    periodo_RSI(5);               // Período do RSI principal
    
    // RSI Filtro
    filtro_rsi_ativo(true);       // Ativa/desativa a exibição do RSI filtro
    filtro_rsi_periodo(10);       // Período do RSI filtro
    
    // RSI Filtro - Reversão
    filtro_rsi_rev_ativo(true);   // Filtro RSI para Reversão
    filtro_rsi_rev_AC(45);        // Sobrevenda Reversão
    filtro_rsi_rev_AV(55);        // Sobrecompra Reversão
    
    // RSI Filtro - PullBack
    filtro_rsi_pb_ativo(false);   // Filtro RSI para PullBack
    filtro_rsi_pb_AC(45);         // Sobrevenda PullBack
    filtro_rsi_pb_AV(55);         // Sobrecompra PullBack
    
    // ---------- BLOCO GATILHOS ----------
    // Gatilho Reversão
    gatilho_rev_ativo(true);      // Ativar reversão
    gatilho_rev_AC(30);           // Sobrevenda para compra
    gatilho_rev_AV(70);           // Sobrecompra para venda
    
    // Gatilho Pullback
    gatilho_pb_ativo(true);       // Ativar pullback
    gatilho_pb_AC(35);            // Sobrevenda para compra
    gatilho_pb_AV(65);            // Sobrecompra para venda
    
    // ---------- BLOCO ADX ----------
    // ADX Principal
    periodo_ADX(14);              // Período do ADX
    adx_limiar_ativo(true);       // Limiar ADX para DI
    adx_limiar(12);               // Limiar tendência forte
    
    // ADX Filtros
    rev_filtro_adx_ativo(true);   // Filtro ADX para Reversão
    rev_filtro_adx_nivel(15);     // Nível ADX - Reversão
    pb_filtro_adx_ativo(false);   // Filtro ADX para Pullback
    pb_filtro_adx_nivel(10);      // Nível ADX - Pullback
    
    // ==================== CONFIGURAÇÕES DE INTERFACE ====================
    
    // Alertas
    alerta_rev_ativo(true);       // Alertas de reversão
    alerta_pb_ativo(true);        // Alertas de pullback
    alerta_di_ativo(false);        // Alertas de cruzamento DI
    
    // Visualização
    plotar_candles_re(45);        // Candles para reversão: 1=atual, 2=anterior, etc.
    plotar_candles_pb(45);        // Candles para pullback
    plotar_candles_di(2);         // Candles para cruzamento DI
    
    // Coloração
    colorir_candles(true);        // Ativa/desativa a coloração dos candles
    
    // Logo - Configurações
    logo_cor(clBranco);           // Cor do logo quando válido
    logo_estilo(0);               // Estilo da linha do logo (0=sólida, 1=tracejada, etc)
    logo_espessura(1);            // Espessura da linha do logo (1=normal, 2=grosso, etc)

VAR
    // RSI
    RSI_valor, RSI_anterior, RSI_filtro_valor : real;   
    
    // ADX
    ADX_valor, DiPos_valor, DiNeg_valor : real;
    di_cruzamento_compra, di_cruzamento_venda : boolean;
    
    // Estados do RSI
    rsi_abaixo_rev_AC, rsi_acima_rev_AV : boolean;
    
    // Filtros
    rev_filtro_adx_ok, pb_filtro_adx_ok, di_filtro_adx_ok : boolean;
    filtro_rsi_rev_compra_ok, filtro_rsi_rev_venda_ok : boolean;
    filtro_rsi_pb_compra_ok, filtro_rsi_pb_venda_ok : boolean;
    
    // Sinais
    sinal_retorno_compra, sinal_retorno_venda : boolean;
    sinal_pb_compra, sinal_pb_venda : boolean;
    
    // Controle de alertas
    alerta_compra_ativo, alerta_venda_ativo : boolean;
    alerta_compra_ant, alerta_venda_ant : boolean;
    retorno_compra_exibido, retorno_venda_exibido : boolean;
    
    // Alertas exibidos
    alerta_rev_compra_exibido, alerta_rev_venda_exibido : boolean;
    alerta_pb_compra_exibido, alerta_pb_venda_exibido : boolean;
    alerta_di_compra_exibido, alerta_di_venda_exibido : boolean;
    
    // Estudo e logo
    study_name : string;
    study_overlay : boolean;
    precoLogo : real;
    
    // Controle
    indicador_valido : boolean;
    mostrar_re, mostrar_pb, mostrar_di : boolean;
    
    // Variáveis para controle de estudos
    rsi_adx_estudo_criado : boolean;
    usando_estudo_separado : boolean;
    
    // =========== SISTEMA DE CORES UNIFICADO ===========
    branco_padrao : integer;              // Cor padrão branca para todos os candles
    cor_final : integer;                  // Cor final unificada para PaintBar

BEGIN
    // Verificação de validade
    indicador_valido := CurrentDate <= DATA_VALIDADE;
    
    // ======================= DEFINIÇÃO DE CORES =======================
    branco_padrao := RGB(255, 255, 255);     // Cor branca padrão para todos os candles
    
    // Inicialização das variáveis na primeira execução do indicador
    if CurrentBar = 0 then
    begin
        retorno_compra_exibido := false;
        retorno_venda_exibido := false;
        rsi_adx_estudo_criado := false;
        usando_estudo_separado := false;
        cor_final := branco_padrao;           // Inicializar cor final como branco
    end;
    
    if indicador_valido then
    begin
        // Cálculo dos indicadores (apenas uma vez por candle)
        RSI_valor := RSI(periodo_RSI, 0);
        RSI_anterior := RSI(periodo_RSI, 0)[1];
        RSI_filtro_valor := RSI(filtro_rsi_periodo, 0);
        
        ADX_valor := ADX(periodo_ADX, periodo_ADX);
        DiPos_valor := DiPDiM(periodo_ADX)|0|;   // DI+
        DiNeg_valor := DiPDiM(periodo_ADX)|1|;   // DI-
        
        // Verificação de visualização
        if LastBarOnChart then
        begin
            mostrar_re := MOSTRAR_TODOS_AVISOS or (plotar_candles_re = 1);
            mostrar_pb := MOSTRAR_TODOS_AVISOS or (plotar_candles_pb = 1);
            mostrar_di := MOSTRAR_TODOS_AVISOS or (plotar_candles_di = 1);
        end
        else
        begin
            mostrar_re := MOSTRAR_TODOS_AVISOS or (MaxBarsForward < plotar_candles_re - 1);
            mostrar_pb := MOSTRAR_TODOS_AVISOS or (MaxBarsForward < plotar_candles_pb - 1);
            mostrar_di := MOSTRAR_TODOS_AVISOS or (MaxBarsForward < plotar_candles_di - 1);
        end;
        
        // Detecção de condições
        di_cruzamento_compra := (DiPos_valor[1] <= DiNeg_valor[1]) and (DiPos_valor > DiNeg_valor);
        di_cruzamento_venda := (DiNeg_valor[1] <= DiPos_valor[1]) and (DiNeg_valor > DiPos_valor);
        
        // Estados anteriores
        alerta_compra_ant := alerta_compra_ativo;
        alerta_venda_ant := alerta_venda_ativo;
        
        // Reset de sinais para o candle atual
        sinal_retorno_compra := false;
        sinal_retorno_venda := false;
        sinal_pb_compra := false;
        sinal_pb_venda := false;
        alerta_rev_compra_exibido := false;
        alerta_rev_venda_exibido := false;
        alerta_pb_compra_exibido := false;
        alerta_pb_venda_exibido := false;
        alerta_di_compra_exibido := false;
        alerta_di_venda_exibido := false;
            
        // Verificação de filtros (unificada)
        rev_filtro_adx_ok := (not rev_filtro_adx_ativo) or (ADX_valor >= rev_filtro_adx_nivel);
        pb_filtro_adx_ok := (not pb_filtro_adx_ativo) or (ADX_valor >= pb_filtro_adx_nivel);
        di_filtro_adx_ok := (not adx_limiar_ativo) or (ADX_valor > adx_limiar);
        
        filtro_rsi_rev_compra_ok := (not filtro_rsi_rev_ativo) or (RSI_filtro_valor <= filtro_rsi_rev_AC);
        filtro_rsi_rev_venda_ok := (not filtro_rsi_rev_ativo) or (RSI_filtro_valor >= filtro_rsi_rev_AV);
        
        filtro_rsi_pb_compra_ok := (not filtro_rsi_pb_ativo) or (RSI_filtro_valor <= filtro_rsi_pb_AC);
        filtro_rsi_pb_venda_ok := (not filtro_rsi_pb_ativo) or (RSI_filtro_valor >= filtro_rsi_pb_AV);
        
        // Processamento de Reversão
        if gatilho_rev_ativo then
        begin
            // Estados do RSI
            rsi_abaixo_rev_AC := (RSI_valor < gatilho_rev_AC);
            rsi_acima_rev_AV := (RSI_valor > gatilho_rev_AV);
            
            // Detecção de retorno para compra e venda
            if LastBarOnChart then
            begin
                // Lógica para o último candle (otimizada)
                if rsi_abaixo_rev_AC and (RSI_valor >= gatilho_rev_AC) and (not retorno_compra_exibido) then
                begin
                    sinal_retorno_compra := true;
                    retorno_compra_exibido := true;
                end
                else
                begin
                    sinal_retorno_compra := (RSI_anterior < gatilho_rev_AC) and (RSI_valor >= gatilho_rev_AC);
                    if not sinal_retorno_compra then
                        retorno_compra_exibido := false;
                end;
                
                if rsi_acima_rev_AV and (RSI_valor <= gatilho_rev_AV) and (not retorno_venda_exibido) then
                begin
                    sinal_retorno_venda := true;
                    retorno_venda_exibido := true;
                end
                else
                begin
                    sinal_retorno_venda := (RSI_anterior > gatilho_rev_AV) and (RSI_valor <= gatilho_rev_AV);
                    if not sinal_retorno_venda then
                        retorno_venda_exibido := false;
                end;
            end
            else
            begin
                // Lógica para candles anteriores (otimizada)
                if rsi_abaixo_rev_AC and (RSI_valor >= gatilho_rev_AC) then
                    sinal_retorno_compra := true
                else
                    sinal_retorno_compra := (RSI_anterior < gatilho_rev_AC) and (RSI_valor >= gatilho_rev_AC);
                
                if rsi_acima_rev_AV and (RSI_valor <= gatilho_rev_AV) then
                    sinal_retorno_venda := true
                else
                    sinal_retorno_venda := (RSI_anterior > gatilho_rev_AV) and (RSI_valor <= gatilho_rev_AV);
                
                retorno_compra_exibido := false;
                retorno_venda_exibido := false;
            end;
            
            // Atualização de alertas
            if rsi_abaixo_rev_AC and (not alerta_compra_ant) then
                alerta_compra_ativo := true;
                
            if rsi_acima_rev_AV and (not alerta_venda_ant) then
                alerta_venda_ativo := true;
        end;
        
        // Processamento de Pullback
        if gatilho_pb_ativo then
        begin
            sinal_pb_compra := (RSI_anterior < gatilho_pb_AC) and (RSI_valor >= gatilho_pb_AC);
            sinal_pb_venda := (RSI_anterior > gatilho_pb_AV) and (RSI_valor <= gatilho_pb_AV);
        end;
        
        // Definindo o estudo de gráfico principal (sempre necessário)
        // Garantimos que estamos no gráfico principal antes de qualquer coloração
        study_overlay := true;
        
        // ======================= SISTEMA DE CORES UNIFICADO E SIMPLIFICADO =======================
        // Decidir cor UMA vez baseada nos gatilhos de RSI e fazer uma única chamada PaintBar
        if colorir_candles then
        begin
            cor_final := branco_padrao;  // Cor padrão branca para TODOS os candles
            
            // Verde: RSI rompeu qualquer gatilho de sobrecompra (zona de venda)
            if ((gatilho_rev_ativo and (RSI_valor >= gatilho_rev_AV)) or 
                (gatilho_pb_ativo and (RSI_valor >= gatilho_pb_AV))) then
                cor_final := clVerde
            // Vermelho: RSI rompeu qualquer gatilho de sobrevenda (zona de compra)
            else if ((gatilho_rev_ativo and (RSI_valor <= gatilho_rev_AC)) or 
                     (gatilho_pb_ativo and (RSI_valor <= gatilho_pb_AC))) then
                cor_final := clVermelho;
            
            // ÚNICA chamada PaintBar com a cor final decidida
            PaintBar(cor_final);
        end;
        
        // Plotagem de alertas (hierarquia)
        // 1. Alertas de Reversão (prioridade alta)
        if alerta_rev_ativo and gatilho_rev_ativo and mostrar_re then
        begin            
            if alerta_compra_ativo and sinal_retorno_compra and rev_filtro_adx_ok and filtro_rsi_rev_compra_ok then
            begin
                PlotText("C(RE)", clVerdeLimao, 0, TAMANHO_MARCADOR);
                alerta_compra_ativo := false;
                alerta_rev_compra_exibido := true;
            end;
            
            if alerta_venda_ativo and sinal_retorno_venda and rev_filtro_adx_ok and filtro_rsi_rev_venda_ok then
            begin
                PlotText("V(RE)", clVermelho, 2, TAMANHO_MARCADOR);
                alerta_venda_ativo := false;
                alerta_rev_venda_exibido := true;
            end;
        end;
        
        // 2. Alertas de Pullback (prioridade média)
        if alerta_pb_ativo and gatilho_pb_ativo and mostrar_pb then
        begin
            if sinal_pb_compra and pb_filtro_adx_ok and filtro_rsi_pb_compra_ok and (not alerta_rev_compra_exibido) then
            begin
                PlotText("C(PB)", clVerdeLimao, 0, TAMANHO_MARCADOR);
                alerta_pb_compra_exibido := true;
            end;
            
            if sinal_pb_venda and pb_filtro_adx_ok and filtro_rsi_pb_venda_ok and (not alerta_rev_venda_exibido) then
            begin
                PlotText("V(PB)", clVermelho, 2, TAMANHO_MARCADOR);
                alerta_pb_venda_exibido := true;
            end;
        end;
        
        // 3. Alertas de cruzamento DI (prioridade baixa)
        if alerta_di_ativo and mostrar_di then
        begin
            if di_cruzamento_compra and di_filtro_adx_ok and 
               (not alerta_rev_compra_exibido) and (not alerta_pb_compra_exibido) then
            begin
                PlotText("DI+", clVerdeLimao, 1, TAMANHO_MARCADOR);
                alerta_di_compra_exibido := true;
            end;
            
            if di_cruzamento_venda and di_filtro_adx_ok and 
               (not alerta_rev_venda_exibido) and (not alerta_pb_venda_exibido) then
            begin
                PlotText("DI-", clVermelho, 1, TAMANHO_MARCADOR);
                alerta_di_venda_exibido := true;
            end;
        end;
        
        // Reset de alertas
        if not rsi_abaixo_rev_AC then
            alerta_compra_ativo := false;
            
        if not rsi_acima_rev_AV then
            alerta_venda_ativo := false;
        
        // Criação do estudo separado para RSI e ADX, apenas se necessário
        // Note que isso é feito APÓS a coloração das barras para evitar interferência
        if MOSTRAR_LINHAS_RSI or MOSTRAR_LINHAS_ADX then
        begin
            // Definimos um novo estudo separado
            study_name := "TaFacin RSI+ADX";
            study_overlay := false; // Define que é um estudo separado
            usando_estudo_separado := true;
            
            // Plotagem de RSI apenas se solicitado
            if MOSTRAR_LINHAS_RSI then
            begin
                // RSI principal - Plot sem mostrar valor na escala lateral
                PlotN(1, RSI_valor);
                SetPlotColor(1, RGB(0, 0, 255)); // Azul puro forçado
                SetPlotWidth(1, 2);
                SetPlotType(1, 0); // Tipo linha
                
                // RSI filtro - só plotar se o filtro RSI estiver ativo
                // Também sem mostrar valor na escala lateral
                if filtro_rsi_ativo then
                begin
                    PlotN(2, RSI_filtro_valor);
                    SetPlotColor(2, RGB(100, 180, 255)); // Azul claro puro forçado
                    SetPlotWidth(2, 1);
                    SetPlotType(2, 0); // Tipo linha
                end
                else
                begin
                    NoPlot(2); // Remove a plotagem do RSI filtro quando desativado
                end;
                
                // Linhas de gatilho para Reversão - COM marcadores na escala lateral
                if gatilho_rev_ativo then
                begin
                    Plot3(gatilho_rev_AC);
                    SetPlotColor(3, RGB(50, 205, 50)); // Verde limão puro forçado
                    SetPlotWidth(3, 1);
                    SetPlotStyle(3, 1); // Tracejado
                    
                    Plot4(gatilho_rev_AV);
                    SetPlotColor(4, RGB(255, 0, 0)); // Vermelho puro forçado
                    SetPlotWidth(4, 1);
                    SetPlotStyle(4, 1); // Tracejado
                end
                else
                begin
                    NoPlot(3); // Remove a plotagem quando desativado
                    NoPlot(4); // Remove a plotagem quando desativado
                end;
                
                // Linhas de gatilho para Pullback - COM marcadores na escala lateral
                if gatilho_pb_ativo then
                begin
                    if (gatilho_pb_AC <> gatilho_rev_AC) then
                    begin
                        Plot5(gatilho_pb_AC);
                        SetPlotColor(5, RGB(50, 205, 50)); // Verde limão puro forçado
                        SetPlotWidth(5, 1);
                        SetPlotStyle(5, 2);
                    end;
                    
                    if (gatilho_pb_AV <> gatilho_rev_AV) then
                    begin
                        Plot6(gatilho_pb_AV);
                        SetPlotColor(6, RGB(255, 0, 0)); // Vermelho puro forçado
                        SetPlotWidth(6, 1);
                        SetPlotStyle(6, 2);
                    end;
                end
                else
                begin
                    NoPlot(5); // Remove a plotagem quando desativado
                    NoPlot(6); // Remove a plotagem quando desativado
                end;
                
                // Linhas de filtro de RSI - sem marcadores na escala lateral
                if filtro_rsi_ativo and filtro_rsi_rev_ativo then
                begin
                    PlotN(7, filtro_rsi_rev_AC);
                    SetPlotColor(7, RGB(144, 238, 144)); // Verde claro puro forçado
                    SetPlotWidth(7, 1);
                    SetPlotStyle(7, 3);
                    
                    PlotN(8, filtro_rsi_rev_AV);
                    SetPlotColor(8, RGB(255, 0, 0)); // Vermelho puro forçado
                    SetPlotWidth(8, 1);
                    SetPlotStyle(8, 3);
                end
                else
                begin
                    NoPlot(7); // Remove a plotagem quando desativado
                    NoPlot(8); // Remove a plotagem quando desativado
                end;
                
                if filtro_rsi_ativo and filtro_rsi_pb_ativo then
                begin
                    PlotN(9, filtro_rsi_pb_AC);
                    SetPlotColor(9, RGB(50, 205, 50)); // Verde limão puro forçado
                    SetPlotWidth(9, 1);
                    SetPlotStyle(9, 4);
                    
                    PlotN(10, filtro_rsi_pb_AV);
                    SetPlotColor(10, RGB(255, 0, 0)); // Vermelho puro forçado
                    SetPlotWidth(10, 1);
                    SetPlotStyle(10, 4);
                end
                else
                begin
                    NoPlot(9); // Remove a plotagem quando desativado
                    NoPlot(10); // Remove a plotagem quando desativado
                end;
            end
            else
            begin
                // Se RSI não deve ser mostrado, remover todas as plotagens relacionadas
                NoPlot(1); // RSI principal
                NoPlot(2); // RSI filtro
                NoPlot(3); // Gatilho Reversão AC
                NoPlot(4); // Gatilho Reversão AV
                NoPlot(5); // Gatilho Pullback AC
                NoPlot(6); // Gatilho Pullback AV
                NoPlot(7); // Filtro RSI Rev AC
                NoPlot(8); // Filtro RSI Rev AV
                NoPlot(9); // Filtro RSI PB AC
                NoPlot(10); // Filtro RSI PB AV
            end;
            
            // Plotagem do ADX apenas se solicitado
            if MOSTRAR_LINHAS_ADX then
            begin
                // Plotagem do ADX - sem marcador lateral
                PlotN(11, ADX_valor);
                SetPlotColor(11, RGB(255, 255, 0)); // Amarelo puro forçado
                SetPlotWidth(11, 2);
                
                // DI+ e DI- - sem marcador lateral
                PlotN(12, DiPos_valor);
                SetPlotColor(12, RGB(50, 205, 50)); // Verde limão puro forçado
                SetPlotWidth(12, 1);
                
                PlotN(13, DiNeg_valor);
                SetPlotColor(13, RGB(255, 0, 0)); // Vermelho puro forçado
                SetPlotWidth(13, 1);
                
                // Filtros e limiares - com marcador lateral
                if rev_filtro_adx_ativo then
                begin
                    Plot14(rev_filtro_adx_nivel);
                    SetPlotColor(14, RGB(255, 255, 0)); // Amarelo puro forçado
                    SetPlotWidth(14, 1);
                    SetPlotStyle(14, 2);
                end
                else
                begin
                    NoPlot(14); // Remove a plotagem quando desativado
                end;
                
                if pb_filtro_adx_ativo then
                begin
                    Plot15(pb_filtro_adx_nivel);
                    SetPlotColor(15, RGB(100, 180, 255)); // Azul claro puro forçado
                    SetPlotWidth(15, 1);
                    SetPlotStyle(15, 3);
                end
                else
                begin
                    NoPlot(15); // Remove a plotagem quando desativado
                end;
                
                if adx_limiar_ativo then
                begin
                    Plot16(adx_limiar);
                    SetPlotColor(16, RGB(128, 128, 128)); // Cinza puro forçado
                    SetPlotWidth(16, 1);
                    SetPlotStyle(16, 1);
                end
                else
                begin
                    NoPlot(16); // Remove a plotagem quando desativado
                end;
            end
            else
            begin
                // Se ADX não deve ser mostrado, remover todas as plotagens relacionadas
                NoPlot(11); // ADX valor
                NoPlot(12); // DiPos valor
                NoPlot(13); // DiNeg valor
                NoPlot(14); // Filtro ADX Rev
                NoPlot(15); // Filtro ADX PB
                NoPlot(16); // ADX limiar
            end;
            
            // Marcar que o estudo foi criado
            rsi_adx_estudo_criado := true;
        end
        else if rsi_adx_estudo_criado then
        begin
            // Se o estudo existia mas agora deve ser removido
            study_name := "TaFacin RSI+ADX";
            study_overlay := false;
            
            // Remover todas as plotagens
            NoPlot(1); NoPlot(2); NoPlot(3); NoPlot(4); NoPlot(5);
            NoPlot(6); NoPlot(7); NoPlot(8); NoPlot(9); NoPlot(10);
            NoPlot(11); NoPlot(12); NoPlot(13); NoPlot(14); NoPlot(15);
            NoPlot(16);
            
            // Marcar que o estudo foi removido
            rsi_adx_estudo_criado := false;
        end;
        
        // Retornar ao gráfico principal para o restante do código
        if usando_estudo_separado then
        begin
            study_overlay := true;
            usando_estudo_separado := false;
        end;
    end;
    
    // Logo do Indicador
    if LastBarOnChart then
    begin
        precoLogo := Close;
        
        if indicador_valido then
        begin
            HorizontalLineCustom(precoLogo, logo_cor, logo_espessura, logo_estilo, 
                               "TaFacinRSI🧭", 9, 0, 0, 0, 0, LOGO_VALIDO_ID);
            HorizontalLineCustom(precoLogo, logo_cor, logo_espessura, logo_estilo, 
                               "ByMarombaTrader💪🤑", 9, 1, 0, 0, 0, LOGO_EDT_ID);
        end
        else
        begin
            HorizontalLineCustom(precoLogo, clVermelho, logo_espessura, logo_estilo, 
                               "TaFacinRSI - Expirado 🐔😔", 9, 0, 0, 0, 0, LOGO_EXPIRADO_ID);
        end;
    end;
END;