{ lFTP CopyRight (C) 2005-2006 Ales Katona

  This library is Free software; you can rediStribute it and/or modify it
  under the terms of the GNU Library General Public License as published by
  the Free Software Foundation; either version 2 of the License, or (at your
  option) any later version.

  This program is diStributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; withOut even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
  for more details.

  You should have received a Copy of the GNU Library General Public License
  along with This library; if not, Write to the Free Software Foundation,
  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

  This license has been modified. See File LICENSE for more inFormation.
  Should you find these sources withOut a LICENSE File, please contact
  me at ales@chello.sk
}

unit lFTP;

{$mode objfpc}{$H+}
{$inline on}
{$macro on}
//{$define debug}

interface

uses
  Classes, lNet, lTelnet;
  
type
  TLFTP = class;
  TLFTPClient = class;

  TLFTPStatus = (fsNone, fsCon, fsUser, fsPass, fsPasv, fsPort, fsList, fsRetr,
                 fsStor, fsType, fsCWD, fsMKD, fsRMD, fsDEL, fsRNFR, fsRNTO,
                 fsSYS, fsFeat, fsPWD, fsHelp, fsLast);
                 
  TLFTPStatusSet = set of TLFTPStatus;
                 
  TLFTPStatusRec = record
    Status: TLFTPStatus;
    Args: array[1..2] of string;
  end;
  
  TLFTPTransferMethod = (ftActive, ftPassive);
                 
  TLFTPClientStatusEvent = procedure (aSocket: TLSocket;
                                     const aStatus: TLFTPStatus) of object;

  { TLFTPStatusStack }

  { TLFTPStatusFront }
  {$DEFINE __front_type__  :=  TLFTPStatusRec}
  {$i lcontainersh.inc}
  TLFTPStatusFront = TLFront;
  
  TLFTP = class(TLComponent, ILDirect)
   protected
    FControl: TLTelnetClient;
    FData: TLTcp;//TLTcpList;
    FSending: Boolean;
    FTransferMethod: TLFTPTransferMethod;

    function GetConnected: Boolean; virtual;
    
    function GetTimeout: DWord;
    procedure SetTimeout(const Value: DWord);
    
    function GetSocketClass: TLSocketClass;
    procedure SetSocketClass(Value: TLSocketClass);
   public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    
    function Get(var aData; const aSize: Integer; aSocket: TLSocket = nil): Integer; virtual; abstract;
    function GetMessage(out msg: string; aSocket: TLSocket = nil): Integer; virtual; abstract;
    
    function Send(const aData; const aSize: Integer; aSocket: TLSocket = nil): Integer; virtual; abstract;
    function SendMessage(const msg: string; aSocket: TLSocket = nil): Integer; virtual; abstract;
    
   public
    property Connected: Boolean read GetConnected;
    property Timeout: DWord read GetTimeout write SetTimeout;
    property SocketClass: TLSocketClass read GetSocketClass write SetSocketClass;
    property ControlConnection: TLTelnetClient read FControl;
    property DataConnection: TLTCP read FData;
    property TransferMethod: TLFTPTransferMethod read FTransferMethod write FTransferMethod;
  end;

  { TLFTPTelnetClient }
  
  TLFTPTelnetClient = class(TLTelnetClient)
   protected
    procedure React(const Operation, Command: Char); override;
  end;

  { TLFTPClient }

  TLFTPClient = class(TLFTP, ILClient)
   protected
    FStatus: TLFTPStatusFront;
    FCommandFront: TLFTPStatusFront;
    FStoreFile: TFileStream;
    FExpectedBinary: Boolean;
    FPipeLine: Boolean;
    FPassword: string;
    FStatusFlags: array[TLFTPStatus] of Boolean;

    FOnError: TLSocketErrorEvent;
    FOnReceive: TLSocketEvent;
    FOnSent: TLSocketProgressEvent;
    FOnControl: TLSocketEvent;
    FOnConnect: TLSocketEvent;
    FOnSuccess: TLFTPClientStatusEvent;
    FOnFailure: TLFTPClientStatusEvent;

    FChunkSize: Word;
    FLastPort: Word;
    FStartPort: Word;
    FStatusSet: TLFTPStatusSet;
    FSL: TStringList; // for evaluation, I want to prevent constant create/free
    procedure OnRe(aSocket: TLSocket);
    procedure OnDs(aSocket: TLSocket);
    procedure OnSe(aSocket: TLSocket);
    procedure OnEr(const msg: string; aSocket: TLSocket);

    procedure OnControlEr(const msg: string; aSocket: TLSocket);
    procedure OnControlRe(aSocket: TLSocket);
    procedure OnControlCo(aSocket: TLSocket);
    procedure OnControlDs(aSocket: TLSocket);
    
    function GetTransfer: Boolean;

    function GetEcho: Boolean;
    procedure SetEcho(const Value: Boolean);

    function GetConnected: Boolean; override;

    function GetBinary: Boolean;
    procedure SetBinary(const Value: Boolean);

    function CanContinue(const aStatus: TLFTPStatus; const Arg1, Arg2: string): Boolean;

    function CleanInput(var s: string): Integer;

    procedure SetStartPor(const Value: Word);

    procedure EvaluateAnswer(const Ans: string);

    procedure PasvPort;

    function User(const aUserName: string): Boolean;
    function Password(const aPassword: string): Boolean;

    procedure SendChunk(const Event: Boolean);

    procedure ExecuteFrontCommand;
   public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;

    function Get(var aData; const aSize: Integer; aSocket: TLSocket = nil): Integer; override;
    function GetMessage(out msg: string; aSocket: TLSocket = nil): Integer; override;
    
    function Send(const aData; const aSize: Integer; aSocket: TLSocket = nil): Integer; override;
    function SendMessage(const msg: string; aSocket: TLSocket = nil): Integer; override;
    
    function Connect(const aHost: string; const aPort: Word = 21): Boolean; virtual; overload;
    function Connect: Boolean; virtual; overload;
    
    function Authenticate(const aUsername, aPassword: string): Boolean;
    
    function GetData(var aData; const aSize: Integer): Integer;
    function GetDataMessage: string;
    
    function Retrieve(const FileName: string): Boolean;
    function Put(const FileName: string): Boolean; virtual; // because of LCLsocket
    
    function ChangeDirectory(const DestPath: string): Boolean;
    function MakeDirectory(const DirName: string): Boolean;
    function RemoveDirectory(const DirName: string): Boolean;
    
    function DeleteFile(const FileName: string): Boolean;
    function Rename(const FromName, ToName: string): Boolean;
   public
    procedure List(const FileName: string = '');
    procedure Nlst(const FileName: string = '');
    procedure SystemInfo;
    procedure FeatureList;
    procedure PresentWorkingDirectory;
    procedure Help(const Arg: string);
    
    procedure Disconnect; override;
    
    procedure CallAction; override;
   public
    property StatusSet: TLFTPStatusSet read FStatusSet write FStatusSet;
    property ChunkSize: Word read FChunkSize write FChunkSize;
    property Binary: Boolean read GetBinary write SetBinary;
    property PipeLine: Boolean read FPipeLine write FPipeLine;
    property Echo: Boolean read GetEcho write SetEcho;
    property StartPort: Word read FStartPort write FStartPort;
    property Transfer: Boolean read GetTransfer;

    property OnError: TLSocketErrorEvent read FOnError write FOnError;
    property OnConnect: TLSocketEvent read FOnConnect write FOnConnect;
    property OnSent: TLSocketProgressEvent read FOnSent write FOnSent;
    property OnReceive: TLSocketEvent read FOnReceive write FOnReceive;
    property OnControl: TLSocketEvent read FOnControl write FOnControl;
    property OnSuccess: TLFTPClientStatusEvent read FOnSuccess write FOnSuccess;
    property OnFailure: TLFTPClientStatusEvent read FOnFailure write FOnFailure;
  end;
  
  function FTPStatusToStr(const aStatus: TLFTPStatus): string;
  
