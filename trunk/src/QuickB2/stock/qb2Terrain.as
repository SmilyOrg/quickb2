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

package QuickB2.stock 
{
	import flash.display.*;
	import flash.utils.*;
	import QuickB2.*;
	import QuickB2.debugging.*;
	import QuickB2.debugging.drawing.qb2_debugDrawSettings;
	import QuickB2.events.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	import surrender.srGraphics2d;
	
	use namespace qb2_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2Terrain extends qb2Body
	{
		public function qb2Terrain(ubiquitous:Boolean = false) 
		{
			_ubiquitous = ubiquitous;
			
			isGhost = true;
			
			if ( !_ubiquitous )
			{
				addContactListeners();
			}
			
			addEventListener(qb2ContainerEvent.ADDED_TO_WORLD,     addedOrRemoved, null, true);
			addEventListener(qb2ContainerEvent.REMOVED_FROM_WORLD, addedOrRemoved, null, true);
		}
		
		private function addContactListeners():void
		{
			addEventListener(qb2ContactEvent.CONTACT_STARTED, contact, null, true);
			addEventListener(qb2ContactEvent.CONTACT_ENDED,   contact, null, true);
		}
		
		private function removeContactListeners():void
		{
			removeEventListener(qb2ContactEvent.CONTACT_STARTED, contact);
			removeEventListener(qb2ContactEvent.CONTACT_ENDED,   contact);
		}
		
		public function get ubiquitous():Boolean
			{  return _ubiquitous;  }
		private var _ubiquitous:Boolean = false;
		
		//--- Terrain is organized z-wise with other terrains globally whenever one is added to the world.
		private function addedOrRemoved(evt:qb2ContainerEvent):void
		{
			if ( evt.type == qb2ContainerEvent.ADDED_TO_WORLD )
			{
				world.registerGlobalTerrain(this);
			}
			else
			{
				evt.ancestor.world.unregisterGlobalTerrain(this);
			}
		}
		
		public function get frictionZMultiplier():Number
			{  return _frictionZMultiplier;  }
		public function set frictionZMultiplier(value:Number):void 
		{
			_frictionZMultiplier = value;
			
			if ( _ubiquitous )
			{
				if ( world )
				{
					world.updateFrictionJoints();
				}
			}
			else
			{
				for (var key:* in shapeContactDict )
				{
					(key as qb2Tangible).updateFrictionJoints();
				}
			}
		}
		private var _frictionZMultiplier:Number = 1;
		
		private var shapeContactDict:Dictionary = new Dictionary(true);
		
		protected function contact(evt:qb2ContactEvent):void
		{
			var otherShape:qb2Shape = evt.otherShape;
			
			if ( evt.type == qb2ContactEvent.CONTACT_STARTED )
			{
				if ( !shapeContactDict[otherShape] )
				{
					shapeContactDict[otherShape] = 0 as int;
					
					otherShape.registerContactTerrain(this);
				}
				
				shapeContactDict[otherShape]++;
			}
			else
			{
				shapeContactDict[otherShape]--;
				
				if ( shapeContactDict[otherShape] == 0 ) 
				{
					delete shapeContactDict[otherShape];
					otherShape.unregisterContactTerrain(this);
				}
			}
		}
		
		public override function drawDebug(graphics:srGraphics2d):void
		{
			pushDebugFillColor(qb2_debugDrawSettings.terrainFillColor);
				super.drawDebug(graphics);
			popDebugFillColor();
		}
		
		public override function clone(deep:Boolean = true):qb2Object
		{
			var cloned:qb2Terrain = super.clone(deep) as qb2Terrain;
			
			cloned.frictionZMultiplier = this.frictionZMultiplier;
			cloned._ubiquitous = this._ubiquitous;
			
			if ( cloned._ubiquitous )
			{
				cloned.removeContactListeners();
			}
			
			return cloned;
		}
	}
}