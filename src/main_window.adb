-----------------------------------------------------------------------------
--                                                                         --
--                 Copyright (C) 2018 Andrea Cervetti                      --
--                                                                         --
-- This program is free software: you can redistribute it and/or modify    --
-- it under the terms of the GNU General Public License as published by    --
-- the Free Software Foundation, either version 3 of the License, or       --
-- (at your option) any later version.                                     --
--                                                                         --
-- This program is distributed in the hope that it will be useful,         --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of          --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           --
-- GNU General Public License for more details.                            --
--                                                                         --
-- You should have received a copy of the GNU General Public License       --
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.   --
--                                                                         --
-----------------------------------------------------------------------------

with Gtk.Main;
with Gtk.Window;         use Gtk.Window;
with Gtk.Box;            use Gtk.Box;
with Gtk.Menu;           use Gtk.Menu;
with Gtk.Menu_Bar;       use Gtk.Menu_Bar;
with Gtk.Menu_Item;      use Gtk.Menu_Item;
with Gtk.Table;          use Gtk.Table;
with Gtk.Frame;          use Gtk.Frame;
with Gtk.Button;         use Gtk.Button;
with Gtk.Combo_Box_Text; use Gtk.Combo_Box_Text;
with Gtk.Widget;         use Gtk.Widget;
with Gtk.Handlers;
with Gtk.Combo_Box;      use Gtk.Combo_Box;
with Gtk.Label;          use Gtk.Label;
with Glib;               use Glib;
with Gtkada.Dialogs;     use Gtkada.Dialogs;
with Gtk.Enums;

with Ada.Containers.Vectors;
use Ada.Containers;
with Ada.Numerics;
with Ada.Numerics.Discrete_Random;

