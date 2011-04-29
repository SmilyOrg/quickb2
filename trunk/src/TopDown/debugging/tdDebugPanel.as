/**
 * Copyright (c) 2010 Johnson Center for Simulation at Pine Technical College
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package TopDown.debugging 
{
	import com.bit101.components.*;
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import QuickB2.debugging.*;
	import QuickB2.debugging.gui.qb2DebugPanel;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	
	import QuickB2.*;
	use namespace qb2_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdDebugPanel extends Window
	{
		public static var rememberSettings:Boolean = true;
		
		private var tires:CheckBox, tireLoads:CheckBox, skids:CheckBox, tracks:CheckBox, tethers:CheckBox, antennas:CheckBox;
		
		private var checkboxMap:Object =
		{
			tires            : td_debugDrawFlags.TIRES, 
			tireLoads        : td_debugDrawFlags.TIRE_LOADS,
			skids            : td_debugDrawFlags.SKIDS,
			tracks           : td_debugDrawFlags.TRACKS,
			tethers          : td_debugDrawFlags.TRACK_TETHERS,
			antennas         : td_debugDrawFlags.ANTENNAS
		};
		
		public function tdDebugPanel()
		{
			this.title = "TopDown Debug Panel";
			this.hasMinimizeButton = true;
			this.draggable = true;
			this.grips.visible = true;
			this.alpha = qb2DebugPanel.DEFAULT_ALPHA;
			
			width = 210;  height = 70;
			
			var left:Number = 5;
			
			// FLAG CHECK BOXES
			var startY:Number = 5, incY:Number = 15;
			tires = new CheckBox(this, left, startY, "Draw Tires", checkBoxChange);
			tireLoads = new CheckBox(this, left, tires.y+incY, "Draw Tire Loads", checkBoxChange);
			skids = new CheckBox(this, left, tireLoads.y + incY, "Draw Skid Marks", checkBoxChange);
			
			left = 100;
			
			tracks = new CheckBox(this, left, tires.y, "Draw Tracks", checkBoxChange);
			tethers = new CheckBox(this, left, tracks.y + incY, "Draw Track Tethers", checkBoxChange);
			antennas = new CheckBox(this, left, tethers.y + incY, "Draw Antennas", checkBoxChange);
			
			addEventListener(Event.ADDED_TO_STAGE, added); // to start fps
			
			initSettings();
		}
		
		private function update(evt:Event):void
		{
			var data:Object = sharedData;
			data.windowX = this.x;
			data.windowY = this.y;
		}
		
		private function initSettings():void
		{
			if ( rememberSettings )
			{
				var data:Object = sharedData;
				
				//--- Set the shared data initially it looks like it hasn't been set before.
				if ( !data.hasOwnProperty("tires") )
				{
					for ( var key:String in checkboxMap)
					{
						data[key] = td_debugDrawSettings.flags & checkboxMap[key] ? true : false
					}
					
					data.windowMinimized = false;
					data.windowX = data.windowY = 0;
				}
				
				for ( key in checkboxMap)
				{
					manualSet(this[key], checkboxMap[key],      data[key]     == true);
				}
				
				this.minimized = data.windowMinimized == true;
				this.x = data.windowX;
				this.y = data.windowY;
			}
			else
			{
				for ( key in checkboxMap)
				{
					this[key].selected = td_debugDrawSettings.flags & checkboxMap[key] ? true : false;
				}
			}
		}
		
		private static function manualSet(checkBox:CheckBox, bit:uint, flag:Boolean):void
		{
			checkBox.selected = flag;
			if ( flag )
				td_debugDrawSettings.flags |= bit;
			else
				td_debugDrawSettings.flags &= ~bit;
		}
		
		private static function get sharedData():Object
			{  return SharedObject.getLocal("TopDownDebugPanelSharedObject").data;  }
			
		private static function setSharedData(variable:String, value:*):void
		{
			if ( !rememberSettings )  return;
			
			sharedData[variable] = value;
		}
		
		public override function set minimized(value:Boolean):void
		{
			for (var i:int = 0; i < numChildren; i++) 
			{
				var child:DisplayObject = getChildAt(i);
				
				if ( child != grips && child != _minimizeButton && child != _titleLabel && child != _titleBar && child != _panel )
				{
					child.visible = !value;
				}
			}
			
			setSharedData("windowMinimized", value);
			super.minimized = value;
			
			if ( !minimized )
			{
				this.setChildIndex(_panel, 0);
			}
		}
		
		private function added(evt:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, added, false);
			addEventListener(Event.REMOVED_FROM_STAGE, removed, false, 0, true );
			addEventListener(Event.ENTER_FRAME, update, false, 0, true);
		}
		
		private function removed(evt:Event):void
		{
			removeEventListener(Event.REMOVED_FROM_STAGE, removed, false);
			addEventListener(Event.ADDED_TO_STAGE, added, false, 0, true);
			removeEventListener(Event.ENTER_FRAME, update);
		}
		
		private function checkBoxChange(evt:Event):void
		{
			for ( var key:String in checkboxMap )
			{
				if ( evt.currentTarget == this[key] )
				{
					var flag:Boolean = this[key].selected;
					var drawFlag:uint = checkboxMap[key];
					setSharedData(key, flag);
					
					if ( flag )
						td_debugDrawSettings.flags |= drawFlag;
					else
						td_debugDrawSettings.flags &= ~drawFlag;
					
					break;
				}
			}
		}
	}
}