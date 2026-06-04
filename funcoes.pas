unit Funcoes;

interface

uses
  Windows, SysUtils, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, ExtCtrls, Printers, Menus, ComCtrls, DB, Variants, Buttons,
  FMTBcd; //WinTypes, WinProcs, OleCtrls, AppEvnts,

function RetornaConteudoIni(sParam: string): string;

function ConverteStringParaInteiro(sVar: string): integer;

function Replicate(sCampo: string; iTamanho: integer): string;

function Preenche(sTexto: string; iTamanho: integer; sLado, sConteudo: string): string;

function GetNomeComputador(): string;

function TransformaDataHora(sData, sHora: string): TDateTime;

function TransformaDataHoraPHP(sData, sHora: string): string;

function SomenteNumeros(sVar: string): string;

function RecortaLinha(sLinha, sTag: string): string;

function HexaToInt(sValorHexa: string): integer;

function RetiraAcentos(txt: string): string;

function RemoveSpecialChars(const S: string): string;

function RemontaData(sData: string): string;

function BinToHex16(const BinStr: string): string;

function AccessDateTimeStr(const ADateTime: TDateTime): string;

const
  sVersao: string = '01 Build 001';
  sVersao2: string = '1.001';

implementation

//uses
//  Funcoes, Com2208, untMensagemSistema;

function RetornaConteudoIni(sParam: string): string;
var
  sResult: string;
  iPosicao, iTamanho: integer;
begin
  sResult := '';
  iTamanho := Length(sParam);
  iPosicao := Pos('=', sParam);
  if (iTamanho > 0) and (iPosicao > 0) then
    sResult := Copy(sParam, iPosicao + 1, iTamanho - 1);
  Result := sResult;
end;

function ConverteStringParaInteiro(sVar: string): integer;
var
  iResult: integer;
begin
  iResult := 0;
  if sVar <> '' then
  begin
    try
      iResult := StrToInt(sVar);
    except
    end;
  end;
  Result := iResult;
end;

function Replicate(sCampo: string; iTamanho: integer): string;
var
  iLaco: integer;
  sPadlAux: string;
begin
  sPadlAux := '';
  for iLaco := 1 to iTamanho do
    sPadlAux := sPadlAux + sCampo;
  Result := sPadlAux;
end;

function Preenche(sTexto: string; iTamanho: integer; sLado, sConteudo: string): string;
var
  iTamTexto: integer;
begin
  iTamTexto := Length(sTexto);
  if iTamTexto > iTamanho then
    sTexto := Copy(sTexto, 1, iTamanho);

  if iTamTexto < iTamanho then
  begin
    if sLado = 'D' then
      sTexto := sTexto + Replicate(sConteudo, iTamanho - iTamTexto)
    else
      sTexto := Replicate(sConteudo, iTamanho - iTamTexto) + sTexto;
  end;
  Result := sTexto;
end;

function GetNomeComputador(): string;
var
  Buffer: array[0..MAX_COMPUTERNAME_LENGTH + 1] of char;
  Tamanho: DWORD;
begin
  Tamanho := SizeOf(Buffer) div SizeOf(Buffer[0]);
  if GetComputerName(Buffer, Tamanho) then
    Result := StrPas(Buffer)
  else
    Result := 'Nome do computador nao encontrado';
end;

function TransformaDataHora(sData, sHora: string): TDateTime;
var
  dthRetorno: TDateTime;
  sTemp, sDia, sMes, sAno, sHora2, sMinuto: string;
begin

  dthRetorno := Now();
  if (sData <> '') and (sHora <> '') then
  begin
    // 20220902 e 0800
    sDia := Copy(sData, 7, 2);
    sMes := Copy(sData, 5, 2);
    sAno := Copy(sData, 1, 4);
    sHora2 := Copy(sHora, 1, 2);
    sMinuto := Copy(sHora, 3, 2);

    sTemp := sDia + '/' + sMes + '/' + sAno + ' ' + sHora2 + ':' + sMinuto;

    try
      dthRetorno := StrToDateTime(sTemp);
    except
    end;
  end;

  Result := dthRetorno;

end;

function TransformaDataHoraPHP(sData, sHora: string): string;
var
  sdthRetorno: string;
  sDia, sMes, sAno, sHora2, sMinuto: string;
begin

  sdthRetorno := '';
  if (sData <> '') and (sHora <> '') then
  begin
    // 20220902 e 0800
    sDia := Copy(sData, 7, 2);
    sMes := Copy(sData, 5, 2);
    sAno := Copy(sData, 1, 4);
    sHora2 := Copy(sHora, 1, 2);
    sMinuto := Copy(sHora, 3, 2);

    //sTemp := sDia + '/' + sMes + '/' + sAno + ' ' + sHora2 + ':' + sMinuto;

    sdthRetorno := sAno + '-' + sMes + '-' + sDia + ' ' + sHora2 + ':' + sMinuto + ':00';

  end;

  Result := sdthRetorno;

end;

function SomenteNumeros(sVar: string): string;
var
  sParte, sRetorno: string;
  iLacoLocal: integer;
begin
  sRetorno := '';

  for iLacoLocal := 1 to Length(sVar) do
  begin
    sParte := Copy(sVar, iLacoLocal, 1);
    if Pos(sParte, '0123456789') <> 0 then
      sRetorno := sRetorno + sParte;
  end;

  Result := sRetorno;

end;

