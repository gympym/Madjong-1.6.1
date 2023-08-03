uses graphabc,Events,ABCObjects, System.Media;

type button = record  
  picture_now: PictureABC;
  name :string; 
end;

type majong_cost = record   
  name: string;
  layer: integer; 
  type_mc: ^integer; 
  picture_now: PictureABC;
  state: ^integer;  // 1 - act , 2 - pass , 3 - sel
end;

type mc_save = record   
  name: string;
  layer: integer; 
  type_mc: integer; 
  x,y :integer;
  state: integer; 
end;

type majong_tree = record  // шаблон mt
  branch_up: List<integer> := new List<integer>;  
  mc_now : integer;
  branch_down: List<integer> := new List<integer>;
end;

type select_mj = record    // шаблон хранилищя нажатий на mc
  first_select: boolean;
  second_select: boolean;
  first_mc_name: string;
  second_select_name: string;
end;

type map = record 
  path:string;
  number :integer;
end;

type tree_mc = List<majong_tree>;
type majongs = List<majong_cost>; 

var world :  list<string> := new List<string>;

var click_on_button:= new SoundPlayer();
var click_on_mc:= new SoundPlayer();

var maps := new List<map>;

var username := System.Security.Principal.WindowsIdentity.GetCurrent.Name;
var file_ways: text;
var file_score: text;
var index_map:integer:=-1;
 
var majong_all:= new majongs;  
var majong_all_save := new List<mc_save>; 
var menu := new List<button>; 
var tree := new tree_mc; 
var stap_all := new  List<string>; 

var select: select_mj; 
  
var count_mc := 0; 
var path := ''; 
var now_map_type := -1; 

var local_scale :integer := 0;

var difficult:= 15; 
const max_layer  = 3;
var type_count := 36;
//функции///////////////////////////////////////////////////
procedure set_type_count(value_mc:integer);
begin
  if (value_mc < 1) or (value_mc> 36) then begin
    type_count := 1;
  end
  else begin
    type_count:= value_mc ;
  end;
end;
type click = (start_menu,select_menu,complexity,none);
var cl:click := start_menu;