implementation

uses
  SysUtils;

const
  FLE             = #13#10;
  DEFAULT_PORT    = 1024;

  EMPTY_REC: TLFTPStatusRec = (Status: fsNone; Args: ('', ''));

  FTPStatusStr: array[TLFTPStatus] of string = ('None', 'Connect', 'Authenticate', 'Password',
                                                'Passive', 'Active', 'List', 'Retrieve',
                                                'Store', 'Type', 'CWD', 'MKDIR',
                                                'RMDIR', 'Delete', 'RenameFrom',
                                                'RenameTo', 'System', 'Features',
                                                'PWD', 'HELP', 'LAST');

procedure Writedbg(const ar: array of const);
{$ifdef debug}
var
  i: Integer;
begin
  if High(ar) >= 0 then
    for i := 0 to High(ar) do
      case ar[i].vtype of
        vtInteger: Write(ar[i].vinteger);
        vtString: Write(ar[i].vstring^);
        vtAnsiString: Write(AnsiString(ar[i].vpointer));
        vtBoolean: Write(ar[i].vboolean);
        vtChar: Write(ar[i].vchar);
        vtExtended: Write(Extended(ar[i].vpointer^));
      end;
  Writeln;
end;
{$else}
begin
end;
{$endif}

function MakeStatusRec(const aStatus: TLFTPStatus; const Arg1, Arg2: string): TLFTPStatusRec;
begin
  Result.Status := aStatus;
  Result.Args[1] := Arg1;
  Result.Args[2] := Arg2;