function RecortaLinha(sLinha, sTag: string): string;
var
  iPosicao: integer;
  sRetorno: string;
begin

  if (sLinha <> '') and (sTag <> '') then
  begin
    iPosicao := Pos(sTag, sLinha);
    if iPosicao > 0 then
    begin
      sRetorno := Copy(sLinha, iPosicao + 1, Length(sLinha) - 1);
      sRetorno := StringReplace(sRetorno, '"', '', [rfReplaceAll]);
      if (lowercase(sRetorno) = 'null') then
        sRetorno := '';
    end;
  end;
  Result := sRetorno;
end;

function HexaToInt(sValorHexa: string): integer;
var
  HexStr: string;
  Value: cardinal;
begin

  (*
    Exemplo em hexa: 9F898CD2
    Correspondente em inteiro 2676591826 (casa do bilhão mesmo)
  *)

  if (sValorHexa <> '') then
  begin
    HexStr := '$' + sValorHexa; // Valor hexadecimal com prefixo $
    Value := StrToInt(HexStr);
  end
  else
    Value := 0;

  Result := Value;

end;

function RetiraAcentos(txt: string): string;
var
  i: integer;
begin
  if Length(txt) > 0 then
  begin
    for i := 0 to Length(txt) do
      case txt[i] of
        'á', 'à', 'â', 'ä', 'ã':
          txt[i] := 'a';
        'Á', 'À', 'Â', 'Ä', 'Ã':
          txt[i] := 'A';
        'é', 'è', 'ê', 'ë':
          txt[i] := 'e';
        'É', 'È', 'Ê', 'Ë', '&':
          txt[i] := 'E';
        'í', 'ì', 'î', 'ï':
          txt[i] := 'i';
        'Í', 'Ì', 'Î', 'Ï':
          txt[i] := 'I';
        'ó', 'ò', 'ô', 'ö', 'õ':
          txt[i] := 'o';
        'Ó', 'Ò', 'Ô', 'Ö', 'Õ':
          txt[i] := 'O';
        'ú', 'ù', 'û', 'ü':
          txt[i] := 'u';
        'Ú', 'Ù', 'Û', 'Ü':
          txt[i] := 'U';
        'ç':
          txt[i] := 'c';
        'Ç':
          txt[i] := 'C';
        '?':
          txt[i] := ' ';
        '%':
          txt[i] := ' ';
        '"':
          txt[i] := ' ';
        char(39):
          txt[i] := ' ';
        // Retira as aspas simples ( ' ),pois causa erro(Unterminated string constant) em cds.locate
      end;
  end;

  Result := txt;
end;

function RemoveSpecialChars(const S: string): string;
var
  I: integer;
  Ch: char;
begin
  // Inicializa a string de resultado vazia
  Result := '';

  // Itera por cada caractere da string de entrada
  for I := 1 to Length(S) do
  begin
    Ch := S[I]; // Obtém o caractere atual

    // Verifica se o caractere é uma letra (maiúscula ou minúscula), um número ou um espaço.
    // Usamos comparações de faixa de caracteres ASCII.
    if ((Ch >= 'a') and (Ch <= 'z')) or     // Letras minúsculas
      ((Ch >= 'A') and (Ch <= 'Z')) or     // Letras maiúsculas
      ((Ch >= '0') and (Ch <= '9')) or     // Dígitos numéricos
      (Ch = ' ') then                      // Espaço em branco
    begin
      // Se for um caractere "normal", adiciona ao resultado
      Result := Result + Ch;
    end;
    // IMPORTANTE: Se você precisar manter caracteres acentuados (á, é, ç, etc.),
    // terá que adicionar mais faixas de caracteres ou verificações específicas aqui.
    // Por exemplo, para manter 'ç', poderia adicionar: or (Ch = 'ç')
    // Para um controle mais fino de acentuação, a tarefa fica um pouco mais complexa no D7.
  end;
end;

function RemontaData(sData: string): string;
var
  sAno, sMes, sDia, sHora, sMinuto, sRetorno: string;
begin
  //1234567890
  //2505311500 2025-05-31 15:00

  sAno := '20' + copy(sData, 1, 2);
  sMes := Copy(sData, 3, 2);
  sDia := Copy(sData, 5, 2);
  sHora := Copy(sData, 7, 2);
  sMinuto := Copy(sData, 9, 2);

  sRetorno := sAno + '-' + sMes + '-' + sDia + ' ' + sHora + ':' + sMinuto;

  Result := sRetorno;

end;

function BinToHex16(const BinStr: string): string;
var
  i, Value: integer;
begin
  if Length(BinStr) <> 16 then
  begin
    Result := 'Erro: A string binaria deve ter 16 caracteres.';
    Exit;
  end;

  // Converte string binária para inteiro
  Value := 0;
  for i := 1 to 16 do
  begin
    if not (BinStr[i] in ['0', '1']) then
    begin
      Result := 'Erro: A string deve conter apenas 0 ou 1.';
      Exit;
    end;
    Value := (Value shl 1) or Ord(BinStr[i] = '1');
  end;

  // Converte inteiro para hexadecimal
  Result := IntToHex(Value, 4); // 4 dígitos hexadecimais
end;


function AccessDateTimeStr(const ADateTime: TDateTime): string;
begin
  // Retorna no formato #MM/DD/YYYY HH:NN:SS#
  //Result := '#' + FormatDateTime('mm/dd/yyyy hh:nn:ss', ADateTime) + '#';

  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', ADateTime);
end;


end.