procedure get_user_path();
var i :integer := 1;
var s :string;
var t :boolean ;
begin
  while i <= username.Length do begin
    if (t) then s+=username[i];
    if (username[i] = '\') then t :=true;
    i+=1;
  end;
  path := 'C:\Users\' + s + '\Desktop\маджонг'; 
end;

function Creat_mc_name():string; // создаем уникальное имя mc
begin
  inc(count_mc); 
  Creat_mc_name := count_mc.ToString() + 'AUF11' ;
end;

function Get_index_mc(x:majong_cost; mc_all:majongs): integer;  // индекс mc 
var i :integer := 0;
begin
  foreach var mc in mc_all do begin
    inc(i);
    if (x.name = mc.name) then begin Get_index_mc:= i -1; end
  end;
end;

function Get_index_name(x:string; mc_all:majongs): integer;  // индекс mc
var i :integer := 0;
begin
  foreach var mc in mc_all do begin
    inc(i);
    if (x = mc.name) then begin Get_index_name:= i -1; end
  end;
end;

function Get_index_name_for_copy(x:string):integer;
var i :integer := 0;
begin
  foreach var mc in majong_all_save do begin
    inc(i);
    if (x = mc.name) then begin Get_index_name_for_copy:= i -1; end
  end;
end;

function Get_path_for_type(type_mc: integer; state:string):string;        
begin
  case state of   
    'passive': Get_path_for_type := ( path+'\sprite\mj_' +  type_mc + '_2.png');
    'activate': Get_path_for_type  := ( path+'\sprite\mj_' +  type_mc + '_1.png');
    'select': Get_path_for_type := ( path+'\sprite\mj_' +  type_mc + '_3.png');
  end;
end;

procedure Creat_mc(x,y:integer; type_mc:integer:=1 ; layer:integer := 1 ; index:integer := 0  ; name:string := '');  // создание mc
var mc: majong_cost;
begin
  if name = '' then begin  mc.name := Creat_mc_name() end
  else begin mc.name := name end;
  mc.layer := layer;
  mc.picture_now := PictureABC.Create(x,y, Get_path_for_type(type_mc,'activate'));
  mc.picture_now.dx := x; 
  mc.picture_now.dy := y;
  new (mc.type_mc);
  mc.type_mc^ := type_mc;
  new(mc.state);
  mc.state^ := 1;
  if index = 0 then begin majong_all.Add(mc) end
  else begin majong_all.Insert(index,mc) end;
end;

procedure Save_stap(stap:string); ///////////////////////////
begin
  stap_all.Add(stap);
end;

function slice(str:string): List<integer> ;
var indexs := new List<integer> ;
var a,b : integer;
begin
  foreach var s in str.Split('.') do begin
    val(s,a,b);
    indexs.Add(a);
  end;
  slice:=indexs;
end;

procedure otkat(index:integer);
begin
  Creat_mc(majong_all_save[index].x,majong_all_save[index].y , majong_all_save[index].type_mc , majong_all_save[index].layer, 0,majong_all_save[index].name);
end;

procedure Get_save_world();
var mc_copy : mc_save;
begin
  foreach var mc in majong_all do begin
    mc_copy.layer := mc.layer;
    mc_copy.name := mc.name;
    mc_copy.x := mc.picture_now.dx;
    mc_copy.y := mc.picture_now.dy;
    mc_copy.type_mc := mc.type_mc^;
    majong_all_save.Add(mc_copy);
  end;
end;

procedure Creat_mc_with_type(x,y:integer; type_mc:integer:=1 ; layer:integer := 1 );  // cоздание mc по типу косточки 
begin
  if type_mc <= type_count then begin
    Creat_mc(x,y ,type_mc, layer);
  end
  else begin
     writeln('попытака создать несуществующий тип');
  end;
end; 

procedure Creat_mc_with_orientation(vector:string; main_mc_index:integer; modificate:real := 1;  type_mc:integer:=1 ; layer:integer := 1 );    // cоздание mc относительно другой mc (справа от, слево от) 
var f :integer := round(2*modificate);
var main_mc:majong_cost;
begin
  if main_mc_index < 0 then begin
    main_mc:= majong_all[majong_all.Count-1]
  end
  else begin
    main_mc:= majong_all[main_mc_index];
  end;
  case vector of 
    'r':Creat_mc_with_type  (main_mc.picture_now.dx + round(main_mc.picture_now.Width * modificate) +f, main_mc.picture_now.dy, type_mc, layer );
    'rd':Creat_mc_with_type  (main_mc.picture_now.dx + round(main_mc.picture_now.Width * modificate) +f, main_mc.picture_now.dy + round(main_mc.picture_now.Height * modificate)+f, type_mc, layer );
    'dr':Creat_mc_with_type  (main_mc.picture_now.dx + round(main_mc.picture_now.Width * modificate) +f, main_mc.picture_now.dy + round(main_mc.picture_now.Height * modificate)+f, type_mc, layer );
    'l': Creat_mc_with_type (main_mc.picture_now.dx - round(main_mc.picture_now.Width * modificate) -f , main_mc.picture_now.dy,  type_mc, layer );
    'd':Creat_mc_with_type  (main_mc.picture_now.dx ,main_mc.picture_now.dy + round(main_mc.picture_now.Height * modificate)+f , type_mc, layer);
    'u': Creat_mc_with_type (main_mc.picture_now.dx ,main_mc.picture_now.dy - round(main_mc.picture_now.Height * modificate)-f,  type_mc, layer);
    'ur': Creat_mc_with_type (main_mc.picture_now.dx + round(main_mc.picture_now.Width * modificate) +f,main_mc.picture_now.dy - round(main_mc.picture_now.Height * modificate)-f,  type_mc, layer);
    'ru': Creat_mc_with_type (main_mc.picture_now.dx + round(main_mc.picture_now.Width * modificate) +f,main_mc.picture_now.dy - round(main_mc.picture_now.Height * modificate)-f,  type_mc, layer);
    'dl':Creat_mc_with_type  (main_mc.picture_now.dx - round(main_mc.picture_now.Width * modificate) -f ,main_mc.picture_now.dy + round(main_mc.picture_now.Height * modificate)+f , type_mc, layer);
    'ld':Creat_mc_with_type  (main_mc.picture_now.dx - round(main_mc.picture_now.Width * modificate) -f ,main_mc.picture_now.dy + round(main_mc.picture_now.Height * modificate)+f , type_mc, layer);
    'ul': Creat_mc_with_type (main_mc.picture_now.dx - round(main_mc.picture_now.Width * modificate) -f ,main_mc.picture_now.dy - round(main_mc.picture_now.Height * modificate)-f,  type_mc, layer);
    'lu': Creat_mc_with_type (main_mc.picture_now.dx - round(main_mc.picture_now.Width * modificate) -f ,main_mc.picture_now.dy - round(main_mc.picture_now.Height * modificate)-f,  type_mc, layer);
  end;
end;

function Get_File_end(file_name:string):integer;
var s: string;
var count :integer:=1;
begin
   assign(file_ways,path + '\world_1.txt');
   Reset(file_ways);
   while(true) do begin
     writeln(file_ways,s);
      if (s.Split).Count <> 0 then begin
         writeln(file_ways,s);
         inc(count);
      end;
   end;
   Get_File_end:= count;
   close(file_ways);
end;

procedure Save_creat_stap(direction:string ;main_mc_index:integer ; modificate:real ; type_mc : integer ; layer:integer);
begin
    world.Add(direction + ' ' + main_mc_index.ToString() + ' ' +modificate.ToString() + ' '+type_mc+ ' '  + layer.ToString());
end;
function get_path_for_number(index:integer) :string;
begin
  foreach var v in maps do begin
    if (v.number = index ) then begin
      get_path_for_number := v.path;
      break;
    end;
  end;
end;

procedure Save_world(number:integer);
begin
  Assign(file_ways,path + get_path_for_number(number));
  Rewrite(file_ways);
  foreach var v in world do begin
    writeln(file_ways,v);
  end;
  close(file_ways);
end;

procedure Get_worlds();
var count :integer;
var m : map;
begin
  Assign(file_ways,path +'\World\World_registry.txt');
  Reset(file_ways);
  while true do begin
   readln(file_ways , m.path);
   if(m.path.Length <> 0 ) then begin
     inc(count);
     m.number := count;
     maps.Add(m);
     end
   else begin
      break;
   end;
  end;
end;

procedure Destroy_mс(index:integer);  // главный метод удаления mc
begin
   if ( majong_all[index].picture_now <> nil) then begin
      majong_all[index].picture_now.Destroy();
   end;
   majong_all.RemoveAt(index);
end;

procedure Destroy_select_mc();  // метод отчистик выбора mc
begin
    if select.first_select = true then Destroy_mс(Get_index_name(select.first_mc_name,majong_all));
    if select.second_select = true then Destroy_mс(Get_index_name(select.second_select_name,majong_all));
    select.first_select := false;
    select.second_select := false;
end;

procedure sprite_swap(index : integer; sprite_type :string  ); // изменяет состояния спрайта
begin
  case sprite_type of
    'select': begin
      majong_all[index].picture_now.ChangePicture(Get_path_for_type(majong_all[index].type_mc^, 'select'));
      majong_all[index].state^ := 3; 
    end;
    'activate': begin
      majong_all[index].picture_now.ChangePicture(Get_path_for_type(majong_all[index].type_mc^, 'activate'));
      majong_all[index].state^ := 1;
    end;
    'passive': begin
      majong_all[index].picture_now.ChangePicture(Get_path_for_type(majong_all[index].type_mc^, 'passive'));
      majong_all[index].state^ := 2;
    end;
  end;
end;

procedure Swap_type(index:integer; type_mc:integer);
begin
  majong_all[index].type_mc^ := type_mc;
end;

function Get_mc_in_layer( layer:integer): List<integer>;
var indexs := new List<integer>;
begin
foreach var mc in majong_all do begin
    if mc.layer = layer then begin
      indexs.Add(Get_index_mc(mc,majong_all));
    end;
  end;
  Get_mc_in_layer := indexs;
end;

function mc_in_mc(   mc:majong_cost; layer:integer := 1) : List<integer>;
var rr:= new List<integer>;
begin
   foreach var ss in Get_mc_in_layer(layer) do begin
     if  ((majong_all[ss].picture_now.dx >= mc.picture_now.dx  ) and ( majong_all[ss].picture_now.dx <= (mc.picture_now.dx + mc.picture_now.Width)    )  and  (majong_all[ss].picture_now.dy >= mc.picture_now.dy   ) and (majong_all[ss].picture_now.dy <= (mc.picture_now.dy +mc.picture_now.Height )  )) or
          (((majong_all[ss].picture_now.dx + majong_all[ss].picture_now.Width) >= mc.picture_now.dx   ) and ( (majong_all[ss].picture_now.dx + majong_all[ss].picture_now.Width) <= (mc.picture_now.dx + mc.picture_now.Width)  )  and  (majong_all[ss].picture_now.dy > mc.picture_now.dy  ) and (majong_all[ss].picture_now.dy <= (mc.picture_now.dy +mc.picture_now.Height )  )) or
         ((majong_all[ss].picture_now.dx > mc.picture_now.dx ) and ( majong_all[ss].picture_now.dx <= (mc.picture_now.dx + mc.picture_now.Width)   )  and  ( (majong_all[ss].picture_now.dy +majong_all[ss].picture_now.Height) >= mc.picture_now.dy  ) and ((majong_all[ss].picture_now.dy +majong_all[ss].picture_now.Height) <= (mc.picture_now.dy +mc.picture_now.Height )  )) or
          (((majong_all[ss].picture_now.dx + majong_all[ss].picture_now.Width) >= mc.picture_now.dx  ) and ( (majong_all[ss].picture_now.dx + majong_all[ss].picture_now.Width) <= (mc.picture_now.dx + mc.picture_now.Width)  )  and  ((majong_all[ss].picture_now.dy +majong_all[ss].picture_now.Height) >= mc.picture_now.dy  ) and ((majong_all[ss].picture_now.dy +majong_all[ss].picture_now.Height) <= (mc.picture_now.dy +mc.picture_now.Height )  )) 
        then begin
          if majong_all[ss].name <> mc.name then rr.Add (ss);
        end;
  end;
  mc_in_mc := rr;
end;

function mc_in_mc2(   mc:majong_cost; layer:integer := 1) : boolean;
var b :boolean := false;
begin
   foreach var ss in Get_mc_in_layer(layer) do begin
     if  ((majong_all[ss].picture_now.dx >= mc.picture_now.dx  ) and ( majong_all[ss].picture_now.dx <= (mc.picture_now.dx + mc.picture_now.Width)    )  and  (majong_all[ss].picture_now.dy >= mc.picture_now.dy   ) and (majong_all[ss].picture_now.dy <= (mc.picture_now.dy +mc.picture_now.Height )  )) or
          (((majong_all[ss].picture_now.dx + majong_all[ss].picture_now.Width) >= mc.picture_now.dx   ) and ( (majong_all[ss].picture_now.dx + majong_all[ss].picture_now.Width) <= (mc.picture_now.dx + mc.picture_now.Width)  )  and  (majong_all[ss].picture_now.dy > mc.picture_now.dy  ) and (majong_all[ss].picture_now.dy <= (mc.picture_now.dy +mc.picture_now.Height )  )) or
         ((majong_all[ss].picture_now.dx > mc.picture_now.dx ) and ( majong_all[ss].picture_now.dx <= (mc.picture_now.dx + mc.picture_now.Width)   )  and  ( (majong_all[ss].picture_now.dy +majong_all[ss].picture_now.Height) >= mc.picture_now.dy  ) and ((majong_all[ss].picture_now.dy +majong_all[ss].picture_now.Height) <= (mc.picture_now.dy +mc.picture_now.Height )  )) or
          (((majong_all[ss].picture_now.dx + majong_all[ss].picture_now.Width) >= mc.picture_now.dx  ) and ( (majong_all[ss].picture_now.dx + majong_all[ss].picture_now.Width) <= (mc.picture_now.dx + mc.picture_now.Width)  )  and  ((majong_all[ss].picture_now.dy +majong_all[ss].picture_now.Height) >= mc.picture_now.dy  ) and ((majong_all[ss].picture_now.dy +majong_all[ss].picture_now.Height) <= (mc.picture_now.dy +mc.picture_now.Height )  )) 
        then begin
          if majong_all[ss].name <> mc.name then 
          begin
            b := true;
            break;
          end;
        end;

  end;
  mc_in_mc2 := b;
end;

procedure creat_mc_branch(index:integer);
var mct:majong_tree;
var layer : integer ;
begin
  layer := majong_all[index].layer;
  mct.mc_now:=index;
  mct.branch_up := mc_in_mc(majong_all[index],layer + 1);
  mct.branch_down := mc_in_mc(majong_all[index],layer - 1);
  tree.Add(mct);
end;

procedure Creat_tree();
begin
  tree.Clear();
  foreach var mc in majong_all do begin
    creat_mc_branch(Get_index_mc(mc,majong_all));
  end;
end;

procedure get_peth_for_sount();
begin
  click_on_button.SoundLocation:= path+ '\click_button.wav'; 
  click_on_mc.SoundLocation := path+'\click_mc.wav';
end;

function Copy_arrray(array_1 : tree_mc):tree_mc;  // создаёт дубликат дерева 
var array_clone:tree_mc := new tree_mc;
begin
  foreach var tr in array_1 do begin
    var t: majong_tree; 
    t.mc_now := tr.mc_now;
    foreach var w in tr.branch_down do begin
      t.branch_down.Add(w);
    end;
    foreach var w2 in tr.branch_up do begin
      t.branch_up.Add(w2);
    end;
    array_clone.add(t);
  end;
  Copy_arrray :=  array_clone;
end;

function Get_score():integer;
var s:string;
var a,b :integer;
begin
  Assign(file_score,  path +'\Save_statistic.txt');
  file_score.Reset();
  Readln(file_score,s);
  if s <> '' then begin
     val(s,a,b);
    Get_score:=a;
  end
  else begin
    Get_score:=0;
  end;
  file_score.Close();
end;

function get_way(index:integer):string;
var s,s2 :string;
var a,b:integer;
begin
  val(s2,a,b);
  Reset(file_ways);
  Readln(file_ways,s2); 
  if (index = 0 ) then  get_way:=s2
  else begin
    if (s2 <>  '' ) then begin
      val(s2,a,b);
      if (index  <= a) then begin
        for var x:integer:=2  to index + 1  do begin
          Readln(file_ways,s);
        end;
        get_way:=s;
      end;
    end;
  end;
  close(file_ways);
end;

procedure Destroy_braunch(tree_now: tree_mc ; index:integer);
var mt:majong_tree;
begin
  foreach var tr in tree_now do begin
    tr.branch_down.Remove(index);
    tr.branch_up.Remove(index);
    if tr.mc_now = index then mt:= tr;
  end;
  tree_now.Remove(mt);
end;

function random_tree(tree_now: tree_mc):integer;
begin
  random_tree := random(1,tree_now.Count-1);
end;

function Move_on_tree(tree_now: tree_mc; now_mt:integer; ways: List<string>; way:string): integer;
begin
  if ways.Count < 100 then begin 
    if tree_now.Count <> 0 then begin
    if now_mt = -1 then begin
    foreach var tr in tree_now do begin
      var tre: majong_tree := tree_now[random_tree(tree_now)];
      if tre.branch_up.Count = 0 then begin
        var way2:= way + tre.mc_now.ToString() + '.';
        var tree_clone := Copy_arrray(tree_now);
        Move_on_tree(tree_clone,tre.mc_now,ways,way2); 
      end;
    end;
  end
  else begin
    foreach var tr in tree_now do begin
      if ( majong_all[tree[now_mt].mc_now].type_mc^ = majong_all[tr.mc_now].type_mc^) and (majong_all[tree[now_mt].mc_now].name <> majong_all[tr.mc_now].name) and (tr.branch_up.Count = 0 ) then begin
        var tree_reserv :tree_mc:= Copy_arrray(tree_now);
        var way2 := way + tr.mc_now.ToString() + '.' ;
        Destroy_braunch(tree_reserv,now_mt);
        Destroy_braunch(tree_reserv,tr.mc_now);
        Move_on_tree += Move_on_tree(tree_reserv, -1,ways,way2); 
      end;
    end;
  end;
  end
  else begin
    ways.Add(way);
  end; 
  end
  else begin
    
  end;
end;

procedure Creat_button(x,y:integer; name, path:string);
var but:button;
begin
  but.name:= name;
  but.picture_now := PictureABC.Create(x,y, path);
  but.picture_now.dx := x;
  but.picture_now.dy := y;
   menu.Add(but);
end;

procedure Creat_map(number,x,y,type_mc,layer:integer );
var s:string;
var s_split : array of string ;
begin
  Creat_mc_with_type(x,y, type_mc,layer);
  Assign(file_ways,path +get_path_for_number(number) );
  Reset(file_ways);
  while true do begin
      Readln(file_ways,s);
      if ((s.Length = 0) or (s = '') ) then break;
      s_split := s.Split;
      Creat_mc_with_orientation(s_split[0],StrToInt(s_split[1]), StrToFloat(s_split[2]),StrToInt(s_split[3]),StrToInt(s_split[4]));
  end;
end;

procedure Creat_menu();
begin
  Creat_button(0,0,'fon', path +'\Безымянный.jpg');
  Creat_button(660,200, 'start',  path+ '\Start.png');
  Creat_button(menu[menu.Count-1].picture_now.dx, menu[menu.Count-1].picture_now.dy + menu[menu.Count-1].picture_now.Height + 20, 'Разработчики',  path+ '\Разработчики.png');
  TextOut(0,0,'Made with PascalABC.NET     Ваш счёт за всё время: ' + Get_score().ToString());
end;
//////////////////////////*?//////////////////////////////////*?/////////////////////////////////*?/////////////
function Find_way():List<string>;
var tree_clone: tree_mc := new tree_mc;
var ways: List<string> = new List<string>;
begin
  tree_clone := Copy_arrray(tree);  
  Move_on_tree(tree_clone,-1,ways,'');
  Find_way:= ways;
end;
//////////////////////////*?//////////////////////////////////*?/////////////////////////////////*?/////////////
procedure save_ways(ways : List<string>);
begin
  assign(file_ways,path + '\ways.txt');
  Rewrite (file_ways);
  Writeln(file_ways,ways.Count);
  foreach var way in ways do begin
    Writeln(file_ways,way);
  end;
  close(file_ways);
end;
//////////////////////////*?//////////////////////////////////*?/////////////////////////////////*?/////////////
procedure Random_generation_map();
begin
  var a,b,c:integer;
  var ss :integer;
  var ways : List<string> := find_way();
  save_ways(ways);
  var s : array of string :=  get_way(67).Split('.');
  var i :integer := 0;
  while i < s.Length-1 do begin
    val(s[i] ,a,c);
    val(s[i+1] ,b,c);
    ss := random(1,type_count);
    Swap_type(a, ss);
    Swap_type(b, ss);
    i += 2; 
  end;
end;

procedure Creat_select_menu(x,y:integer);
begin
   Creat_button(0,0,'fon', path +'\Безымянный.jpg');
   Creat_button(x,y,'map_0' , path + '\плоская_карта.png');
   for var w: integer := 1 to  maps.Count do begin
      Creat_button(menu[menu.Count-1].picture_now.dx + menu[menu.Count-1].picture_now.Width + 20,y,'map_'  + w.ToString(), path + '\карта_'+w.ToString() +'.png');
   end;
  TextOut(0,0,'Made with PascalABC.NET     Ваш счёт за всё время: ' + Get_score().ToString());
end;

procedure f(m1,m2: List<integer>);
var m3:= new List<integer>;
begin
  foreach var x1 in m1 do begin
    foreach var x2 in m2 do begin
      if x1 = x2 then begin
        m3.add(x1);
      end;
    end;
  end;
  foreach var x3 in m3 do begin
    m1.Remove(x3);
  end;
end;

procedure Update_mc3();
begin
   for var b3: integer:= 1 to max_layer-1 do begin
      foreach var b in Get_mc_in_layer(b3) do begin   // весь элементы анализируемого слоя 
         
          if not(mc_in_mc2 (majong_all[b] ,b3 +1) or mc_in_mc2 (majong_all[b] ,3)) then begin sprite_swap(b,'activate') end
          else begin  
            sprite_swap(b,'passive') 
          end;
       end;
   end;
end;

procedure Update_mc();
begin
  foreach var mc in majong_all do begin
    sprite_swap(Get_index_mc(mc,majong_all),'activate');
  end;
   for var b3: integer:= 2 to max_layer do begin
      foreach var b in Get_mc_in_layer(b3) do begin   // весь элементы анализируемого слоя 
        for var i := 1 to b3-1 do begin
          foreach var b2 in mc_in_mc(majong_all[b],i) do  sprite_swap(b2,'passive');  // все элементы которые под анализируемым слоям 
        end;
    end;
   end;
end;

procedure Update_mc2();
begin
   for var b3: integer:= 1 to max_layer-1 do begin
      foreach var b in Get_mc_in_layer(b3) do begin   // весь элементы анализируемого слоя 
         
          if not(mc_in_mc2 (majong_all[b] ,b3 +1) or mc_in_mc2 (majong_all[b] ,3)) then sprite_swap(b,'activate');
       end;
   end;
end;

procedure Index_update(); // показывает индексы mc (для тестов)  
begin
  foreach var mc in majong_all do begin
    TextOut(mc.picture_now.dx + 5, mc.picture_now.dy + 5, Get_index_mc(mc,majong_all));
  end;
end;

function Check_have_stap():boolean;
var m:= new List<integer>;
var b :boolean;
begin
  Creat_tree();
  foreach var mc in tree do begin
    if mc.branch_up.Count = 0 then  m.Add(mc.mc_now);
  end;
  for var x:= 0 to m.Count -1 do begin
     for var y:= 0 to m.Count -1 do begin
        if (majong_all[m[x]].type_mc^ = majong_all[m[y]].type_mc^) and (x<>y)  then begin
           b := true ;
        end;
     end;
  end;
  Check_have_stap := b;
end;
//////////////////////////*?//////////////////////////////////*?/
procedure Destroy_menu();  // уничтожает все элементы menu
begin
  foreach var but:button in menu do begin
    but.picture_now.Destroy();
  end;
  menu.Clear();
end;
//////////////////////////*?//////////////////////////////////*?//
procedure Destroy_mc();  // уничтожает игровое поля 
begin
  foreach var mc in majong_all do begin
    mc.picture_now.Destroy();
  end;
  majong_all.Clear();
  tree.Clear();
end;
//////////////////////////*?//////////////////////////////////*?//
procedure Creat_shablon_map();
begin
  //Creat_mc_with_orientation('r',0,1,1,1) =   Save_creat_stap('r',0,1,1,1);
   
   Save_creat_stap('r',-1,1,1,1);
   Save_creat_stap('r',-1,1,1,1);
   //Save_creat_stap('r',0,1/2,1,2);
   
   Save_creat_stap('d',1,1,1,1);
   Save_creat_stap('d',0,1,1,1);
   Save_creat_stap('l',-1,1,1,1);
   Save_creat_stap('d',-1,1,1,1);
   Save_creat_stap('l',-1,1,1,1);//jmj
   Save_creat_stap('d',6,1,1,1);
   Save_creat_stap('r',-1,1,1,1);
   Save_creat_stap('u',-1,1,1,1);//10
   Save_creat_stap('r',-1,1,1,1);
   Save_creat_stap('d',-1,1,1,1);
   Save_creat_stap('l',-1,1,1,1);
   Save_creat_stap('d',13,1,1,1);
   Save_creat_stap('r',-1,1,1,1);
   //Save_creat_stap('r',-2,1,1,1);
   //Save_creat_stap('u',-2,1,1,1);
   
  
   Save_world(3); // в конце
  //Save_world(введи индекс сохранения); // в конце
end;
//////////////////////////*?//////////////////////////////////*?/
procedure Creat_zero_map();
begin
  index_map := -2;
  var i2:= 0;
  Creat_mc_with_type(150,150, 1,1);
  Creat_mc_with_orientation('r',0,1,1,1);
  for var x := 1 to 13 do begin
    Creat_mc_with_orientation('r',majong_all.Count-1,1,1,1);
  end;
  for var x:= 1 to 5 do begin
    Creat_mc_with_orientation('d',0,1*x,1,1);
     for var i:=1  to 14 do begin
       Creat_mc_with_orientation('r',majong_all.Count-1,1,1,1);
    end;
  end;
end;
//////////////////////////*?//////////////////////////////////*?//
procedure Creat_map(map_type: integer);  // создание карты 
begin
  Creat_button(0,0,'fon', path +'\Безымянный.jpg');
  if (map_type > 0) and (map_type <= maps.Count) then begin Creat_map(map_type,200,200,1,1) end
  else begin Creat_zero_map() end;
   //ClearWindow();
   stap_all.Clear();
   local_scale:= 0;
     
   Creat_button(10,10,'menu', path + '\Menu.png' );
   Creat_button(menu[menu.Count-1].picture_now.dx+ 20 + menu[menu.Count-1].picture_now.Width,menu[menu.Count-1].picture_now.dy,'back', path + '\Back.png' );
   Creat_tree();
   TextOut(menu[menu.Count-1].picture_now.dx +20+ menu[menu.Count-1].picture_now.Width,menu[menu.Count-1].picture_now.dy,'счёт:                       ');
   TextOut(menu[menu.Count-1].picture_now.dx +20+ menu[menu.Count-1].picture_now.Width,menu[menu.Count-1].picture_now.dy,'счёт: '+local_scale.ToString() + ' осталось косточек: ' + majong_all.Count.ToString());
   Update_mc();
   Random_generation_map();
   Update_mc();
   TextOut(5,100, 'Существуют ходы                           ');
   Get_save_world();
end;
//////////////////////////*?//////////////////////////////////*?//
procedure Set_score(i:integer);
var s:string;
var x :integer;
begin
  x := Get_score() + i;
  Assign(file_score,  path +'\Save_statistic.txt');
  file_score.Rewrite();
  writeln(file_score,x);
  file_score.Close();
end;
//////////////////////////*?//////////////////////////////////*?//
procedure Stap_back();
begin
  if stap_all.Count-1 >= 0 then begin
    otkat(slice(stap_all[stap_all.Count-1])[0]);
    otkat(slice(stap_all[stap_all.Count-1])[1]);
    stap_all.RemoveAt(stap_all.Count-1);
  end
  else begin
    stap_all.Clear();
  end;
end;
procedure Set_complexity(x:integer);
begin
  difficult :=x ;
  cl := start_menu;
end;
procedure Creat_complexity_menu();
begin
  Creat_button(0,0,'fon', path +'\Безымянный.jpg');
  Creat_button(577,257,'легкий',  path + '\легкий.png');
  Creat_button(menu[menu.Count-1].picture_now.dx +20+ menu[menu.Count-1].picture_now.Width,menu[menu.Count-1].picture_now.dy,'средний',  path +'\средний.png');
  Creat_button(menu[menu.Count-1].picture_now.dx +20+ menu[menu.Count-1].picture_now.Width,menu[menu.Count-1].picture_now.dy,'сложный',  path +'\сложный.png');
end;
//////////////////////////*?//////////////////////////////////*?//
procedure Mouse_click_UI(x,y,mb: integer);
begin
   // кнопки меню 
 //var destroy_menu_b:boolean := false;
 var creat_zero_map:= false;
 cl := complexity;
 foreach var button in menu do begin
   if (x>button.picture_now.dx) and (x< (button.picture_now.dx + button.picture_now.Width)) and    // если курсор попал по какому либо mc
     (y>button.picture_now.dy) and (y< (button.picture_now.dy + button.picture_now.Height))   then begin
        if (button.name <> 'fon') then begin click_on_button.Play(); end
        else begin cl := none; 
        end;
        case button.name  of 
          'start':  cl := select_menu; 
          'menu': cl :=start_menu;
          'Разработчики': cl := complexity; 
          'легкий': Set_complexity(15);
          'средний': Set_complexity(24);
          'сложный': Set_complexity(36);
          'back': begin 
              TextOut(5,100, 'Существуют ходы                           ');
              if (stap_all.Count <> 0) and (local_scale <> 0) then begin
                local_scale -=2;
                Set_score(-2);
              end;
              Stap_back();
              TextOut(menu[menu.Count-1].picture_now.dx +20+ menu[menu.Count-1].picture_now.Width,menu[menu.Count-1].picture_now.dy,'счёт:               ');
              TextOut(menu[menu.Count-1].picture_now.dx +20+ menu[menu.Count-1].picture_now.Width,menu[menu.Count-1].picture_now.dy,'счёт: '+local_scale.ToString() + ' осталось косточек: ' + majong_all.Count.ToString() + '                ');
              Update_mc3();
          end;
          'map_0': creat_zero_map:= true;
          'map_1': index_map := 1;
          'map_2': index_map := 2;
          'map_3': index_map := 3;
          'map_4': index_map := 4;
          'map_5': index_map := 5;
          'map_6': index_map := 6;
        end;
   end;
 end;
 if (cl = select_menu) then begin
   clearwindow;
   Destroy_menu();
   now_map_type := -1;
   Creat_select_menu(120,200);
 end;
 if (cl = complexity) then begin
    clearwindow;
    Destroy_menu();
    cl:=none;
    Creat_complexity_menu();
 end;
 if (cl = start_menu) then begin
    clearwindow;
    Destroy_mc();
    Destroy_menu();
    Creat_menu();
    now_map_type := -1;
    //destroy_mc_b := false;
 end;
 if (creat_zero_map) then begin
   clearwindow;
   Destroy_menu();
   set_type_count (36);
   now_map_type := 0;
   Creat_map(0);
   creat_zero_map:=false;
 end;
 
 if (majong_all.Count = 0) and (now_map_type = 0) then 
 begin
   Destroy_mc();
   Creat_map(0);
   now_map_type := 0;
   creat_zero_map:=false;
 end;
 
 if(index_map > 0 ) then begin
    clearwindow;
    set_type_count (difficult);
    Destroy_menu();
    Creat_map(index_map);
    index_map := -1;
 end;
end;
//////////////////////////*?//////////////////////////////////*?//
procedure Mouse_click_mc(x,y,mb: integer);
var b : boolean := true;
begin
 foreach var mc in majong_all do begin   
   if mc.state^ = 1 then begin  // если активная mc
     if (x>mc.picture_now.dx) and (x< (mc.picture_now.dx + mc.picture_now.Width)) and    // если курсор попал по какому либо mc
        (y>mc.picture_now.dy) and (y< (mc.picture_now.dy + mc.picture_now.Height))   then 
     begin
       if not(select.first_select) then begin
          select.first_select := true;
          b := false;
          select.first_mc_name := mc.name;
          click_on_mc.Play;
          sprite_swap(Get_index_mc(mc,majong_all),'select');
         end
       else if (select.first_select) and (majong_all[Get_index_name(select.first_mc_name,majong_all)].type_mc^ = mc.type_mc^) then begin
          select.second_select_name := mc.name;
          select.second_select  := true;
          Save_stap((Get_index_name_for_copy(select.first_mc_name)).ToString() + '.' + (Get_index_name_for_copy(mc.name)).ToString());
          b := false;
          click_on_mc.Play;
       end
       else begin
         sprite_swap(Get_index_name(select.first_mc_name,majong_all) , 'activate');
         select.first_select := false;
         end;
     end
   end;
 end;
 if select.first_select = true and (b) then begin
   sprite_swap(Get_index_name(select.first_mc_name,majong_all) , 'activate');
   select.first_select := false;
   end;
 if (select.first_select and select.second_select) then begin 
  Destroy_select_mc();
  Set_score(2);
  
  local_scale += 2; 
  TextOut(menu[menu.Count-1].picture_now.dx +20+ menu[menu.Count-1].picture_now.Width,menu[menu.Count-1].picture_now.dy,'счёт:          ');
  TextOut(menu[menu.Count-1].picture_now.dx +20+ menu[menu.Count-1].picture_now.Width,menu[menu.Count-1].picture_now.dy,'счёт: '+local_scale.ToString() + ' осталось косточек: ' + majong_all.Count.ToString() + '                ');
  Update_mc2();
   if (Check_have_stap() = false) then TextOut(5,140,'ходы закончились');
  if ( majong_all.Count = 0 ) and (index_map <> -2 )then begin
    clearwindow;
    Destroy_mc();
    Destroy_menu();
    Creat_menu();
    now_map_type := -1;
  end;
 end;
end; 
//////////////////////////*?//////////////////////////////////*?/
procedure Awake(); // Запуск предпроцессов
begin
  Get_user_path();
  Get_peth_for_sount();
  ClearWindow();
  Get_worlds();
  MaximizeWindow;
end;
//////////////////////////*?//////////////////////////////////*?//
begin // main
  Awake();
  Creat_menu();
  Creat_shablon_map();// временно
  OnMouseDown := Mouse_click_mc;
  OnMouseDown += Mouse_click_UI;
end.