end;

function FTPStatusToStr(const aStatus: TLFTPStatus): string;
begin
  Result := FTPStatusStr[aStatus];
end;

{$i lcontainers.inc}

{ TLFTP }

function TLFTP.GetConnected: Boolean;
begin
  Result := FControl.Connected;
end;

function TLFTP.GetTimeout: DWord;
begin
  Result := FControl.Timeout;
end;

procedure TLFTP.SetTimeout(const Value: DWord);
begin
  FControl.Timeout := Value;
  FData.Timeout := Value;
end;

function TLFTP.GetSocketClass: TLSocketClass;
begin
  Result := FControl.SocketClass;
end;

procedure TLFTP.SetSocketClass(Value: TLSocketClass);
begin
  FControl.SocketClass := Value;
  FData.SocketClass := Value;
end;

constructor TLFTP.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);

  FHost := '';
  FPort := 21;

  FControl := TLFTPTelnetClient.Create(nil);

  FData := TLTcp.Create(nil);

  FTransferMethod  :=  ftPassive; // let's be modern
end;

destructor TLFTP.Destroy;
begin
  FControl.Free;
  FData.Free;

  inherited Destroy;
end;

{ TLFTPTelnetClient }

procedure TLFTPTelnetClient.React(const Operation, Command: Char);
begin
  // don't do a FUCK since they broke Telnet in FTP as per-usual
end;

{ TLFTPClient }

constructor TLFTPClient.Create(aOwner: TComponent);
const
  DEFAULT_CHUNK = 8192;
var
  s: TLFTPStatus;
begin
  inherited Create(aOwner);

  FControl.OnReceive := @OnControlRe;
  FControl.OnConnect := @OnControlCo;
  FControl.OnError := @OnControlEr;
  FControl.OnDisconnect := @OnControlDs;

  FData.OnReceive := @OnRe;
  FData.OnDisconnect := @OnDs;
  FData.OnCanSend := @OnSe;
  FData.OnError := @OnEr;

  FStatusSet := []; // empty Event set
  FPassWord := '';
  FChunkSize := DEFAULT_CHUNK;
  FStartPort := DEFAULT_PORT;
  FSL := TStringList.Create;
  FLastPort := FStartPort;

  for s := fsNone to fsDEL do
    FStatusFlags[s] := False;
    
  FStatus := TLFTPStatusFront.Create(EMPTY_REC);
  FCommandFront := TLFTPStatusFront.Create(EMPTY_REC);
  
  FStoreFile := nil;
end;

destructor TLFTPClient.Destroy;
begin
  Disconnect;
  FSL.Free;
  FStatus.Free;
  FCommandFront.Free;
  if Assigned(FStoreFile) then
    FreeAndNil(FStoreFile);
  inherited Destroy;
end;

procedure TLFTPClient.OnRe(aSocket: TLSocket);
begin
  if Assigned(FOnReceive) then
    FOnReceive(aSocket);
end;

procedure TLFTPClient.OnDs(aSocket: TLSocket);
begin
  FSending := False;
  Writedbg(['Disconnected']);
end;

procedure TLFTPClient.OnSe(aSocket: TLSocket);
begin
  if Connected and FSending then
    SendChunk(True);
end;

procedure TLFTPClient.OnEr(const msg: string; aSocket: TLSocket);
begin
  FSending := False;
  if Assigned(FOnError) then
    FOnError(msg, aSocket);
