unit untPrincipal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  IdFTP, IdFTPList, IdFTPListParseBase, IdFTPListParseUnix, IdFTPListParseWindowsNT,
  IdAntiFreeze;

(*
    Windows, Classes, SysUtils, DateUtils, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, ComCtrls, Menus, Grids, Spin, Buttons, lNetComponents,
  IdHTTP, IdSocksServer, ZDataset, ZConnection, IdAuthentication, IdComponent,
  IdGlobal, IdCustomTCPServer, IdContext, IdThread, lNet;

*)

type

  { TfrmPrincipal }

  TfrmPrincipal = class(TForm)
    btnConecta: TButton;
    btnDisconecta: TButton;
    btnDownload: TButton;
    IdAntiFreeze1: TIdAntiFreeze;
    IdFTP1: TIdFTP;
    Memo1: TMemo;
    pnlBottom: TPanel;
    pnlTop: TPanel;
    Timer1: TTimer;
    procedure btnConectaClick(Sender: TObject);
    procedure btnDisconectaClick(Sender: TObject);
    procedure btnDownloadClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    iSegundos: integer;
    sDiretorio: string;
    sHost, sUser, sPassword, sOrigem, sDestino, sPorta: string;
    bConectado: boolean;
    procedure BaixarArquivosFTP(const PastaRemota, PastaLocal: string);
    procedure CarregaIni;
    procedure GravaLog(sMensagem: string);
    procedure Conectar;
    procedure Desconectar;
    procedure Baixar;
  public

  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.lfm}

uses funcoes;

  { TfrmPrincipal }

procedure TfrmPrincipal.btnConectaClick(Sender: TObject);
begin
  Conectar;
end;

procedure TfrmPrincipal.btnDisconectaClick(Sender: TObject);
begin
  GravaLog('Desconectado');
  Desconectar;
end;

procedure TfrmPrincipal.btnDownloadClick(Sender: TObject);
begin
  Baixar;
end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  iSegundos := 0;
  sHost     := '';
  sUser     := '';
  sPassword := '';
  sOrigem   := '';
  sDestino  := '';
  sPorta    := '';
  sDiretorio := ExtractFilePath(ParamStr(0));
  bConectado := False;
  GravaLog('Diretório do Sistema: ' + sDiretorio);
  CarregaIni;
end;

procedure TfrmPrincipal.Timer1Timer(Sender: TObject);
begin
  Inc(iSegundos);
  pnlTop.Caption := 'Próximo download em: ' + IntToStr(3600 - iSegundos) + 's';
  if iSegundos >= 3600 then
  begin
    iSegundos := 0;
    GravaLog('Timer: iniciando ciclo de download automático');
    Conectar;
    Baixar;
    Desconectar;
  end;
end;

// Monta caminho remoto sempre com '/' (Linux/FTP)
function FTPPath(const Pasta, Nome: string): string;
begin
  if (Length(Pasta) > 0) and (Pasta[Length(Pasta)] = '/') then
    Result := Pasta + Nome
  else
    Result := Pasta + '/' + Nome;
end;

// -----------------------------------------------------------------------
// BaixarArquivosFTP - recursiva: percorre subpastas e baixa apenas
// arquivos que ainda não existem localmente.
// -----------------------------------------------------------------------
procedure TfrmPrincipal.BaixarArquivosFTP(const PastaRemota, PastaLocal: string);
var
  i: integer;
  sArquivoDestino: string;
  sPastaRemotaFilho, sPastaLocalFilha: string;
  // Captura local da listagem antes de entrar em recursão
  Nomes:   array of string;
  EhPasta: array of boolean;
  iTot: integer;
