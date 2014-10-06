unit QuestionnaireBuilder;

interface

uses
  SysUtils, Classes, Generics.Collections,
  GUIDSupport, DateAndTime, AdvObjects, ShellSupport, StringSupport, AdvStringMatches,
  FHIRResources, FHIRComponents, FHIRTypes, FHIRConstants, FHIRBase, FHIRAtomFeed, FHIRParser,
  FHIRUtilities, FHIRSupport, ProfileManager;

Const
  TYPE_EXTENSION = 'http://www.healthintersections.com.au/fhir/Profile/metadata#type';
  TYPE_REFERENCE = 'http://www.healthintersections.com.au/fhir/Profile/metadata#reference';
  FLYOVER_REFERENCE = 'http://hl7.org/fhir/Profile/questionnaire-extensions#flyover';
  EXTENSION_FILTER_ONLY = 'http://www.healthintersections.com.au/fhir/Profile/metadata#expandNeedsFilter';
  MaxListboxCodings = 20;


Type
  TGetValueSetExpansion = function(vs : TFHIRValueSet; ref : TFhirReference; limit : integer; allowIncomplete : Boolean; dependencies : TStringList) : TFhirValueSet of object;
  TLookupCodeEvent = function(system, code : String) : String of object;
  TLookupReferenceEvent = function(Context : TFHIRRequest; uri : String) : TResourceWithReference of object;

  {
 * This class takes a profile, and builds a questionnaire from it
 *
 * If you then convert this questionnaire to a form using the
 * XMLTools form builder, and then take the QuestionnaireAnswers
 * this creates, you can use QuestionnaireInstanceConvert to
 * build an instance the conforms to the profile
 *
 * FHIR context:
 *   conceptLocator, codeSystems, valueSets, maps, client, profiles
 * You don't have to provide any of these, but
 * the more you provide, the better the conversion will be
 *
 * @author Grahame
  }
  TQuestionnaireBuilder = class (TAdvObject)
  private
    FProfiles : TProfileManager;
    lastid : integer;
    FResource: TFhirResource;
    FStructure: TFhirProfileStructure;
    FProfile: TfhirProfile;
    FQuestionnaire: TFhirQuestionnaire;
    FAnswers: TFhirQuestionnaireAnswers;
    FQuestionnaireId: String;
    FFactory : TFHIRFactory;
    FOnExpand : TGetValueSetExpansion;
    vsCache : TAdvStringMatch;
    FPrebuiltQuestionnaire: TFhirQuestionnaire;
    FOnLookupCode : TLookupCodeEvent;
    FOnLookupReference : TLookupReferenceEvent;
    FContext : TFHIRRequest;
    FDependencies: TList<String>;

    function nextId(prefix : string) : String;

    function getChildList(structure :TFHIRProfileStructure; path : String) : TFhirProfileStructureSnapshotElementList; overload;
    function getChildList(structure :TFHIRProfileStructure; element : TFhirProfileStructureSnapshotElement) : TFhirProfileStructureSnapshotElementList; overload;
    function isExempt(element, child: TFhirProfileStructureSnapshotElement) : boolean;

    function getSystemForCode(vs : TFHIRValueSet; code : String; path : String) : String;
    function resolveValueSet(profile : TFHIRProfile; binding : TFhirProfileStructureSnapshotElementDefinitionBinding) : TFHIRValueSet; overload;
    function resolveValueSet(url : String) : TFHIRValueSet; overload;
    function makeAnyValueSet : TFhirValueSet;

    function expandTypeList(types: TFhirProfileStructureSnapshotElementDefinitionTypeList): TFhirProfileStructureSnapshotElementDefinitionTypeList;
    function makeTypeList(profile : TFHIRProfile; types : TFhirProfileStructureSnapshotElementDefinitionTypeList; path : String) : TFHIRValueSet;
    function convertType(v: TFhirElement; t: string; path : String): TFhirElement; overload;
    function convertType(value : TFHIRObject; af : TFhirAnswerFormat; vs : TFHIRValueSet; path : String) : TFhirType; overload;
    procedure selectTypes(profile : TFHIRProfile; sub : TFHIRQuestionnaireGroup; t: TFhirProfileStructureSnapshotElementDefinitionType; source, dest: TFhirQuestionnaireAnswersGroupList);
    function instanceOf(t : TFhirProfileStructureSnapshotElementDefinitionType; obj : TFHIRObject) : boolean;

    function addQuestion(group: TFHIRQuestionnaireGroup; af: TFhirAnswerFormat; path, id, name: String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList; vs : TFHIRValueSet = nil): TFhirQuestionnaireGroupQuestion;

    procedure addAddressQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addAgeQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addAttachmentQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addBinaryQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addBooleanQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addCodeQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addCodeableConceptQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addCodingQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addContactQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addDateTimeQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addDecimalQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addDurationQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addExtensionQuestions(profile : TFHIRProfile; group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; profileURL : String; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addHumanNameQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addIdRefQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addIdentifierQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addInstantQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addIntegerQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addPeriodQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addQuantityQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addRangeQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addRatioQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addReferenceQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; profileURL : String; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addSampledDataQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addScheduleQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addStringQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addTimeQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure addUriQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);

    function processAnswerGroup(group : TFhirQuestionnaireAnswersGroup; context : TFhirElement; defn :  TProfileDefinition) : boolean;

    procedure processDataType(profile : TFHIRProfile; group: TFHIRQuestionnaireGroup; element: TFhirProfileStructureSnapshotElement; path: String; t: TFhirProfileStructureSnapshotElementDefinitionType; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure buildQuestion(group : TFHIRQuestionnaireGroup; profile : TFHIRProfile; structure :TFHIRProfileStructure; element : TFhirProfileStructureSnapshotElement; path : String; answerGroups : TFhirQuestionnaireAnswersGroupList);
	  procedure buildGroup(group : TFHIRQuestionnaireGroup; profile : TFHIRProfile; structure :TFHIRProfileStructure; element : TFhirProfileStructureSnapshotElement; parents : TFhirProfileStructureSnapshotElementList; answerGroups : TFhirQuestionnaireAnswersGroupList);
    procedure processMetadata;
    procedure SetProfiles(const Value: TProfileManager);
    procedure SetProfile(const Value: TFhirProfile);
    procedure SetResource(const Value: TFhirResource);
    procedure SetStructure(const Value: TFhirProfileStructure);
    procedure processExisting(path : String; answerGroups, nAnswers: TFhirQuestionnaireAnswersGroupList);
    procedure SetAnswers(const Value: TFhirQuestionnaireAnswers);
    procedure SetPrebuiltQuestionnaire(const Value: TFhirQuestionnaire);
    procedure SetContext(const Value: TFHIRRequest);
  public
    Constructor Create; override;
    Destructor Destroy; override;

    Property Profiles : TProfileManager read FProfiles write SetProfiles;
    Property OnExpand : TGetValueSetExpansion read FOnExpand write FOnExpand;
    Property onLookupCode : TLookupCodeEvent read FonLookupCode write FonLookupCode;
    Property onLookupReference : TLookupReferenceEvent read FonLookupReference write FonLookupReference;
    Property Context : TFHIRRequest read FContext write SetContext;

    Property Profile : TFhirProfile read FProfile write SetProfile;
    Property Structure : TFhirProfileStructure read FStructure write SetStructure;
    Property Resource : TFhirResource read FResource write SetResource;
    Property Questionnaire : TFhirQuestionnaire read FQuestionnaire;
    Property Answers : TFhirQuestionnaireAnswers read FAnswers write SetAnswers;
    Property QuestionnaireId : String read FQuestionnaireId write FQuestionnaireId;
    Property Dependencies : TList<String> read FDependencies;

    // sometimes, when this is used, the questionnaire is already build and cached, and we are
    // processing the answers. for technical reasons, we still go through the process, but
    // we don't do the intensive parts of the work (save time)
    Property PrebuiltQuestionnaire : TFhirQuestionnaire read FPrebuiltQuestionnaire write SetPrebuiltQuestionnaire;

    procedure Build;
    procedure UnBuild;
  end;

implementation

Uses
  NarrativeGenerator;

Function tail(path : String) : String;
begin
  result := path.substring(path.lastIndexOf('.')+1);
end;

{ TQuestionnaireBuilder }

procedure TQuestionnaireBuilder.build;
var
  p : TFhirProfileStructure;
  list : TFhirProfileStructureSnapshotElementList;
  answerGroups : TFhirQuestionnaireAnswersGroupList;
  group : TFhirQuestionnaireGroup;
begin
  if profile = nil then
    raise Exception.Create('QuestionnaireBuilder.build: No Profile provided');

  if (profile.structureList.IsEmpty) then
		raise Exception.create('QuestionnaireBuilder.build: no structure found');

  if Structure = nil then
  begin
    for p in profile.structureList do
      if p.publish then
        if structure = nil then
          structure := p.Link
        else
          raise Exception.create('buildQuestionnaire: if there is more than one published structure in the profile, you must choose one');
    if (structure = nil) then
      raise Exception.create('buildQuestionnaire: no published structure found');
  end;

  if (not profile.structureList.ExistsByReference(structure)) then
 		raise Exception.create('buildQuestionnaire: profile/structure mismatch');

  if resource <> nil then
    if Structure.type_ <> CODES_TFhirResourceType[resource.ResourceType] then
      raise Exception.Create('Wrong Type');

  if FPrebuiltQuestionnaire <> nil then
    FQuestionnaire := FPrebuiltQuestionnaire.Link
  else
    FQuestionnaire := TFHIRQuestionnaire.Create();
  if resource <> nil then
    FAnswers := TFhirQuestionnaireAnswers.Create;
  processMetadata;


  list := TFhirProfileStructureSnapshotElementList.Create;
  answerGroups := TFhirQuestionnaireAnswersGroupList.create;
  try
    if resource <> nil then
      answerGroups.Add(FAnswers.group.Link);
    if PrebuiltQuestionnaire <> nil then
    begin
     // give it a fake group to build
     group := TFhirQuestionnaireGroup.Create;
     try
      buildGroup(group, profile, structure, structure.snapshot.elementList[0], list, answerGroups);
     finally
       group.free;
     end;
    end
    else
      buildGroup(FQuestionnaire.group, profile, structure, structure.snapshot.elementList[0], list, answerGroups);
  finally
    list.Free;
    answerGroups.Free;
  end;

  if FAnswers <> nil then
    FAnswers.collapseAllContained;
end;

procedure TQuestionnaireBuilder.processExisting(path : String; answerGroups, nAnswers: TFhirQuestionnaireAnswersGroupList);
var
  ag : TFhirQuestionnaireAnswersGroup;
  ans: TFhirQuestionnaireAnswersGroup;
  children: TFHIRObjectList;
  ch : TFHIRObject;
begin
  // processing existing data
  for ag in answerGroups do
  begin
    children := TFHIRObjectList.Create;
    try
      TFHIRObject(ag.tag).ListChildrenByName(tail(path), children);
      for ch in children do
        if ch <> nil then
        begin
          ans := ag.groupList.Append;
          ans.Tag := ch.Link;
          nAnswers.add(ans.link);
        end;
    finally
      children.Free;
    end;
  end;
end;

destructor TQuestionnaireBuilder.Destroy;
begin
  FDependencies.Free;
  vsCache.Free;
  FResource.Free;
  FStructure.Free;
  FProfile.Free;
  FQuestionnaire.Free;
  FAnswers.Free;
  FProfiles.Free;
  FPrebuiltQuestionnaire.Free;
  FContext.free;
  inherited;
end;

function convertStatus(status : TFhirResourceProfileStatus) : TFHIRQuestionnaireStatus;
begin
  case (status) of
		ResourceProfileStatusActive: result := QuestionnaireStatusPublished;
		ResourceProfileStatusDraft: result := QuestionnaireStatusDraft;
		ResourceProfileStatusRetired : result := QuestionnaireStatusRetired;
	else
  result := QuestionnaireStatusNull;
	end;
end;

procedure TQuestionnaireBuilder.processMetadata;
var
  id : TFhirIdentifier;
begin
  // todo: can we derive a more informative identifier from the questionnaire if we have a profile
  if FPrebuiltQuestionnaire = nil then
  begin
    id := FQuestionnaire.identifierList.Append;
    id.System := 'urn:ietf:rfc:3986';
    id.Value := FQuestionnaireId;
    FQuestionnaire.Version := profile.Version;
    FQuestionnaire.Status := convertStatus(profile.Status);
    FQuestionnaire.Date := profile.Date.link;
    FQuestionnaire.publisher := profile.Publisher;
    FQuestionnaire.Group := TFhirQuestionnaireGroup.Create;
    FQuestionnaire.group.conceptList.AddAll(profile.codeList);
  end;

  if FAnswers <> nil then
  begin
    // no identifier - this is transient
    FQuestionnaire.xmlId := nextId('qs');
    FAnswers.questionnaire := TFhirReference.Create;
    FAnswers.questionnaire.reference := '#'+FQuestionnaire.xmlId;
    FAnswers.containedList.Add(FQuestionnaire.Link);
    FAnswers.status := QuestionnaireAnswersStatusInProgress;
    FAnswers.Group := TFhirQuestionnaireAnswersGroup.Create;
    FAnswers.Group.Tag := FResource.Link;
  end;
end;

function TQuestionnaireBuilder.resolveValueSet(url: String): TFHIRValueSet;
var
  ref : TFhirReference;
  dependencies : TStringList;
  s : String;
begin
  result := nil;
  if PrebuiltQuestionnaire <> nil then
    exit; // we don't do anything with value sets in this case

  if vsCache.ExistsByKey(url) then
    result := FQuestionnaire.contained[vsCache.GetValueByKey(url)].link as TFhirValueSet
  else
  begin
    ref := TFhirReference.Create;
    dependencies := TStringList.create;
    try
      ref.reference := url;
      try
        result := OnExpand(nil, ref, MaxListboxCodings, false, dependencies);
        for s in dependencies do
          if not FDependencies.Contains(s) then
            FDependencies.Add(s);
      except
        on e: ETooCostly do
        begin
          result := TFhirValueSet.Create;
          try
            result.identifier := ref.reference;
            result.link;
          finally
            result.Free;
          end;
        end;
        on e : Exception do
          raise;
      end;
    finally
      dependencies.Free;
      ref.Free;
    end;
  end;
end;

function TQuestionnaireBuilder.resolveValueSet(profile: TFHIRProfile; binding: TFhirProfileStructureSnapshotElementDefinitionBinding): TFHIRValueSet;
var
  ref : TFhirReference;
  vs : TFHIRValueSet;
  dependencies : TStringList;
  s : String;
begin
  result := nil;
  if PrebuiltQuestionnaire <> nil then
    exit; // we don't do anything with value sets in this case

  if (binding = nil) or not (binding.reference is TFhirReference) then
    exit;

  dependencies := TStringList.create;
  try
    ref := binding.reference as TFhirReference;
    if ref.reference.StartsWith('#') then
    begin
      vs := TFhirValueSet(Fprofile.contained[ref.reference.Substring(1)]);
      try
        result := OnExpand(vs, nil, MaxListboxCodings, false, dependencies);
        for s in dependencies do
          if not FDependencies.Contains(s) then
            FDependencies.Add(s);
      except
        on e: ETooCostly do
        begin
          result := TFhirValueSet.Create;
          try
            result.identifier := ref.reference;
            result.link;
          finally
            result.Free;
          end;
        end;
        on e : Exception do
          raise;
      end;

    end
    else if vsCache.ExistsByKey(ref.reference) then
      result := FQuestionnaire.contained[vsCache.GetValueByKey(ref.reference)].link as TFhirValueSet
    else
      try
        result := OnExpand(nil, ref, MaxListboxCodings, false, dependencies);
        for s in dependencies do
          if not FDependencies.Contains(s) then
            FDependencies.Add(s);
      except
        on e: ETooCostly do
        begin
          result := TFhirValueSet.Create;
          try
            result.identifier := ref.reference;
            result.link;
          finally
            result.Free;
          end;
        end;
        on e : Exception do
          raise;
      end;
  finally
    dependencies.Free;
  end;
end;

procedure TQuestionnaireBuilder.SetAnswers(const Value: TFhirQuestionnaireAnswers);
begin
  FAnswers.Free;
  FAnswers := Value;
end;

procedure TQuestionnaireBuilder.SetContext(const Value: TFHIRRequest);
begin
  FContext.Free;
  FContext := Value;
end;

procedure TQuestionnaireBuilder.SetPrebuiltQuestionnaire(const Value: TFhirQuestionnaire);
begin
  FPrebuiltQuestionnaire.Free;
  FPrebuiltQuestionnaire := Value;
end;

procedure TQuestionnaireBuilder.SetProfile(const Value: TFHIRProfile);
begin
  FProfile.Free;
  FProfile := Value;
end;

procedure TQuestionnaireBuilder.SetProfiles(const Value: TProfileManager);
begin
  FProfiles.Free;
  FProfiles := Value;
end;

procedure TQuestionnaireBuilder.SetResource(const Value: TFhirResource);
begin
  FResource.Free;
  FResource := Value;
end;

procedure TQuestionnaireBuilder.SetStructure(const Value: TFhirProfileStructure);
begin
  FStructure.Free;;
  FStructure := Value;
end;

procedure TQuestionnaireBuilder.UnBuild;
var
  ps : TFhirProfileStructure;
  defn : TProfileDefinition;
  gen : TNarrativeGenerator;
begin
  if Profile = nil then
    raise Exception.Create('A Profile is required');

  if Structure = nil then
  begin
    for ps in profile.structureList do
      if ps.publish then
        if structure = nil then
          structure := ps.Link
        else
          raise Exception.create('buildQuestionnaire: if there is more than one published structure in the profile, you must choose one');
    if (structure = nil) then
      raise Exception.create('buildQuestionnaire: no published structure found');
  end;

  if Structure = nil then
    raise Exception.Create('A Structure is required');
  if Answers = nil then
    raise Exception.Create('A set of answers is required');
  if Answers.group = nil then
    raise Exception.Create('A base group is required in the answers');

  if Answers.group.linkId <> Structure.snapshot.elementList[0].path then
    raise Exception.Create('Mismatch between answers and profile');

  Resource := FFactory.makeByName(structure.type_) as TFhirResource;

  defn := TProfileDefinition.create(profiles.Link, profile.link, structure.link);
  try
    processAnswerGroup(Answers.group, resource, defn);
  finally
    defn.free;
  end;

  gen := TNarrativeGenerator.Create('', FProfiles.Link, OnLookupCode, onLookupReference, context.Link);
  try
    gen.generate(Resource, profile);
  finally
    gen.Free;
  end;
end;

function TQuestionnaireBuilder.convertType(v : TFhirElement; t : string; path : String) : TFhirElement;
var
  s : String;
begin
  s := v.FhirType;
  if (s = t) then
    result := v.link
  else if ((s = 'string') and (t = 'code')) then
    result := TFhirEnum.Create(TFHIRString(v).value)
  else if ((s = 'string') and (t = 'uri')) then
    result := TFhirUri.Create(TFHIRString(v).value)
  else if ((s = 'Coding') and (t = 'code')) then
    result := TFhirEnum.Create(TFHIRCoding(v).code)
  else if ((s = 'dateTime') and (t = 'date')) then
    result := TFhirDate.Create(TFhirDateTime(v).value.Link)
  else
    raise Exception.Create('Unable to convert from '+s+' to '+t+' at path = '+path);
end;

function isPrimitive(t : TFhirProfileStructureSnapshotElementDefinitionType) : Boolean; overload;
begin
  result := (t <> nil) and (StringArrayExistsSensitive(['string', 'code', 'boolean', 'integer', 'decimal', 'date', 'dateTime', 'instant', 'time', 'ResourceReference'], t.code));
end;

function allTypesSame(types : TFhirProfileStructureSnapshotElementDefinitionTypeList) : boolean;
var
  t : TFhirProfileStructureSnapshotElementDefinitionType;
  s : String;
begin
  result := true;
  s := types[0].code;
  for t in types do
    if s <> t.code then
      result := false;
end;

function determineType(g : TFhirQuestionnaireAnswersGroup) : TFhirProfileStructureSnapshotElementDefinitionType;
var
  q : TFhirQuestionnaireAnswersGroupQuestion;
  cc : TFhirCoding;
begin
  result := nil;
  if (g.questionList.Count <> 1) then
    exit;
  q := g.questionList[0];
  if (q.linkId <> g.linkId+'._type') then
    exit;
  if q.answerList.Count <> 1 then
    exit;
  if q.answerList[0].value is TFhirCoding then
  begin
    cc := TFhirCoding(q.answerList[0].value);
    result := TFhirProfileStructureSnapshotElementDefinitionType.Create;
    try
      result.tagValue := cc.code;
      if cc.system = 'http://hl7.org/fhir/resource-types' then
      begin
        result.code := 'ResourceReference';
        result.profile := 'http://hl7.org/fhir/Profile/'+cc.code;
      end
      else // cc.system = 'http://hl7.org/fhir/data-types'
      begin
        result.code := cc.code;
      end;
      result.Link;
    finally
      result.Free;
    end;
  end;
end;

function selectTypeGroup(g : TFhirQuestionnaireAnswersGroup; t : TFhirProfileStructureSnapshotElementDefinitionType) : TFhirQuestionnaireAnswersGroup;
var
  qg : TFhirQuestionnaireAnswersGroup;
begin
  result := nil;
  for qg in g.questionList[0].groupList do
    if qg.linkId = g.linkId+'._'+t.TagValue then
      result := qg;
end;

function TQuestionnaireBuilder.processAnswerGroup(group : TFhirQuestionnaireAnswersGroup; context : TFhirElement; defn :  TProfileDefinition) : boolean;
var
  g, g1 : TFhirQuestionnaireAnswersGroup;
  q : TFhirQuestionnaireAnswersGroupQuestion;
  a : TFhirQuestionnaireAnswersGroupQuestionAnswer;
  d : TProfileDefinition;
  t : TFhirProfileStructureSnapshotElementDefinitionType;
  o : TFHIRElement;
begin
  result := false;

  for g1 in group.groupList do
  begin
    g := g1;
    d := defn.getById(g.linkId);
    try
      t := nil;
      try
        if d.hasTypeChoice then
        begin
          t := determineType(g);
          d.setType(t.link);
          // now, select the group for the type
          g := selectTypeGroup(g, t);
        end
        else
          t := d.statedType.link;

        if ((g <> nil) and (t <> nil)) or not d.hasTypeChoice then
        begin
          if (isPrimitive(t)) then
          begin
            if (g.questionList.Count <> 1) then
              raise Exception.Create('Unexpected Condition: a group for a primitive type with more than one question @ '+g.linkId);
            if (g.groupList.Count > 0) then
              raise Exception.Create('Unexpected Condition: a group for a primitive type with groups @ '+g.linkId);
            q := g.questionList[0];
            for a in q.answerList do
            begin
              if a.value <> nil then
              begin
                context.setProperty(d.name, convertType(a.value, t.code, g.linkId));
                result := true;
              end
              else
                raise Exception.Create('Empty answer for '+g.linkId);
            end;
          end
          else
          begin
            if t = nil then
              o := FFactory.makeByName(d.path)
            else
              o := FFactory.makeByName(t.code);
            try
              if processAnswerGroup(g, o, d) then
              begin
                context.setProperty(d.name, o.Link);
                result := true;
              end;
            finally
              o.Free;
            end;
          end;
        end;
      finally
        t.Free;
      end;
    finally
      d.free;
    end;
  end;

  for q in group.questionList do
  begin
    d := defn.getById(q.linkId);
    try
      if d.hasTypeChoice then
        raise Exception.Create('not done yet - shouldn''t get here??');
      for a in q.answerList do
      begin
        context.setProperty(d.name, convertType(a.value, d.statedType.code, q.linkId));
        result := true;
      end;
    finally
      d.free;
    end;
  end;
end;

procedure TQuestionnaireBuilder.buildGroup(group: TFHIRQuestionnaireGroup; profile: TFHIRProfile; structure: TFHIRProfileStructure; element: TFhirProfileStructureSnapshotElement; parents: TFhirProfileStructureSnapshotElementList; answerGroups : TFhirQuestionnaireAnswersGroupList);
var
  list : TFhirProfileStructureSnapshotElementList;
  child : TFhirProfileStructureSnapshotElement;
  nparents : TFhirProfileStructureSnapshotElementList;
  childGroup : TFHIRQuestionnaireGroup;
  nAnswers : TFhirQuestionnaireAnswersGroupList;
  ag : TFhirQuestionnaireAnswersGroup;
begin
  group.LinkId := element.Path; // todo: this will be wrong when we start slicing
  group.Title := element.Definition.Short; // todo - may need to prepend the name tail...
  group.Text := element.Definition.comments;
  group.SetExtensionString(FLYOVER_REFERENCE, element.Definition.Formal);
  group.Required := element.Definition.Min > '0';
  group.Repeats := element.Definition.Max <> '1';

  for ag in answerGroups do
  begin
    ag.linkId := group.linkId;
    ag.Title := group.Title;
    ag.Text := group.Text;
  end;

  // now, we iterate the children
  list := getChildList(structure, element);
  try
    for child in list do
    begin
			if (child.Definition = nil) then
				raise Exception.create('Found an element with no definition generating a Questionnaire');

      if (not isExempt(element, child)) and (not parents.ExistsByReference(child)) then
      begin
        nparents := TFhirProfileStructureSnapshotElementList.Create;
        try
          nparents.Assign(parents);
          nparents.add(child.link);
          childGroup := group.groupList.Append;

          nAnswers := TFhirQuestionnaireAnswersGroupList.Create;
          try
             processExisting(child.path, answerGroups, nAnswers);
            // if the element has a type, we add a question. else we add a group on the basis that
            // it will have children of it's own
            if (child.Definition.type_List.isEmpty) then
              buildGroup(childGroup, profile, structure, child, nparents, nAnswers)
            else
              buildQuestion(childGroup, profile, structure, child, child.path, nAnswers);
          finally
            nAnswers.Free;
          end;
        finally
          nparents.Free;
        end;
      end;
	  end;
  finally
    list.Free;
  end;
end;

function TQuestionnaireBuilder.getChildList(structure :TFHIRProfileStructure; path : String) : TFhirProfileStructureSnapshotElementList;
var
  e : TFhirProfileStructureSnapshotElement;
  p, tail : String;
begin
  result := TFhirProfileStructureSnapshotElementList.Create;
  try
    for e in structure.snapshot.elementList do
    begin
      p := e.path;

      if (e.definition.nameReference <> '') and path.startsWith(p) then
      begin
        result.Free;
        if (path.length > p.length) then
          result := getChildList(structure, e.Definition.NameReference+'.'+path.substring(p.length+1))
        else
          result := getChildList(structure, e.Definition.NameReference);
      end
      else if p.startsWith(path+'.') and (p <> path) then
      begin
        tail := p.substring(path.length+1);
        if (not tail.contains('.')) then
          result.add(e.Link);
      end;
    end;
    result.link;
  finally
    result.Free;
  end;
end;


function TQuestionnaireBuilder.getChildList(structure :TFHIRProfileStructure; element : TFhirProfileStructureSnapshotElement) : TFhirProfileStructureSnapshotElementList;
begin
  result := getChildList(structure, element.Path);
end;

function TQuestionnaireBuilder.getSystemForCode(vs: TFHIRValueSet; code: String; path : String): String;
var
  r : TFhirResource;
  cc : TFhirValueSetExpansionContains;
begin
  if (vs = nil) then
  begin
    if FPrebuiltQuestionnaire <> nil then
    begin
      for r in FPrebuiltQuestionnaire.containedList do
        if r is TFhirValueSet then
        begin
          vs := TFhirValueSet(r);
          if (vs.expansion <> nil) then
          begin
            for cc in vs.expansion.containsList do
              if cc.code = code then
                if result = '' then
                  result := cc.system
                 else
                  raise Exception.Create('Multiple matches in '+vs.identifier+' for code '+code+' at path = '+path);
          end;
        end;
    end;
    raise Exception.Create('Logic error'+' at path = '+path);
  end;
  result := '';
  for cc in vs.expansion.containsList Do
  begin
    if cc.code = code then
      if result = '' then
        result := cc.system
      else
        raise Exception.Create('Multiple matches in '+vs.identifier+' for code '+code+' at path = '+path);
  end;
  if result = '' then
    raise Exception.Create('Unable to resolve code '+code+' at path = '+path);
end;

function TQuestionnaireBuilder.isExempt(element, child: TFhirProfileStructureSnapshotElement) : boolean;
var
  n, t : string;
begin
  n := tail(child.Path);
  if not element.Definition.type_List.isEmpty then
    t :=  element.Definition.type_List[0].Code;

  // we don't generate questions for the base stuff in every element
	if (t = 'Resource') and
				((n = 'text') or (n = 'language') or (n = 'contained')) then
    result := true
		// we don't generate questions for extensions
	else if (n = 'extension') or (n = 'modifierExtension') then
  begin
    if (child.definition.type_List.Count > 0) and (child.definition.type_List[0].profile <> '') then
      result := false
    else
      result := true
  end
  else
	  result := false;
end;

function TQuestionnaireBuilder.expandTypeList(types: TFhirProfileStructureSnapshotElementDefinitionTypeList): TFhirProfileStructureSnapshotElementDefinitionTypeList;
var
  t : TFhirProfileStructureSnapshotElementDefinitionType;
begin
  result := TFhirProfileStructureSnapshotElementDefinitionTypeList.create;
  try
    for t in types do
    begin
      if (t.profile <> '') then
        result.Add(t.Link)
      else if (t.code = '*') then
      begin
        result.Append.code := 'integer';
        result.Append.code := 'decimal';
        result.Append.code := 'dateTime';
        result.Append.code := 'date';
        result.Append.code := 'instant';
        result.Append.code := 'time';
        result.Append.code := 'string';
        result.Append.code := 'uri';
        result.Append.code := 'boolean';
        result.Append.code := 'Coding';
        result.Append.code := 'CodeableConcept';
        result.Append.code := 'Attachment';
        result.Append.code := 'Identifier';
        result.Append.code := 'Quantity';
        result.Append.code := 'Range';
        result.Append.code := 'Period';
        result.Append.code := 'Ratio';
        result.Append.code := 'HumanName';
        result.Append.code := 'Address';
        result.Append.code := 'Contact';
        result.Append.code := 'Schedule';
        result.Append.code := 'ResourceReference';
      end
      else
        result.Add(t.Link);
    end;
    result.Link;
  finally
    result.Free;
  end;
end;

function TQuestionnaireBuilder.makeAnyValueSet: TFhirValueSet;
begin
  if vsCache.ExistsByKey(ANY_CODE_VS) then
    result := FQuestionnaire.contained[vsCache.GetValueByKey(ANY_CODE_VS)].link as TFhirValueSet
  else
  begin
    result := TFhirValueSet.Create;
    try
      result.identifier := ANY_CODE_VS;
      result.name := 'All codes known to the system';
      result.description := 'All codes known to the system';
      result.status := ValuesetStatusActive;
      result.compose := TFhirValueSetCompose.create;
      result.compose.includeList.Append.system := ANY_CODE_VS;
      result.link;
    finally
      result.Free;
    end;
  end;

end;

function TQuestionnaireBuilder.makeTypeList(profile : TFHIRProfile; types: TFhirProfileStructureSnapshotElementDefinitionTypeList; path : String): TFHIRValueSet;
var
  vs : TFhirValueset;
  t : TFhirProfileStructureSnapshotElementDefinitionType;
  cc : TFhirValueSetExpansionContains;
  structure : TFhirProfileStructure;
begin
  vs := TFhirValueset.Create;
  try
    vs.identifier := NewGuidURN;
    vs.name := 'Type options for '+path;
    vs.description := vs.name;
    vs.status := ValuesetStatusActive;
    vs.expansion := TFhirValueSetExpansion.Create;
    vs.expansion.timestamp := NowUTC;
    for t in types do
    begin
      cc := vs.expansion.containsList.Append;
      if (t.code = 'ResourceReference') and (t.profile.startsWith('http://hl7.org/fhir/Profile/')) then
      begin
        cc.code := t.profile.Substring(28);
        cc.system := 'http://hl7.org/fhir/resource-types';
        cc.display := cc.code;
      end
      else if (t.profile <> '') and FProfiles.getStructure(profile, t.profile, profile, structure) then
      begin
        cc.code := t.profile;
        cc.display := structure.name;
        cc.system := 'http://hl7.org/fhir/resource-types';
      end
      else
      begin
        cc.code := t.code;
        cc.display := t.code;
        cc.system := 'http://hl7.org/fhir/data-types';
      end;
      t.TagValue := cc.code;
    end;
    result := vs.Link;
  finally
    vs.Free;
  end;
end;

function TQuestionnaireBuilder.nextId(prefix : string): String;
begin
  inc(lastid);
  result := prefix+inttostr(lastid);
end;

function TQuestionnaireBuilder.instanceOf(t : TFhirProfileStructureSnapshotElementDefinitionType; obj : TFHIRObject) : boolean;
var
  url : String;
begin
  if t.code = 'ResourceReference' then
  begin
    if not (obj is TFhirReference) then
      result := false
    else
    begin
      url := TFhirReference(obj).reference;
      {
      there are several problems here around profile matching. This process is degenerative, and there's probably nothing we can do to solve it
      }
      if url.StartsWith('http:') or url.StartsWith('https:') then
        result := true
      else if (t.profile.startsWith('http://hl7.org/fhir/Profile/')) then
        result := url.StartsWith(t.profile.Substring(28)+'/')
      else
        result := true;
    end;
  end
  else if t.code = 'Quantity' then
    result := obj is TFHIRQuantity
  else
    raise Exception.Create('Not Done Yet');
end;

procedure TQuestionnaireBuilder.selectTypes(profile : TFHIRProfile; sub : TFHIRQuestionnaireGroup; t : TFhirProfileStructureSnapshotElementDefinitionType; source, dest : TFhirQuestionnaireAnswersGroupList);
var
  temp : TFhirQuestionnaireAnswersGroupList;
  subg : TFhirQuestionnaireAnswersGroup;
  q : TFhirQuestionnaireAnswersGroupQuestion;
  cc : TFhirCoding;
  structure : TFhirProfileStructure;
  ag : TFhirQuestionnaireAnswersGroup;
begin
  temp := TFhirQuestionnaireAnswersGroupList.Create;
  try
    for ag in source do
      if instanceOf(t, ag.tag as TFHIRObject) then
        temp.add(ag.link);
    for ag in temp do
      source.DeleteByReference(ag);
    for ag in temp do
    begin
      // 1st the answer:
      assert(ag.questionList.count = 0); // it should be empty
      q := ag.questionList.Append;
      q.linkId := ag.linkId+'._type';
      q.text := 'type';

      cc := TFHIRCoding.Create;
      q.answerList.append.value := cc;
      if (t.code = 'ResourceReference') and (t.profile.startsWith('http://hl7.org/fhir/Profile/')) then
      begin
        cc.code := t.profile.Substring(28);
        cc.system := 'http://hl7.org/fhir/resource-types';
      end
      else if (t.profile <> '') and FProfiles.getStructure(profile, t.profile, profile, structure) then
      begin
        cc.code := t.profile;
        cc.system := 'http://hl7.org/fhir/resource-types';
      end
      else
      begin
        cc.code := t.code;
        cc.system := 'http://hl7.org/fhir/data-types';
      end;

      // 1st: create the subgroup
      subg := q.groupList.Append;
      dest.Add(subg.Link);
      subg.linkId := sub.linkId;
      subg.text := sub.text;
      subg.Tag := ag.Tag.Link;

    end;
  finally
    temp.Free;
  end;
end;

// most of the types are complex in regard to the Questionnaire, so they are still groups
	// there will be questions for each component
procedure TQuestionnaireBuilder.buildQuestion(group : TFHIRQuestionnaireGroup; profile : TFHIRProfile; structure :TFHIRProfileStructure; element : TFhirProfileStructureSnapshotElement; path : String; answerGroups : TFhirQuestionnaireAnswersGroupList);
var
  t : TFhirProfileStructureSnapshotElementDefinitionType;
  q : TFhirQuestionnaireGroupQuestion;
  types : TFhirProfileStructureSnapshotElementDefinitionTypeList;
  sub : TFHIRQuestionnaireGroup;
  selected : TFhirQuestionnaireAnswersGroupList;
  ag : TFhirQuestionnaireAnswersGroup;
begin
  group.LinkId := path;

  // in this context, we don't have any concepts to mark...
  group.Text := element.Definition.Short; // prefix with name?
  group.Required := element.Definition.Min > '0';
  group.Repeats := element.Definition.Max <> '1';

  for ag in answerGroups do
  begin
    ag.linkId := group.linkId;
    ag.Title := group.Title;
    ag.Text := group.Text;
  end;

  if element.Definition.comments <> '' then
    group.setExtensionString(FLYOVER_REFERENCE, element.Definition.Formal+' '+element.Definition.comments)
  else
    group.setExtensionString(FLYOVER_REFERENCE, element.Definition.Formal);

  if (element.Definition.type_List.Count > 1) or (element.Definition.type_List[0].Code = '*') then
  begin
    types := expandTypeList(element.definition.type_List);
    try
      q := addQuestion(group, AnswerFormatChoice, element.path, '_type', 'type', true, nil, makeTypeList(profile, types, element.path));
      for t in types do
      begin
        sub := q.groupList.Append;
        sub.LinkId := element.Path+'._'+t.tagValue;
        sub.Text := t.TagValue;
        // always optional, never repeats

        selected := TFhirQuestionnaireAnswersGroupList.create;
        try
          selectTypes(profile, sub, t, answerGroups, selected);
          processDataType(profile, sub, element, element.Path+'._'+t.tagValue, t, group.required, selected);
        finally
          selected.free;
        end;
      end;
    finally
      types.free;
    end;
  end
  else
    // now we have to build the question panel for each different data type
    processDataType(profile, group, element, element.Path, element.Definition.Type_list[0], group.required, answerGroups);
end;

procedure TQuestionnaireBuilder.processDataType(profile : TFHIRProfile; group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; t : TFhirProfileStructureSnapshotElementDefinitionType; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
begin
  if (t.Code = 'code') then
    addCodeQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'string') or (t.Code = 'id') or (t.Code = 'oid') then
    addStringQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'uri') then
    addUriQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'boolean') then
    addBooleanQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'decimal') then
    addDecimalQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'dateTime') or (t.Code = 'date') then
    addDateTimeQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'instant') then
    addInstantQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'time') then
    addTimeQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'CodeableConcept') then
    addCodeableConceptQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'Period') then
    addPeriodQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'Ratio') then
    addRatioQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'HumanName') then
    addHumanNameQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'Address') then
    addAddressQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'Contact') then
    addContactQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'Identifier') then
    addIdentifierQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'integer') then
    addIntegerQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'Coding') then
    addCodingQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'Quantity') then
    addQuantityQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'ResourceReference') then
    addReferenceQuestions(group, element, path, required, t.profile, answerGroups)
  else if (t.Code = 'idref') then
    addIdRefQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'Duration') then
    addDurationQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'base64Binary') then
    addBinaryQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'Attachment') then
    addAttachmentQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'Age') then
    addAgeQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'Range') then
    addRangeQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'Schedule') then
    addScheduleQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'SampledData') then
    addSampledDataQuestions(group, element, path, required, answerGroups)
  else if (t.Code = 'Extension') then
    addExtensionQuestions(profile, group, element, path, required, t.profile, answerGroups)
  else
    raise Exception.create('Unhandled Data Type: '+t.Code+' on element '+element.Path);
