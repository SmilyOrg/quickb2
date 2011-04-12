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

package TopDown.objects 
{
	import As3Math.geo2d.*;
	import flash.display.*;
	import flash.utils.*;
	import QuickB2.events.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	import QuickB2.stock.*;
	import surrender.srGraphics2d;
	import TopDown.debugging.*;
	import TopDown.internals.*;
	
	import TopDown.*;
	use namespace td_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdTerrain extends qb2Terrain
	{
		public static const SKID_TYPE_ROLLING:uint = 1;
		public static const SKID_TYPE_SLIDING:uint = 2;
		
		public var rollingFrictionZMultiplier:Number = 1;
		
		public var slidingSkidColor:uint = 0x000000;
		public var rollingSkidColor:uint = 0x000000;
		
		public var slidingSkidAlpha:Number = .6;
		public var rollingSkidAlpha:Number = .6;
		
		public var skidDuration:Number = 2;
		
		public var drawSlidingSkids:Boolean = true;
		public var drawRollingSkids:Boolean = false;
		
		public function tdTerrain(ubiquitous:Boolean = false) 
		{
			super(ubiquitous);
		}
		
		public override function addObject(... bd):qb2ObjectContainer
		{
			return super.addObject(bd[0]);
		}
		
		public function addSkid(start:amPoint2d, end:amPoint2d, thickness:Number, type:uint):void
		{
			var entry:tdInternalSkidEntry = new tdInternalSkidEntry();
			entry.start = start;
			entry.end   = end;
			entry.thickness = thickness;
			entry.startTime = world.clock;
			entry.type = type;
			
			skidEntries[entry] = true;
		}
		
		private var skidEntries:Dictionary = new Dictionary(false);
		
		public override function draw(graphics:srGraphics2d):void
		{
			super.draw(graphics);
			
			drawSkids(graphics);
		}
		
		public override function drawDebug(graphics:srGraphics2d):void
		{
			super.drawDebug(graphics);
			
			if ( td_debugDrawFlags.SKIDS & td_debugDrawSettings.flags )
			{
				drawSkids(graphics);
			}
		}
		
		public function drawSkids(graphics:srGraphics2d):void
		{
			var time:Number = world.clock;
			
			for ( var key:* in skidEntries )
			{
				var entry:tdInternalSkidEntry = key as tdInternalSkidEntry;
				var startAlpha:Number = entry.type == SKID_TYPE_SLIDING ? slidingSkidAlpha : rollingSkidAlpha;
				var color:uint = entry.type == SKID_TYPE_SLIDING ? slidingSkidColor : rollingSkidColor;
				
				if ( time - entry.startTime > skidDuration )
				{
					delete skidEntries[key];
				}
				else
				{
					var alpha:Number = startAlpha * (1 - (time - entry.startTime) / skidDuration );
					graphics.setLineStyle(entry.thickness, color, alpha);
					//trace(entry.thickness, entry.color, alpha, entry.start, entry.end);
					graphics.moveTo(entry.start.x, entry.start.y);
					graphics.lineTo(entry.end.x, entry.end.y);
				}
			}
		}
		
		private var carContactDict:Dictionary = new Dictionary(true);
		
		protected override function contact(evt:qb2ContactEvent):void
		{
			super.contact(evt);
			
			var otherShape:qb2Shape = evt.otherShape;
			var carBody:tdCarBody = otherShape.getAncestorOfType(tdCarBody) as tdCarBody;
			
			if ( !carBody )  return;
			
			if ( evt.type == qb2ContactEvent.CONTACT_STARTED )
			{
				if ( !carContactDict[carBody] )
				{
					carContactDict[carBody] = 0 as int;
					
					carBody.registerContactTerrain(this);
				}
				
				carContactDict[carBody]++;
			}
			else
			{
				carContactDict[carBody]--;
				
				if ( carContactDict[carBody] == 0 ) 
				{
					delete carContactDict[carBody];
					carBody.unregisterContactTerrain(this);
				}
			}
		}
		
		public override function clone(deep:Boolean = true):qb2Object
		{
			var cloned:tdTerrain = super.clone(deep) as tdTerrain;
			
			cloned.rollingFrictionZMultiplier = this.rollingFrictionZMultiplier;
			cloned.rollingSkidColor           = this.rollingSkidColor;
			cloned.slidingSkidColor           = this.slidingSkidColor;
			cloned.slidingSkidAlpha           = this.slidingSkidAlpha;
			cloned.rollingSkidAlpha           = this.rollingSkidAlpha;
			cloned.skidDuration               = this.skidDuration;
			
			return cloned;
		}
	}
}