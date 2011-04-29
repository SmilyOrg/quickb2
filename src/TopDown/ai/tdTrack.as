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

package TopDown.ai
{
	import As3Math.general.*;
	import As3Math.geo2d.*;
	import flash.display.*;
	import QuickB2.debugging.*;
	import QuickB2.debugging.drawing.qb2_debugDrawSettings;
	import QuickB2.objects.*;
	import surrender.srGraphics2d;
	import TopDown.*;
	import TopDown.debugging.*;
	import TopDown.events.*;
	import TopDown.internals.*;
	import TopDown.objects.*;
	
	use namespace td_friend;

	[Event(name="trackMoved", type="TopDown.events.tdTrackEvent")]

	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdTrack extends qb2Object
	{
		td_friend var branches:Vector.<tdInternalTrackBranch> = new Vector.<tdInternalTrackBranch>();
		
		public var speedLimit:Number = 13.5; // in meters/sec...this equals about 30 mph.
		public var width:Number = 10;
		
		td_friend var lastSpawnTime:Number = 0;
		
		td_friend const lineRep:amLine2d = new amLine2d();
		
		
		private var freezeUpdate:Boolean = false;
		
		public function tdTrack( initStart:amPoint2d = null, initEnd:amPoint2d = null)
		{
			set(initStart ? initStart : new amPoint2d(), initEnd ? initEnd : new amPoint2d());
		}
		
		public function get numBranches():uint
			{  return branches.length;  }
			
		public function getBranchAt(index:uint):tdTrack
			{  return branches[index].track;  }
			
		public function getDistanceToBranchAt(index:uint):Number
			{  return branches[index].distance;  }
		
		td_friend function addBranch(branch:tdInternalTrackBranch):void
		{
			var inserted:Boolean = false;
			var numBranches:int = branches.length;
			for (var i:int = 0; i < numBranches; i++) 
			{
				if ( branch.distance < branches[i].distance)
				{
					branches.splice(i, 0, branch);
					inserted = true;
					break;
				}
			}
			
			if ( !inserted )
			{
				branches.push(branch);
			}
		}
		
		td_friend function clearBranches():void
		{
			//--- Most of the job here is actually clearing this branch from its branches' branch lists.
			var numBranches:int = branches.length;
			for (var i:int = 0; i < numBranches; i++) 
			{
				var branchTrack:tdTrack = branches[i].track;
				
				var otherBranchNumBranches:int = branchTrack.branches.length;
				for (var j:int = 0; j < otherBranchNumBranches; j++) 
				{
					var otherBranchBranch:tdTrack = branchTrack.branches[j].track;
					if ( otherBranchBranch == this )
					{
						branchTrack.branches.splice(j, 1);
						break; // should only be one instance of this track in the other track's branch list.
					}
				}
			}
			
			branches.length = 0;
		}
		
		private function updateOnMap(evt:amUpdateEvent):void
		{
			if ( freezeUpdate )  return;
			
			_length = _end.distanceTo(_start);
			lineRep.setByCopy(start, end);
			
			if ( _map )
			{
				_map.updateTrackBranches(this);
			}
			
			var event:tdTrackEvent = td_cachedEvents.TRACK_EVENT;
			event.type = tdTrackEvent.TRACK_MOVED;
			event._track = this;
			event._map = _map;
			this.dispatchEvent(event);
		}
		
		public function get map():tdMap
			{  return _map;  }
		td_friend var _map:tdMap;
		
		public function get length():Number
			{  return _length;  }
		private var _length:Number = 0;
		
		public override function clone(deep:Boolean = true):qb2Object
		{
			var newTrack:tdTrack = super.clone(deep) as tdTrack;
			newTrack.start.copy(this.start);
			newTrack.end.copy(this.end);
			newTrack.speedLimit = this.speedLimit;
			newTrack.width = this.width;
			
			return newTrack;
		}
		
		public function get asLine():amLine2d
			{  return lineRep.clone() as amLine2d;  }
		
		public function set(newStart:amPoint2d, newEnd:amPoint2d):void
		{
			freezeUpdate = true;
				start = newStart;
				end = newEnd;
			freezeUpdate = false;
			
			updateOnMap(null);
		}
		
		public function set start(aPoint:amPoint2d):void
		{
			if ( _start )  _start.removeEventListener(amUpdateEvent.ENTITY_UPDATED, updateOnMap);
			_start = aPoint;
			_start.addEventListener(amUpdateEvent.ENTITY_UPDATED, updateOnMap, null, true);
			
			updateOnMap(null);
		}
		public function get start():amPoint2d
			{  return _start;  }
		private var _start:amPoint2d;
		
		public function set end(aPoint:amPoint2d):void
		{
			if ( _end )  _end.removeEventListener(amUpdateEvent.ENTITY_UPDATED, updateOnMap);
			_end = aPoint;
			_end.addEventListener(amUpdateEvent.ENTITY_UPDATED, updateOnMap, null, true);
			
			updateOnMap(null);
		}
		public function get end():amPoint2d
			{  return _end;  }
		private var _end:amPoint2d;
			
			
		public function scaleBy(xValue:Number, yValue:Number, origin:amPoint2d = null):tdTrack
		{
			freezeUpdate = true;
				_start.scaleBy(xValue, yValue, origin);
				_end.scaleBy(xValue, yValue, origin);
			freezeUpdate = false;
			
			updateOnMap(null);
			return this;
		}
		
		public function rotateBy(radians:Number, origin:amPoint2d = null):tdTrack
		{
			freezeUpdate = true;
				_start.rotateBy(radians, origin)
				_end.rotateBy(radians, origin);
			freezeUpdate = false;
			
			updateOnMap(null);
			return this;
		}
		
		public function translateBy(vector:amVector2d):tdTrack
		{
			freezeUpdate = true;
				_start.translateBy(vector);
				_end.translateBy(vector);
			freezeUpdate = false;
			
			updateOnMap(null);
			return this;
		}
		
		/*public function transformBy(matrix:amMatrix2d):tdTrack
		{
			freezeUpdate = true;
				_start.transformBy(matrix);
				_end.transformBy(matrix);
			freezeUpdate = false;
			
			updateOnMap();
			return this;
		}*/
		
		public function mirror(across:amLine2d):tdTrack
		{
			freezeUpdate = true;
				_start.mirror(across);
				_end.mirror(across);
			freezeUpdate = false;
			
			updateOnMap(null);
			return this;
		}

		public function flip():tdTrack
		{
			//--- Don't need to freeze the update here because the actual x/y variables of the points aren't being changed.
			var temp:amPoint2d = _start;
			_start = _end;
			_end = temp;
			
			updateOnMap(null);
			
			return this;
		}
		
		public override function draw(graphics:srGraphics2d):void
		{
			//lineRep.asVector().draw(graphics, lineRep.getStartPoint(), 0, td_debugDrawSettings.trackArrowSize, 1);
		}
		
		public override function drawDebug(graphics:srGraphics2d):void
		{
			if ( !(td_debugDrawSettings.flags & td_debugDrawFlags.TRACKS) )
				return;
				
			graphics.setLineStyle(td_debugDrawSettings.trackThickness, td_debugDrawSettings.trackColor, qb2_debugDrawSettings.outlineAlpha);
			draw(graphics);
		}
	}
}