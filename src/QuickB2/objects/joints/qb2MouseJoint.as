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

package QuickB2.objects.joints
{
	import As3Math.*;
	import As3Math.general.*;
	import As3Math.geo2d.*;
	import Box2DAS.Common.*;
	import Box2DAS.Dynamics.Joints.*;
	import flash.display.*;
	import QuickB2.*;
	import QuickB2.debugging.*;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	import surrender.srGraphics2d;
	
	use namespace am_friend;
	use namespace qb2_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2MouseJoint extends qb2Joint
	{
		private var _worldTarget:amPoint2d = null;
	
		public function qb2MouseJoint(initObject:qb2IRigidObject = null, initWorldAnchor:amPoint2d = null) 
		{
			setProperty(qb2_props.MAX_FORCE,    100.0, false);
			setProperty(qb2_props.FREQUENCY_HZ,   5.0, false);
			setProperty(qb2_props.DAMPING_RATIO,  0.7, false);
			
			requiresTwoRigids = false;
			hasOneWorldPoint = true;
			
			object = initObject;
			
			worldTarget = new amPoint2d();
			
			setWorldAnchor(initWorldAnchor ? initWorldAnchor : initWorldPoint(initObject));
		}
		
		public function get localAnchor():amPoint2d
			{  return _localAnchor2;  }
		public function set localAnchor(newPoint:amPoint2d):void
			{  setLocalAnchor2(newPoint);  }
		
		public function get worldTarget():amPoint2d
			{  return _worldTarget;  }
		public function set worldTarget(newPoint:amPoint2d):void
		{
			if ( _worldTarget )  _worldTarget.removeEventListener(amUpdateEvent.ENTITY_UPDATED, entityEventFired);
			_worldTarget = newPoint;
			_worldTarget.addEventListener(amUpdateEvent.ENTITY_UPDATED, entityEventFired, null, true);
			anchorUpdated(_worldTarget);
		}
		
		public function getWorldAnchor():amPoint2d
		{
			return _object2 ? (_object2 as qb2Tangible).getWorldPoint(_localAnchor2) : _localAnchor2.clone();
		}
		
		public function setWorldAnchor(worldAnchor:amPoint2d):void
		{
			localAnchor = _object2 ? _object2.getLocalPoint(worldAnchor) : worldAnchor.clone();
		}
		
		qb2_friend override function anchorUpdated(point:amPoint2d):void
		{
			if ( jointB2 )
			{
				if ( point == _localAnchor2 )
				{
					correctLocals();
				}
				else
				{
					var conversion:Number = worldPixelsPerMeter;
					var pntB2:V2 = new V2(_worldTarget.x / conversion, _worldTarget.y / conversion);
					joint.SetTarget(pntB2);
				}
				
				wakeUpAttached();
			}
		}
		
		qb2_friend override function correctLocals():void
		{
			if ( jointB2 )
			{
				var corrected:amPoint2d = getCorrectedLocal2(worldPixelsPerMeter, worldPixelsPerMeter);
				
				joint.m_localAnchor.x = corrected.x;
				joint.m_localAnchor.y = corrected.y;
			}
		}
		
		public function get frequencyHz():Number
			{  return getProperty(qb2_props.FREQUENCY_HZ) as Number;  }
		public function set frequencyHz(value:Number):void
			{  setProperty(qb2_props.FREQUENCY_HZ, value);  }
			
		public function get dampingRatio():Number
			{  return getProperty(qb2_props.DAMPING_RATIO) as Number;  }
		public function set dampingRatio(value:Number):void
			{  setProperty(qb2_props.DAMPING_RATIO, value);  }
			
		public function get maxForce():Number
			{  return getProperty(qb2_props.MAX_FORCE) as Number;  }
		public function set maxForce(value:Number):void
			{  setProperty(qb2_props.MAX_FORCE, value);  }
			
		protected override function propertyChanged(propertyName:String):void
		{
			if ( !jointB2 )  return;
			
			var value:Number = _propertyMap[propertyName];
			
			if ( propertyName == qb2_props.MAX_FORCE )
			{
				joint.SetMaxForce(value);
			}
			else if ( propertyName == qb2_props.DAMPING_RATIO )
			{
				joint.SetDampingRatio(value);
			}
			else if ( propertyName == qb2_props.FREQUENCY_HZ )
			{
				joint.SetFrequency(value);
			}
		}
		
		public function get object():qb2IRigidObject
			{  return _object2 as qb2IRigidObject;   }
		public function set object(newObject:qb2IRigidObject):void
			{  setObject2(newObject);  }
		
		qb2_friend override function make(theWorld:qb2World):void
		{
			var conversion:Number = theWorld.pixelsPerMeter;
			
			var mouseJointDef:b2MouseJointDef = b2Def.mouseJoint;
			var worldTargetPnt:amPoint2d = _object2.getWorldPoint(_localAnchor2);
			mouseJointDef.target.x = worldTargetPnt.x / conversion;
			mouseJointDef.target.y = worldTargetPnt.y / conversion;
			mouseJointDef.frequencyHz = frequencyHz;
			mouseJointDef.dampingRatio = dampingRatio;
			mouseJointDef.maxForce = maxForce;
			
			jointDef = mouseJointDef;
			_object1 = theWorld.background;  // Box2d requires another b2Body for this joint for some insane reason, so temporarily set this just to the background
			
			super.make(theWorld);
	
			joint.m_target.x = _worldTarget.x / theWorld.pixelsPerMeter;
			joint.m_target.y = _worldTarget.y / theWorld.pixelsPerMeter;
			
			_object1 = null;
		}
		
		private function get joint():b2MouseJoint
			{  return jointB2 ? jointB2 as b2MouseJoint : null;  }
			
		public override function clone(deep:Boolean = true):qb2Object
		{
			var mouseJoint:qb2MouseJoint = super.clone(deep) as qb2MouseJoint;
			
			mouseJoint._localAnchor2._x = this._localAnchor2._x;
			mouseJoint._localAnchor2._y = this._localAnchor2._y;
			
			return mouseJoint;
		}
		
		public static var arrowDrawSize:Number = 8;
		
		public override function draw(graphics:srGraphics2d):void
		{
			var worldPoints:Vector.<V2> = drawAnchors(graphics);
			
			graphics.endFill();
			
			if ( !worldPoints )   return;
			
			var world1:amPoint2d = reusableDrawPoint.set(worldPoints[0].x, worldPoints[0].y);
			
			var diff:amVector2d = worldTarget.minus(world1);
			
			if ( diff.lengthSquared > 1 ) // Not checking for this causes some glitchy graphics.
			{
				diff.draw(graphics, world1, 0, arrowDrawSize);
			}
		}
		
		qb2_friend override function getWorldAnchors():Vector.<V2>
		{
			reusableV2.xy(joint.m_localAnchor.x, joint.m_localAnchor.y);
			var anch1:V2 = joint.m_bodyB.GetWorldPoint(reusableV2);
			anch1.multiplyN(worldPixelsPerMeter);
			
			return Vector.<V2>([anch1]);
		}
		
		public override function toString():String 
			{  return qb2DebugTraceUtils.formatToString(this, "qb2MouseJoint");  }
	}
}