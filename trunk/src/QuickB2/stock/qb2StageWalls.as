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
	import As3Math.general.*;
	import As3Math.geo2d.*;
	import flash.display.*;
	import flash.events.*;
	import QuickB2.debugging.*;
	import QuickB2.debugging.logging.qb2_toString;
	import QuickB2.misc.*;
	import QuickB2.objects.tangibles.*;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2StageWalls extends qb2Group
	{
		private var _leftWall:qb2FollowBody, _rightWall:qb2FollowBody, _upperWall:qb2FollowBody, _lowerWall:qb2FollowBody;
		
		private const _upperLeft:amPoint2d = new amPoint2d();
		private var _stageWidth:Number;
		private var _stageHeight:Number;
		
		private var _wallThickness:Number;
		private var _overhang:Number;
		private var _minWidth:Number;
		private var _maxWidth:Number;
		private var _minHeight:Number;
		private var _maxHeight:Number;
		
		public var instantResize:Boolean = false;
		
		public function qb2StageWalls(stage:Stage, wallThickness:Number = 500, overhang:Number = 0, minWidth:Number = 300, maxWidth:Number = 2000, minHeight:Number = 300, maxHeight:Number = 2000, setStageProps:Boolean = true) 
		{
			_stage = stage;
			_stage.addEventListener(Event.RESIZE, stageEvent);
			
			_wallThickness = wallThickness;
			_overhang = overhang;
			_minWidth = minWidth;
			_maxWidth = maxWidth;
			_minHeight = minHeight;
			_maxHeight = maxHeight;
			
			addObject(_upperWall = makeWall(_maxWidth, _wallThickness ));
			addObject(_lowerWall = makeWall(_maxWidth, _wallThickness ));
			addObject(_leftWall  = makeWall(_wallThickness, _maxHeight));
			addObject(_rightWall = makeWall(_wallThickness, _maxHeight));
			
			if ( setStageProps )
			{
				_stage.align     = StageAlign.TOP_LEFT;
				_stage.scaleMode = StageScaleMode.NO_SCALE;
			}
			
			turnFlagOff(qb2_flags.JOINS_IN_DEBUG_DRAWING);
			
			stageEvent(null);
		}
		
		private var firstResize:Boolean = true;
		
		private function stageEvent(evt:Event):void
		{
			_stageWidth = amUtils.constrain(_stage.stageWidth, _minWidth, _maxWidth);
			_stageHeight = amUtils.constrain(_stage.stageHeight, _minHeight, _maxHeight);
		
			_upperLeft.set(_stage.x, _stage.y);
			
			_leftWall.targetPoint.x = _upperLeft.x - _wallThickness / 2 + _overhang;
			_leftWall.targetPoint.y = _upperLeft.y + _stageHeight / 2;
			if ( instantResize || firstResize)  _leftWall.position.copy(_leftWall.targetPoint);
			
			_rightWall.targetPoint.x = _upperLeft.x + _stageWidth + _wallThickness / 2 - _overhang;
			_rightWall.targetPoint.y = _upperLeft.y + _stageHeight / 2;
			if ( instantResize || firstResize )  _rightWall.position.copy(_rightWall.targetPoint);
			
			_upperWall.targetPoint.x = _upperLeft.x + _stageWidth / 2;
			_upperWall.targetPoint.y = _upperLeft.y - _wallThickness / 2 + _overhang;
			if ( instantResize || firstResize )  _upperWall.position.copy(_upperWall.targetPoint);
			
			_lowerWall.targetPoint.x = _upperLeft.x + _stageWidth / 2;
			_lowerWall.targetPoint.y = _upperLeft.y +_stageHeight + _wallThickness / 2 - _overhang;
			if ( instantResize || firstResize )  _lowerWall.position.copy(_lowerWall.targetPoint);
			
			firstResize = false;
		}
		
		private static function makeWall(width:Number, height:Number):qb2FollowBody
		{
			var body:qb2FollowBody = new qb2FollowBody();
			body.addObject(qb2Stock.newRectShape(new amPoint2d(), width, height));
			return body;
		}
		
		private function get stage():Stage
			{  return _stage;  }
		private var _stage:Stage;
		
		public override function toString():String 
			{  return qb2_toString(this, "qb2StageWalls");  }
	}
}