end;

procedure TLFTPClient.OnControlEr(const msg: string; aSocket: TLSocket);
begin
  FSending := False;
  if Assigned(FOnError) then
    FOnError(msg, aSocket);
end;

procedure TLFTPClient.OnControlRe(aSocket: TLSocket);
begin
  if Assigned(FOnControl) then
    FOnControl(aSocket);
end;

procedure TLFTPClient.OnControlCo(aSocket: TLSocket);
begin
  if Assigned(FOnConnect) then
    FOnConnect(aSocket);
end;

procedure TLFTPClient.OnControlDs(aSocket: TLSocket);
begin
  if Assigned(FOnError) then
    FOnError('Connection lost', aSocket);
end;

function TLFTPClient.GetTransfer: Boolean;
begin
  Result := FData.Connected;
end;

function TLFTPClient.GetEcho: Boolean;
begin
  Result := FControl.OptionIsSet(TS_ECHO);
end;

function TLFTPClient.GetConnected: Boolean;
begin
  Result  :=  FStatusFlags[fsCon] and inherited;
end;

function TLFTPClient.GetBinary: Boolean;
begin
  Result := FStatusFlags[fsType];
end;

function TLFTPClient.CanContinue(const aStatus: TLFTPStatus; const Arg1,
  Arg2: string): Boolean;
begin
  Result := FPipeLine or FStatus.Empty;
  if not Result then
    FCommandFront.Insert(MakeStatusRec(aStatus, Arg1, Arg2));
end;

function TLFTPClient.CleanInput(var s: string): Integer;
var
  i: Integer;
begin
  FSL.Text := s;
  if FSL.Count > 0 then
    for i := 0 to FSL.Count-1 do
      if Length(FSL[i]) > 0 then EvaluateAnswer(FSL[i]);
  s := StringReplace(s, FLE, LineEnding, [rfReplaceAll]);
  i := Pos('PASS', s);
  if i > 0 then
    s := Copy(s, 1, i-1) + 'PASS';
  Result := Length(s);
end;

procedure TLFTPClient.SetStartPor(const Value: Word);
begin
  FStartPort := Value;
  if Value > FLastPort then
    FLastPort := Value;
end;

procedure TLFTPClient.SetEcho(const Value: Boolean);
begin
  if Value then
    FControl.SetOption(TS_ECHO)
  else
    FControl.UnSetOption(TS_ECHO);
end;

procedure TLFTPClient.SetBinary(const Value: Boolean);
const
  TypeBool: array[Boolean] of string = ('A', 'I');
begin
  if CanContinue(fsType, BoolToStr(Value), '') then begin
    FExpectedBinary := Value;
    FControl.SendMessage('TYPE ' + TypeBool[Value] + FLE);
    FStatus.Insert(MakeStatusRec(fsType, '', ''));
  end;
end;

procedure TLFTPClient.EvaluateAnswer(const Ans: string);

  function GetNum: Integer;
  begin
    try
      Result := StrToInt(Copy(Ans, 1, 3));
    except
      Result := -1;
    end;
  end;

  procedure ParsePortIP(s: string);
  var
    i, l: Integer;
    aIP: string;
    aPort: Word;
    sl: TStringList;
  begin
    if Length(s) >= 15 then begin
      sl := TStringList.Create;
      for i := Length(s) downto 5 do
        if s[i] = ',' then Break;
      while (i <= Length(s)) and (s[i] in ['0'..'9', ',']) do Inc(i);
      if not (s[i] in ['0'..'9', ',']) then Dec(i);
      l := 0;
      while s[i] in ['0'..'9', ','] do begin
        Inc(l);
        Dec(i);
      end;
      Inc(i);
      s := Copy(s, i, l);
      sl.CommaText := s;
      aIP := sl[0] + '.' + sl[1] + '.' + sl[2] + '.' + sl[3];
      try
        aPort := (StrToInt(sl[4]) * 256) + StrToInt(sl[5]);
      except
        aPort := 0;
      end;
      Writedbg(['Server PASV addr/port - ', aIP, ' : ', aPort]);
      if (aPort > 0) and FData.Connect(aIP, aPort) then
        Writedbg(['Connected after PASV']);
      sl.Free;
      FStatus.Remove;
    end;
  end;
  
  procedure SendFile;
  begin
    FStoreFile.Position := 0;
    FSending := True;
    SendChunk(False);
  end;
  
  function ValidResponse(const Answer: string): Boolean; inline;
  begin
    Result := (Length(Ans) >= 3) and
            (Ans[1] in ['1'..'5']) and
            (Ans[2] in ['0'..'9']) and
            (Ans[3] in ['0'..'9']);
            
    if Result then
      Result := (Length(Ans) = 3) or ((Length(Ans) > 3) and (Ans[4] = ' '));
  end;
  
  procedure Eventize(const aStatus: TLFTPStatus; const Res: Boolean);
  begin
    if Res then begin
      if Assigned(FOnSuccess) and (aStatus in FStatusSet) then
        FOnSuccess(FData.Iterator, aStatus);
    end else begin
      if Assigned(FOnFailure) and (aStatus in FStatusSet) then
        FOnFailure(FData.Iterator, aStatus);
    end;
  end;
  
