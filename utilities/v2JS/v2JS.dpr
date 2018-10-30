program v2JS;

uses
  System.StartUpCopy,
  FMX.Forms,
  MainForm in 'MainForm.pas' {EditorForm},
  FHIR.Support.Base in '..\..\library\support\FHIR.Support.Base.pas',
  FHIR.Support.Utilities in '..\..\library\support\FHIR.Support.Utilities.pas',
  FHIR.Support.Fpc in '..\..\library\support\FHIR.Support.Fpc.pas',
  FHIR.Javascript.Base in '..\..\library\javascript\FHIR.Javascript.Base.pas',
  FHIR.Javascript in '..\..\library\javascript\FHIR.Javascript.pas',
  FHIR.Javascript.Chakra in '..\..\library\javascript\FHIR.Javascript.Chakra.pas',
  FHIR.Support.Javascript in '..\..\library\support\FHIR.Support.Javascript.pas',
  FHIR.Support.Collections in '..\..\library\support\FHIR.Support.Collections.pas',
  FHIR.Support.Stream in '..\..\library\support\FHIR.Support.Stream.pas',
  FHIR.Base.Objects in '..\..\library\base\FHIR.Base.Objects.pas',
  FHIR.Base.Lang in '..\..\library\base\FHIR.Base.Lang.pas',
  FHIR.Support.MXml in '..\..\library\support\FHIR.Support.MXml.pas',
  FHIR.Base.Factory in '..\..\library\base\FHIR.Base.Factory.pas',
  FHIR.Support.Json in '..\..\library\support\FHIR.Support.Json.pas',
  FHIR.Ucum.IFace in '..\..\library\ucum\FHIR.Ucum.IFace.pas',
  FHIR.Base.Parser in '..\..\library\base\FHIR.Base.Parser.pas',
  FHIR.Support.Xml in '..\..\library\support\FHIR.Support.Xml.pas',
  FHIR.Support.Turtle in '..\..\library\support\FHIR.Support.Turtle.pas',
  FHIR.Base.Xhtml in '..\..\library\base\FHIR.Base.Xhtml.pas',
  FHIR.Base.Narrative in '..\..\library\base\FHIR.Base.Narrative.pas',
  FHIR.Base.PathEngine in '..\..\library\base\FHIR.Base.PathEngine.pas',
  FHIR.Base.Common in '..\..\library\base\FHIR.Base.Common.pas',
  FHIR.Web.Parsers in '..\..\library\web\FHIR.Web.Parsers.pas',
  FHIR.Client.Base in '..\..\library\client\FHIR.Client.Base.pas',
  FHIR.Client.Javascript in '..\..\library\client\FHIR.Client.Javascript.pas',
  FHIR.v2.Protocol in '..\..\library\v2\FHIR.v2.Protocol.pas',
  FHIR.v2.Message in '..\..\library\v2\FHIR.v2.Message.pas',
  FHIR.R4.PathEngine in '..\..\library\r4\FHIR.R4.PathEngine.pas',
  FHIR.R4.PathNode in '..\..\library\r4\FHIR.R4.PathNode.pas',
  FHIR.R4.Types in '..\..\library\r4\FHIR.R4.Types.pas',
  FHIR.R4.Base in '..\..\library\r4\FHIR.R4.Base.pas',
  FHIR.Support.Signatures in '..\..\library\support\FHIR.Support.Signatures.pas',
  FHIR.Support.Certs in '..\..\library\support\FHIR.Support.Certs.pas',
  FHIR.Web.Fetcher in '..\..\library\web\FHIR.Web.Fetcher.pas',
  FHIR.R4.ElementModel in '..\..\library\r4\FHIR.R4.ElementModel.pas',
  FHIR.R4.Resources in '..\..\library\r4\FHIR.R4.Resources.pas',
  FHIR.Base.Utilities in '..\..\library\base\FHIR.Base.Utilities.pas',
  FHIR.R4.Utilities in '..\..\library\r4\FHIR.R4.Utilities.pas',
  FHIR.R4.Context in '..\..\library\r4\FHIR.R4.Context.pas',
  FHIR.R4.Constants in '..\..\library\r4\FHIR.R4.Constants.pas',
  FHIR.R4.Parser in '..\..\library\r4\FHIR.R4.Parser.pas',
  FHIR.R4.Xml in '..\..\library\r4\FHIR.R4.Xml.pas',
  FHIR.R4.ParserBase in '..\..\library\r4\FHIR.R4.ParserBase.pas',
  FHIR.R4.Json in '..\..\library\r4\FHIR.R4.Json.pas',
  FHIR.R4.Turtle in '..\..\library\r4\FHIR.R4.Turtle.pas',
  FHIR.R4.Common in '..\..\library\r4\FHIR.R4.Common.pas',
  FHIR.R4.Operations in '..\..\library\r4\FHIR.R4.Operations.pas',
  FHIR.R4.OpBase in '..\..\library\r4\FHIR.R4.OpBase.pas',
  FHIR.R4.Profiles in '..\..\library\r4\FHIR.R4.Profiles.pas',
  FHIR.Support.Threads in '..\..\library\support\FHIR.Support.Threads.pas',
  FHIR.v2.Javascript in '..\..\library\v2\FHIR.v2.Javascript.pas',
  FHIR.Client.InteractiveFMX in '..\..\library\client\FHIR.Client.InteractiveFMX.pas' {InteractiveClientForm},
  FHIR.Client.Debugger in '..\..\library\client\FHIR.Client.Debugger.pas',
  FHIR.Client.Threaded in '..\..\library\client\FHIR.Client.Threaded.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TInteractiveClientForm, InteractiveClientForm);
  Application.CreateForm(TEditorForm, EditorForm);
  Application.Run;
end.
