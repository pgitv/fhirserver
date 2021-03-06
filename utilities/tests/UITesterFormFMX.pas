unit UITesterFormFMX;

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

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls, FMX.Objects,
  FMX.Controls.Presentation,
  Generics.Collections, Math,
  FHIR.Ui.Graph, GraphTester;

type
  TForm10 = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
  private
    FGraph : TFGraph; // TFGraph;
    function GetFuncValue(sender : TObject; x : Double) : Double;
  public
  end;

var
  Form10: TForm10;

implementation

{$R *.fmx}

procedure TForm10.Button1Click(Sender: TObject);
begin
  TFGraphTester.addMarks(FGraph);
end;

procedure TForm10.Button2Click(Sender: TObject);
begin
  TFGraphTester.addSeries(FGraph);
end;

procedure TForm10.Button3Click(Sender: TObject);
begin
  (FGraph.Series.last.Data as TRandomData).addMore;
end;

procedure TForm10.Button4Click(Sender: TObject);
begin
  FGraph.Functions.Add(FGraph.CreateFunction(GetFuncValue));
end;

procedure TForm10.Button5Click(Sender: TObject);
begin
  TFGraphTester.addBand(FGraph);
end;

procedure TForm10.FormCreate(Sender: TObject);
begin
  FGraph := TFGraph.create(self);
  AddObject(FGraph);
  TFGraphTester.configure(FGraph);
  FGraph.Repaint;
end;


function TForm10.GetFuncValue(sender: TObject; x: Double): Double;
begin
  result := 4000 / abs(500 - x);
end;


end.
