unit FHIR.Smart.Utilities;

{
todo:
Apps MUST generate an unpredictable state parameter for each user session. An app MUST validate the state value for any request sent to its redirect URL; include state with all authorization requests; and validate the state value included in access tokens it receives.

* support AUD on redirect url
* add redirect url to token requeest
* implement refresh_token on server / support in client
* The authorization server�s response MUST include the HTTP �Cache-Control� response header field with a value of �no-store,� as well as the �Pragma� response header field with a value of �no-cache.�
* On occasion, an app may receive a FHIR resource that contains a �reference� to a resource hosted on a different resource server. The app SHOULD NOT blindly follow such references and send along its access_token, as the token may be subject to potential theft. The app SHOULD either ignore the reference, or initiate a new request for access to that resource.
* http://smarthealthit.org/fhir/scopes/patient/*.read.. openID scopes have a URI prefix of http://openid.net/specs/openid-connect-core-1_0#
* implement http://hl7.org/fhir/smart-app-launch/conformance/

}
{
Copyright (c) 2011+, HL7 and Health Intersections Pty Ltd (http://www.healthintersections.com.au)
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
 * Neither the name of HL7 nor the names of its contributors may be used to
   endorse or promote products derived from this software without specific
   prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 'AS IS' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
}



{
Using the Smart App Launch client library

Using Smart App Launch consists of 2 main phases:

1. registration
- you must register with the specific Smart App Launch Server. You give it a name, and a redirect URL, and it will return a client id

- for this library, the redirect URL must take the form of http://localhost:[port]/done where post is any number
  between 1 and 65535. There is no flexibility associated with this

- if you are a confidential application (e.g. server side) you can also ask for a client secret. This library supports secrets,
  though it is a server side library that is not associated with actual secret applications (but it's supported anyway for
  development assistance.

- you also need to know the authorization and token end points on the server. These are advertised in the
  server's conformance statement, and the function usesSmartOnFHIR below can extract them for you

- at the end of the registration process, you have all the information in the TRegisteredServer record

2. Operational Use
- Create a TSmartOnFhirLoginForm. give it:
  * logoPath : the path to a PNG describing your application (used by some servers)
  * server: the server details from the registration phase
  * scopes: the scopes you are asking. See Smart App Launch documentation for what are valid scopes
  * handle error:
       if this is false, and an error occurs, the form will close without telling
       the user about the error, and the host can handle the user. If this is true,
       the form will handle it (this is generally a more comfortable UI for the user)

- Important: you may need to set the following registry key to get OAuth to work:
  // HKEY_LOCAL_MACHINE\SOFTWARE\(Wow6432Node\)Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION\[your exe name] = 10000
  see https://msdn.microsoft.com/en-us/library/ee330730(v=vs.85).aspx or http://blogs.msdn.com/b/patricka/archive/2015/01/12/controlling-webbrowser-control-compatibility.aspx

  (alternate approach: put <meta http-equiv="X-UA-Compatible" content="IE=edge"> in every page...)

- Show the form (.showmodal).

- the form will create an HTTP Server that only binds to the local host. This
  SHOULD avoid problems with firewalls, etc, but this is not guaranteed.
  Note that a localhost server is required because the POX IE control doesn't inform
  the host application about redirects, and OAuth finishes with a redirect.
  (And why not use DCEF? - it's not maintained to the current version of webkit,
  it's a distibution nightmare, and you can't use it in dlls)

- the modal result of the form will have one of the 3 values
  mrOK: Authorization succeeded. The outcome information will be able in .Token on the form - a TClientAccessToken
  mrCancel: the user cancelled the process
  mrAbort: something went wrong. if HandleError is false, a description of what went wrong will be in ErrorMessage

- note that the OAuth process in the browser could go wrong for many reasons that are not known to the
  Smart App Launch client. In these cases, the user has no choice but to process cancel, so you should not
  assume that cancel means the user chose not to succeed - just that they already know it failed.

3. CDS hooks Support

 when registering a server, you can specify a list of CDS Hooks that it implements.
 For further information, see FHIR.CdsHooks.Utilities.
}

interface

uses
  SysUtils, Classes,
  IdContext, IdHTTPServer, IdCustomHTTPServer, IdSocketHandle, IdHTTP, IdSSLOpenSSL,
  FHIR.Support.Base, FHIR.Support.Utilities, FHIR.Support.Certs, FHIR.Web.Parsers, FHIR.Support.Stream, FHIR.Support.Json,
  FHIR.Base.Objects, FHIR.Base.Common, FHIR.Client.Base, FHIR.Base.Lang;

type
  TRegisteredCDSHook = class (TFslObject)
  private
    Fname: String;
    FpreFetch: TStringList;
    FHook : String;
  public
    constructor Create; override;
    destructor Destroy; Override;
    Function Link : TRegisteredCDSHook; overload;

    property name : String read Fname write Fname;
    property hook : String read FHook write FHook;
    property preFetch : TStringList read FpreFetch;
  end;

  TSmartAppLaunchMode = (salmNone, salmOAuthClient, salmBackendClient);

const
  CODES_TSmartAppLaunchMode : array [TSmartAppLaunchMode] of string = ('No Security', 'OAuth Client', 'Backend Services');
type
  // information about a server required to get Smart App Launch working
  TRegisteredFHIRServer = class (TFslObject)
  private
    Fname: String;
    FfhirEndpoint: String;
    FSmartAppLaunchMode: TSmartAppLaunchMode;
    Fclientid: String;
    Fclientsecret: String;
    FautoUseHooks: boolean;
    Fcdshooks: TFslList<TRegisteredCDSHook>;
    Fredirectport: integer;
    FtokenEndpoint: String;
    FauthorizeEndpoint: String;
    FFormat: TFHIRFormat;
    FVersion: TFHIRVersion;
    FPassword: String;
    FUserName: String;
    FissuerUrl: String;
    Fpassphrase: String;
    Fprivatekey: String;
    FSSLPassphrase: String;
    FSSLPublicCert: String;
    FSSLPrivateKey: String;
    FId: integer;
    FHost: string;
  public
    constructor Create; override;
    destructor Destroy; Override;
    Function Link : TRegisteredFHIRServer; overload;
    procedure clear;
    procedure writeToJson(o : TJsonObject);
    procedure readFromJson(o : TJsonObject);

    function addCdsHook(name : String; hook : String) : TRegisteredCDSHook;
    function cdshookSummary : String;
    function doesHook(c : string; var hook : TRegisteredCDSHook) : boolean;

    // internal use only (not persisted)
    property id : integer read FId write FId;

    // user casual name for the server
    property name : String read Fname write Fname;

    // the FHIR Base endpoint for the server
    property fhirEndpoint : String read FfhirEndpoint write FfhirEndpoint;

    // version of the server
    property version : TFHIRVersion read FVersion write FVersion;

    // as is, choose from the conformance statement at run time. Else XML or JSON
    property format : TFHIRFormat read FFormat write FFormat;

    // whether the server needs Smart App Launch
    property SmartAppLaunchMode: TSmartAppLaunchMode read FSmartAppLaunchMode write FSmartAppLaunchMode;

    // you can get these 2 endpoints from the fhirEndPoint using usesSmartOnFHIR below:

    // where to point the browser to authorise a user
    property authorizeEndpoint : String read FauthorizeEndpoint write FauthorizeEndpoint;

    // where to get the access token after authorization has completed
    property tokenEndpoint : String read FtokenEndpoint write FtokenEndpoint;

    // registered client id
    property clientid : String read Fclientid write Fclientid;

    // client secret, if we're pretending we're a confidential application.
    // this is for testing purposes; the notepad++ plug-in is not a confidential app
    // (nor any other application using this library)
    property clientsecret : String read Fclientsecret write Fclientsecret;

    // the port for redirecting to this server
    property redirectport : integer read Fredirectport write Fredirectport;
    property host : string read FHost write FHost;

    // backend services
    property issuerUrl : String read FissuerUrl write FissuerUrl;
    property privatekey : String read Fprivatekey write Fprivatekey;
    property passphrase : String read Fpassphrase write Fpassphrase;

    // what CDS hooks are used on this server
    property cdshooks : TFslList<TRegisteredCDSHook> read Fcdshooks;

    // whether to use hooks automatically, or only if the server is connected
    property autoUseHooks : boolean read FautoUseHooks write FautoUseHooks;

    property username : String read FUserName write FUserName;
    property password : String read FPassword write FPassword;

    property SSLPublicCert : String read FSSLPublicCert write FSSLPublicCert;
    property SSLPrivateKey : String read FSSLPrivateKey write FSSLPrivateKey;
    property SSLPassphrase : String read FSSLPassphrase write FSSLPassphrase;
    function isSSL : boolean;
  end;

// given a conformance statement, check the server is using Smart App Launch, and extract the end points
function usesSmartOnFHIR(conf : TFhirCapabilityStatementW; var authorize, token, register: String): Boolean;

// build the launch token (used by the form)
function buildAuthUrl(server : TRegisteredFHIRServer; scopes, state : String) : String;

// called after the authorization part finishes to get an actual access token
function getSmartOnFhirAuthToken(server : TRegisteredFHIRServer; authcode : String) : TClientAccessToken;
function getSmartOnFhirAuthTokenRequest(server : TRegisteredFHIRServer; request : String) : TClientAccessToken;


implementation

function buildAuthUrl(server : TRegisteredFHIRServer; scopes, state : String) : String;
begin
  result := server.authorizeEndpoint+'?response_type=code&client_id='+server.clientid+'&redirect_uri=http://'+server.host+':'+inttostr(server.redirectport)+'/done&scope='+EncodeMIME(scopes)+'&state='+state+'&aud='+server.fhirEndpoint;
end;

function usesSmartOnFHIR(conf : TFhirCapabilityStatementW; var authorize, token, register: String): Boolean;
//var
//  cc : TFhirCodeableConcept;
//  ex1, ex2 : TFhirExtension;
begin
  result := false;
  authorize := '';
  token := '';
  if not conf.hasRest then
    raise EFHIRException.create('Unable to find rest entry in conformance statement');
  if (conf.hasSecurity('http://hl7.org/fhir/restful-security-service', 'SMART-on-FHIR') or conf.hasSecurity('http://hl7.org/fhir/restful-security-service', 'OAuth2') or
     // work around for some servers
      conf.hasSecurity('http://hl7.org/fhir/vs/restful-security-service', 'SMART-on-FHIR') or conf.hasSecurity('http://hl7.org/fhir/vs/restful-security-service', 'OAuth2') or
     // Epic workaround
      conf.hasSecurity('http://hl7.org/fhir/ValueSet/restful-security-service', 'SMART-on-FHIR') or conf.hasSecurity('http://hl7.org/fhir/ValueSet/restful-security-service', 'OAuth2')) then
    conf.readSmartExtension(authorize, token, register);
  result := (token <> '') and (authorize <> '');
end;

function getSmartOnFhirAuthTokenRequest(server : TRegisteredFHIRServer; request : String) : TClientAccessToken;
var
  http: TIdHTTP;
  ssl : TIdSSLIOHandlerSocketOpenSSL;
  post, resp : TBytesStream;
  json : TJSONObject;
  s : String;
begin
  result := nil;

  post := TBytesStream.create(TEncoding.UTF8.getBytes(request));
  try
    http := TIdHTTP.Create(nil);
    Try
      if server.clientsecret <> '' then
      begin
        http.Request.BasicAuthentication := True;
        http.Request.Username := server.clientid;
        http.Request.Password := server.clientsecret;
      end;
      ssl := TIdSSLIOHandlerSocketOpenSSL.Create(Nil);
      Try
        http.IOHandler := ssl;
        ssl.SSLOptions.Mode := sslmClient;
        ssl.SSLOptions.Method := sslvTLSv1_2;
        http.Request.ContentType := 'application/x-www-form-urlencoded; charset=UTF-8';
        resp := TBytesStream.create;
        try
          try
            http.Post(server.tokenEndpoint, post, resp);
            resp.position := 0;
            json := TJSONParser.Parse(resp);
            try
              result := TClientAccessToken.Create;
              try
                if not sameText(json.vStr['token_type'], 'Bearer') then
                  raise EFHIRException.create('token type is not "Bearer" (is '+json.vStr['token_type']+')');
                result.accesstoken := json.vStr['access_token'];
                result.scopes := json.vStr['scope'];
                s := json.vStr['expires_in'];
                if (s <> '') then
                begin
                  if not StringIsInteger16(s) then
                    raise EFHIRException.create('expires_in is not an integer');
                  result.expires := now + StrToInt(s) * DATETIME_SECOND_ONE;
                end;
                if json.vStr['id_token'] <> '' then
                  result.idToken := TJWTUtils.unpack(json.vStr['id_token'], false, nil);
                result.patient := json.vStr['patient'];
                result.Link;
              finally
                result.Free;
              end;
            finally
              json.free;
            end;
          except
            on e : EIdHTTPProtocolException do
              raise EFHIRException.create(e.message+' : '+e.ErrorMessage);
            on e:Exception do
              raise;
          end;
        finally
          resp.free;
        end;
      finally
        ssl.free;
      end;
    finally
      http.free;
    end;
  finally
    post.free;
  end;
end;

function getSmartOnFhirAuthToken(server : TRegisteredFHIRServer; authcode : String) : TClientAccessToken;
begin
  if server.clientsecret = '' then
    result := getSmartOnFhirAuthTokenRequest(server, 'code='+authcode+'&grant_type=authorization_code&client_id='+server.clientid+'&redirect_uri='+EncodeMime('http://'+server.host+':'+inttostr(server.redirectport)+'/done'))
  else
    result := getSmartOnFhirAuthTokenRequest(server, 'code='+authcode+'&grant_type=authorization_code&redirect_uri='+EncodeMime('http://'+server.host+':'+inttostr(server.redirectport)+'/done'));
end;

{ TRegisteredFHIRServer }

function TRegisteredFHIRServer.addCdsHook(name: String; hook: String): TRegisteredCDSHook;
begin
  result := TRegisteredCDSHook.Create;
  try
    result.name := name;
    result.hook := hook;
    cdshooks.add(result.link);
  finally
    result.Free;
  end;
end;

function TRegisteredFHIRServer.cdshookSummary: String;
var
  c : TRegisteredCDSHook;
begin
  result := '';
  for c in cdshooks do
    CommaAdd(result, c.name);
end;

procedure TRegisteredFHIRServer.clear;
begin
  Fname := '';
  FfhirEndpoint := '';
  FSmartAppLaunchMode := salmNone;
  Fclientid := '';
  Fclientsecret := '';
  FautoUseHooks := false;
  Fcdshooks.clear;
  Fredirectport := 0;
  FtokenEndpoint := '';
  FauthorizeEndpoint := '';
end;

constructor TRegisteredFHIRServer.Create;
begin
  inherited;
  Fcdshooks := TFslList<TRegisteredCDSHook>.create;
end;

destructor TRegisteredFHIRServer.Destroy;
begin
  Fcdshooks.Free;
  inherited;
end;

function TRegisteredFHIRServer.doesHook(c: string; var hook : TRegisteredCDSHook): boolean;
var
  h : TRegisteredCDSHook;
begin
  result := false;
  for h in cdshooks do
    if (c = h.hook) then
    begin
      hook := h;
      exit(true);
    end;
end;

function TRegisteredFHIRServer.isSSL: boolean;
begin
  result := FileExists(SSLPublicCert);
end;

function TRegisteredFHIRServer.Link: TRegisteredFHIRServer;
begin
  result := TRegisteredFHIRServer(Inherited Link);
end;

procedure TRegisteredFHIRServer.readFromJson(o: TJsonObject);
var
  arr : TJsonArray;
  n, n2 : TJsonNode;
  o1 : TJsonObject;
  c : TRegisteredCDSHook;
begin
  clear;

  name := o.vStr['name'];
  fhirEndpoint := o.vStr['fhir'];
  username := o.vStr['username'];
  password := o.vStr['password'];
  if password.StartsWith('##') then
    password := strDecrypt(password.Substring(2), 35252);
  if StringArrayExistsSensitive(['true', 'outh'], o.vStr['smart']) then
    FSmartAppLaunchMode := salmOAuthClient
  else if StringArrayExistsSensitive(['false', 'none'], o.vStr['smart']) then
    FSmartAppLaunchMode := salmNone
  else if StringArrayExistsSensitive(['backend'], o.vStr['smart']) then
    FSmartAppLaunchMode := salmBackendClient
  else
    FSmartAppLaunchMode := salmNone;
  if o.vStr['version']  = '' then
    version := fhirVersionRelease3
  else
    version := TFHIRVersion(StringArrayIndexOfSensitive(CODES_TFHIRVersion, o.vStr['version']));
  if o.vStr['format']  = 'xml' then
    format := ffXml
  else if o.vStr['format']  = 'json' then
    format := ffJson
  else
    format := ffUnspecified;

  tokenEndpoint := o.vStr['token'];
  authorizeEndpoint := o.vStr['authorize'];
  clientid := o.vStr['clientid'];
  redirectport := StrToIntDef(o.vStr['port'], 0);
  clientsecret := o.vStr['secret'];
  issuerUrl := o.vStr['issuer'];
  privatekey := o.vStr['key'];
  passphrase := strDecrypt(o.vStr['passphrase'], 42344);

  SSLPublicCert := o.vStr['ssl-cert'];
  SSLPrivateKey := o.vStr['ssl-key'];
  SSLpassphrase := strDecrypt(o.vStr['ssl-passphrase'], 42345);

  autoUseHooks := o.bool['auto-cds-hooks'];
  arr := o.arr['cdshooks'];
  if arr <> nil then
    for n in arr do
    begin
      o1 := n as TJsonObject;
      c := TRegisteredCDSHook.Create;
      cdshooks.Add(c);
      c.hook := o1.vStr['hook'];
      c.name := o1.vStr['name'];
      arr := o.arr['prefetch'];
      if arr <> nil then
        for n2 in arr do
          c.preFetch.Add((n2 as TJsonString).value)
    end;
end;

procedure TRegisteredFHIRServer.writeToJson(o: TJsonObject);
var
  arr, arr2 : TJsonArray;
  c : TRegisteredCDSHook;
  s : String;
begin
  o.clear;
  o.vStr['name'] := name;
  o.vStr['fhir'] := fhirEndpoint;
  o.vStr['username'] := username;
  o.vStr['password'] := '##'+strEncrypt(password, 35252);
  o.vStr['version'] := CODES_TFHIRVersion[version];
  case format of
    ffXml: o.vStr['format'] := 'xml';
    ffJson: o.vStr['format'] := 'json';
    ffTurtle : o.vStr['format'] := 'turtle';
  else
    o.vStr['format'] := 'either';
  end;
  case SmartAppLaunchMode of
    salmNone: o.vStr['smart'] := 'none';
    salmOAuthClient: o.vStr['smart'] := 'oauth';
    salmBackendClient: o.vStr['smart'] := 'backend';
  end;
  o.vStr['token'] := tokenEndpoint;
  o.vStr['authorize'] := authorizeEndpoint;

  o.vStr['clientid'] := clientid;
  o.vStr['port'] := inttostr(redirectport);
  o.vStr['secret'] := clientsecret;
  o.vStr['issuer'] := issuerUrl;
  o.vStr['key'] := privatekey;
  o.vStr['passphrase'] := strEncrypt(passphrase, 42344);

  o.vStr['ssl-cert'] := SSLPublicCert;
  o.vStr['ssl-key'] := SSLPrivateKey;
  o.vStr['ssl-passphrase'] := strEncrypt(SSLpassphrase, 42345);

  o.bool['auto-cds-hooks'] := autoUseHooks;
  if cdshooks.Count > 0 then
  begin
    arr := o.forceArr['cdshooks'];
    for c in cdshooks do
    begin
      o := arr.addObject;
      o.vStr['hook'] := c.hook;
      o.vStr['name'] := c.name;
      if (c.preFetch.Count > 0) then
      begin
        arr2 := o.forceArr['prefetch'];
        for s in c.preFetch do
          arr2.add(s);
      end;
    end;
  end;
end;

{ TRegisteredCDSHook }

constructor TRegisteredCDSHook.Create;
begin
  inherited;
  FpreFetch := TStringList.Create;
end;

destructor TRegisteredCDSHook.Destroy;
begin
  FPrefetch.Free;
  inherited;
end;

function TRegisteredCDSHook.Link: TRegisteredCDSHook;
begin
  result := TRegisteredCDSHook(inherited Link);
end;


end.
