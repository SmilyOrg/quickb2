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
	import As3Math.general.*;
	import As3Math.geo2d.*;
	import Box2DAS.Common.*;
	import Box2DAS.Dynamics.Joints.*;
	import flash.display.*;
	import QuickB2.*;
	import QuickB2.debugging.*;
	import QuickB2.events.*;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	import surrender.srGraphics2d;
	
	use namespace qb2_friend;

	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2Joint extends qb2Object
	{
		qb2_friend var _localAnchor1:amPoint2d = null;
		qb2_friend var _localAnchor2:amPoint2d = null;
		
		qb2_friend var jointB2:b2Joint;
		
		qb2_friend var _object1:qb2Tangible, _object2:qb2Tangible;
		
		qb2_friend var requiresTwoRigids:Boolean = true;
		qb2_friend var hasOneWorldPoint:Boolean = false;
		
		public static const anchorDrawRadius:Number = 4;
		
		qb2_friend static const MAX_SPRING_SPEED:Number = 1000000;
		
		public function qb2Joint()
		{
			if ( (this as Object).constructor == qb2Joint )  throw qb2_errors.ABSTRACT_CLASS_ERROR;
		}
		
		public function get b2_joint():b2Joint
			{  return jointB2;  }
			
		public function get reactionForce():amVector2d
		{
			if ( jointB2 )
			{
				var b2Vec:V2 = jointB2.GetReactionForce(1 / _world.lastTimeStep);
				return new amVector2d(b2Vec.x, b2Vec.y);
			}
			return null;
		}
		
		public function get reactionTorque():Number
			{  return jointB2 ? jointB2.GetReactionTorque(1 / _world.lastTimeStep) : 0;  }
		
		public function get isActive():Boolean
			{  return jointB2 ? true : false;  }
		
		private function registerObject(object:qb2Tangible):void
		{
			if ( !object._rigidImp._attachedJoints )  object._rigidImp._attachedJoints = new Vector.<qb2Joint>();
			object._rigidImp._attachedJoints.push(this);
			object.addEventListener(qb2ContainerEvent.ADDED_TO_WORLD,     addedOrRemoved, null, true);
			object.addEventListener(qb2ContainerEvent.REMOVED_FROM_WORLD, addedOrRemoved, null, true);
			
			makeWrapper(_world);
		}
		
		private function unregisterObject(object:qb2Tangible):void
		{
			var index:int = object._rigidImp._attachedJoints.indexOf(this);
			object._rigidImp._attachedJoints.splice(index, 1);
			if ( object._rigidImp._attachedJoints.length == 0 )  object._rigidImp._attachedJoints = null;
			object.removeEventListener(qb2ContainerEvent.ADDED_TO_WORLD,     addedOrRemoved);
			object.removeEventListener(qb2ContainerEvent.REMOVED_FROM_WORLD, addedOrRemoved);
			
			destroyWrapper(_world);
		}
		
		private function addedOrRemoved(evt:qb2ContainerEvent):void
		{
			if ( evt.type == qb2ContainerEvent.ADDED_TO_WORLD )
			{
				makeWrapper(_world);
			}
			else
			{
				destroyWrapper(_world);
			}
		}
		
		qb2_friend function setObject1(someObject:qb2IRigidObject, callObjectsUpdated:Boolean = true ):void
		{
			if ( _object1 )
			{
				unregisterObject(_object1 as qb2Tangible);
			}
			
			_object1 = someObject as qb2Tangible;
			
			if ( _object1 )
			{
				registerObject(_object1 as qb2Tangible);
			}
			
			if( callObjectsUpdated )
				objectsUpdated();
		}
		
		qb2_friend function setObject2(someObject:qb2IRigidObject, callObjectsUpdated:Boolean = true):void
		{
			if ( _object2 )
			{
				unregisterObject(_object2 as qb2Tangible);
			}
			
			_object2 = someObject as qb2Tangible;
			
			if ( _object2 )
			{
				registerObject(_object2 as qb2Tangible);
			}
			
			if( callObjectsUpdated )
				objectsUpdated();
		}
		
		
		qb2_friend function setLocalAnchor1(aPoint:amPoint2d):void
		{
			if ( _localAnchor1 )  _localAnchor1.removeEventListener(amUpdateEvent.ENTITY_UPDATED, entityEventFired);
			_localAnchor1 = aPoint;
			_localAnchor1.addEventListener(amUpdateEvent.ENTITY_UPDATED, entityEventFired, null, true);
			anchorUpdated(_localAnchor1);
		}
		
		qb2_friend function setLocalAnchor2(aPoint:amPoint2d):void
		{
			if ( _localAnchor2 )  _localAnchor2.removeEventListener(amUpdateEvent.ENTITY_UPDATED, entityEventFired);
			_localAnchor2 = aPoint;
			_localAnchor2.addEventListener(amUpdateEvent.ENTITY_UPDATED, entityEventFired, null, true);
			anchorUpdated(_localAnchor2);
		}
		
		qb2_friend function getCorrectedLocal1(scalingX:Number, scalingY:Number):amPoint2d
		{
			return _object1._bodyB2 ? _localAnchor1.scaledBy(1/scalingX, 1/scalingY) : _object1.getWorldPoint(_localAnchor1, _object1._ancestorBody).scaleBy(1/scalingX, 1/scalingY);
		}
		
		qb2_friend function getCorrectedLocal2(scalingX:Number, scalingY:Number):amPoint2d
		{
			return _object2._bodyB2 ? _localAnchor2.scaledBy(1/scalingX, 1/scalingY) : _object2.getWorldPoint(_localAnchor2, _object2._ancestorBody).scaleBy(1/scalingX, 1/scalingY);
		}
		
		qb2_friend virtual function correctLocals():void  {}
		
		qb2_friend function entityEventFired(evt:amUpdateEvent):void
		{
			anchorUpdated(evt.entity as amPoint2d);
		}
		
		qb2_friend function hasObjectsSet():Boolean
		{
			return requiresTwoRigids && _object1 && _object2 || !requiresTwoRigids && _object2;
		}
		
		qb2_friend virtual function objectsUpdated():void { }
		
		qb2_friend virtual function anchorUpdated(anchor:amPoint2d):void  {}
		
		public function get collideConnected():Boolean
			{  return _flags & qb2_flags.COLLIDE_CONNECTED ? true : false;  }
		public function set collideConnected(bool:Boolean):void
			{  setFlag(bool, qb2_flags.COLLIDE_CONNECTED);  }
		
		qb2_friend var jointDef:b2JointDef = null; // this is assigned in make() in subclasses, then nullified again in the base make() function.

		qb2_friend override function shouldMake():Boolean
		{
			if ( !_object2 )  return false;
			if ( _object2._ancestorBody )
			{
				if( !_object2._ancestorBody._bodyB2 )
					return false;
			}
			else if ( !_object2._bodyB2 )
			{
				return false;
			}
			
			if ( !requiresTwoRigids )  return true;
			
			if ( !_object1 )  return false;
			if ( _object1._ancestorBody )
			{
				if( !_object1._ancestorBody._bodyB2 )
					return false;
			}
			else if ( !_object1._bodyB2 )
			{
				return false;
			}
			
			if ( jointB2 ) throw new Error("WHAT JOINT IS DEFINED??!?!");
			
			return true;
		}
		
		qb2_friend override function shouldDestroy():Boolean
		{
			return jointB2 ? true : false;
		}
		
		qb2_friend override function make(theWorld:qb2World):void
		{
			jointDef.bodyA = _object1._bodyB2 ? _object1._bodyB2 : _object1._ancestorBody._bodyB2;
			jointDef.bodyB = _object2._bodyB2 ? _object2._bodyB2 : _object2._ancestorBody._bodyB2;
			jointDef.collideConnected = collideConnected;
			jointB2 = theWorld._worldB2.CreateJoint(jointDef);
			jointB2.SetUserData(this);
			jointDef = null;
			
			theWorld._totalNumJoints++;
		}
		
		qb2_friend override function destroy(theWorld:qb2World):void
		{
			theWorld._worldB2.DestroyJoint(jointB2);
			theWorld._totalNumJoints--;
			
			jointB2.SetUserData(null);
			jointB2 = null;
		}
		
		public function wakeUpAttached():void
		{
			if ( _object1 )  (_object1 as qb2Tangible).wakeUp();
			if ( _object2 )  (_object2 as qb2Tangible).wakeUp();
		}
		
		qb2_friend function flush():void
		{
			destroyWrapper(_world);
			makeWrapper(_world);
		}
		
		qb2_friend static function scaleJointAnchors(xValue:Number, yValue:Number, rigid:qb2IRigidObject):void
		{
			for (var i:int = 0; i < rigid.numAttachedJoints; i++) 
			{
				var joint:qb2Joint = rigid.getAttachedJointAt(i);
				
				if ( joint.requiresTwoRigids )
				{
					if ( joint._object1 == rigid )
					{
						joint._localAnchor1.scaleBy(xValue, yValue);
					}
					else if ( joint._object2 == rigid )
					{
						joint._localAnchor2.scaleBy(xValue, yValue);
					}
				}
				else
				{
					if ( joint._object2 == rigid )
						joint._localAnchor2.scaleBy(xValue, yValue);
				}
			}
		}
		
		/// Used by constructors and only constructors to initialize a world point given an object.
		qb2_friend static function initWorldPoint(rigid:qb2IRigidObject):amPoint2d
		{
			if ( !rigid )  return new amPoint2d();
			
			if ( rigid.parent )
				return rigid.parent.getWorldPoint(rigid.position);
			else
				return rigid.position;
		}
		
		public override function drawDebug(graphics:srGraphics2d):void
		{
			var flags:uint = qb2_debugDrawSettings.flags;
			if ( flags & qb2_debugDrawFlags.JOINTS )
			{
				graphics.setLineStyle(qb2_debugDrawSettings.jointLineThickness, qb2_debugDrawSettings.jointOutlineColor, qb2_debugDrawSettings.outlineAlpha);
					
				graphics.beginFill(qb2_debugDrawSettings.jointFillColor, qb2_debugDrawSettings.fillAlpha);
				draw(graphics);
				graphics.endFill();
			}
		}
		
		qb2_friend virtual function getWorldAnchors():Vector.<V2> { return null };
		
		protected static var reusableDrawPoint:amPoint2d = new amPoint2d();
		protected static var reusableV2:V2 = new V2();
		
		qb2_friend function drawAnchors(graphics:srGraphics2d):Vector.<V2>
		{
			var worldAnchors:Vector.<V2> = jointB2 ? getWorldAnchors() : null;
			
			if ( worldAnchors )
			{
				for (var i:int = 0; i < worldAnchors.length; i++) 
				{
					graphics.drawCircle(worldAnchors[i].x, worldAnchors[i].y, anchorDrawRadius);
				}
			}
			
			return worldAnchors;
		}
		
		public override function toString():String 
			{  return qb2DebugTraceUtils.formatToString(this, "qb2Joint");  }
	}
}