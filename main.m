clear all; close all; clc

%% Captura da Imagem

    NumberFrameDisplayPerSecond = 30;% Define o Frame Rate
    % Liberta a Camara ao Correr o Codigo
    objects = imaqfind; % Encontra Entrada de Video na Memoria
    delete(objects)
    
    % Set-up da Entrada de Video
    try
        vid = videoinput('winvideo', 1, 'MJPG_1280x720');% Windows
    catch
        try
            vid = videoinput('macvideo', 1); % Macs.
        catch
            errordlg('No webcam available');% Em caso de erro
        end
    end
    
    % Define os Parametros para o Video
    set(vid,'FramesPerTrigger',1);% Aquisicao de um Frame
    set(vid,'TriggerRepeat',Inf);% Aquisicao Continua
    set(vid,'ReturnedColorSpace','RGB');% Aquisicao de Imagem em RGBa
    triggerconfig(vid, 'Manual');
    
    while true
        % Timer que Chama a Funcao Processamento
        TimerData=timer('TimerFcn', {@Processamento,vid},'Period',1/NumberFrameDisplayPerSecond,'ExecutionMode','fixedRate','BusyMode','drop');
        
        start(vid); %Inicio do Video
        start(TimerData); %Inicio do Timer
    end
    
%     Apaga os Objectos Criados
    stop(TimerData);
    delete(TimerData);
    stop(vid);
    delete(vid);
    % Apaga as Variaveis do Tipo Persistent
    clear functions;
    imaqreset;
    
%% Função Processamento
function Processamento(obj, event,vidd)% Funcao que e chamada de n em n segundo
% Variaveis do Tipo Persistent para Evitar Estar Sempre a Alocar Memoria
persistent im;

trigger(vidd);% Da um Trigger
im = getdata(vidd,1,'uint8');%l? os dados da imagem

% Declaração de variáveis
n = 0; 
maskRed = 0;
maskYellow = 0;
maskBlue = 0;
im = flip(im ,2); % Espelhar a Imagem, pois a Camara Espelha a Real

