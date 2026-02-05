# índice de cada camada
camadaPalavras = 1
camadaFones = 2
camadaBusca = 4
camadaTonicidade = 3

# Caminho de arquivos manipulados
dirAudios$ = "E:/SP2010/"
dirTextGrids$ = "C:/Users/marqu/OneDrive/Área de Trabalho/ic/gabriela/"
caminhoParametros$ = "C:/Users/marqu/OneDrive/Área de Trabalho/ic/dados/Parametros-entrada.csv"
caminhoResultado$ = "C:/Users/marqu/OneDrive/Área de Trabalho/ic/gabriela/formantes-e-duracao.csv"

# Abre a tabela de parâmetros
Read Table from comma-separated file: caminhoParametros$

# Cria uma lista com todos os identificadores do corpus para posterior iteração
Create Strings as file list: "ids", dirAudios$ + "*.wav"
selectObject: "Strings ids"
qtIds =  Get number of strings
for i from 1 to qtIds
    nomeArquivo$ = Get string: i
    id$ = nomeArquivo$ - ".wav"
    Set string: i, id$
endfor

# Inicializa CSV
writeFileLine: caminhoResultado$, "ID.FALANTE,FONEMA,DURACAO,PALAVRA,FON.ANTERIOR,FON.SEGUINTE,DUR.FON.SEG,TONICIDADE,F1,F2,F3,F4"
writeInfoLine: "Começando"

# Itera por falantes
for i from 1 to qtIds

    # Resgata o ID do falante
    selectObject: "Strings ids"
    id$ = Get string: i
    idFalante$ = left$(id$, 3)
    
    # Abre TextGrid e Sound
    appendInfoLine: "Acessando o falante " + id$ 
    Read from file: dirAudios$ + id$ + ".wav"
    Read from file: dirTextGrids$ + id$ + ".TextGrid"

    # Extrai o canal do entrevistado
    selectObject: "Table Parametros-entrada"
    channel = Get value: i, "Channel"
    selectObject: "Sound " + id$
    Extract one channel: channel
    selectObject: "Sound " + id$
    Remove
    channel$ = string$: channel
    textoRemover$ = "_ch" + channel$
    selectObject: "Sound " + id$ + textoRemover$
    Rename: id$ - textoRemover$

    # Cria um objeto Formants
    selectObject: "Table Parametros-entrada"
    noFormants = Get value: i, "NoFormants"
    fmtCeiling = Get value: i, "FmtCeiling"
    appendInfoLine: "Número de formantes no modelo do falante " + id$ + ": " + string$(noFormants)
    appendInfoLine: "Teto de formantes no modelo do falante " + id$ + ": " + string$(fmtCeiling)
    selectObject: "Sound " + id$
    To Formant (burg): 0, noFormants, fmtCeiling, 0.025, 50.0 

    # Resgata informações sobre o TextGrid
    selectObject: "TextGrid " + id$
    numeroFones = Get number of intervals: camadaFones
    numeroPontos = Get number of points: camadaBusca
    appendInfoLine: "Resgatando os dados do falante " + id$ 

    # Itera por todos os pontos da camada de busca
    for estePonto from 1 to numeroPontos

        # Resgata informações do ponto
        selectObject: "TextGrid " + id$
        marcacaoPonto$ = Get label of point: camadaBusca, estePonto
        momentoPonto = Get time of point: camadaBusca, estePonto
        if index_regex(marcacaoPonto$, "#")

            # Resgata informações sobre o fone
            intervaloFone = Get interval at time: camadaFones, momentoPonto
            fonema$ = Get label of interval: camadaFones, intervaloFone

            # Calcula a duração do fone
            comecoFone = Get start time of interval: camadaFones, intervaloFone
            finalFone = Get end time of interval: camadaFones, intervaloFone
            duracao = finalFone - comecoFone
            
            # Calcula a duração do fone seguinte
            if intervaloFone != numeroFones
                comecoFoneSeguinte = Get start time of interval: camadaFones, intervaloFone + 1
                finalFoneSeguinte = Get end time of interval: camadaFones, intervaloFone + 1
                duracaoFoneSeguinte = finalFoneSeguinte - comecoFoneSeguinte
            else
                duracaoFoneSeguinte = 0
            endif

            # Resgata contexto lexical
            intervaloPalavra = Get interval at time: camadaPalavras, momentoPonto
            palavra$ = Get label of interval: camadaPalavras, intervaloPalavra

            # Resgata contexto fonético
            if intervaloFone != 0
                fonemaAnterior$ = Get label of interval: camadaFones, intervaloFone - 1
            else
                # Indefinido se primeiro fonema
                fonemaAnterior$ = "--undefined--"
            endif

            if intervaloFone != numeroFones
                fonemaSeguinte$ = Get label of interval: camadaFones, intervaloFone + 1
            else
                # Indefinido se último fonema
                fonemaSeguinte$ = "--undefined--"
            endif

            if fonemaAnterior$ == ""
                 # Indefinido se vazio
                fonemaAnterior$ = "--undefined--" 
            endif

            if fonemaSeguinte$ == ""
                 # Indefinido se vazio
                fonemaSeguinte$ = "--undefined--"
            endif
            
            # Resgata tonicidade do fone
            intervaloTonicidade = Get interval at time: camadaTonicidade, momentoPonto
            tonicidade$ = Get label of interval: camadaTonicidade, intervaloTonicidade

            # Resgata f1, f2 e f3 em três momentos
            selectObject: "Formant " + id$
            f1 = Get value at time: 1, momentoPonto, "hertz", "linear"
            f2 = Get value at time: 2, momentoPonto, "hertz", "linear"
            f3 = Get value at time: 3, momentoPonto, "hertz", "linear"
            f4 = Get value at time: 4, momentoPonto, "hertz", "linear"

            # Salva no CSV
            appendFileLine: caminhoResultado$,
                ...idFalante$, ",",
                ...fonema$, ",",
                ...duracao, ",",
                ...palavra$, ",",
                ...fonemaAnterior$, ",",
                ...fonemaSeguinte$, ",",
                ...duracaoFoneSeguinte, ",",
                ...tonicidade$, ",",
                ...f1, ",",
                ...f2, ",",
                ...f3, ",",
                ...f4

        endif
    endfor

    appendInfoLine: "Dados salvos para o falante " + id$

    # Remove objetos criados para liberar memória
    selectObject: "TextGrid " + id$
    Remove
    selectObject: "Sound " + id$
    Remove
    selectObject: "Formant " + id$
    Remove
    # selectObject: "Pitch " + id$
    # Remove

endfor

appendInfoLine: "Terminamos!"