var
  x: Integer;
begin
  x := GetNum;
  Writedbg(['WOULD EVAL: ', FTPStatusStr[FStatus.First.Status], ' with value: ',
            x, ' from "', Ans, '"']);
  if ValidResponse(Ans) then
    if not FStatus.Empty then begin
      Writedbg(['EVAL: ', FTPStatusStr[FStatus.First.Status], ' with value: ', x]);
      case FStatus.First.Status of
        fsCon  : case x of
                   220:
                     begin
                       FStatusFlags[FStatus.First.Status] := True;
                       Eventize(FStatus.First.Status, True);
                       FStatus.Remove;
                     end;
                   else
                     begin
                       FStatusFlags[FStatus.First.Status] := False;
                       Eventize(FStatus.First.Status, False);
                       FStatus.Remove;
                     end;
                 end;

        fsUser : case x of
                   230:
                     begin
                       FStatusFlags[FStatus.First.Status] := True;
                       Eventize(FStatus.First.Status, True);
                       FStatus.Remove;
                     end;
                   331,
                   332:
                     begin
                       FStatus.Remove;
                       Password(FPassword);
                     end;
                   else
                     begin
                       FStatusFlags[FStatus.First.Status] := False;
                       Eventize(FStatus.First.Status, False);
                       FStatus.Remove;
                     end;
                 end;
                 
        fsPass : case x of
                   230:
                     begin
                       FStatusFlags[FStatus.First.Status] := True;
                       Eventize(FStatus.First.Status, True);
                       FStatus.Remove;
                     end;
                   else
                     begin
                       FStatusFlags[FStatus.First.Status] := False;
                       Eventize(FStatus.First.Status, False);
                       FStatus.Remove;
                     end;
                 end;

        fsPasv : case x of
                   227: ParsePortIP(Ans);
                   300..600: FStatus.Remove;
                 end;

        fsPort : case x of
                   200:
                     begin
                       Eventize(FStatus.First.Status, True);
                       FStatus.Remove;
                     end;
                   else
                     begin
                       Eventize(FStatus.First.Status, False);
                       FStatus.Remove;
                     end;
                 end;

        fsType : case x of
                   200:
                     begin
                       FStatusFlags[FStatus.First.Status] := FExpectedBinary;
                       Writedbg(['Binary mode: ', FExpectedBinary]);
                       Eventize(FStatus.First.Status, True);
                       FStatus.Remove;
                     end;
                   else
                     begin
                       Eventize(FStatus.First.Status, False);
                       FStatus.Remove;
                     end;
                 end;

        fsRetr : case x of
                   125, 150: begin { Do nothing } end;
                   226:
                     begin
                       Eventize(FStatus.First.Status, True);
                       FStatus.Remove;
                     end;
                   else
                     begin
                       FData.Disconnect;
                       Writedbg(['Disconnecting data connection']);
                       Eventize(FStatus.First.Status, False);
                       FStatus.Remove; // error after connection established
                     end;
                 end;

        fsStor : case x of
                   125, 150: SendFile;
                   
                   226:
                     begin
                       Eventize(FStatus.First.Status, True);
                       FStatus.Remove;
                     end;
                   else
                     begin
                       Eventize(FStatus.First.Status, True);
                       FStatus.Remove;
                     end;
                 end;

        fsCWD  : case x of
                   200, 250:
                     begin
                       FStatusFlags[FStatus.First.Status] := True;
                       Eventize(FStatus.First.Status, True);
                       FStatus.Remove;
                     end;
                   else
                     begin
                       FStatusFlags[FStatus.First.Status] := False;
                       Eventize(FStatus.First.Status, False);
                       FStatus.Remove;
                     end;
                 end;
                 
        fsList : case x of
                   125, 150: begin { do nothing } end;
                   226:
                     begin
                       Eventize(FStatus.First.Status, True);
                       FStatus.Remove;
                     end;
                   else
                     begin
                       Eventize(FStatus.First.Status, False);
                       FStatus.Remove;
                     end;
                 end;
                 
        fsMKD  : case x of
                   250, 257:
                     begin
                       FStatusFlags[FStatus.First.Status] := True;
                       Eventize(FStatus.First.Status, True);
                       FStatus.Remove;
                     end;
                   else
                     begin
                       FStatusFlags[FStatus.First.Status] := False;
                       Eventize(FStatus.First.Status, False);
                       FStatus.Remove;
                     end;
                 end;
                 
        fsRMD,
        fsDEL  : case x of
                   250:
                     begin
                       FStatusFlags[FStatus.First.Status] := True;
                       Eventize(FStatus.First.Status, True);
                       FStatus.Remove;
                     end;
                   else
                     begin
                       FStatusFlags[FStatus.First.Status] := False;
                       Eventize(FStatus.First.Status, False);
                       FStatus.Remove;
                     end;
                 end;
                 
        fsRNFR : case x of
                   350:
                     begin
                       FStatusFlags[FStatus.First.Status] := True;
                       Eventize(FStatus.First.Status, True);
                       FStatus.Remove;
                     end;
                   else
                     begin
                       Eventize(FStatus.First.Status, False);
                       FStatus.Remove;
                     end;
                 end;
                 
        fsRNTO : case x of
                   250:
                     begin
                       FStatusFlags[FStatus.First.Status] := True;
                       Eventize(FStatus.First.Status, True);
                       FStatus.Remove;
                     end;
                   else
                     begin
                       Eventize(FStatus.First.Status, False);
                       FStatus.Remove;
                     end;
                 end;
      end;
    end;
  if FStatus.Empty and not FCommandFront.Empty then
    ExecuteFrontCommand;
