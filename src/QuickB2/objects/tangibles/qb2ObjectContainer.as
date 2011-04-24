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
	import flash.utils.*;
	import QuickB2.*;
	import QuickB2.events.*;
	import QuickB2.internals.*;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import QuickB2.objects.joints.*;
	import surrender.srGraphics2d;
	
	use namespace qb2_friend;
	
	[Event(name="addedObject",             type="QuickB2.events.qb2ContainerEvent")]
	[Event(name="removedObject",           type="QuickB2.events.qb2ContainerEvent")]
	[Event(name="descendantAddedObject",   type="QuickB2.events.qb2ContainerEvent")]
	[Event(name="descendantRemovedObject", type="QuickB2.events.qb2ContainerEvent")]
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2ObjectContainer extends qb2Tangible
	{
		qb2_friend const _objects:Vector.<qb2Object> = new Vector.<qb2Object>();
		
		public function qb2ObjectContainer() 
		{
			if ( (this as Object).constructor == qb2ObjectContainer )  throw qb2_errors.ABSTRACT_CLASS_ERROR;
		}
		
		public function isAncestorOf(possibleDescendant:qb2Object):Boolean
			{  return possibleDescendant.isDescendantOf(this);  }
			
		private static function clone_pushDictUsage():void
		{
			if ( !clone_dictUsageTracker )
			{
				clone_rigidDict = new Dictionary(false);
				clone_jointDict = new Dictionary(false);
			}
			
			clone_dictUsageTracker++;
		}
		
		private static function clone_popDictUsage():void
		{
			clone_dictUsageTracker--;
			
			if ( clone_dictUsageTracker <= 0 )
			{
				clone_jointDict = clone_rigidDict = null;
				clone_dictUsageTracker = 0;
			}
		}
		
		private static var clone_dictUsageTracker:int = 0;
		private static var clone_rigidDict:Dictionary;
		private static var clone_jointDict:Dictionary;
		
		public override function clone(deep:Boolean = true):qb2Object
		{
			var newContainer:qb2ObjectContainer = super.clone(deep) as qb2ObjectContainer;
			newContainer.removeAllObjects(); // in case the constructor adds some objects, which it generally shouldn't, but you never know.
		
			if ( deep )
			{
				var deepCloneBit:uint = qb2_flags.JOINS_IN_DEEP_CLONING;
				
				clone_pushDictUsage();
				{
					newContainer._flags |= qb2_flags.IS_DEEP_CLONING; // cancels inheritance of properties for improved performance.
					{
						var numObjects:int = _objects.length;
						for (var i:int = 0; i < numObjects; i++) 
						{
							var ithObject:qb2Object = _objects[i];
							
							if ( !(ithObject._flags & deepCloneBit) )  continue;
							
							var ithObjectClone:qb2Object = ithObject.clone(deep);
							newContainer.addObject(ithObjectClone);
							
							if ( ithObject as qb2IRigidObject )
							{
								clone_rigidDict[ithObject] = ithObjectClone;
							}
							else if ( ithObject as qb2Joint )
							{
								clone_jointDict[ithObject] = ithObjectClone;
							}
						}
					}
					newContainer._flags &= ~qb2_flags.IS_DEEP_CLONING;
					
					if ( clone_dictUsageTracker == 1 ) // (if this was the original object that got cloned...
					{					
						for ( var key:* in clone_jointDict )
						{
							var joint:qb2Joint = key as qb2Joint;
							var clonedObject1:qb2IRigidObject = clone_rigidDict[joint._object1] as qb2IRigidObject;
							var clonedObject2:qb2IRigidObject = clone_rigidDict[joint._object2] as qb2IRigidObject;
							
							var clonedJoint:qb2Joint = clone_jointDict[joint];
							
							if ( !clonedJoint._object1 && clonedObject1 )
								clonedJoint.setObject1(clonedObject1, false);
							if ( !clonedJoint._object2 && clonedObject2 )
								clonedJoint.setObject2(clonedObject2, false);
							
							if ( clonedJoint.hasObjectsSet() )
							{
								delete clone_jointDict[joint];
							}
						}
					}
				}
				clone_popDictUsage();
			}
			
			var asBody:qb2Body = newContainer as qb2Body;
			if ( newContainer as qb2Body )
			{
				asBody.setTransform(_rigidImp._position.clone(), _rigidImp._rotation);
			}
			
			return newContainer;
		}
		
		qb2_friend override function updateFrictionJoints():void
		{
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				if ( _objects[i] is qb2Tangible )
				{
					(_objects[i] as qb2Tangible).updateFrictionJoints();
				}
			}
		}
		
		private function collectAncestorFlagsAndProperties():qb2InternalPropertyAndFlagCollection
		{
			var currParent:qb2Object = this;
			var booleanFlags:uint = 0;
			var flagsTaken:uint   = 0;
			var ancestorPropertyMapStacks:Object = { };
			var CONTACT_REPORTING_FLAGS:uint = qb2_flags.CONTACT_REPORTING_FLAGS;
			
			while ( currParent )
			{
				//--- Fill in the property map with ancestor values.
				for ( var propertyName:String in currParent._propertyMap )
				{
					if ( currParent._ownershipFlagsForProperties & _propertyBits[propertyName] )
					{
						if ( ancestorPropertyMapStacks[propertyName] )  continue;
						
						ancestorPropertyMapStacks[propertyName] = [currParent._propertyMap[propertyName]];
					}
				}
				
				//--- Fill in the flags.
				var flagsOwnedByCurrParentThatAreNotYetTaken:uint = currParent._ownershipFlagsForBooleans & ~flagsTaken;
				booleanFlags |= flagsOwnedByCurrParentThatAreNotYetTaken & currParent._flags;
				flagsTaken   |= flagsOwnedByCurrParentThatAreNotYetTaken;
				
				//--- Contact reporting flags are always filled in.
				booleanFlags |= currParent._flags & ( CONTACT_REPORTING_FLAGS & currParent._ownershipFlagsForBooleans);
				
				currParent = currParent._parent;
			}
			
			flagsTaken &= ~CONTACT_REPORTING_FLAGS;
			
			var collection:qb2InternalPropertyAndFlagCollection = new qb2InternalPropertyAndFlagCollection();
			collection.booleanOwnershipFlags = flagsTaken;
			collection.booleanFlags = booleanFlags;
			collection.ancestorPropertyMapStacks = ancestorPropertyMapStacks;
			
			return collection;
		}
		
		private function addMultipleObjectsToArray(someObjects:Vector.<qb2Object>, startIndex:uint):qb2ObjectContainer
		{
			if ( !(this._flags & qb2_flags.IS_DEEP_CLONING) )
			{
				var collection:qb2InternalPropertyAndFlagCollection = this.collectAncestorFlagsAndProperties();
				var propStacks:Object          = collection.ancestorPropertyMapStacks;
				var booleanFlags:uint          = collection.booleanFlags;
				var booleanOwnerShipFlags:uint = collection.booleanOwnershipFlags;
			}
			
			var tangibleFound:Boolean = false;
		
			var totalArea:Number = 0, totalMass:Number = 0;
			for ( var i:int = 0; i < someObjects.length; i++ )
			{
				var object:qb2Object = someObjects[i];
				
				if ( object._parent )  throw qb2_errors.ALREADY_HAS_PARENT_ERROR;
				
				var tang:qb2Tangible = object as qb2Tangible;
				
				if ( tang )
				{
					if ( !tangibleFound )
					{
						pushEditSession();
						tangibleFound = true;
					}
					
					_surfaceArea += tang._surfaceArea;
					_mass        += tang._mass;
				}
				
				addObjectToArray(object, startIndex, propStacks, booleanFlags, booleanOwnerShipFlags);
				
				startIndex++;
			}
			
			if ( tangibleFound )
			{
				popEditSession();
			}
			
			return this;
		}
		
		private function addObjectToArray(object:qb2Object, index:uint, propStacks:Object, booleanFlags:uint, booleanOwnershipFlags:uint ):void
		{			
			if ( index == _objects.length )
				_objects.push(object);
			else
				_objects.splice(index, 0, object);
			
			object._parent = object._lastParent = this;
			
			var asTang:qb2Tangible = object as qb2Tangible;
			if ( asTang )
			{
				asTang.addActor();
			}
			
			walkDownTree(object, _world, this._ancestorBody ? this._ancestorBody :  ( this is qb2Body ? this as qb2Body : null), propStacks, booleanFlags, booleanOwnershipFlags, this, true);
			
			var evt:qb2ContainerEvent = qb2_cachedEvents.CONTAINER_EVENT.inUse ? new qb2ContainerEvent() : qb2_cachedEvents.CONTAINER_EVENT;
			evt.type = qb2ContainerEvent.ADDED_OBJECT;
			evt._ancestor = this;
			evt._child    = object;
			dispatchEvent(evt);
			
			processDescendantEvent(qb2ContainerEvent.DESCENDANT_ADDED_OBJECT, object);
		}
		
		private function removeObjectFromArray(index:uint):qb2Object
		{
			var objectRemoved:qb2Object = _objects.splice(index, 1)[0];
			
			pushEditSession();
			{
				var asTang:qb2Tangible = objectRemoved as qb2Tangible;
				if ( asTang )
				{
					asTang.removeActor();
					_surfaceArea -= asTang._surfaceArea;
					_mass        -= asTang._mass;
				}
				
				objectRemoved._parent = null;
				
				walkDownTree(objectRemoved, _world, null, null, 0, 0, this, false);
			}
			popEditSession();
			
			var evt:qb2ContainerEvent = qb2_cachedEvents.CONTAINER_EVENT.inUse ? new qb2ContainerEvent() : qb2_cachedEvents.CONTAINER_EVENT;
			evt.type = qb2ContainerEvent.REMOVED_OBJECT;
			evt._ancestor = this;
			evt._child    = objectRemoved;
			dispatchEvent(evt);
			
			processDescendantEvent(qb2ContainerEvent.DESCENDANT_REMOVED_OBJECT, objectRemoved);
		
			return objectRemoved;
		}
		
		private function processDescendantEvent(type:String, object:qb2Object):void
		{
			var currParent:qb2ObjectContainer = this.parent;
			
			while ( currParent )
			{
				var evt:qb2ContainerEvent = qb2_cachedEvents.CONTAINER_EVENT.inUse ? new qb2ContainerEvent() : qb2_cachedEvents.CONTAINER_EVENT;
				evt.type = type;
				evt._ancestor = this;
				evt._child    = object;
				currParent.dispatchEvent(evt);
				
				currParent = currParent.parent;
			}
		}		
		
		public function containsObject(object:qb2Object):Boolean
			{  return _objects.indexOf(object) >= 0;  }
		
		public function getObjectAt(index:uint):qb2Object
			{  return _objects[index];  }

		public function lastObject(minus:uint = 0):qb2Object
			{  return _objects[_objects.length - 1 - minus];  }
		
		public function get numObjects():uint
			{  return _objects.length;  }
			
		public function getObjectIndex(object:qb2Object):int
			{  return _objects.indexOf(object);  }
		
		public function addObjects(someObjects:Vector.<qb2Object>):qb2ObjectContainer
			{  return addMultipleObjectsToArray(someObjects, _objects.length);  }
		
		public function addObject(... oneOrMoreObjects):qb2ObjectContainer
			{  return addMultipleObjectsToArray(Vector.<qb2Object>(oneOrMoreObjects), _objects.length);  }
			
		public function addObjectAt(object:qb2Object, index:uint):qb2ObjectContainer
			{  return addMultipleObjectsToArray(Vector.<qb2Object>([object]), index);  }
			
		public function insertObjectAt(index:uint, ... oneOrMoreObjects):qb2ObjectContainer
			{  return addMultipleObjectsToArray(Vector.<qb2Object>(oneOrMoreObjects), index);  }
		
		public function setObjectAt(index:uint, replacement:qb2Object):qb2Object
		{
			//--- Remove the current shape at this index without recomputing mass yet...don't want to do it twice.
			var objectRemoved:qb2Object = _objects[index];
			
			var pushedSession:Boolean = false;
			if ( (replacement as qb2Tangible) || (objectRemoved as qb2Tangible) )
			{
				pushedSession = true;
				pushEditSession();
			}
			{
				objectRemoved = removeObjectAt(index);
				insertObjectAt(index, replacement);
				
				if ( objectRemoved as qb2Tangible )
				{
					var asTang:qb2Tangible = objectRemoved as qb2Tangible;
					_mass        -= asTang._mass;
					_surfaceArea -= asTang._surfaceArea;
				}
				
				if ( replacement as qb2Tangible )
				{
					asTang = replacement as qb2Tangible;
					_mass        += asTang._mass;
					_surfaceArea += asTang._surfaceArea;
				}
			}
			if ( pushedSession )
			{
				popEditSession();
			}
			
			return objectRemoved;
		}

		public function setObjectIndex(object:qb2Object, index:uint):qb2ObjectContainer
		{
			if ( object._parent != this )
			{
				throw qb2_errors.WRONG_PARENT;
			}
			
			var origIndex:int = _objects.indexOf(object);
			_objects.splice(origIndex, 1);
			_objects.splice(index, 0, object);
			
			if ( object is qb2Shape )
			{
				//--- Let this shape know that it needs to update its list of terrains that are beneath it.
				var asShape:qb2Shape = object as qb2Shape;
				if ( asShape.frictionJoints )
				{
					world._terrainRevisionDict[asShape] = -1;
				}
			}
			
			var event:qb2ContainerEvent = qb2_cachedEvents.CONTAINER_EVENT.inUse ? new qb2ContainerEvent() : qb2_cachedEvents.CONTAINER_EVENT;
			event.type = qb2ContainerEvent.INDEX_CHANGED;
			event._child    = object;
			event._ancestor = this;
			object.dispatchEvent(event);
			
			return this;
		}
	
		public function removeObject(object:qb2Object):qb2ObjectContainer
		{
			removeObjectAt(_objects.indexOf(object));
			return this;
		}
	
		public function removeObjectAt(index:uint):qb2Object
			{  return removeObjectFromArray(index);  }
		
		public function removeAllObjects():Vector.<qb2Object>
		{
			var toReturn:Vector.<qb2Object> = new Vector.<qb2Object>();
			
			pushEditSession();
			{
				for ( var i:int = 0; i < _objects.length; i++ )
				{
					var startedNumObjects:uint = _objects.length;
			
					var object:qb2Object = removeObjectAt(i--);
					toReturn.push(object);
				}
			}
			popEditSession();
			
			return toReturn;
		}
		
		public function explode(preserveVelocities:Boolean = true, addToParent:Boolean = true):Vector.<qb2Object>
		{
			var explodes:Vector.<qb2Object> = new Vector.<qb2Object>();
			
			if ( this is qb2Body )
			{
				var parentBody:qb2Body = this as qb2Body;
				
				for (var i:int = 0; i < _objects.length; i++) 
				{
					var explodesI:qb2Object = _objects[i];
					
					if ( explodesI is qb2IRigidObject )
					{
						var rigid:qb2IRigidObject = explodesI as qb2IRigidObject;
						
						if ( preserveVelocities && !_ancestorBody )
						{
							var worldVel:amVector2d = parentBody.getLinearVelocityAtLocalPoint(rigid.position);
							rigid.linearVelocity.copy(worldVel);
						}
						else
						{
							rigid.linearVelocity.zeroOut();
							rigid.angularVelocity = 0;
						}
						
						rigid.position.add(parentBody.position);
						rigid.rotateBy(parentBody.rotation, parentBody.position);
						
					}
					else if( explodesI is qb2Group )
					{
						var group:qb2Group = explodesI as qb2Group;
						group.translateBy(parentBody.position.asVector());
						group.rotateBy(parentBody.rotation, parentBody.position);
						
						if ( preserveVelocities && !_ancestorBody )
						{
							// do get vel at thing and set velocity of whole group
						}
						else
						{
							group.setAvgLinearVelocity(new amVector2d());
							group.setAvgAngularVelocity(0);
						}
					}
					
					var removed:qb2Object = parentBody.removeObjectAt(i--);
					explodes.push(removed);
				}
			}
			else if ( (this is qb2Group) && !preserveVelocities && !_ancestorBody ) // have to cancel out velocities
			{
				for ( i = 0; i < _objects.length; i++)
				{
					explodesI = _objects[i];
					
					if ( explodesI is qb2IRigidObject )
					{
						(explodesI as qb2IRigidObject).linearVelocity.zeroOut();
						(explodesI as qb2IRigidObject).angularVelocity = 0;
					}
					else if ( explodes[i] is qb2Group )
					{
						(explodesI as qb2Group).setAvgLinearVelocity(new amVector2d());
						(explodesI as qb2Group).setAvgAngularVelocity(0);
					}
				
					explodes.push(explodesI);
				}
			}
			
			if ( _parent )
			{
				if( addToParent )  _parent.addObjects(explodes);
				removeFromParent();
			}
			
			return explodes;
		}
		
		public override function testPoint(point:amPoint2d):Boolean
		{
			const localPoint:amPoint2d = getLocalPoint(point, _parent);
			
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				if ( _objects[i] is qb2Tangible )
				{
					if ( (_objects[i] as qb2Tangible).testPoint(localPoint) )
						return true;
				}
			}
			
			return false;
		}
		
		public override function set density(value:Number):void
		{
			pushEditSession();
			{
				for ( var i:int = 0; i < _objects.length; i++ )
				{
					if ( _objects[i] as qb2Tangible )
					{
						(_objects[i] as qb2Tangible).density = value;
					}
				}
			}
			popEditSession();
		}
		
		public override function set mass(value:Number):void
		{
			pushEditSession();
			{
				if ( _mass )
				{
					for ( var i:int = 0; i < _objects.length; i++ )
					{
						if ( _objects[i] is qb2Tangible )
						{
							var physObject:qb2Tangible = _objects[i] as qb2Tangible
							var ratio:Number = physObject._mass / _mass;
							physObject.mass = ratio * value;
						}
					}
				}
				else
				{
					var totalDensity:Number = value / _surfaceArea;
					for ( i = 0; i < _objects.length; i++ )
					{
						if ( _objects[i] is qb2Tangible )
						{
							(_objects[i] as qb2Tangible).density = totalDensity;
						}
					}
				}
			}
			popEditSession();
		}
		
		public override function scaleBy(xValue:Number, yValue:Number, origin:amPoint2d = null, scaleMass:Boolean = true, scaleJointAnchors:Boolean = true, scaleActor:Boolean = true):qb2Tangible
		{
			var forwardOrigin:amPoint2d = this is qb2Group ? origin : null;
			
			pushEditSession();
			{
				if ( this as qb2IRigidObject )
				{
					_rigidImp.scaleBy(xValue, yValue, origin, scaleMass, scaleJointAnchors, scaleActor);
				}
				
				var subOrigin:amPoint2d = this is qb2Body ? null : origin; // objects belonging to bodies are scaled relative to the body's origin.
				for (var i:int = 0; i < _objects.length; i++) 
				{
					var tang:qb2Tangible = _objects[i] as qb2Tangible;
					
					if ( !tang )  continue;
					
					tang.scaleBy(xValue, yValue, forwardOrigin, scaleMass, scaleJointAnchors, scaleActor);
				}
				
				// NOTE: this object's surfaceArea/mass are changed by children propagating said changes up through the tree on popEditSession().
			}
			popEditSession();
			
			return this;
		}
		
		public override function draw(graphics:srGraphics2d):void
		{
			for (var i:int = 0; i < _objects.length; i++) 
			{
				_objects[i].draw(graphics);
			}
		}
		
		public override function drawDebug(graphics:srGraphics2d):void
		{
			var debugDrawBit:uint = qb2_flags.JOINS_IN_DEBUG_DRAWING;
			
			for (var i:int = 0; i < _objects.length; i++) 
			{
				if ( _objects[i]._flags & debugDrawBit )
				{
					_objects[i].drawDebug(graphics);
				}
				
				if ( _objects[i] is qb2Tangible )
				{
					(_objects[i] as qb2Tangible).drawDebugExtras(graphics);
				}
			}
		}
		
		public override function get centerOfMass():amPoint2d
		{
			var totMass:Number = 0;
			var totX:Number = 0, totY:Number = 0;
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				var object:qb2Object = _objects[i];
				
				if ( !(object is qb2Tangible) )  continue;
				
				var physObject:qb2Tangible = _objects[i] as qb2Tangible;
				var ithMass:Number = physObject.mass;
				var ithCenter:amPoint2d = getWorldPoint(physObject.centerOfMass, this.parent);
				
				if ( !ithCenter )  continue;
				
				totX += ithCenter.x * ithMass;
				totY += ithCenter.y * ithMass;
				totMass += ithMass;
			}
			
			return totMass ? new amPoint2d(totX / totMass, totY / totMass) : new amPoint2d();
		}
		
		qb2_friend override function flushShapes():void
		{
			for (var i:int = 0; i < _objects.length; i++)
			{
				if ( _objects[i] is qb2Tangible )
				{
					(_objects[i] as qb2Tangible).flushShapes();
				}
			}
		}
		
		public function getAllRigids():Vector.<qb2IRigidObject>
		{
			if ( !_objects.length )  return null;
			
			var queue:Vector.<qb2Object> = new Vector.<qb2Object>();
		
			var toReturn:Vector.<qb2IRigidObject> = null;
			queue.unshift(this);
			while ( queue.length )
			{
				var object:qb2Object = queue.shift();
				
				if ( !(object is qb2Tangible) )  continue;
				
				var physObject:qb2Tangible = object as qb2Tangible
				
				if ( physObject is qb2ObjectContainer )
				{
					var container:qb2ObjectContainer = physObject as qb2ObjectContainer;
					for ( var i:int = 0; i < container.numObjects; i++ )
					{
						queue.push(container.getObjectAt(i));
					}
				}
				else if ( physObject is qb2IRigidObject )
				{
					if ( !toReturn )
						toReturn = new Vector.<qb2IRigidObject>();
						
					toReturn.push(physObject as qb2IRigidObject);
				}
			}
			
			return toReturn;
		}
		
		public function getRigidsAtPoint(point:amPoint2d, limit:uint = uint.MAX_VALUE, searchDirection:int = -1, dynamicOnly:Boolean = true):Vector.<qb2IRigidObject>
		{
			var toReturn:Vector.<qb2IRigidObject> = null;
			
			if ( !_objects.length || limit < 1 )  return toReturn;
	
			var queue:Vector.<qb2Object> = new Vector.<qb2Object>();
			queue.unshift(this);
			var count:uint = 0;
			while ( queue.length )
			{
				var object:qb2Object = queue.shift();
				
				if ( !(object is qb2Tangible) )  continue;
				
				var tang:qb2Tangible = object as qb2Tangible;
				
				if ( (!tang.mass || tang.isKinematic) && dynamicOnly )  continue;
				
				if ( tang is qb2Group )
				{
					var group:qb2Group = tang as qb2Group;
					if ( searchDirection < 0 )
					{
						for ( var i:int = group.numObjects-1; i >= 0; i--)
						{
							queue.unshift(group.getObjectAt(i));
						}
					}
					else
					{
						for ( i =0; i < group.numObjects; i++)
						{
							queue.unshift(group.getObjectAt(i));
						}
					}
				}
				else if ( tang is qb2IRigidObject )
				{
					if ( tang.testPoint(point) )
					{
						if ( !toReturn )  toReturn = new Vector.<qb2IRigidObject>();
						
						toReturn.push(tang);
						count++;
						
						if ( count >= limit )  return toReturn;
					}
				}
			}
			
			return toReturn;
		}
	}
}