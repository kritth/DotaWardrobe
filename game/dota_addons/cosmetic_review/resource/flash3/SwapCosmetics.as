package {
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	import scaleform.clik.events.*;
	import scaleform.clik.data.DataProvider;

	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	
	public class SwapCosmetics extends MovieClip{
		
		//these three variables are required by the engine
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		
		var toggleBtn:Object;
		
		//constructor, you usually will use onLoaded() instead
		public function SwapCosmetics() : void {
		}
		
		//this function is called when the UI is loaded
		public function onLoaded() : void {			
			//make this UI visible
			this.visible = true;
			
			//let the client rescale the UI
			Globals.instance.resizeManager.AddListener(this);
			
			//this is not needed, but it shows you your UI has loaded (needs 'scaleform_spew 1' in console)
			trace("Custom UI loaded!");
			
			this.my_panel.setup( this.gameAPI, this.globals );
			
			this.toggleBtn = replaceWithValveComponent(this.toggle_btn, "DotaCheckBoxDota");
			this.toggleBtn.label = "Toggle cosmetic control panel on/off";
			this.toggleBtn.selected = false;
			this.toggleBtn.addEventListener(MouseEvent.CLICK, toggle_click);
			this.toggleBtn.visible = false;			
			
			this.gameAPI.SubscribeToGameEvent("enable_cosmetics_panel", this.updateVisible);
		}
		
		// Switch
		public function updateVisible(args:Object) {
			var pID:int = globals.Players.GetLocalPlayer();
			
			if (args.player_id == pID) {
				if (this.toggleBtn.visible == false) {
					this.toggleBtn.visible = true;
				}
			}
		}
		
		//this handles the resizes - credits to Nullscope
		public function onResize(re:ResizeManager) : * {
			
			var scaleRatioY:Number = re.ScreenHeight/900;
					
			if (re.ScreenHeight > 900){
				scaleRatioY = 1;
			}
                    
            //You will probably want to scale your elements by here, they keep the same width and height by default.
            //I recommend scaling both X and Y with scaleRatioY.
            
            //The engine keeps elements at the same X and Y coordinates even after resizing, you will probably want to adjust that here.
		}
		
		private function toggle_click(e:MouseEvent) {
			if (e.target.parent.my_panel.visible == false) {
				e.target.parent.my_panel.visible = true;
			} else {
				e.target.parent.my_panel.visible = false;
			}
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