end;

procedure TLFTPClient.PasvPort;

  function StringPair(const aPort: Word): string;
  begin
    Result := IntToStr(aPort div 256);
    Result := Result + ',' + IntToStr(aPort mod 256);
  end;
  
  function StringIP: string;
  begin
    Result := StringReplace(FControl.Connection.Iterator.LocalAddress, '.', ',',
                          [rfReplaceAll]) + ',';
  end;
  
begin
  if FTransferMethod = ftActive then begin
    Writedbg(['Sent PORT']);
    FData.Disconnect;
    FData.Listen(FLastPort);
    FControl.SendMessage('PORT ' + StringIP + StringPair(FLastPort) + FLE);
    FStatus.Insert(MakeStatusRec(fsPort, '', ''));

    if FLastPort < 65535 then
      Inc(FLastPort)
    else
      FLastPort := FStartPort;
  end else begin
    Writedbg(['Sent PASV']);
    FControl.SendMessage('PASV' + FLE);
    FStatus.Insert(MakeStatusRec(fsPasv, '', ''));
  end;
end;

function TLFTPClient.User(const aUserName: string): Boolean;
begin
  Result := not FPipeLine;
  if CanContinue(fsUser, aUserName, '') then begin
    FControl.SendMessage('USER ' + aUserName + FLE);
    FStatus.Insert(MakeStatusRec(fsUser, '', ''));
    Result := True;
  end;
end;

function TLFTPClient.Password(const aPassword: string): Boolean;
begin
  Result := not FPipeLine;
  if CanContinue(fsPass, aPassword, '') then begin
    FControl.SendMessage('PASS ' + aPassword + FLE);
    FStatus.Insert(MakeStatusRec(fsPass, '', ''));
    Result := True;
  end;
end;

procedure TLFTPClient.SendChunk(const Event: Boolean);
var
  Buf: array[0..65535] of Byte;
  n: Integer;
  Sent: Integer;
