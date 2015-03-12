package  {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	import flash.utils.Dictionary;
	import scaleform.clik.events.*;
	import scaleform.clik.data.DataProvider;
	
	import ValveLib.*;
	import flash.text.TextFormat;
	
	public class cosmetic_panel extends MovieClip {
		var gameAPI:Object;
		var globals:Object;
		
		var textFormat:TextFormat;
		var model_lookup:Object;
		var CurrentComboBox:Object;
		var AvailableComboBox:Object;
		var AnimationComboBox:Object;
		var CameraSlider:Object;
		var FogBtn:Object;
		var FreeBtn:Object;
		
		var current_hero:String = "";
		
		public function cosmetic_panel() {
			// constructor code
		}
		
		public function setup(api:Object, globals:Object)
		{
			//set our needed variables
			this.gameAPI = api;
			this.globals = globals;
			
			this.visible = false;
			
			this.textFormat = new TextFormat();
			this.textFormat.font = "$TextFont";
			this.textFormat.size = 13;
			
			var Background = replaceWithValveComponent(this.mc_background, "DB4_floading_panel", true);
			
			var ReplaceButton = replaceWithValveComponent(this.replace_btn, "chrome_button_normal");
			ReplaceButton.label = "Replace";
			ReplaceButton.addEventListener(MouseEvent.CLICK, replaceCosmetic);
			
			var DefaultButton = replaceWithValveComponent(this.default_btn, "chrome_button_primary");
			DefaultButton.label = "Default";
			DefaultButton.addEventListener(MouseEvent.CLICK, defaultCosmetic);
			
			this.CurrentComboBox = replaceWithValveComponent(this.current_combobox, "ComboBoxSkinned", true);
			this.CurrentComboBox.visibleRows = 10;
			this.CurrentComboBox.showScrollBar = true;
			this.CurrentComboBox.rowHeight = 25;
			
			this.AvailableComboBox = replaceWithValveComponent(this.available_combobox, "ComboBoxSkinned", true);
			this.AvailableComboBox.visibleRows = 10;
			this.AvailableComboBox.showScrollBar = true;
			this.AvailableComboBox.rowHeight = 25;
			
			this.AnimationComboBox = replaceWithValveComponent(this.animation_combobox, "ComboBoxSkinned", true);
			this.AnimationComboBox.visibleRows = 10;
			this.AnimationComboBox.showScrollBar = true;
			this.AnimationComboBox.rowHeight = 25;
			var animation_array:Array = new Array();
			animation_array.push({"label":"Idle", "data":"Idle"});
			animation_array.push({"label":"Run", "data":"Run"});
			animation_array.push({"label":"Die", "data":"Die"});
			animation_array.push({"label":"Flail", "data":"Flail"});
			animation_array.push({"label":"Spawn", "data":"Spawn"});
			animation_array.push({"label":"Victory", "data":"Victory"});
			animation_array.push({"label":"Defeat", "data":"Defeat"});
			animation_array.push({"label":"Disabled", "data":"Disabled"});
			animation_array.push({"label":"Attack 1", "data":"Attack_1"});
			animation_array.push({"label":"Attack 2", "data":"Attack_2"});
			animation_array.push({"label":"Ability 1", "data":"Ability_1"});
			animation_array.push({"label":"Ability 2", "data":"Ability_2"});
			animation_array.push({"label":"Ability 3", "data":"Ability_3"});
			animation_array.push({"label":"Ability 4", "data":"Ability_4"});
			animation_array.push({"label":"Channel 1", "data":"Channel_1"});
			animation_array.push({"label":"Channel 2", "data":"Channel_2"});
			animation_array.push({"label":"Channel 3", "data":"Channel_3"});
			animation_array.push({"label":"Channel 4", "data":"Channel_4"});
			var dataProvider = new DataProvider(animation_array);
			this.AnimationComboBox.setDataProvider(dataProvider);
			this.AnimationComboBox.setSelectedIndex(0);
			this.AnimationComboBox.menuList.addEventListener( ListEvent.INDEX_CHANGE, animationChanged );
			
			this.CameraSlider = replaceWithValveComponent(this.camera_slider, "Slider_New", true);
			this.CameraSlider.minimum = 750;
			this.CameraSlider.maximum = 2000;
			this.CameraSlider.value = 1150;
			this.CameraSlider.snapInterval = 50;
			this.CameraSlider.addEventListener( SliderEvent.VALUE_CHANGE, onSliderChanged );
			
			this.FogBtn = replaceWithValveComponent(this.fog_btn, "DotaCheckBoxDota");
			this.FogBtn.label = "Toggle fog of war on/off";
			this.FogBtn.selected = true;
			this.FogBtn.addEventListener(MouseEvent.CLICK, fog_click);
			
			this.FreeBtn = replaceWithValveComponent(this.free_style_btn, "DotaCheckBoxDota");
			this.FreeBtn.label = "Show all cosmetics for every units";
			this.FreeBtn.selected = false;
			this.FreeBtn.addEventListener(MouseEvent.CLICK, free_style_click);
			
			this.current_text.setTextFormat(this.textFormat);
			this.available_text.setTextFormat(this.textFormat);
			this.animation_text.setTextFormat(this.textFormat);
			this.camera_text.setTextFormat(this.textFormat);
			
			this.addChild(this.current_text);
			this.addChild(this.available_text);
			this.addChild(this.animation_text);
			this.addChild(this.camera_text);
				 
			this.model_lookup = Globals.instance.GameInterface.LoadKVFile('scripts/maps/model_lookup.txt');
			
			this.gameAPI.SubscribeToGameEvent("update_current_panel", this.updateCurrentBox);
			this.gameAPI.SubscribeToGameEvent("update_available_panel", this.updateAvailableBox);
		}
		
		public function animationChanged(e:ListEvent) {
			var Current:String = this.AnimationComboBox.menuList.dataProvider[this.AnimationComboBox.selectedIndex].data;
			this.gameAPI.SendServerCommand("set_animation " + Current);
		}
		
		public function onSliderChanged(e:SliderEvent) {
			this.gameAPI.SendServerCommand("zoom " + this.CameraSlider.value);
		}
		
		public function free_style_click(e:MouseEvent) {
			if (this.FreeBtn.selected == true) {
				this._updateAvailableBox(this.current_hero);
			} else {
				this._updateAvailableBox("");
			}
		}
		
		public function fog_click(e:MouseEvent) {
			if (this.FogBtn.selected == true) {
				this.gameAPI.SendServerCommand("fow_enable 1");
			} else {
				this.gameAPI.SendServerCommand("fow_enable 0");
			}
		}
		
		public function updateCurrentBox(args:Object) {
			var pID:int = globals.Players.GetLocalPlayer();
			
			if (args.player_id == pID) {
				// init values
				var model_name:Array = args.models.split(",");
				
				// Push data to new array
				var cosmetic_array:Array = new Array();
				
				for (var index in model_name) {
					var searchString:String = model_name[index];
					var start_index:Number = searchString.lastIndexOf("/") + 1;
					var end_index:Number = searchString.lastIndexOf(".vmdl");
					searchString = searchString.slice( start_index, end_index );
					cosmetic_array.push({"label":searchString, "data":model_name[index]});
				}
				
				// Initializing the scale form
				var dataProvider = new DataProvider(cosmetic_array);
				this.CurrentComboBox.setDataProvider(dataProvider);
				this.CurrentComboBox.setSelectedIndex(0);
			}
		}
		
		public function updateAvailableBox(args:Object) {
			var pID:int = globals.Players.GetLocalPlayer();
			
			if (args.player_id == pID) {
				this._updateAvailableBox(args.hero_name)
			}
		}
		
		private function _updateAvailableBox(hero_name:String) {
			// init values
			var hero_name:String = hero_name;
			var associated_name:Array = new Array();
			
			if (hero_name != "") {
				this.current_hero = hero_name;
				// Check if it has special names
				if (hero_name == "vengefulspirit") {
					associated_name.push(hero_name);
					associated_name.push("vengeful");
				} else if (hero_name == "life_stealer") {
					associated_name.push(hero_name);
					associated_name.push("lifestealer");
				} else if (hero_name == "tiny") {
					associated_name.push(hero_name);
					associated_name.push("tiny_01");
					associated_name.push("tiny_02");
					associated_name.push("tiny_03");
					associated_name.push("tiny_04");
				} else if (hero_name == "doom_bringer") {
					associated_name.push("doom");
				} else if (hero_name == "drow_ranger") {
					associated_name.push("drow");
				} else if (hero_name == "templar_assassin") {
					associated_name.push("lanaya");
				} else if (hero_name == "naga_siren") {
					associated_name.push("siren");
				} else if (hero_name == "nyx_assassin") {
					associated_name.push("nerubian_assassin");
				} else if (hero_name == "riki") {
					associated_name.push("rikimaru");
				} else if (hero_name == "shadow_shaman") {
					associated_name.push("shadowshaman");
				} else if (hero_name == "tusk") {
					associated_name.push("tuskarr");
				} else if (hero_name == "witch_doctor") {
					associated_name.push("witchdoctor");
				} else if (hero_name == "skeleton_king") {
					associated_name.push(hero_name);
					associated_name.push("wraith_king");
				} else {
					associated_name.push(hero_name);
				}
			} else {
				for (var name in model_lookup) {
					associated_name.push(name);
				}
			}
				
			// Push data to new array
			var cosmetic_array:Array = new Array();
				
			for (var name in associated_name) {
				for (var screen_name in model_lookup[associated_name[name]]) {
					cosmetic_array.push({"label":screen_name, "data":model_lookup[associated_name[name]][screen_name]});
				}
			}
				
			// Initializing the scale form
			cosmetic_array.sortOn("label");
			var dataProvider = new DataProvider(cosmetic_array);
			this.AvailableComboBox.setDataProvider(dataProvider);
			this.AvailableComboBox.setSelectedIndex(0);
		}
		
		public function replaceCosmetic(e:MouseEvent) {
			var Current:String = this.CurrentComboBox.menuList.dataProvider[this.CurrentComboBox.selectedIndex].data;
			var Available:String = this.AvailableComboBox.menuList.dataProvider[this.AvailableComboBox.selectedIndex].data;
			this.gameAPI.SendServerCommand("swap_cosmetic " + Current + " " + Available);
		}
		
		public function defaultCosmetic(e:MouseEvent) {
			this.gameAPI.SendServerCommand("cosmetic_default");
		}
		
		//Parameters: 
		//	mc - The movieclip to replace
		//	type - The name of the class you want to replace with
		//	keepDimensions - Resize from default dimensions to the dimensions of mc (optional, false by default)
		public function replaceWithValveComponent(mc:MovieClip, type:String, keepDimensions:Boolean = false) : MovieClip {
			var parent = mc.parent;
			var oldx = mc.x;
			var oldy = mc.y;
			var oldwidth = mc.width;
			var oldheight = mc.height;
			
			var newObjectClass = getDefinitionByName(type);
			var newObject = new newObjectClass();
			newObject.x = oldx;
			newObject.y = oldy;
			if (keepDimensions) {
				newObject.width = oldwidth;
				newObject.height = oldheight;
			}
			
			parent.removeChild(mc);
			parent.addChild(newObject);
			
			return newObject;
		}
	}
	
}