begin
  GravaLog('Entrando na pasta remota: ' + PastaRemota);

  // Garante que a pasta local exista
  if not DirectoryExists(PastaLocal) then
  begin
    ForceDirectories(PastaLocal);
    GravaLog('Pasta local criada: ' + PastaLocal);
  end;

  // Muda para a pasta remota usando caminho absoluto
  try
    IdFTP1.ChangeDir(PastaRemota);
  except
    on E: Exception do
    begin
      GravaLog('Erro ao entrar na pasta "' + PastaRemota + '": ' + E.Message);
      Exit;
    end;
  end;

  // Lista o conteúdo com metadados
  try
    IdFTP1.List('', True);
  except
    on E: Exception do
    begin
      GravaLog('Erro ao listar pasta "' + PastaRemota + '": ' + E.Message);
      Exit;
    end;
  end;

  // Copia a listagem para arrays locais antes de qualquer ChangeDir
  iTot := IdFTP1.DirectoryListing.Count;
  SetLength(Nomes,   iTot);
  SetLength(EhPasta, iTot);
  for i := 0 to iTot - 1 do
  begin
    Nomes[i]   := IdFTP1.DirectoryListing[i].FileName;
    EhPasta[i] := IdFTP1.DirectoryListing[i].ItemType = ditDirectory;
  end;

  // Processa a listagem copiada
  for i := 0 to iTot - 1 do
  begin
    if (Nomes[i] = '.') or (Nomes[i] = '..') or (Trim(Nomes[i]) = '') then
      Continue;

    if EhPasta[i] then
    begin
      // --- Subpasta: monta caminho absoluto e desce recursivamente ---
      sPastaRemotaFilho := FTPPath(PastaRemota, Nomes[i]);
      sPastaLocalFilha  := IncludeTrailingPathDelimiter(PastaLocal) + Nomes[i];
      GravaLog('Subpasta: ' + Nomes[i]);
      BaixarArquivosFTP(sPastaRemotaFilho, sPastaLocalFilha);
    end
    else
    begin
      // --- Arquivo: baixa somente se não existir localmente ---
      sArquivoDestino := IncludeTrailingPathDelimiter(PastaLocal) + Nomes[i];

      if FileExists(sArquivoDestino) then
      begin
        //GravaLog('Já existe, pulando: ' + Nomes[i]);
        pnlBottom.Caption := 'Já existe, pulando: ' + Nomes[i];
        Continue;
      end;

      // Volta para a pasta correta antes de baixar
      try
        IdFTP1.ChangeDir(PastaRemota);
      except
        on E: Exception do
        begin
          GravaLog('Erro ao voltar para "' + PastaRemota + '": ' + E.Message);
          Continue;
        end;
      end;

      GravaLog('Baixando: ' + Nomes[i]);
      try
        IdFTP1.Get(Nomes[i], sArquivoDestino, True);
        GravaLog('OK: ' + Nomes[i]);
      except
        on E: Exception do
          GravaLog('Erro ao baixar "' + Nomes[i] + '": ' + E.Message);
      end;
    end;
  end;

  GravaLog('Pasta concluída: ' + PastaRemota);
end;

procedure TfrmPrincipal.CarregaIni;
var
  sArquivoIni, sLinha, sConteudo: string;
  iLinhas: integer;
  mmoInvisivel: TMemo;
