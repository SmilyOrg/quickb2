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

package QuickB2.objects.tangibles
{
	import As3Math.geo2d.*;
	import flash.display.*;
	import QuickB2.*;
	import QuickB2.debugging.*;
	import QuickB2.debugging.logging.qb2_toString;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	
	use namespace qb2_friend;
	
	[Event(name="subPreSolve",       type="QuickB2.events.qb2SubContactEvent")]
	[Event(name="subPostSolve",      type="QuickB2.events.qb2SubContactEvent")]
	[Event(name="subContactStarted", type="QuickB2.events.qb2SubContactEvent")]
	[Event(name="subContactEnded",   type="QuickB2.events.qb2SubContactEvent")]

	/** The qb2Group class provides a convenient way to treat a bunch of objects as one.  For example, you might put all the walls in a level into one group,
	 * so that you can easily set all their properties.  You might even have a whole level as one group; this way, swapping levels is a snap.  Another use is for when an object,
	 * for example a ragdoll, cannot be built with just one rigid body, but requires multiples bodies attached with joints.  Nesting groups is also possible, like if you wanted
	 * to have a ragdoll's arms be a subgroup of the ragdoll itself.
	 * 
	 * @author Doug Koellmer
	 */
	public class qb2Group extends qb2ObjectContainer
	{
		public var killBox:qb2KillBox;
		
		public function qb2Group() 
		{
		}

		/*protected override function baseClone(newObject:qb2Tangible, actorToo:Boolean, deep:Boolean):qb2Tangible
		{
			if ( !newObject || newObject && !(newObject is qb2Group) )
				throw new Error("newObject must be a type of qb2Group.");
				
			var newGroup:qb2Group = newObject as qb2Group;
			newGroup.copyProps(this);

			if ( deep )
			{
				var propertyFlushAlreadyCancelled:Boolean = cancelPropertyFlush;
				cancelPropertyFlush = true;
				{
					var objDict:Dictionary = new Dictionary(true);
					var foundJoints:Vector.<qb2Joint> = new Vector.<qb2Joint>();
					for ( var i:int = 0; i < _objects.length; i++)
					{
						if ( _objects[i] is qb2Tangible )
						{
							var clonedObj:qb2Tangible = (_objects[i] as qb2Tangible).clone(actorToo, deep);
							objDict[_objects[i]] = clonedObj;
							newGroup.addObject(clonedObj);
						}
						else if ( _objects[i] is qb2Joint )
						{
							foundJoints.push(_objects[i] as qb2Joint)
						}
					}
					
					for ( i = 0; i < foundJoints.length; i++ )
					{
						var clonedObject1:qb2IRigidObject = objDict[foundJoints[i]._object1] as qb2IRigidObject;
						var clonedObject2:qb2IRigidObject = objDict[foundJoints[i]._object2] as qb2IRigidObject;
						
						if ( clonedObject1 && clonedObject2 )
						{						
							var clonedJoint:qb2Joint = foundJoints[i].internalClone(clonedObject1, clonedObject2);
							newGroup.addObject(clonedJoint);
						}
					}
					
					for ( i = 0; i < _objects.length; i++ )
					{
						if ( objDict[_objects[i]] )
							delete objDict[_objects[i]];
					}
				}
				cancelPropertyFlush = propertyFlushAlreadyCancelled; // if the property flush was already cancelled, presumably by a deep clone of some ancestor, then the cancelled property flush should remain in effect.
			}
			
			if ( actorToo && actor )
			{
				newGroup.actor = cloneActor();
			}
			
			return newGroup;
		}*/
		
		private function allOutsideBox(box:amBoundBox2d):Boolean
		{
			for (var i:int = 0; i < this.numObjects; i++) 
			{
				var ith:qb2Object = this.getObjectAt(i);
				if ( ith is qb2IRigidObject )
				{
					if ( box.containsPoint((ith as qb2IRigidObject).position ) )
						return false;
				}
				else if ( ith is qb2Group )
				{
					if ( !(ith as qb2Group).allOutsideBox(box) )
						return false;
				}
			}
			
			return true;
		}
		
		protected override function update():void
		{
			// NOTE qb2Group doesn't call super.update() (for qb2Tangible) since it only applies effects, which are applied implicitly with the effects stack.
			
			//--- Cache these for slight speed boost.
			if ( killBox )
			{
				const POSITION_LEAVES:uint        = qb2KillBox.POSITION_LEAVES;
				const CENTROID_LEAVES:uint        = qb2KillBox.CENTROID_LEAVES;;
				const BOUND_BOX_LEAVES:uint       = qb2KillBox.BOUND_BOX_LEAVES;
				const GEOMETRY_LEAVES:uint        = qb2KillBox.GEOMETRY_LEAVES;
				const ACTOR_POSITION_LEAVES:uint  = qb2KillBox.ACTOR_POSITION_LEAVES;
				const ACTOR_BOUND_BOX_LEAVES:uint = qb2KillBox.ACTOR_BOUND_BOX_LEAVES;
			}
			
			var numToPop:int = pushToEffectsStack();
			
			var updateLoopBit:uint = qb2_flags.JOINS_IN_UPDATE_CHAIN;
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				var object:qb2Object = _objects[i];
				
				if ( !(object._flags & updateLoopBit) )  continue;
				
				object.relay_update(); // You can't call update directly because it's protected.
				
				/*if ( drawingDebug )
				{
					if ( !(object is qb2Group) )
					{
						if ( object.drawsDebug )
						{
							object.drawDebug(context);
						}
					}
					
					if ( object is qb2Tangible )
					{
						if ( object is qb2Tangible )
						{
							(object as qb2Tangible).drawDebugExtras(context);
						}
					}
				}*/
				
				if( object is qb2Tangible )
				{
					var tang:qb2Tangible = object as qb2Tangible;
					
					if ( killBox && (killBox.ignoreStatics && tang._mass || !killBox.ignoreStatics) )
					{
						if ( killBox.conditionFlag & POSITION_LEAVES )
						{
							if ( tang is qb2IRigidObject )
							{
								if ( !killBox.containsPoint(tang._rigidImp._position) )
								{
									removeObjectAt(i--);
									continue;
								}
							}
							else if ( tang is qb2Group )
							{
								var asGroup:qb2Group = tang as qb2Group;
								if ( asGroup.allOutsideBox(killBox) )
								{
									removeObjectAt(i--);
									continue;
								}
							}
						}
						if ( killBox.conditionFlag & ACTOR_POSITION_LEAVES )
						{
							if ( tang._actor )
							{
								if ( !killBox.containsPoint(tang._actor.getPosition()) )
								{
									removeObjectAt(i--);
									continue;
								}
							}
						}
						if ( killBox.conditionFlag & CENTROID_LEAVES )
						{
							if ( !killBox.containsPoint(tang.centerOfMass) )
							{
								removeObjectAt(i--);
								continue;
							}
						}
						
						/*if ( killBox.conditionFlag & BOUND_BOX_LEAVES )
						{
							if( !tang.boundBox.intersectsArea(killBox) )
								removeObjectAt(i--);
						}*/
					}
				}
			}
			
			popFromEffectsStack(numToPop);
		}
		
		public function convertToBody(registrationPoint:amPoint2d = null, preserveVelocities:Boolean = true ):qb2Body
		{
			registrationPoint = registrationPoint ? registrationPoint : this.centerOfMass;
			var diff:amVector2d = registrationPoint.asVector().negate();
			
			if ( preserveVelocities )
			{
				var avgLinear:amVector2d = this.getAvgLinearVelocity();
				var avgAngular:Number = this.getAvgAngularVelocity();
			}
			
			var oldParent:qb2ObjectContainer = this._parent;
			if ( oldParent )  removeFromParent();
			
			var body:qb2Body = new qb2Body();
			body.copyTangibleProps(this, false);
			body.position.copy(registrationPoint);
			
			var explodes:Vector.<qb2Object> = this.explode();
			
			if ( explodes )
			{
				for (var i:int = 0; i < explodes.length; i++) 
				{
					if ( explodes[i] is qb2Tangible )
					{
						var tang:qb2Tangible = explodes[i] as qb2Tangible;
						tang.translateBy(diff);
					}
				}			
				
				body.addObjects(explodes);
				
				if ( preserveVelocities )
				{
					body.linearVelocity.copy(avgLinear);
					body.angularVelocity = avgAngular
				}
			}
			
			if ( oldParent )  oldParent.addObject(body);
			
			return body;
		}

		public override function rotateBy(radians:Number, origin:amPoint2d = null):qb2Tangible
		{
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				if( _objects[i] is qb2Tangible )
					(_objects[i] as qb2Tangible).rotateBy(radians, origin);
			}
			
			return this;
		}
		
		public override function translateBy(vector:amVector2d):qb2Tangible
		{
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				if( _objects[i] is qb2Tangible )
					(_objects[i] as qb2Tangible).translateBy(vector);
			}
			
			return this;
		}
		
		//public function applyRadialImpulse(focalPoint:amPoint2d, impulse:Number = 0, radiusOfEffect:Number = Number.MAX_VALUE, dropOff:Number = 0, scaleByMasses:Boolean = false):void
	//	{
		
		public function translateRadial(focalPoint:amPoint2d, scale:Number, radiusOfEffect:Number = Number.MAX_VALUE, dropOff:Number = 0):void
		{
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				var object:qb2Object = _objects[i];
				
				if ( !(object is qb2Tangible) )  continue;
				
				var physObject:qb2Tangible = object as qb2Tangible;
				
				if ( physObject is qb2Group )
					(physObject as qb2Group ).translateRadial(focalPoint, scale, radiusOfEffect, dropOff);
				else if( physObject is qb2IRigidObject )
				{
					var rigid:qb2IRigidObject = physObject as qb2IRigidObject;
					var vec:amVector2d = rigid.position.minus(focalPoint);
					var vecLength:Number = vec.length;
					if ( vecLength > radiusOfEffect || vecLength == 0 )  continue;
					
					var ratio:Number = 1 - (vecLength / radiusOfEffect) * dropOff;
					
					vec.normalize().scaleBy(scale * ratio);
					
					physObject.translateBy(vec);
				}
			}
		}
			
		public override function get isSleeping():Boolean
		{
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				if ( _objects[i] is qb2Tangible )
				{
					if ( !(_objects[i] as qb2Tangible).isSleeping )  return false;
				}
			}
			
			return true;
		}
			
		public function getAvgLinearVelocity():amVector2d
		{
			var avg:amVector2d;
			
			if ( !_objects.length )  return avg;
		
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				var object:qb2Object = _objects[i];
				
				if ( !(object is qb2Tangible) )  continue;
				
				var physObject:qb2Tangible = object as qb2Tangible;
				
				if ( !avg )  avg = new amVector2d();
				
				var vel:amVector2d = physObject is qb2IRigidObject ? (physObject as qb2IRigidObject).linearVelocity : (physObject as qb2Group).getAvgLinearVelocity();
				avg.x += vel.x;
				avg.y += vel.y;
			}
			
			if ( avg )
			{
				avg.x /= _objects.length;
				avg.y /= _objects.length;
			}
			
			return avg;
		}
		
		public function setAvgLinearVelocity(vector:amVector2d):void
		{
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				if( _objects[i] is qb2IRigidObject )
					(_objects[i] as qb2IRigidObject).linearVelocity.copy(vector);
				else if( _objects[i] is qb2Group )
					(_objects[i] as qb2Group).setAvgLinearVelocity(vector);
			}
		}
			
		public function getAvgAngularVelocity():Number
		{
			var avg:Number = 0;
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				if ( !(_objects[i] is qb2Tangible) )  continue;
				
				var physObject:qb2Tangible = _objects[i] as qb2Tangible;
				
				avg += physObject is qb2IRigidObject ? (physObject as qb2IRigidObject).angularVelocity : (physObject as qb2Group).getAvgAngularVelocity();
			}
			
			if ( _objects.length )  avg /= _objects.length;
			
			return avg;
		}
		
		public function setAvgAngularVelocity(radsPerSec:Number):void
		{
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				if( _objects[i] is qb2IRigidObject )
					(_objects[i] as qb2IRigidObject).angularVelocity = radsPerSec;
				else if( _objects[i] is qb2Group )
					(_objects[i] as qb2Group).setAvgAngularVelocity(radsPerSec);
			}
		}
			
		public override function applyImpulse(atPoint:amPoint2d, impulseVector:amVector2d):void
		{
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				if ( _objects[i] is qb2Tangible )
					(_objects[i] as qb2Tangible).applyImpulse(atPoint, impulseVector);
			}
		}
		
		public override function applyForce(atPoint:amPoint2d, forceVector:amVector2d):void
		{
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				if ( _objects[i] is qb2Tangible )
					(_objects[i] as qb2Tangible).applyForce(atPoint, forceVector);
			}
		}
		
		public override function applyTorque(torque:Number):void
		{
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				if ( _objects[i] is qb2Tangible )
					(_objects[i] as qb2Tangible).applyTorque(torque);
			}
		}
			
		public function applyRadialImpulse(focalPoint:amPoint2d, impulse:Number = 0, radiusOfEffect:Number = Number.MAX_VALUE, dropOff:Number = 0, angularOffset:Number = 0, scaleByMasses:Boolean = false):void
		{			
			applyRadial(true, focalPoint, impulse, radiusOfEffect, dropOff, angularOffset, scaleByMasses);
		}
		
		public function applyRadialForce(focalPoint:amPoint2d, force:Number, radiusOfEffect:Number = Number.MAX_VALUE, dropOff:Number = 0, angularOffset:Number = 0, scaleByMasses:Boolean = false):void
		{
			applyRadial(false , focalPoint, force, radiusOfEffect, dropOff, angularOffset, scaleByMasses);
		}
		
		private function applyRadial(impulse:Boolean, focalPoint:amPoint2d, scalar:Number = 0, radiusOfEffect:Number = Number.MAX_VALUE, dropOff:Number = 0, angularOffset:Number = 0, scaleByMasses:Boolean = false):void
		{
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				var object:qb2Object = _objects[i];
				
				if ( !(object is qb2Tangible) )  continue;
				
				var physObject:qb2Tangible = object as qb2Tangible;
				
				if ( physObject is qb2Group )
				{
					(physObject as qb2Group).applyRadial(impulse, focalPoint, scalar, radiusOfEffect, dropOff, angularOffset, scaleByMasses);
				}
				else
				{
					var centroid:amPoint2d = physObject.centerOfMass;
					var vec:amVector2d = centroid.minus(focalPoint);
					var vecLength:Number = vec.length;
					if ( vecLength > radiusOfEffect || vecLength == 0 )  continue;
					vec.rotateBy(angularOffset);
					
					var ratio:Number = 1 - (vecLength / radiusOfEffect) * dropOff;
					var thisScalar:Number = scalar * ratio;
					if ( scaleByMasses )  thisScalar *= physObject.mass;
					
					vec.normalize().scaleBy(thisScalar);
					
					impulse ? physObject.applyImpulse(centroid, vec) : physObject.applyForce(centroid, vec);
				}
			}
		}
			
		public function applyUniformImpulse(impulseVector:amVector2d, scaleByMasses:Boolean = false):void
		{		
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				var object:qb2Object = _objects[i];
				
				if ( !(object is qb2Tangible) )  continue;
				
				var physObject:qb2Tangible = object as qb2Tangible;
				
				if ( physObject is qb2Group )
					( physObject as qb2Group ).applyUniformImpulse(impulseVector, scaleByMasses);
				else
				{
					var vector:amVector2d = scaleByMasses ? impulseVector.scaledBy(physObject.mass) : impulseVector;
					physObject.applyImpulse(physObject.centerOfMass, vector);
				}
			}
		}
		
		public function applyUniformForce(forceVector:amVector2d, scaleByMasses:Boolean = false):void
		{
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				var object:qb2Object = _objects[i];
				
				if ( !(object is qb2Tangible) )  continue;
				
				var physObject:qb2Tangible = object as qb2Tangible;
				
				if ( physObject is qb2Group )
					( physObject as qb2Group ).applyUniformForce(forceVector, scaleByMasses);
				else if( physObject is qb2IRigidObject )
				{
					var vector:amVector2d = scaleByMasses ? forceVector.scaledBy(physObject.mass) : forceVector;
					physObject.applyForce(physObject.centerOfMass, vector);
				}
			}
		}
		
		public function applyUniformTorque(torque:Number, scaleByMasses:Boolean = false):void
		{
			if ( !_objects.length )  return;
			
			var thisCentroid:amPoint2d = this.centerOfMass;
			var queue:Vector.<qb2Object> = new Vector.<qb2Object>();
			queue.unshift(this);
			
			while ( queue.length )
			{
				var object:qb2Object = queue.shift();
				
				if ( !(object is qb2Tangible) )  continue;
				
				var physObject:qb2Tangible = object as qb2Tangible;
				
				if ( physObject is qb2Group )
				{
					var container:qb2Group = physObject as qb2Group;
					for ( var i:int = 0; i < container.numObjects; i++ )
					{
						queue.push(container.getObjectAt(i));
					}
				}
				else if ( physObject is qb2IRigidObject )
				{
					var tangCentroid:amPoint2d = physObject.centerOfMass;
					var tangent:amVector2d = tangCentroid.minus(thisCentroid).normalize();
					
					tangent.rotateBy( Math.PI / 2);
					var force:Number = torque / tangCentroid.distanceTo(thisCentroid);
					
					tangent = scaleByMasses ? tangent.scaleBy(force * physObject.mass) : tangent.scaleBy(force);
					
					physObject.applyForce(tangCentroid, tangent);
				}
			}
		}

		public override function putToSleep():void
		{
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				if ( _objects[i] is qb2Tangible )
				{
					(_objects[i] as qb2Tangible).putToSleep();
				}
			}
		}
		
		public override function wakeUp():void
		{
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				if ( _objects[i] is qb2Tangible )
				{
					(_objects[i] as qb2Tangible).wakeUp();
				}
			}
		}
		
		public override function toString():String 
			{  return qb2_toString(this, "qb2Group");  }
	}
}