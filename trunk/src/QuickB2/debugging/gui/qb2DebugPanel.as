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

package QuickB2.debugging.gui 
{
	import com.bit101.components.*;
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.system.*;
	import flash.utils.*;
	import QuickB2.*;
	import QuickB2.debugging.drawing.qb2_debugDrawFlags;
	import QuickB2.debugging.drawing.qb2_debugDrawSettings;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	
	use namespace qb2_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2DebugPanel extends Window
	{
		public static var rememberSettings:Boolean = true;
		
		qb2_friend static const DEFAULT_ALPHA:Number = .75;
		
		private var outlines:CheckBox, fills:CheckBox, verts:CheckBox, positions:CheckBox, centroids:CheckBox;
		private var bounds:CheckBox, boundCircles:CheckBox, joints:CheckBox, frictionPoints:CheckBox, decomposition:CheckBox;
		
		private var checkboxMap:Object =
		{
			outlines       : qb2_debugDrawFlags.OUTLINES, 
			fills          : qb2_debugDrawFlags.FILLS,
			verts          : qb2_debugDrawFlags.VERTICES,
			positions      : qb2_debugDrawFlags.POSITIONS,
			centroids      : qb2_debugDrawFlags.CENTROIDS,
			bounds         : qb2_debugDrawFlags.BOUND_BOXES,
			boundCircles   : qb2_debugDrawFlags.BOUND_CIRCLES,
			joints         : qb2_debugDrawFlags.JOINTS,
			frictionPoints : qb2_debugDrawFlags.FRICTION_Z_POINTS,
			decomposition  : qb2_debugDrawFlags.DECOMPOSITION
		};
		
		private var objToString:Dictionary = new Dictionary();
		
		private var alphaSlider:VUISlider;
		
		private var boundBoxRange:HRangeSlider, centroidRange:HRangeSlider, boundCircleRange:HRangeSlider;
		
		private var fps:Label;
		private var polyCount:Label;
		private var circCount:Label;
		private var jointCount:Label;
		private var ram:Label;
		
		private var pausePlay:PushButton;
		private var stepButton:PushButton;
		
		private var polyStart:String  = "  POLYGONS";
		private var circStart:String  = "  CIRCLES";
		private var jointStart:String = "  JOINTS";
		
		[Embed(source = 'qb2Logo_tiny.png')]
		private static var LogoClass:Class;
		private var logoBitmap:Bitmap = new LogoClass;
		private var logo:Sprite = new Sprite();
		
		public function qb2DebugPanel()
		{			
			this.title = "QuickB2 Debug Panel";
			this.hasMinimizeButton = true;
			this.draggable = true;
			this.grips.visible = true;
			this.alpha = DEFAULT_ALPHA;
			
			width = 150;  height = 415;
			
			const left:Number = 7;
			
			// FLAG CHECK BOXES
			var startY:Number = 10, incY:Number = 17;
			outlines = new CheckBox(this, left, startY, "Draw Lines", checkBoxChange);
			fills = new CheckBox(this, left, outlines.y+incY, "Draw Fills", checkBoxChange);
			verts = new CheckBox(this, left, fills.y+incY, "Draw Vertices", checkBoxChange);
			positions = new CheckBox(this, left, verts.y+incY, "Draw Positions", checkBoxChange);
			centroids = new CheckBox(this, left, positions.y + incY, "Draw Centroids", checkBoxChange);
			bounds = new CheckBox(this, left, centroids.y+incY, "Draw Bound Boxes", checkBoxChange);
			boundCircles = new CheckBox(this, left, bounds.y+incY, "Draw Bound Circles", checkBoxChange);
			joints = new CheckBox(this, left, boundCircles.y + incY, "Draw Joints", checkBoxChange);
			frictionPoints = new CheckBox(this, left, joints.y + incY, "Draw FrictionZ", checkBoxChange);
			decomposition = new CheckBox(this, left, frictionPoints.y + incY, "Draw Decomposition", checkBoxChange);
			
			objToString[outlines] = "outlines";
			objToString[fills] = "fills";
			objToString[verts] = "verts";
			objToString[positions] = "positions";
			objToString[centroids] = "centroids";
			objToString[bounds] = "bounds";
			objToString[boundCircles] = "boundCircles";
			objToString[joints] = "joints";
			objToString[frictionPoints] = "frictionPoints";
			objToString[decomposition] = "decomposition";
			
			// SLIDERS
			alphaSlider = new VUISlider(this, 110, 10, "Alpha", alphaChange);
			alphaSlider.labelPrecision = 2;
			alphaSlider.tick = .05;
			alphaSlider.height = 155;
			alphaSlider.maximum = 1;
			
			// RANGES
			const rangeX:Number = 15;
			startY = decomposition.y + 30;  incY = 40;
			boundBoxRange = new HRangeSlider(this, 0, startY);
			boundBoxRange.minimum = 0;
			boundBoxRange.maximum = 10;
			boundBoxRange.tick = 1;
			boundBoxRange.addEventListener(Event.CHANGE, rangeChange);
			var boundBoxRangeLabel:Label = new Label(this, 0, startY + 10, "Bound Box Depth");
			boundBoxRange.x = this.width / 2 - boundBoxRange.width / 2;
			boundBoxRangeLabel.x = this.width / 2 - boundBoxRangeLabel.width / 2;
		
			boundCircleRange = new HRangeSlider(this, 0, startY + incY);
			boundCircleRange.minimum = 0;
			boundCircleRange.maximum = 10;
			boundCircleRange.tick = 1;
			boundCircleRange.addEventListener(Event.CHANGE, rangeChange);
			var boundCircleRangeLabel:Label = new Label(this, 0, startY + incY + 10, "Bound Circle Depth");
			boundCircleRange.x = this.width / 2 - boundBoxRange.width / 2;
			boundCircleRangeLabel.x = this.width / 2 - boundBoxRangeLabel.width / 2;
			
			centroidRange = new HRangeSlider(this, 0, startY + incY*2);
			centroidRange.minimum = 0;
			centroidRange.maximum = 10;
			centroidRange.tick = 1;
			centroidRange.addEventListener(Event.CHANGE, rangeChange);
			var centroidRangeLabel:Label = new Label(this, 0, startY + incY*2 + 10, "Centroid Depth");
			centroidRange.x = this.width / 2 - centroidRange.width / 2;
			centroidRangeLabel.x = this.width / 2 - centroidRangeLabel.width / 2;
			
			var heightOffset:Number = -5;
			var bottom:Number = 368;
			polyCount = new Label(this, left, centroidRangeLabel.y + centroidRangeLabel.height + 10, "0" + polyStart);
			circCount = new Label(this, left, polyCount.y + polyCount.height + heightOffset, "0" + circStart);
			jointCount = new Label(this, left, circCount.y + circCount.height + heightOffset, "0" + jointStart);
			fps = new Label(this,    left, bottom+2, "FPS: ");
			
			ram = new Label(this, left, fps.y - fps.height-heightOffset, "RAM: ");
			//fps.y = this.height - fps.height;
			
			pausePlay = new PushButton(this, 0, bottom, "Pause", buttonPushed);
			pausePlay.width *= .5;
			pausePlay.x = this.width - pausePlay.width - left;
			
			stepButton = new PushButton(this, 0, bottom, "Step", buttonPushed);
			stepButton.width *= .5;
			stepButton.x = pausePlay.x;
			stepButton.y = pausePlay.y - stepButton.height - left;
			
			logo.addChild(logoBitmap);
			//logo.scaleX = logo.scaleY = .5;
			logo.x = stepButton.x + stepButton.width / 2 - logo.width / 2;
			logo.y = stepButton.y - logo.height - 7;
			addChild(logo);
			logo.buttonMode = true;
			logo.mouseChildren = false;
			logo.addEventListener(MouseEvent.CLICK, goToOpenSourcePage, false, 0, true);
			
			addEventListener(Event.ADDED_TO_STAGE, added); // to start fps
			
			initSettings();
		}
		
		private function goToOpenSourcePage(evt:MouseEvent):void
		{
			navigateToURL(new URLRequest("http://code.google.com/p/quickb2"), "_blank");
		}
		
		private function update(evt:Event):void
		{
			var numPolys:uint = 0, numCircles:uint = 0, numJoints:uint = 0;
			
			var worldDict:Dictionary = qb2World.worldDict;
			for (var key:* in worldDict)
			{
				var world:qb2World = worldDict[key];
				numPolys   += world.totalNumPolygons;
				numCircles += world.totalNumCircles;
				numJoints  += world.totalNumJoints;
			}
			
			polyCount.text  = numPolys + polyStart;
			circCount.text  = numCircles + circStart;
			jointCount.text = numJoints + jointStart;
			
			var data:Object = sharedData;
			data.windowX = this.x;
			data.windowY = this.y;
			
			_frames++;
			var time:int = getTimer();
			var elapsed:int = time - _startTime;
			
			if( elapsed >= 500)
			{
				var fpsNum:int = Math.round(_frames * 1000 / elapsed);
				_frames = 0;
				_startTime = time;
				
				fps.text = fpsNum + "  FPS";
				
				var memory:String = (System.totalMemory / 1000).toFixed(0);
				var memStringLen:int = memory.length;
				var newMemory:String = "";
				for (var i:int = memStringLen; i >= 0; i-= 3) 
				{
					var sliceLength:int = 3;
					var end:int = i - sliceLength;
					var numbersLeft:Boolean = end > 0;
					
					if ( !numbersLeft )
					{
						end = 0;
					}
					
					newMemory = (numbersLeft ? "," : "") + memory.slice(end, i) + newMemory;
				}
				ram.text = newMemory + "  KB";
			}
		}
		
		private var _frames:int = 0;
		private var _startTime:int = 0;
		
		private function initSettings():void
		{
			if ( rememberSettings )
			{
				var data:Object = sharedData;
				
				//--- Set the shared data initially it looks like it hasn't been set before.
				if ( !data.hasOwnProperty("outlines") )
				{
					for ( var key:String in checkboxMap)
					{
						data[key] = qb2_debugDrawSettings.flags & checkboxMap[key] ? true : false
					}
					
					data.boundBoxRangeLow     = qb2_debugDrawSettings.boundBoxStartDepth;
					data.boundBoxRangeHigh    = qb2_debugDrawSettings.boundBoxEndDepth;
					data.boundCircleRangeLow  = qb2_debugDrawSettings.boundCircleStartDepth;
					data.boundCircleRangeHigh = qb2_debugDrawSettings.boundCircleEndDepth;
					data.centroidRangeLow     = qb2_debugDrawSettings.centroidStartDepth;
					data.centroidRangeHigh    = qb2_debugDrawSettings.centroidEndDepth;
					
					data.alphaSliderValue     = .75;
					
					data.windowMinimized = false;
					data.windowX = data.windowY = 0;
				}
				
				//---- Set window settings based on shared properties.
				for ( key in checkboxMap)
				{
					manualSet(this[key], checkboxMap[key],      data[key]     == true);
				}
				
				boundBoxRange.lowValue     = data.boundBoxRangeLow;
				boundBoxRange.highValue    = data.boundBoxRangeHigh;
				boundCircleRange.lowValue  = data.boundCircleRangeLow;
				boundCircleRange.highValue = data.boundCircleRangeHigh;
				centroidRange.lowValue     = data.centroidRangeLow;
				centroidRange.highValue    = data.centroidRangeHigh;
				
				alphaSlider.value          = data.alphaSliderValue;
				
				this.minimized = data.windowMinimized == true;
				this.x = data.windowX;
				this.y = data.windowY;
			}
			else
			{
				for ( key in checkboxMap)
				{
					this[key].selected = qb2_debugDrawSettings.flags & checkboxMap[key] ? true : false;
				}
				
				boundBoxRange.lowValue     = qb2_debugDrawSettings.boundBoxStartDepth;
				boundBoxRange.highValue    = qb2_debugDrawSettings.boundBoxEndDepth;
				
				boundCircleRange.lowValue  = qb2_debugDrawSettings.boundCircleStartDepth;
				boundCircleRange.highValue = qb2_debugDrawSettings.boundCircleEndDepth;
				
				centroidRange.lowValue  = qb2_debugDrawSettings.centroidStartDepth;
				centroidRange.highValue = qb2_debugDrawSettings.centroidEndDepth;
				
				alphaSlider.value = .75;
			}
			
			alphaChange(null);
		}
		
		private static function manualSet(checkBox:CheckBox, bit:uint, flag:Boolean):void
		{
			checkBox.selected = flag;
			if ( flag )
				qb2_debugDrawSettings.flags |= bit;
			else
				qb2_debugDrawSettings.flags &= ~bit;
		}
		
		private static function get sharedData():Object
			{  return SharedObject.getLocal("QuickB2DebugPanelSharedObject").data;  }
			
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
			
			super.minimized = value;
			setSharedData("windowMinimized", value);
			
			if ( !minimized )
			{
				this.setChildIndex(_panel, 0);
			}
		}
		
		private function buttonPushed(evt:Event):void
		{
			var sum:int = 0;
			
			var dict:Dictionary = qb2World.worldDict;
			if( evt.target == stepButton )
			{
				pausePlay.label = "Play"
				
				for (key in dict)
				{
					var world:qb2World = dict[key] as qb2World;
					
					if ( world.running )
					{
						world.stop();
					}
					else
					{
						var timeStep:Number = world.realtimeUpdate ? world.maximumRealtimeStep : world.defaultTimeStep;
						world.step(timeStep);
					}
				}
			}
			else if ( pausePlay.label == "Pause" )
			{
				pausePlay.label = "Play";
				
				for (var key:* in dict )
				{
					dict[key].stop();
				}
			}
			else if( pausePlay.label == "Play" )
			{
				pausePlay.label = "Pause";
				
				for (key in dict)
				{
					dict[key].start();
				}
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
			var key:String = objToString[evt.currentTarget];
			
			if ( !key )  return;
			
			var flag:Boolean = evt.currentTarget.selected;
			var drawFlag:uint = checkboxMap[key] as uint;
			setSharedData(key, flag);
			
			if ( flag )
				qb2_debugDrawSettings.flags |= drawFlag;
			else
				qb2_debugDrawSettings.flags &= ~drawFlag;
		}
		
		private function alphaChange(evt:Event):void
		{
			qb2_debugDrawSettings.vertexAlpha = qb2_debugDrawSettings.fillAlpha = qb2_debugDrawSettings.outlineAlpha = qb2_debugDrawSettings.boundBoxAlpha = qb2_debugDrawSettings.centroidAlpha = alphaSlider.value;
			setSharedData("alphaSliderValue", alphaSlider.value);
		}
		
		private function rangeChange(evt:Event):void
		{
			if ( evt.currentTarget == boundBoxRange )
			{
				qb2_debugDrawSettings.boundBoxStartDepth = boundBoxRange.lowValue;
				qb2_debugDrawSettings.boundBoxEndDepth   = boundBoxRange.highValue;
				
				setSharedData("boundBoxRangeLow", boundBoxRange.lowValue);
				setSharedData("boundBoxRangeHigh", boundBoxRange.highValue);
			}
			else if( evt.currentTarget == centroidRange )
			{
				qb2_debugDrawSettings.centroidStartDepth = centroidRange.lowValue;
				qb2_debugDrawSettings.centroidEndDepth   = centroidRange.highValue;
				
				setSharedData("centroidRangeLow", centroidRange.lowValue);
				setSharedData("centroidRangeHigh", centroidRange.highValue);
			}
			
			else if( evt.currentTarget == boundCircleRange )
			{
				qb2_debugDrawSettings.boundCircleStartDepth = boundCircleRange.lowValue;
				qb2_debugDrawSettings.boundCircleEndDepth   = boundCircleRange.highValue;
				
				setSharedData("boundCircleRangeLow", boundCircleRange.lowValue);
				setSharedData("boundCircleRangeHigh", boundCircleRange.highValue);
			}
		}
	}
}