begin
  sArquivoIni := sDiretorio + 'ClienteFTP.ini';
  GravaLog('Arquivo Ini: ' + sArquivoIni);

  mmoInvisivel := TMemo.Create(Self);
  try
    sHost     := '';
    sUser     := '';
    sPassword := '';
    sOrigem   := '';
    sDestino  := '';
    sPorta    := '';

    if FileExists(sArquivoIni) then
    begin
      mmoInvisivel.Lines.LoadFromFile(sArquivoIni);
      for iLinhas := 0 to mmoInvisivel.Lines.Count - 1 do
      begin
        sLinha := mmoInvisivel.Lines[iLinhas];
        if sLinha = '' then Continue;

        if Copy(sLinha, 1, 4) = 'HOST' then
        begin
          sConteudo := RetornaConteudoIni(sLinha);
          if sConteudo <> '' then sHost := sConteudo;
        end;

        if Copy(sLinha, 1, 4) = 'USER' then
        begin
          sConteudo := RetornaConteudoIni(sLinha);
          if sConteudo <> '' then sUser := sConteudo;
        end;

        if Copy(sLinha, 1, 8) = 'PASSWORD' then
        begin
          sConteudo := RetornaConteudoIni(sLinha);
          if sConteudo <> '' then sPassword := sConteudo;
        end;

        if Copy(sLinha, 1, 6) = 'ORIGEM' then
        begin
          sConteudo := RetornaConteudoIni(sLinha);
          if sConteudo <> '' then sOrigem := sConteudo;
        end;

        if Copy(sLinha, 1, 7) = 'DESTINO' then
        begin
          sConteudo := RetornaConteudoIni(sLinha);
          if sConteudo <> '' then sDestino := sConteudo;
        end;

        if Copy(sLinha, 1, 4) = 'PORT' then
        begin
          sConteudo := RetornaConteudoIni(sLinha);
          if sConteudo <> '' then sPorta := sConteudo;
        end;
      end;
    end;

    GravaLog('Host: '    + sHost);
    GravaLog('User: '    + sUser);
    GravaLog('Origem: '  + sOrigem);
    GravaLog('Destino: ' + sDestino);
    GravaLog('Porta: '   + sPorta);

  finally
    mmoInvisivel.Free;
  end;
end;

procedure TfrmPrincipal.GravaLog(sMensagem: string);
var
  sPastaProgressiva, sMes: string;
  dDiaHoje: TDate;
  iAno, iMes: integer;
  sArquivo: string;
  MeuTexto: TextFile;
begin
  if Trim(sMensagem) = '' then Exit;

  dDiaHoje := Date();
  iAno := YearOf(dDiaHoje);
  iMes := MonthOf(dDiaHoje);
  sMes := Format('%.2d', [iMes]);   // substitui o case com 12 opções

  sPastaProgressiva := sDiretorio + IntToStr(iAno) + PathDelim;
  if not DirectoryExists(sPastaProgressiva) then
    ForceDirectories(sPastaProgressiva);

  sPastaProgressiva := sPastaProgressiva + sMes + PathDelim;
  if not DirectoryExists(sPastaProgressiva) then
    ForceDirectories(sPastaProgressiva);

  sArquivo := sPastaProgressiva + SomenteNumeros(DateToStr(Date())) + '.txt';

  AssignFile(MeuTexto, sArquivo);
  if not FileExists(sArquivo) then
    Rewrite(MeuTexto)
  else
    Append(MeuTexto);

  Writeln(MeuTexto, DateTimeToStr(Now) + ': ' + sMensagem);
  CloseFile(MeuTexto);

  Memo1.Lines.Add(DateTimeToStr(Now) + ': ' + sMensagem);
end;

procedure TfrmPrincipal.Conectar;
begin
  if IdFTP1.Connected then
  begin
    GravaLog('Já está conectado');
    Exit;
  end;

  IdFTP1.Host     := sHost;
  IdFTP1.Username := sUser;
  IdFTP1.Password := sPassword;
  if sPorta <> '' then
    IdFTP1.Port := StrToIntDef(sPorta, 21);

  try
    IdFTP1.Connect;
  except
    on E: Exception do
    begin
      GravaLog('Erro ao conectar: ' + E.Message);
      Exit;
    end;
  end;

  if IdFTP1.Connected then
    GravaLog('Conectado com sucesso')
  else
    GravaLog('Falha na conexão');
end;

procedure TfrmPrincipal.Desconectar;
begin
  if IdFTP1.Connected then
  begin
    IdFTP1.Disconnect;
    GravaLog('Desconectado');
  end;
end;

procedure TfrmPrincipal.Baixar;
begin
  GravaLog('Iniciando download de: ' + sOrigem + ' → ' + sDestino);
  BaixarArquivosFTP(sOrigem, sDestino);
  GravaLog('Ciclo de download finalizado');
end;

end.