end;

function isPrimitive(obj : TAdvObject) : boolean; overload;
begin
  result := (obj is TFHIRBoolean) or (obj is TFHIRInteger) or (obj is TFHIRDecimal) or (obj is TFHIRBase64Binary) or (obj is TFHIRInstant) or (obj is TFHIRString) or (obj is TFHIRUri) or
            (obj is TFHIRDate) or (obj is TFHIRDateTime) or (obj is TFHIRTime) or (obj is TFHIRCode) or (obj is TFHIROid) or (obj is TFHIRUuid) or (obj is TFHIRId) or (obj is TFhirReference);
end;

function TQuestionnaireBuilder.convertType(value : TFHIRObject; af : TFhirAnswerFormat; vs : TFHIRValueSet; path : String) : TFhirType;
begin
  result := nil;
  case af of
    // simple cases
    AnswerFormatBoolean: if value is TFhirBoolean then result := value.link as TFhirType;
    AnswerFormatDecimal: if value is TFhirDecimal then result := value.link as TFhirType;
    AnswerFormatInteger: if value is TFhirInteger then result := value.link as TFhirType;
    AnswerFormatDate: if value is TFhirDate then result := value.link as TFhirType;
    AnswerFormatDateTime: if value is TFhirDateTime then result := value.link as TFhirType;
    AnswerFormatInstant: if value is TFhirInstant then result := value.link as TFhirType;
    AnswerFormatTime: if value is TFhirTime then result := value.link as TFhirType;
    AnswerFormatString:
      if value is TFhirString then
        result := value.link as TFhirType
      else if value is TFhirUri then
        result := TFHIRString.Create(TFhirUri(value).value);

    AnswerFormatText: if value is TFhirString then result := value.link as TFhirType;
    AnswerFormatQuantity: if value is TFhirQuantity then result := value.link as TFhirType;

    // complex cases:
    // ? AnswerFormatAttachment: ...?
    AnswerFormatChoice, AnswerFormatOpenChoice :
      if value is TFhirCoding then
        result := value.link as TFhirType
      else if value is TFHIREnum then
      begin
        result := TFhirCoding.create;
        TFhirCoding(result).code := TFHIREnum(value).value;
        TFhirCoding(result).system := getSystemForCode(vs, TFHIREnum(value).value, path);
      end
      else if value is TFHIRString then
      begin
        result := TFhirCoding.create;
        TFhirCoding(result).code := TFHIRString(value).value;
        TFhirCoding(result).system := getSystemForCode(vs, TFHIRString(value).value, path);
      end;

    AnswerFormatReference:
      if value is TFhirReference then
        result := value.link as TFhirType
      else if value is TFHIRString then
      begin
        result := TFhirReference.Create;
        TFhirReference(result).reference := TFHIRString(value).value;
      end;
  end;

  if (result = nil) then
    raise Exception.Create('Unable to convert from "'+value.className+'" for Answer Format '+CODES_TFHIRAnswerFormat[af]+', path = '+path);