%% Aplicação das máscaras
while n < 5
    switch n
        case 0 % Amarelo
            m_bin = createMaskYellowHSV(im); % Aplicar um Threshold cor Amarela
            matrix = strel('square',15);% Matriz para Percorer a Imagem 15x15
            closedIm = imclose(m_bin,matrix); % Fecho Morfologico da Imagem
            BW2 = imfill(closedIm,'holes');% Preenchimento do Interior da do Sinal
            % Eliminar ruído
            stats =  regionprops(BW2,'PixelIdxList','Area'); % Retirar as Areas de todos os Objetos Detetados na Imagem
            Area = cat(1,stats.Area);
            % Eliminar Objetos Indesejados / Ruído
            [maxValue,index] = max([stats.Area]); %Guarda o Objeto com a Maior Area
            [rw col]= size(stats);
            if maxValue < 5000 % Se a Area do Objeto Maior for Mais Pequena do que o Tamanho de um Sinal Normal
                n = n + 1; % Avanca para o Proximo Filtro
            else
                for i=1:rw
                    if (i~=index)
                        BW2(stats(i).PixelIdxList) = 0; % Remove Todas as Pequenas Regions a Excepcao da Area Maior
                    end
                end
                % Se for o sinal com Cor Correspondente
                maskYellow = 1; %% Guarda o Tipo de Mascara
                n = 4; %Avança para o Processamento
            end
        case 1 %Azul
            m_bin = createMaskBlueTesteVideo(im); % Aplicar um Threshold cor Azul
            matrix = strel('square',25);% Matriz para Percorer a Imagem 15x15
            closedIm = imclose(m_bin,matrix); % Fecho Morfologico da Imagem
            BW2 = imfill(closedIm,'holes'); % Preenchimento do Interior da do Sinal
            % Eliminar ruído
            stats =  regionprops(BW2,'PixelIdxList','Area'); % Retirar as Areas de todos os Objetos Detetados na Imagem
            Area = cat(1,stats.Area);
            % Eliminar objetos indesejados / ruído
            [maxValue,index] = max([stats.Area]); %Guarda o Objeto com a Maior Area
            [rw col]= size(stats);
            if maxValue < 5000 % Se a Area do Objeto Maior for Mais Pequena do que o Tamanho de um Sinal Normal
                n = n + 1; % Avanca para o Proximo Filtro
            else  % Se for o Sinal com Cor Correspondente
                for i=1:rw
                    if (i~=index)
                        BW2(stats(i).PixelIdxList) = 0; % Remove Todas as Pequenas Regions a Excepcao da Area Maior
                    end
                end
                maskBlue = 1; %% Guarda o Tipo de Mascara
                n = 4; %Avança para o Processamento
            end
        case 2 % Vermelho
            m_bin = createMaskRedHSV(im);  % Aplicar um Threshold cor Vermelha
            matrix = strel('square',30);% Matriz para Percorer a Imagem 15x15
            closedIm = imclose(m_bin,matrix); % Fecho Morfologico da Imagem
            BW2 = imfill(closedIm,'holes'); % Preenchimento do Interior da do Sinal
            % Eliminar ruído
            stats =  regionprops(BW2,'PixelIdxList','Area');% Retirar as Areas de todos os Objetos Detetados na Imagem
            Area = cat(1,stats.Area);
            % Eliminar Objetos Indesejados / Ruído
            [maxValue,index] = max([stats.Area]); %Guarda o Objeto com a Maior Area
            [rw col]= size(stats);
            if maxValue < 5000 % Se a Area do Objeto Maior for Mais Pequena do que o Tamanho de um Sinal Normal
                n = n + 1; % Avanca para o Proximo Filtro
            else % Se for o Sinal com Cor Correspondente
                for i=1:rw
                    if (i~=index)
                        BW2(stats(i).PixelIdxList) = 0;% Remove Todas as Pequenas Regions a Excepcao da Area Maior
                    end
                end
                maskRed = 1; % Guarda o Tipo de Mascara
                n = 4; %Avança para o Processamento
            end
        case 3
            disp('Nenhum Sinal Detetado');% Caso nao Seja Detetado Nenhum Sinal Fecha o Codigo
            n = 5; % reset
        case 4
            %% Forma do Objeto Principal
            hFigure = figure(1);% Abre uma figura em tempo real
            imshow(im); % apresenta a imagem inicial
            stats =  regionprops(BW2,'PixelIdxList','Area','Centroid','MajorAxisLength','Circularity','MinorAxisLength'); %Retirar todas as Informcoes do Sinal
            Area = cat(1,stats.Area); % Area do Sinal
            Centroid = cat(1, stats.Centroid); % Centro do Sinal
            Ratio = cat(1,stats.MajorAxisLength) / cat(1,stats.MinorAxisLength); %Ratio
            MajorAxis = cat(1,stats.MajorAxisLength); % Lado Maior do Sinal
            CircleMetric = cat(1,stats.Circularity);  % Circularidade
            SquareMetric = Ratio; % Metrica do Quadrado
            TriangleMetric = NaN(length(CircleMetric),1);% Metrica do Triangulo
            
            boxArea = m_minbbarea(BW2);
            
            %Para cada Limite, Colocar a Bounding Box e Calcular alguns Parametros
            for k=1:length(TriangleMetric),
                TriangleMetric(k) = Area(k)/boxArea(k);  %Area Preenchida VS Area da Box
            end
            % Definir alguns Limites para Cada Metrica
            % Circulo-Triangulo-Quadrado-Retangulo-Pentagono para Evitar a mesma Forma em Varios Objetos
            isCircle =   (CircleMetric > 0.85);
            isTriangle = ~isCircle & (TriangleMetric < 0.65);
            isSquare =   ~isCircle & ~isTriangle & (SquareMetric < 1) & (TriangleMetric > 0.9);
            isRectangle = ~isCircle & ~isTriangle & ~isSquare & (TriangleMetric > 0.9);
            
            % Atribuir a Forma a cada Objeto
            whichShape = cell(length(TriangleMetric),1);
            whichShape(isCircle) = {'Circulo'};
            whichShape(isTriangle) = {'Triangulo'};
            whichShape(isSquare) = {'Quadrado'};
            whichShape(isRectangle)= {'Retangulo'};

            %%  Multiplicar as imagens
            multi = uint8(BW2); % Converter para 8bits
            submask = im.*multi; % Multiplicar a Imagem Binaria com a Original
            
            %% Aplicação da Segunda Mascara e Identificação do Sinal
            
            if maskYellow == 1 % Se for Mascara Amarela
                filter = createMaskRedYellowSign(submask); % Aplica um Filtro Vermelho para Detetar os Objetos Vermelhos Dentro do Sinal Amarelo
                cc = bwconncomp(filter); % Bounding Box no Objeto que Detetou
                numObj = cc.NumObjects; % Contagem do Numero de Objetos Detetados
                if numObj ~= 0 % Se Existe Algum Objeto Vermelho(No Caso a Bola Do Semaforo Vermelho)
                    title("Sinal Aviso de Semaforo") % Mostra o Tipo de Sinal
                else % Se nao Forem Detetados Objetos
                    title("Sinal Aviso de Lomba")% Mostra o Tipo de Sinal
                end
                
            elseif maskBlue == 1 % Se for Mascara Azul
                if isCircle ~= 1 % Se na Mascara Azul o Objeto nao For Redondo (Sinal sem Saida é um Quadrado)
                    title("Sinal Sem saída") % Mostra o Tipo de Sinal
                else  % No Caso de Ser Redondo
                    filterWhite = createMaskWhiteHSV(submask); % Aplicar um Filtro Branco para Extrair os Objetos Brancos Dentro dos Sinais Azuis
                    matrix = strel('square',10);% Matriz para Percorer a Imagem 5x5
                    erodedIm = imerode(filterWhite,matrix); % Imagem Fechada
                    ccBlueSign = bwconncomp(erodedIm); % Fazer Bounding Box
                    numObj = ccBlueSign.NumObjects; % Retirar o Numero de Objetos Identificados no Interior
                    if numObj == 3 % Caso hajam 3 Objeto
                        title("Sinal de Rotunda") % Display do Sinal
                    else
                        stats =  regionprops(erodedIm,'PixelIdxList','Area'); % Retirar a Area de Todos os Objetos Detetados
                        [maxValue,index] = max([stats.Area]); % Guardar qual a Area Maior que Corresponde oa Objeto do Interior Que se Quer
                        [rw col]= size(stats);
                        % Melhorar a Imagem
                        for i=1:rw
                            if (i~=index)
                                erodedIm(stats(i).PixelIdxList)= 0; % Remover Todos os Pixeis a Branco das Areas mais Pequenas
                            end
                        end
                        % Dividir a Imagem a Meio para Contar os Pixeis Brancos para
                        % Saber a Orientacao da Seta
                        figure,imhshow(erodedIm);
                        stats =  regionprops(erodedIm,'Centroid'); % Centro do Objeto
                        middleColumn = floor(stats.Centroid(1)); % Define que o a Linha de Separacao para Contar Pixeis vai a Posicao da Coordenada X do Centroid
                        leftHalf = floor(nnz(erodedIm(:,1:middleColumn))); % Contar os Pixeis a Esqueda da Coluna Central
                        rightHalf = floor(nnz(erodedIm(:,middleColumn+1:end))); % Contar os Pixeis a Direita da Coluna Central
                        if leftHalf > rightHalf % Se Houver mais Pixeis a Esquerda, a Seta Aponta para a Esquerda
                            title("Sinal Virar Esquerda") % Display do Sinal
                        else % Se Houver mais Pixeis a Direita, a Seta Aponta para a Direita
                            title("Sinal Virar Direita")% Display do Sinal
                        end
                    end
                end
            elseif maskRed == 1 % Se for Mascara Vermelha
                if isCircle == 1 % Se Detetar um Sinal Redondo
                    filterBlack = createMaskBlackHSV(submask); % Aplica Mascara Preta para Detetar os Objetos Dentro
                    ccBlack = bwconncomp(filterBlack); % Bounding Box
                    numObj = ccBlack.NumObjects; % Conta o Numero de Objetos Detetados
                    if numObj ~= 0 % Se Identificar Objetos
                        statsRed =  regionprops(filterBlack,'PixelIdxList','Area'); %Retira a Area Maior de todos os Objetos
                        maxValue = max([statsRed.Area]); %  Guarda o Objeto com Maior Area
                        if maxValue < 500 % Comparacao para Evitar o Ruido que se Possa Gerar Dentro do Sinal(valor Verificado com Varios Testes)
                            title('Sinal Proibido') % Display do Sinal
                        else %% Se a Area for Maior que o "Limite" Entao o Sinal Restante e o Proibido Ultrapassar
                            title('Sinal Proíbido Ultrapassar') % Display do Sinal
                        end
                    else
                        title('Proibido')
                    end
                    
                elseif isTriangle == 1 % Se o Sinal for Triangular
                    filterBlack = createMaskBlackHSV(submask); % Aplica um Filtro Preto Para Ler os Objetos do Centro do Sinal
                    stats =  regionprops(filterBlack,'PixelIdxList','Area'); %Retira os Dados das Areas dos Ojetos Detetados
                    ccBlack = bwconncomp(filterBlack); % Bounding Box
                    numObj = ccBlack.NumObjects; % Conta o Numero de Objetos Detetados
                    if numObj ~= 0
                        [maxValue,index] = max([stats.Area]); % Guarda a Area Maior Que vai Ser o Objeto do Interior
                        [rw col]= size(stats);
                        for i=1:rw
                            if (i~=index)
                                filterBlack(stats(i).PixelIdxList)=0; % Remove Todas as Pequenas Regions a Excepcao da Area Maior
                            end
                        end
                        stats =  regionprops(filterBlack,'PixelIdxList','Area','Centroid'); % Centro do Objeto
                        middleRow = stats.Centroid(2); % Define que o a Linha de Separacao para Contar Pixeis vai a Posicao da Coordenada Y do Centroid
                        upperHalf = floor(nnz(filterBlack(1:middleRow,:))); % Conta os Pixeis Brancos Acima do Centro do Objeto
                        lowerHalf = floor(nnz(filterBlack(middleRow+1:end,:))); % Conta os Pixeis Brancos Abaixo do Centro do Objeto
                        compare = abs(upperHalf - lowerHalf); % Pequena Comparacao na Diferenca dos Pixeis, pois o Sinal de Neve Teoricamente e Simetrico
                        if compare > 300 % Se a Diferenca for Maior que 300 Pixeis(Verificao Feita Depois de Varios Testes)
                            title('Sinal Perigo Lomba') % Display do Sinal
                        else
                            title('Sinal Perigo Neve') % Display do Sinal
                        end
                    else
                        title('Sinal de Perigo')
                    end
                end
            else
                errordlg('Sem objeto');
            end
            n = n+1; % sair do processamento
    end
end
end