package body main_window is
         
   Size : constant := 6;

   type Values is mod 4;
   
   type Board_Size is range 1 .. Size * Size;

   type Cells is record
      Button : Gtk_Button;
      Value  : Values;
   end record;

   type Direction is (Up, Down);

   package Move_Vector is new Ada.Containers.Vectors (Positive, Board_Size);
   package Rand is new Ada.Numerics.Discrete_Random (Board_Size);
   

   package Simple_Handlers is new Gtk.Handlers.Callback
     (Widget_Type => Gtk_Widget_Record);

   package Return_Handlers is new Gtk.Handlers.Return_Callback
     (Widget_Type => Gtk_Widget_Record,
      Return_Type => Boolean);

   package Cell_Handlers is new Gtk.Handlers.User_Callback
     (Widget_Type => Gtk_Widget_Record,
      User_Type   => Board_Size);

   package Level_Handlers is new Gtk.Handlers.Callback
     (Widget_Type => Gtk_Combo_Box_Record);



   Images : array (Values) of String (1 .. 57) :=
     (0 => "<span weight=""bold"" color=""blue"" size=""xx-large"">0</span>",
      1 => "<span weight=""bold"" color=""blue"" size=""xx-large"">1</span>",
      2 => "<span weight=""bold"" color=""blue"" size=""xx-large"">2</span>",
      3 => "<span weight=""bold"" color=""blue"" size=""xx-large"">3</span>");

   Move_List : Move_Vector.Vector;

   Moves : Ada.Containers.Count_Type;

   Seed       : Rand.Generator;
   Saved_Seed : Rand.State;

   Board : array (Board_Size) of Cells;

   Label : Gtk_Label;

   Level : Gint := 4;
   
   Window    : Gtk_Window;

   procedure Increase_Cell (Cell : in out Cells) is
   begin
      Cell.Value := Cell.Value + 1;
      Set_Markup (Gtk_Label (Get_Child (Cell.Button)), Images (Cell.Value));
   end Increase_Cell;

   procedure Decrease_Cell (Cell : in out Cells) is
   begin
      Cell.Value := Cell.Value - 1;
      Set_Markup (Gtk_Label (Get_Child (Cell.Button)), Images (Cell.Value));
   end Decrease_Cell;

   procedure Make_Move (Pos : Board_Size; Dir : Direction := Down) is
      Change_Cell : access procedure (Cell : in out Cells);
   begin
      case Dir is
         when Up =>
            Change_Cell := Increase_Cell'Access;
         when Down =>
            Change_Cell := Decrease_Cell'Access;
      end case;
      Change_Cell (Board (Pos));
      if (Pos - Size) in Board_Size then
         Change_Cell (Board (Pos - Size));
      end if;
      if (Pos + Size) in Board_Size then
         Change_Cell (Board (Pos + Size));
      end if;
      if ((Pos - 1) mod Size) in 1 .. Size then
         Change_Cell (Board (Pos - 1));
      end if;
      if (Pos mod Size) in 1 .. Size then
         Change_Cell (Board (Pos + 1));
      end if;
   end Make_Move;

   procedure Compute_Board is
   begin
      Move_List.Clear;
      Label.Set_Label ("Moves:" & Count_Type'Image (Move_List.Length));
      for I in Board_Size loop
         Board (I).Value := 0;
      end loop;
      for I in 1 .. (3 + Level * 3) loop
         Make_Move (Rand.Random (Seed), Up);
      end loop;
      for I in Board_Size loop
         Set_Markup
           (Gtk_Label (Get_Child (Board (I).Button)),
            Images (Board (I).Value));
      end loop;
   end Compute_Board;

   procedure Restart_Game is
   begin
      Rand.Reset (Seed, Saved_Seed);
      Compute_Board;
   end Restart_Game;

   procedure New_Game is
   begin
      Rand.Reset (Seed);
      Rand.Save (Seed, Saved_Seed);
      Compute_Board;
   end New_Game;

   ----------------
   -- Callbacks --
   ---------------

   procedure Cell_Callback
     (Object    : access Gtk_Widget_Record'Class;
      User_Data : Board_Size)
   is
      Counter : Integer                 := 0;
      Buttons : Message_Dialog_Buttons;
      Str1    : aliased constant String := "Perfect: Done in";
      Str2    : aliased constant String := "Done in";
      Str     : access constant String;
   begin
      Make_Move (User_Data);
      Move_List.Append (User_Data);
      Label.Set_Label ("Moves:" & Count_Type'Image (Move_List.Length));
      for I in Board_Size loop
         Counter := Counter + Integer (Board (I).Value);
      end loop;
      if Counter = 0 then
         Moves := Move_List.Length;
         if Moves <= 3 + 3 * Count_Type (Level) then
            Str     := Str1'Access;
            Buttons := Button_OK;
         else
            Str     := Str2'Access;
            Buttons := Button_Retry or Button_OK;
         end if;
         if Message_Dialog
             (Str.all & Count_Type'Image (Moves) & " moves",
              Title   => "You Won!",
              Buttons => Buttons,
              Parent  => Window) =
           Button_Retry
         then
            Restart_Game;
         else
            New_Game;
         end if;
      end if;
   end Cell_Callback;

   procedure New_Game_Callback (Object : access Gtk_Widget_Record'Class) is
   begin
      New_Game;
   end New_Game_Callback;

   procedure Restart_Game_Callback (Object : access Gtk_Widget_Record'Class) is
   begin
      Restart_Game;
   end Restart_Game_Callback;

   procedure Undo_Move_Callback (Object : access Gtk_Widget_Record'Class) is
   begin
      if not Move_List.Is_Empty then
         Make_Move (Move_List.Last_Element, Up);
         Move_List.Delete_Last;
         Label.Set_Label ("Moves:" & Count_Type'Image (Move_List.Length));
      end if;
   end Undo_Move_Callback;

   procedure Level_Change_Callback
     (Object : access Gtk_Combo_Box_Record'Class)
   is
      New_Level : Gint := Get_Active(Object);
   begin
      Level := New_Level;
      New_Game;
   end Level_Change_Callback;

   function Delete_Event
     (Object : access Gtk_Widget_Record'Class) return Boolean
   is
   begin
      return False;
   end Delete_Event;
   
   procedure Destroy (Object : access Gtk_Widget_Record'Class) is
   begin
      Gtk.Main.Main_Quit;
   end Destroy;
      
   procedure Create_Window is
      Box1      : Gtk_Box;
      Box2      : Gtk_Box;
      Menu      : Gtk_Menu;
      Menu_Bar  : Gtk_Menu_Bar;
      Menu_Item : Gtk_Menu_Item;
      Table     : Gtk_Table;
      Frame     : Gtk_Frame;
      Button    : Gtk_Button;
      Combo     : Gtk_Combo_Box_Text;
   begin
      Gtk_New (Window);
      Window.Set_Title ("Button Mania");
      Window.Set_Default_Size (300, 340);
      -- Standard stuff
      Return_Handlers.Connect
        (Window,
         "delete_event",
         Return_Handlers.To_Marshaller (Delete_Event'Access));
      Simple_Handlers.Connect
        (Window,
         "destroy",
         Simple_Handlers.To_Marshaller (Destroy'Access));

      Gtk_New_Vbox (Box1);
      Window.Add (Box1);
      -- main menu
      Gtk_New (Menu_Bar);
      Box1.Pack_Start (Menu_Bar, False);

      Gtk_New (Menu_Item, "Game");
      Menu_Bar.Append (Menu_Item);

      Gtk_New (Menu);
      Set_Submenu (Menu_Item, Menu);
      Gtk_New (Menu_Item, "New Game");
      Simple_Handlers.Connect
        (Menu_Item,
         "activate",
         Simple_Handlers.To_Marshaller (New_Game_Callback'Access));
      Menu.Append (Menu_Item);
      Gtk_New (Menu_Item, "Restart Game");
      Simple_Handlers.Connect
        (Menu_Item,
         "activate",
         Simple_Handlers.To_Marshaller (Restart_Game_Callback'Access));
      Menu.Append (Menu_Item);
      Gtk_New (Menu_Item, "Undo Move");
      Simple_Handlers.Connect
        (Menu_Item,
         "activate",
         Simple_Handlers.To_Marshaller (Undo_Move_Callback'Access));
      Menu.Append (Menu_Item);
      Gtk_New (Menu_Item, "Quit");
      Simple_Handlers.Connect
        (Menu_Item,
         "activate",
         Simple_Handlers.To_Marshaller (Destroy'Access));
      Menu.Append (Menu_Item);
      -- game field
      Gtk_New (Table, Size, Size, True);
      Box1.Pack_Start (Table, True, True, 0);

      for I in Board_Size loop
         Gtk_New (Board (I).Button, Values'Image (Board (I).Value));
         Cell_Handlers.Connect
           (Board (I).Button,
            "clicked",
            Cell_Handlers.To_Marshaller (Cell_Callback'Access),
            User_Data => I);
         declare
            Column : constant Guint := (Guint (I - 1) mod Size) + 1;
            Row    : constant Guint := (Guint (I) + Size - 1) / Size;
         begin
            Table.Attach (Board (I).Button, Column - 1, Column, Row - 1, Row);
         end;
      end loop;

      Gtk_New (Frame);
      Set_Shadow_Type (Frame, Gtk.Enums.Shadow_Out);
      Box1.Pack_Start (Frame, False, False, 0);
      Gtk_New_Hbox (Box2);
      Add (Frame, Box2);
      Gtk_New (Label, "Moves:" & Count_Type'Image (Move_List.Length));
      Box2.Pack_Start (Label, True, False, 0);
      Gtk_New (Button);
      Button.Set_Label ("Undo");
      Simple_Handlers.Connect
        (Button,
         "pressed",
         Simple_Handlers.To_Marshaller (Undo_Move_Callback'Access));
      Box2.Pack_Start (Button, True, False, 0);
      Gtk_New (Combo);
      Combo.Set_Title ("level");
      Combo.Append_Text ("Huh, what?");
      Combo.Append_Text ("Dumb");
      Combo.Append_Text ("Real easy");
      Combo.Append_Text ("Easy");
      Combo.Append_Text ("Normal");
      Combo.Append_Text ("Hard");
      Combo.Append_Text ("Real hard");
      Combo.Append_Text ("Master");
      Combo.Append_Text ("Impossible");
      Combo.Set_Active (4);
      Level_Handlers.Connect
        (Combo,
         "changed",
         Level_Handlers.To_Marshaller (Level_Change_Callback'Access));
      Box2.Pack_Start (Combo, True, False, 0);
      Window.Show_All;
   end Create_Window;

end main_window;