end;



constructor TQuestionnaireBuilder.create;
begin
  inherited;
  vsCache := TAdvStringMatch.create;
  FDependencies := TList<String>.create;
end;

function TQuestionnaireBuilder.addQuestion(group : TFHIRQuestionnaireGroup; af : TFhirAnswerFormat; path, id, name : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList; vs : TFHIRValueSet) : TFhirQuestionnaireGroupQuestion;
var
  ag : TFhirQuestionnaireAnswersGroup;
  aq : TFhirQuestionnaireAnswersGroupQuestion;
  children : TFHIRObjectList;
  child : TFHIRObject;
  vse : TFhirValueSet;
begin
  try
    result := group.questionList.Append;
    if vs <> nil then
    begin
      result.options := TFhirReference.Create;
      if (vs.expansion = nil) then
      begin
        result.options.reference := vs.identifier;
        result.options.addExtension(EXTENSION_FILTER_ONLY, TFhirBoolean.Create(true));
      end
      else
      begin
        if (vs.xmlId = '') then
        begin
          vse := vs.Clone;
          try
            vse.xmlId := nextId('vs');
            vsCache.Add(vse.identifier, vse.xmlId);
            vse.text := nil;
            vse.defineObject := nil;
            vse.composeObject := nil;
            vse.telecomList.Clear;
            vse.purposeObject := nil;
            vse.publisherObject := nil;
            vse.copyrightObject := nil;
            questionnaire.containedList.Add(vse.Link);
            result.options.reference := '#'+vse.xmlId;
          finally
            vse.Free;
          end;
        end
        else
          result.options.reference := '#'+vs.xmlId;
      end;
    end;

    result.LinkId := path+'.'+id;
    result.Text := name;
    result.Type_ := af;
    result.Required := required;
    result.Repeats := false;

    if (id.endsWith('/1')) then
      id := id.substring(0, id.length-2);

    if assigned(answerGroups) then
    begin
      for ag in answerGroups do
      begin
        children := TFHIRObjectList.Create;
        try
          aq := nil;

          if isPrimitive(ag.Tag) then
            children.add(ag.Tag.Link)
          else if ag.Tag is TFHIREnum then
            children.add(TFHIRString.create(TFHIREnum(ag.Tag).value))
          else
            TFHIRObject(ag.Tag).ListChildrenByName(id, children);

          for child in children do
            if child <> nil then
            begin
              if (aq = nil) then
              begin
                aq := ag.questionList.Append;
                aq.LinkId := result.linkId;
                aq.Text := result.text;
              end;
              aq.answerList.append.value := convertType(child, af, vs, result.linkId);
            end;
        finally
          children.Free;
        end;
      end;
    end;
  finally
    vs.Free;
  end;
