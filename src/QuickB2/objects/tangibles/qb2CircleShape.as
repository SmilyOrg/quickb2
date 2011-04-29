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
	import As3Math.*;
	import As3Math.consts.*;
	import As3Math.geo2d.*;
	import Box2DAS.Collision.Shapes.*;
	import Box2DAS.Dynamics.*;
	import Box2DAS.Dynamics.Joints.*;
	import flash.display.*;
	import QuickB2.*;
	import QuickB2.debugging.*;
	import QuickB2.debugging.drawing.qb2_debugDrawFlags;
	import QuickB2.debugging.drawing.qb2_debugDrawSettings;
	import QuickB2.debugging.logging.qb2_toString;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import QuickB2.objects.joints.*;
	import QuickB2.stock.*;
	import surrender.srGraphics2d;
	
	use namespace qb2_friend;
	use namespace am_friend;

	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2CircleShape extends qb2Shape
	{
		private var _radius:Number = 0;
		
		public function qb2CircleShape() 
		{
			super();
			
			setProperty(qb2_props.ARC_APPROXIMATION, 20.0, false);
		}
		
		public function get arcApproximation():Number
			{  return getProperty(qb2_props.ARC_APPROXIMATION) as Number;  }
		public function set arcApproximation(value:Number):void
			{  setProperty(qb2_props.ARC_APPROXIMATION, value);  }
			
		public override function clone(deep:Boolean = true):qb2Object
		{
			var actorToo:Boolean = true;
			var deep:Boolean = true;
			
			var newCircleShape:qb2CircleShape = super.clone(deep) as qb2CircleShape;
			newCircleShape.set(_rigidImp._position.clone(), _radius, _rigidImp._rotation);
			newCircleShape.mass = this.mass;

			return newCircleShape;
		}
		
		public function convertToPoly(transferJoints:Boolean = true, switchPlaces:Boolean = true, numSides:int = -1, startPoint:amPoint2d = null ):qb2PolygonShape
		{
			numSides = numSides > 0 ? numSides : Math.max(perimeter / arcApproximation, 3);
			var majorAxis:amVector2d = startPoint ? startPoint.minus(_rigidImp._position) : new amVector2d(0, -_radius);
			var poly:qb2PolygonShape = qb2Stock.newEllipseShape(_rigidImp._position.clone(), majorAxis, _radius, numSides);
			poly._rigidImp._rotation = this._rigidImp._rotation;
			
			poly.copyTangibleProps(this, false);
			poly.mass = this.mass;
			poly.copyPropertiesAndFlags(this);
			
			if ( switchPlaces && _parent )
			{
				var index:int = _parent.getObjectIndex(this);
				_parent.setObjectAt(index, poly);
			}
				
			if ( transferJoints && _rigidImp._attachedJoints )
			{
				for (var i:int = 0; i < _rigidImp._attachedJoints.length; i++) 
				{
					var joint:qb2Joint = _rigidImp._attachedJoints[i--];
					
					if ( joint._object1 == this )
					{
						joint.setObject1(poly);
					}
					else if ( joint._object2 == this )
					{
						joint.setObject2(poly);
					}
					
					if ( !_rigidImp._attachedJoints )  break; // qb2Joint will nullify this array if the number of attached joints becomes zero, which in this case should always happen.
				}
			}
			
			return poly;
		}
		
		public function set(newPosition:amPoint2d, newRadius:Number, newRotation:Number = 0 ):qb2CircleShape
		{
			pushEditSession();
			{
				position = newPosition;
				
				_radius = newRadius;
				_rigidImp._rotation = newRotation;
		
				_surfaceArea = (_radius * _radius) * Math.PI;
				
				_geometryChangeOccuredWhileInEditSession = true;
			}
			popEditSession();
			
			return this;
		}
		
		public function get radius():Number
			{  return _radius;  }
		public function set radius(value:Number):void
			{  set(_rigidImp._position, value);  }
			
		public override function get perimeter():Number
			{  return 2 * AM_PI * _radius; }

		public override function get centerOfMass():amPoint2d
			{  return _rigidImp._position.clone();  }
		
		public override function scaleBy(xValue:Number, yValue:Number, origin:amPoint2d = null, scaleMass:Boolean = true, scaleJointAnchors:Boolean = true, scaleActor:Boolean = true):qb2Tangible
		{			
			pushEditSession();
			{
				_rigidImp.scaleBy(xValue, yValue, origin, scaleMass, scaleJointAnchors);
				
				var scaling:Number = (xValue + yValue)/2;
				_radius      *= scaling;
				_mass        *= scaleMass ? scaling : 1;
				_surfaceArea *= (_radius * _radius) * AM_PI;
				
				_geometryChangeOccuredWhileInEditSession = true;
			}
			popEditSession();
			
			return this;
		}
		
		public function asGeoCircle():amCircle2d
			{  return new amCircle2d(_rigidImp._position.clone(), _radius);  }
			
		qb2_friend override function makeShapeB2(theWorld:qb2World):void
		{			
			var conversion:Number = theWorld._pixelsPerMeter;
			var circShape:b2CircleShape = new b2CircleShape();
			
			if ( !_ancestorBody )
			{
				circShape.m_p.x = circShape.m_p.y = 0;
			}
			else
			{
				var ancestorBodyLocalPosition:amPoint2d = _parent == _ancestorBody ? _rigidImp._position : _ancestorBody.getLocalPoint(_parent.getWorldPoint(_rigidImp._position));
				circShape.m_p.x = ancestorBodyLocalPosition.x / conversion;
				circShape.m_p.y = ancestorBodyLocalPosition.y / conversion;
			}
			circShape.m_radius = this._radius / conversion;
			
			shapeB2s.length = 0; // just in case.
			shapeB2s.push(circShape);
			
			theWorld._totalNumCircles++;
			
			super.makeShapeB2(theWorld); // actually creates the shape from the definition(s) created here, and recomputes mass.
		}
		
		qb2_friend override function destroyShapeB2(theWorld:qb2World):void
		{
			theWorld._totalNumCircles--;
			super.destroyShapeB2(theWorld);
		}
		
		qb2_friend override function makeFrictionJoints():void
		{
			var numPoints:int = 4;
			var maxForce:Number = (frictionZ * _world.gravityZ * _mass) / (numPoints as Number);
			
			populateFrictionJointArray(numPoints);
			
			var incAngle:Number = (AM_PI * 2) / (numPoints as Number);
			var reusable:amPoint2d = amPoint2d.reusable;
			var circleShape:b2CircleShape = shapeB2s[0] as b2CircleShape;
			var orig:amPoint2d = new amPoint2d(circleShape.m_p.x, circleShape.m_p.y);
			reusable.copy(orig).incY( -circleShape.m_radius);
			
			for (var i:int = 0; i < frictionJoints.length; i++) 
			{
				var ithFrictionJoint:b2FrictionJoint = frictionJoints[i];
				
				ithFrictionJoint.m_maxForce  = maxForce;
				ithFrictionJoint.m_maxTorque = 0;// maxForce;
				
				ithFrictionJoint.m_localAnchorA.x = reusable.x;
				ithFrictionJoint.m_localAnchorA.y = reusable.y;
				
				reusable.rotateBy(incAngle, orig);
			}
		}
		
		public override function testPoint(point:amPoint2d):Boolean
		{
			if ( shapeB2s.length )
			{
				return super.testPoint(point);
			}
			else
			{
				return point.distanceTo(_rigidImp._position) <= radius;
			}
		}
		
		public override function draw(graphics:srGraphics2d):void
		{
			var vertex:amPoint2d = _parent ? _parent.getWorldPoint(_rigidImp._position) : _rigidImp._position;
			graphics.drawCircle(vertex.x, vertex.y, _radius);
		}
		
		public override function drawDebug(graphics:srGraphics2d):void
		{
			var staticShape:Boolean = mass == 0;
			
			var drawFlags:uint = qb2_debugDrawSettings.flags;
			
			if ( drawFlags & qb2_debugDrawFlags.OUTLINES )
				graphics.setLineStyle(qb2_debugDrawSettings.lineThickness, debugOutlineColor, qb2_debugDrawSettings.outlineAlpha);
			else
				graphics.setLineStyle();
			if ( drawFlags & qb2_debugDrawFlags.FILLS )
				graphics.beginFill(debugFillColor, qb2_debugDrawSettings.fillAlpha);
				
			draw(graphics);
			
			graphics.endFill();
			
			if ( (drawFlags & qb2_debugDrawFlags.OUTLINES) && (drawFlags & qb2_debugDrawFlags.CIRCLE_SPOKES) )
			{
				//graphics.lineStyle(qb2_debugDrawSettings.lineThickness, staticShape ? qb2_debugDrawSettings.staticOutlineColor : qb2_debugDrawSettings.dynamicOutlineColor, qb2_debugDrawSettings.outlineAlpha);
				var vertex:amPoint2d = _parent ? _parent.getWorldPoint(_rigidImp._position) : _rigidImp._position;
				var upVec:amVector2d = amVector2d.newRotVector(0, -1, _rigidImp._rotation).scaleBy(_radius);
				var vec:amVector2d = _parent ? _parent.getWorldVector(upVec) : upVec;
				var inc:Number = 0;
				
				var spokeFlags:Array =
				[
					qb2_debugDrawFlags.CIRCLE_SPOKE_1, qb2_debugDrawFlags.CIRCLE_SPOKE_2,
					qb2_debugDrawFlags.CIRCLE_SPOKE_3, qb2_debugDrawFlags.CIRCLE_SPOKE_4
				];
				
				for (var i:int = 0; i < spokeFlags.length; i++) 
				{
					if ( drawFlags & spokeFlags[i] )
					{
						if ( inc )
						{
							vec.rotateBy(inc);
							inc = 0;
						}
						
						graphics.moveTo(vertex.x, vertex.y);
						var moved:amPoint2d = vertex.translatedBy(vec);
						graphics.lineTo(moved.x, moved.y);
					}
					
					inc += RAD_90;
				}
			}
			
			super.drawDebug(graphics);
		}
		
		public override function toString():String 
			{  return qb2_toString(this, "qb2CircleShape");  }
	}
}