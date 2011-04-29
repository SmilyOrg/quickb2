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
	import As3Math.geo2d.*;
	import Box2DAS.Common.*;
	import Box2DAS.Dynamics.Joints.*;
	import flash.display.*;
	import QuickB2.*;
	import QuickB2.debugging.*;
	import QuickB2.debugging.logging.qb2_toString;
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
	public class qb2WeldJoint extends qb2Joint
	{
		public function qb2WeldJoint(initObject1:qb2IRigidObject = null, initObject2:qb2IRigidObject = null, initWorldAnchor:amPoint2d = null) 
		{
			hasOneWorldPoint = true;
			
			object1 = initObject1;
			object2 = initObject2;
			
			setWorldAnchor(initWorldAnchor ? initWorldAnchor : initWorldPoint(object1));
		}
		
		public function get referenceAngle():Number
			{  return getProperty(qb2_props.REFERENCE_ANGLE) as Number;  }
		public function set referenceAngle(value:Number):void
			{  setProperty(qb2_props.REFERENCE_ANGLE, value);  }
			
		protected override function propertyChanged(propertyName:String):void
		{
			if ( !jointB2 )  return;
			
			var value:Number = _propertyMap[propertyName];
			
			if ( propertyName == qb2_props.REFERENCE_ANGLE )
			{
				joint.m_referenceAngle = this.referenceAngle;
				wakeUpAttached();
			}
		}
		
		public function get localAnchor1():amPoint2d
			{  return _localAnchor1;  }
		public function set localAnchor1(newPoint:amPoint2d):void
			{  setLocalAnchor1(newPoint);  }
		
		public function get localAnchor2():amPoint2d
			{  return _localAnchor2;  }
		public function set localAnchor2(newPoint:amPoint2d):void
			{  setLocalAnchor2(newPoint);  }
		
		public function getWorldAnchor():amPoint2d
		{
			var world1:amPoint2d = _object1 ? (_object1 as qb2Tangible).getWorldPoint(_localAnchor1) : _localAnchor1.clone();
			var world2:amPoint2d = _object2 ? (_object2 as qb2Tangible).getWorldPoint(_localAnchor2) : _localAnchor2.clone();
			return world1.midwayPoint(world2);
		}
		
		public function setWorldAnchor(worldAnchor:amPoint2d):void
		{
			localAnchor1 = _object1 ? (_object1 as qb2Tangible).getLocalPoint(worldAnchor) : worldAnchor.clone();
			localAnchor2 = _object2 ? (_object2 as qb2Tangible).getLocalPoint(worldAnchor) : worldAnchor.clone();
		}
		
		qb2_friend override function anchorUpdated(point:amPoint2d):void
		{
			correctLocals();
			wakeUpAttached();
		}
		
		qb2_friend override function correctLocals():void
		{
			if ( jointB2 )
			{
				var conversion:Number = worldPixelsPerMeter;
				var corrected1:amPoint2d = getCorrectedLocal1(conversion, conversion);
				var corrected2:amPoint2d = getCorrectedLocal2(conversion, conversion);
				
				joint.m_localAnchorA.x = corrected1.x;
				joint.m_localAnchorA.y = corrected1.y;
				joint.m_localAnchorB.x = corrected2.x;
				joint.m_localAnchorB.y = corrected2.y;
			}
		}
		
		public function get object1():qb2IRigidObject
			{  return _object1 as qb2IRigidObject;   }
		public function set object1(newObject:qb2IRigidObject):void
			{  setObject1(newObject);  }
		
		public function get object2():qb2IRigidObject
			{  return _object2 as qb2IRigidObject;  }
		public function set object2(newObject:qb2IRigidObject):void
			{  setObject2(newObject);  }
		
		qb2_friend override function objectsUpdated():void
		{
			if ( _object1 && _object2 )
				referenceAngle = _object2._rigidImp._rotation - _object1._rigidImp._rotation;
		}
		
		qb2_friend override function make(theWorld:qb2World):void
		{
			var conversion:Number = theWorld.pixelsPerMeter;
			var corrected1:amPoint2d    = getCorrectedLocal1(conversion, conversion);
			var corrected2:amPoint2d    = getCorrectedLocal2(conversion, conversion);
			
			var weldJointDef:b2WeldJointDef = b2Def.weldJoint;
			weldJointDef.localAnchorA.x   = corrected1.x;
			weldJointDef.localAnchorA.y   = corrected1.y;
			weldJointDef.localAnchorB.x   = corrected2.x;
			weldJointDef.localAnchorB.y   = corrected2.y;
			weldJointDef.referenceAngle = this.referenceAngle;
			
			jointDef = weldJointDef;
			
			super.make(theWorld);
		}
		
		private function get joint():b2WeldJoint
			{  return jointB2 ? jointB2 as b2WeldJoint : null;  }
			
		public override function clone(deep:Boolean = true):qb2Object
		{
			var weldJoint:qb2WeldJoint = super.clone(deep) as qb2WeldJoint;
			
			weldJoint._localAnchor1._x = this._localAnchor1._x;
			weldJoint._localAnchor1._y = this._localAnchor1._y;
			
			weldJoint._localAnchor2._x = this._localAnchor2._x;
			weldJoint._localAnchor2._y = this._localAnchor2._y;
			
			return weldJoint;
		}
		
		public static var crossDrawRadius:Number = anchorDrawRadius * 3;
		
		public override function draw(graphics:srGraphics2d):void
		{
			var worldPoints:Vector.<V2> = drawAnchors(graphics);
			
			if ( !worldPoints )   return;
			
			graphics.endFill();
			
			var world1:amPoint2d = reusableDrawPoint.set(worldPoints[0].x, worldPoints[0].y);
			var vec:amVector2d = new amVector2d(1, 1);
			vec.setLength(crossDrawRadius);
			
			world1.translateBy(vec);
			graphics.moveTo(world1.x, world1.y);
			world1.translateBy(vec.negate().scaleBy(2));
			graphics.lineTo(world1.x, world1.y);
			world1.translateBy(vec.negate().scaleBy(.5)).translateBy(vec.setToPerpVector());
			graphics.moveTo(world1.x, world1.y);
			world1.translateBy(vec.negate().scaleBy(2));
			graphics.lineTo(world1.x, world1.y);
		}
		
		qb2_friend override function getWorldAnchors():Vector.<V2>
		{
			reusableV2.xy(joint.m_localAnchorA.x, joint.m_localAnchorA.y);
			var anch1:V2 = joint.m_bodyA.GetWorldPoint(reusableV2);
			reusableV2.xy(joint.m_localAnchorB.x, joint.m_localAnchorB.y);
			var anch2:V2 = joint.m_bodyB.GetWorldPoint(reusableV2);
			anch1.multiplyN(worldPixelsPerMeter);
			anch2.multiplyN(worldPixelsPerMeter);
			
			var vecX:Number = (anch2.x - anch1.x) / 2;
			var vecY:Number = (anch2.y - anch1.y) / 2;
			anch1.x += vecX;
			anch1.y += vecY;
			
			return Vector.<V2>([anch1]);
		}
		
		public override function toString():String 
			{  return qb2_toString(this, "qb2WeldJoint");  }
	}
}