end;

function UnCamelCase(s : String) : String;
var
  i, j : integer;
begin
  setLength(result, length(s) * 2);
  i := 1;
  j := 1;
  while (i <= length(s)) do
  begin
    if Upcase(s[i]) = s[i] then
    begin
      result[j] := ' ';
      inc(j);
    end;
    result[j] := s[i];
    inc(j);
    inc(i);
  end;
  setLength(result, j-1);
  result := Result.ToLower;
end;

procedure TQuestionnaireBuilder.addCodeQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
var
  ag : TFhirQuestionnaireAnswersGroup;
  vs : TFHIRValueSet;
begin
  group.setExtensionString(TYPE_EXTENSION, 'code');
  vs := resolveValueSet(nil, element.Definition.Binding);
  if vs = nil then
    vs := makeAnyValueSet;
  addQuestion(group, AnswerFormatChoice, path, 'value', unCamelCase(Tail(element.path)), required, answerGroups, vs);
  group.text := '';
  for ag in answerGroups do
    ag.text := '';
end;

// Primitives ------------------------------------------------------------------
procedure TQuestionnaireBuilder.addStringQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
var
  ag : TFhirQuestionnaireAnswersGroup;
begin
  group.setExtensionString(TYPE_EXTENSION, 'string');
  addQuestion(group, AnswerFormatString, path, 'value', group.text, required, answerGroups);
  group.text := '';
  for ag in answerGroups do
    ag.text := '';