begin
  repeat
    n := FStoreFile.Read(Buf, FChunkSize);
    if n > 0 then begin
      Sent := FData.Send(Buf, n);
      if Event and Assigned(FOnSent) and (Sent > 0) then
        FOnSent(FData.Iterator, Sent);
      if Sent < n then
        FStoreFile.Position := FStoreFile.Position - (n - Sent); // so it's tried next time
    end else begin
      if Assigned(FOnSent) then
        FOnSent(FData.Iterator, 0);
      FreeAndNil(FStoreFile);
      FSending := False;
      {$hint this one calls freeinstance which doesn't pass}
      FData.Disconnect;
    end;
  until (n = 0) or (Sent = 0);
end;

procedure TLFTPClient.ExecuteFrontCommand;
begin
  with FCommandFront.First do
    case Status of
      fsNone : Exit;
      fsUser : User(Args[1]);
      fsPass : Password(Args[1]);
      fsList : List(Args[1]);
      fsRetr : Retrieve(Args[1]);
      fsStor : Put(Args[1]);
      fsCWD  : ChangeDirectory(Args[1]);
      fsMKD  : MakeDirectory(Args[1]);
      fsRMD  : RemoveDirectory(Args[1]);
      fsDEL  : DeleteFile(Args[1]);
      fsRNFR : Rename(Args[1], Args[2]);
      fsSYS  : SystemInfo;
      fsPWD  : PresentWorkingDirectory;
      fsHelp : Help(Args[1]);
      fsType : SetBinary(StrToBool(Args[1]));
      fsFeat : FeatureList;
    end;
  FCommandFront.Remove;
end;

function TLFTPClient.Get(var aData; const aSize: Integer; aSocket: TLSocket): Integer;
var
  s: string;
begin
  Result := FControl.Get(aData, aSize, aSocket);
  if Result > 0 then begin
    SetLength(s, Result);
    Move(aData, PChar(s)^, Result);
    CleanInput(s);
  end;
end;

function TLFTPClient.GetMessage(out msg: string; aSocket: TLSocket): Integer;
begin
  Result := FControl.GetMessage(msg, aSocket);
  if Result > 0 then
    Result := CleanInput(msg);
end;

function TLFTPClient.Send(const aData; const aSize: Integer; aSocket: TLSocket
  ): Integer;
begin
  Result := FControl.Send(aData, aSize);
end;

function TLFTPClient.SendMessage(const msg: string; aSocket: TLSocket
  ): Integer;
begin
  Result := FControl.SendMessage(msg);
end;

function TLFTPClient.GetData(var aData; const aSize: Integer): Integer;
begin
  Result := FData.Iterator.Get(aData, aSize);
end;

function TLFTPClient.GetDataMessage: string;
begin
  Result := '';
  if Assigned(FData.Iterator) then
    FData.Iterator.GetMessage(Result);
end;

function TLFTPClient.Connect(const aHost: string; const aPort: Word): Boolean;
begin
  Result := False;
  Disconnect;
  if FControl.Connect(aHost, aPort) then begin
    FHost := aHost;
    FPort := aPort;
    FStatus.Insert(MakeStatusRec(fsCon, '', ''));
    Result := True;
  end;
  if FData.Eventer <> FControl.Connection.Eventer then
    FData.Eventer := FControl.Connection.Eventer;
end;

function TLFTPClient.Connect: Boolean;
begin
  Result := Connect(FHost, FPort);
end;

function TLFTPClient.Authenticate(const aUsername, aPassword: string): Boolean;
begin
  FPassword := aPassWord;
  Result := User(aUserName);
end;

function TLFTPClient.Retrieve(const FileName: string): Boolean;
begin
  Result := not FPipeLine;
  if CanContinue(fsRetr, FileName, '') then begin
    PasvPort;
    FControl.SendMessage('RETR ' + FileName + FLE);
    FStatus.Insert(MakeStatusRec(fsRetr, '', ''));
    Result := True;
  end;
end;

function TLFTPClient.Put(const FileName: string): Boolean;
begin
  Result := not FPipeLine;
  if FileExists(FileName) and CanContinue(fsStor, FileName, '') then begin
    FStoreFile := TFileStream.Create(FileName, fmOpenRead);
    PasvPort;
    FControl.SendMessage('STOR ' + ExtractFileName(FileName) + FLE);
    FStatus.Insert(MakeStatusRec(fsStor, '', ''));
    Result := True;
  end;
end;

function TLFTPClient.ChangeDirectory(const DestPath: string): Boolean;
begin
  Result := not FPipeLine;
  if CanContinue(fsCWD, DestPath, '') then begin
    FControl.SendMessage('CWD ' + DestPath + FLE);
    FStatus.Insert(MakeStatusRec(fsCWD, '', ''));
    FStatusFlags[fsCWD] := False;
    Result := True;
  end;
end;

function TLFTPClient.MakeDirectory(const DirName: string): Boolean;
begin
  Result := not FPipeLine;
  if CanContinue(fsMKD, DirName, '') then begin
    FControl.SendMessage('MKD ' + DirName + FLE);
    FStatus.Insert(MakeStatusRec(fsMKD, '', ''));
    FStatusFlags[fsMKD] := False;
    Result := True;
  end;
end;

function TLFTPClient.RemoveDirectory(const DirName: string): Boolean;
begin
  Result := not FPipeLine;
  if CanContinue(fsRMD, DirName, '') then begin
    FControl.SendMessage('RMD ' + DirName + FLE);
    FStatus.Insert(MakeStatusRec(fsRMD, '', ''));
    FStatusFlags[fsRMD] := False;
    Result := True;
  end;
end;

function TLFTPClient.DeleteFile(const FileName: string): Boolean;
begin
  Result := not FPipeLine;
  if CanContinue(fsDEL, FileName, '') then begin
    FControl.SendMessage('DELE ' + FileName + FLE);
    FStatus.Insert(MakeStatusRec(fsDEL, '', ''));
    FStatusFlags[fsDEL] := False;
    Result := True;
  end;
end;

function TLFTPClient.Rename(const FromName, ToName: string): Boolean;
begin
  Result := not FPipeLine;
  if CanContinue(fsRNFR, FromName, ToName) then begin
    FControl.SendMessage('RNFR ' + FromName + FLE);
    FStatus.Insert(MakeStatusRec(fsRNFR, '', ''));
    FStatusFlags[fsRNFR] := False;

    FControl.SendMessage('RNTO ' + ToName + FLE);
    FStatus.Insert(MakeStatusRec(fsRNTO, '', ''));
    FStatusFlags[fsRNTO] := False;

    Result := True;
  end;
end;

procedure TLFTPClient.List(const FileName: string = '');
begin
  if CanContinue(fsList, FileName, '') then begin
    PasvPort;
    FStatus.Insert(MakeStatusRec(fsList, '', ''));
    if Length(FileName) > 0 then
      FControl.SendMessage('LIST ' + FileName + FLE)
    else
      FControl.SendMessage('LIST' + FLE);
  end;
end;

procedure TLFTPClient.Nlst(const FileName: string);
begin
  if CanContinue(fsList, FileName, '') then begin
    PasvPort;
    FStatus.Insert(MakeStatusRec(fsList, '', ''));
    if Length(FileName) > 0 then
      FControl.SendMessage('NLST ' + FileName + FLE)
    else
      FControl.SendMessage('NLST' + FLE);
  end;
end;

procedure TLFTPClient.SystemInfo;
begin
  if CanContinue(fsSYS, '', '') then
    FControl.SendMessage('SYST' + FLE);
end;

procedure TLFTPClient.FeatureList;
begin
  if CanContinue(fsFeat, '', '') then
    FControl.SendMessage('FEAT' + FLE);
end;

procedure TLFTPClient.PresentWorkingDirectory;
begin
  if CanContinue(fsPWD, '', '') then
    FControl.SendMessage('PWD' + FLE);
end;

procedure TLFTPClient.Help(const Arg: string);
begin
  if CanContinue(fsHelp, Arg, '') then
    FControl.SendMessage('HELP ' + Arg + FLE);
end;

procedure TLFTPClient.Disconnect;
var
  s: TLFTPStatus;
begin
  FControl.Disconnect;
  FStatus.Clear;
  FData.Disconnect;
  FLastPort := FStartPort;
  for s := fsNone to fsLast do
    FStatusFlags[s] := False;
  FCommandFront.Clear;
end;

procedure TLFTPClient.CallAction;
begin
  TLFTPTelnetClient(FControl).CallAction;
end;

initialization
  Randomize;

end.