end;

procedure TQuestionnaireBuilder.addTimeQuestions(group: TFHIRQuestionnaireGroup; element: TFhirProfileStructureSnapshotElement; path: String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
var
  ag : TFhirQuestionnaireAnswersGroup;
begin
  group.setExtensionString(TYPE_EXTENSION, 'time');
  addQuestion(group, AnswerFormatTime, path, 'value', group.text, required, answerGroups);
  group.text := '';
  for ag in answerGroups do
    ag.text := '';
end;

procedure TQuestionnaireBuilder.addUriQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
var
  ag : TFhirQuestionnaireAnswersGroup;
begin
  group.setExtensionString(TYPE_EXTENSION, 'uri');
  addQuestion(group, AnswerFormatString, path, 'value', group.text, required, answerGroups);
  group.text := '';
  for ag in answerGroups do
    ag.text := '';
end;


procedure TQuestionnaireBuilder.addBooleanQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
var
  ag : TFhirQuestionnaireAnswersGroup;
begin
  group.setExtensionString(TYPE_EXTENSION, 'boolean');
	addQuestion(group, AnswerFormatBoolean, path, 'value', group.text, required, answerGroups);
  group.text := '';
  for ag in answerGroups do
    ag.text := '';
end;

procedure TQuestionnaireBuilder.addDecimalQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
var
  ag : TFhirQuestionnaireAnswersGroup;
begin
  group.setExtensionString(TYPE_EXTENSION, 'decimal');
  addQuestion(group, AnswerFormatDecimal, path, 'value', group.text, required, answerGroups);
  group.text := '';
  for ag in answerGroups do
    ag.text := '';
end;

procedure TQuestionnaireBuilder.addIntegerQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
var
  ag : TFhirQuestionnaireAnswersGroup;
begin
  group.setExtensionString(TYPE_EXTENSION, 'integer');
  addQuestion(group, AnswerFormatInteger, path, 'value', group.text, required, answerGroups);
  group.text := '';
  for ag in answerGroups do
    ag.text := '';
end;

procedure TQuestionnaireBuilder.addDateTimeQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
var
  ag : TFhirQuestionnaireAnswersGroup;
begin
  group.setExtensionString(TYPE_EXTENSION, 'datetime');
  addQuestion(group, AnswerFormatDateTime, path, 'value', group.text, required, answerGroups);
  group.text := '';
  for ag in answerGroups do
    ag.text := '';
end;

procedure TQuestionnaireBuilder.addInstantQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
var
  ag : TFhirQuestionnaireAnswersGroup;
begin
  group.setExtensionString(TYPE_EXTENSION, 'instant');
  addQuestion(group, AnswerFormatInstant, path, 'value', group.text, required, answerGroups);
  group.text := '';
  for ag in answerGroups do
    ag.text := '';
end;

procedure TQuestionnaireBuilder.addBinaryQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
begin
  group.setExtensionString(TYPE_EXTENSION, 'binary');
  // ? Lloyd: how to support binary content
end;

// Complex Types ---------------------------------------------------------------

function AnswerTypeForBinding(binding : TFhirProfileStructureSnapshotElementDefinitionBinding) : TFhirAnswerFormat;
begin
  if (binding = nil) then
    result := AnswerFormatOpenChoice
  else if (binding.isExtensible) then
    result := AnswerFormatOpenChoice
  else
    result := AnswerFormatChoice;
end;

procedure TQuestionnaireBuilder.addCodingQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
var
  ag : TFhirQuestionnaireAnswersGroup;
begin
  group.setExtensionString(TYPE_EXTENSION, 'Coding');
  addQuestion(group, AnswerTypeForBinding(element.Definition.Binding), path, 'value', group.text, required, answerGroups, resolveValueSet(nil, element.Definition.Binding));
  group.text := '';
  for ag in answerGroups do
    ag.text := '';
end;

procedure TQuestionnaireBuilder.addCodeableConceptQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
begin
  group.setExtensionString(TYPE_EXTENSION, 'CodeableConcept');
  addQuestion(group, AnswerTypeForBinding(element.Definition.Binding), path, 'coding', 'code:', false, answerGroups, resolveValueSet(nil, element.Definition.Binding));
  addQuestion(group, AnswerFormatOpenChoice, path, 'coding/1', 'other codes:', false, answerGroups, makeAnyValueSet).Repeats := true;
	addQuestion(group, AnswerFormatString, path, 'text', 'text:', required, answerGroups);
end;

procedure TQuestionnaireBuilder.addPeriodQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
begin
  group.setExtensionString(TYPE_EXTENSION, 'Period');
	addQuestion(group, AnswerFormatDateTime, path, 'start', 'start:', false, answerGroups);
	addQuestion(group, AnswerFormatDateTime, path, 'end', 'end:', false, answerGroups);
end;

procedure TQuestionnaireBuilder.addRatioQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
begin
  group.setExtensionString(TYPE_EXTENSION, 'Ratio');
	addQuestion(group, AnswerFormatDecimal, path, 'numerator', 'numerator:', false, answerGroups);
	addQuestion(group, AnswerFormatDecimal, path, 'denominator', 'denominator:', false, answerGroups);
	addQuestion(group, AnswerFormatString, path, 'units', 'units:', required, answerGroups);
end;

procedure TQuestionnaireBuilder.addHumanNameQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
begin
  group.setExtensionString(TYPE_EXTENSION, 'Name');
	addQuestion(group, AnswerFormatString, path, 'text', 'text:', false, answerGroups);
	addQuestion(group, AnswerFormatString, path, 'family', 'family:', required, answerGroups).Repeats := true;
	addQuestion(group, AnswerFormatString, path, 'given', 'given:', false, answerGroups).Repeats := true;
end;

procedure TQuestionnaireBuilder.addAddressQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
begin
  group.setExtensionString(TYPE_EXTENSION, 'Address');
  addQuestion(group, AnswerFormatString, path, 'text', 'text:', false, answerGroups);
  addQuestion(group, AnswerFormatString, path, 'line', 'line:', false, answerGroups).Repeats := true;
  addQuestion(group, AnswerFormatString, path, 'city', 'city:', false, answerGroups);
  addQuestion(group, AnswerFormatString, path, 'state', 'state:', false, answerGroups);
  addQuestion(group, AnswerFormatString, path, 'zip', 'zip:', false, answerGroups);
  addQuestion(group, AnswerFormatString, path, 'country', 'country:', false, answerGroups);
	addQuestion(group, AnswerFormatChoice, path, 'use', 'use:', false, answerGroups, resolveValueSet('http://hl7.org/fhir/vs/address-use'));
end;

procedure TQuestionnaireBuilder.addContactQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
begin
  group.setExtensionString(TYPE_EXTENSION, 'Contact');
	addQuestion(group, AnswerFormatChoice, path, 'system', 'type:', false, answerGroups, resolveValueSet('http://hl7.org/fhir/vs/contact-system'));
	addQuestion(group, AnswerFormatString, path, 'value', 'value:', required, answerGroups);
	addQuestion(group, AnswerFormatChoice, path, 'use', 'use:', false, answerGroups, resolveValueSet('http://hl7.org/fhir/vs/contact-use'));
end;

procedure TQuestionnaireBuilder.addIdentifierQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
begin
  group.setExtensionString(TYPE_EXTENSION, 'Identifier');
	addQuestion(group, AnswerFormatString, path, 'label', 'label:', false, answerGroups);
	addQuestion(group, AnswerFormatString, path, 'system', 'system:', false, answerGroups);
	addQuestion(group, AnswerFormatString, path, 'value', 'value:', required, answerGroups);
end;

procedure TQuestionnaireBuilder.addQuantityQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
begin
  group.setExtensionString(TYPE_EXTENSION, 'Quantity');
 	addQuestion(group, AnswerFormatChoice, path, 'comparator', 'comp:', false, answerGroups, resolveValueSet('http://hl7.org/fhir/vs/quantity-comparator'));
 	addQuestion(group, AnswerFormatDecimal, path, 'value', 'value:', required, answerGroups);
  addQuestion(group, AnswerFormatString, path, 'units', 'units:', required, answerGroups);
  addQuestion(group, AnswerFormatString, path, 'code', 'coded units:', false, answerGroups);
  addQuestion(group, AnswerFormatString, path, 'system', 'units system:', false, answerGroups);
end;

procedure TQuestionnaireBuilder.addAgeQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
begin
  group.setExtensionString(TYPE_EXTENSION, 'Age');
 	addQuestion(group, AnswerFormatChoice, path, 'comparator', 'comp:', false, answerGroups, resolveValueSet('http://hl7.org/fhir/vs/quantity-comparator'));
 	addQuestion(group, AnswerFormatDecimal, path, 'value', 'value:', required, answerGroups);
  addQuestion(group, AnswerFormatChoice, path, 'units', 'units:', required, answerGroups, resolveValueSet('http://hl7.org/fhir/vs/duration-units'));
end;

procedure TQuestionnaireBuilder.addDurationQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
begin
  group.setExtensionString(TYPE_EXTENSION, 'Duration');
	addQuestion(group, AnswerFormatDecimal, path, 'value', 'value:', false, answerGroups);
	addQuestion(group, AnswerFormatString, path, 'units', 'units:', false, answerGroups);
end;

procedure TQuestionnaireBuilder.addAttachmentQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
begin
  group.setExtensionString(TYPE_EXTENSION, 'Attachment');
//  raise Exception.Create('addAttachmentQuestions not Done Yet');
end;

procedure TQuestionnaireBuilder.addRangeQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
begin
  group.setExtensionString(TYPE_EXTENSION, 'Range');
	addQuestion(group, AnswerFormatDecimal, path, 'low', 'low:', false, answerGroups);
	addQuestion(group, AnswerFormatDecimal, path, 'high', 'high:', false, answerGroups);
	addQuestion(group, AnswerFormatString, path, 'units', 'units:', required, answerGroups);
end;

procedure TQuestionnaireBuilder.addSampledDataQuestions(group: TFHIRQuestionnaireGroup; element: TFhirProfileStructureSnapshotElement; path: String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
begin
  group.setExtensionString(TYPE_EXTENSION, 'SampledData');
end;

procedure TQuestionnaireBuilder.addScheduleQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
begin
  group.setExtensionString(TYPE_EXTENSION, 'Schedule');
//  raise Exception.Create('addScheduleQuestions not Done Yet');
end;

// Special Types ---------------------------------------------------------------

procedure TQuestionnaireBuilder.addReferenceQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; profileURL : String; answerGroups : TFhirQuestionnaireAnswersGroupList);
var
  rn : String;
  ag : TFhirQuestionnaireAnswersGroup;
  q : TFhirQuestionnaireGroupQuestion;
begin
  group.setExtensionString(TYPE_EXTENSION, 'ResourceReference');

  q := addQuestion(group, AnswerFormatReference, path, 'value', group.text, required, answerGroups);
  group.text := '';
  if profileURL.startsWith('http://hl7.org/fhir/Profile/') then
    rn := profileURL.Substring(28)
  else
    rn := 'Any';
  if (rn = 'Any') then
    q.setExtensionString(TYPE_REFERENCE, '/_search?subject=$subj&patient=$subj&encounter=$encounter')
  else
    q.setExtensionString(TYPE_REFERENCE, '/'+rn+'?subject=$subj&patient=$subj&encounter=$encounter');
  for ag in answerGroups do
    ag.text := '';
end;

procedure TQuestionnaireBuilder.addIdRefQuestions(group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; answerGroups : TFhirQuestionnaireAnswersGroupList);
begin
//  raise Exception.Create('not Done Yet');
end;

procedure TQuestionnaireBuilder.addExtensionQuestions(profile : TFHIRProfile; group : TFHIRQuestionnaireGroup; element : TFhirProfileStructureSnapshotElement; path : String; required : boolean; profileURL : String; answerGroups : TFhirQuestionnaireAnswersGroupList);
var
  extension : TFhirProfileExtensionDefn;
begin
  // is this a  profiled extension, then we add it
  if (profileURL <> '') and profiles.getExtensionDefn(profile, profileURL, profile, extension) then
  begin
    if answerGroups.count > 0 then
      raise Exception.Create('Debug this');
    if extension.elementList.Count = 1 then
      buildQuestion(group, profile, nil, extension.elementList[0], path+'.extension['+profileURL+']', answerGroups)
    else
      raise Exception.Create('Not done yet');
  end;
end;

end.


