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
	import As3Math.general.*;
	import As3Math.geo2d.*;
	import Box2DAS.Collision.Shapes.*;
	import Box2DAS.Common.*;
	import Box2DAS.Dynamics.*;
	import Box2DAS.Dynamics.Joints.*;
	import flash.display.*;
	import QuickB2.*;
	import QuickB2.debugging.*;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import surrender.srGraphics2d;
	
	use namespace qb2_friend;
	
	import As3Math.*;
	use namespace am_friend;

	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2PolygonShape extends qb2Shape
	{
		qb2_friend const polygon:amPolygon2d = new amPolygon2d();
		
		qb2_friend const lagPoint:amPoint2d = new amPoint2d();
		qb2_friend var lagRot:Number = 0;
	
		public function qb2PolygonShape() 
		{
			super();
			
			polygon.addEventListener(amUpdateEvent.ENTITY_UPDATED, polygonUpdated);
		}
		
		private function polygonUpdated(evt:amUpdateEvent):void
		{
			pushEditSession()
			{
				_geometryChangeOccuredWhileInEditSession = true;
				_surfaceArea = polygon.area;
			}
			popEditSession();
		}
		
		public function get closed():Boolean
			{  return _closed;  }
		public function set closed(bool:Boolean):void
		{
			if ( _closed != bool )
			{
				_closed = bool;
				
				pushEditSession();
				{
					_geometryChangeOccuredWhileInEditSession = true;
				}
				popEditSession();
			}
		}
		private var _closed:Boolean = true;
		
		public function set(vertices:Vector.<amPoint2d> = null, registrationPoint:amPoint2d = null, isClosed:Boolean = true):qb2PolygonShape
		{
			if ( !registrationPoint )
			{
				const tempPoly:amPolygon2d = new amPolygon2d(vertices);
				registrationPoint = tempPoly.centerOfMass;
			}
			
			lagPoint.copy(registrationPoint);
			lagRot = _rigidImp._rotation = 0;
			
			pushEditSession();
			{
				position = registrationPoint;
				
				_closed = isClosed;
				
				polygon.set(vertices); // eventually gets around to calling polygonUpdated(), which changes _surfaceArea and registers a geometry change.
			}
			popEditSession();
			
			return this;
		}
		
		public function addVertex(vertex1:amPoint2d, ... oneOrMoreVertices):qb2PolygonShape
		{
			//--- The listeners are removed here in order to not have to recalculate polygon surface area for every vertex.
			pushEditSession();
			{
				polygon.removeEventListener(amUpdateEvent.ENTITY_UPDATED, polygonUpdated);
				{
					for ( var i:int = 0; i < oneOrMoreVertices.length; i++ )
					{
						polygon.addVertex(oneOrMoreVertices[i] as amPoint2d);
					}
					polygonUpdated(null); // call the event listener manually to make up for removing the listeners.
				}
				polygon.addEventListener(amUpdateEvent.ENTITY_UPDATED, polygonUpdated);
			}
			popEditSession();
			
			return this;
		}

		public function getVertexAt(index:uint):amPoint2d
		{
			return polygon.getVertexAt(index);
		}

		public function getEdgeAt(index:uint):amLine2d
		{
			return polygon.getEdgeAt(index);
		}
		
		public function setVertexAt(index:uint, point:amPoint2d):qb2PolygonShape
			{  polygon.setVertexAt(index, point);  return this; }
			
		public function insertVertexAt(index:uint, ... oneOrMoreVertices):qb2PolygonShape
		{
			//--- See "addVertex" for comments.
			pushEditSession();
			{
				polygon.removeEventListener(amUpdateEvent.ENTITY_UPDATED, polygonUpdated);
				{
					for ( var i:int = 0; i < oneOrMoreVertices.length; i++ )
					{
						polygon.insertVertexAt(index, oneOrMoreVertices[i] as amPoint2d);
						index++;
					}
					polygonUpdated(null);
				}
				polygon.addEventListener(amUpdateEvent.ENTITY_UPDATED, polygonUpdated);
			}
			popEditSession();
			
			return this;
		}
		
		public function removeVertex(vertex:amPoint2d):qb2PolygonShape
			{  polygon.removeVertex(vertex);  return this;  }
		
		public function removeVertexAt(index:uint):amPoint2d
			{  var toReturn:amPoint2d = polygon.removeVertexAt(index);  return toReturn;  }
			
		public function removeAllVertices():Vector.<amPoint2d>
			{  var toReturn:Vector.<amPoint2d> = polygon.removeAllVertices();  return toReturn;  }
		
		public function get numVertices():uint
			{  return polygon.numVertices;  }
		
		public override function setTransform(point:amPoint2d, rotationInRadians:Number):qb2IRigidObject
		{
			updateFromLagPoints(point, rotationInRadians);
			
			return super.setTransform(point, rotationInRadians);
		}
		
		public override function scaleBy(xValue:Number, yValue:Number, origin:amPoint2d = null, scaleMass:Boolean = true, scaleJointAnchors:Boolean = true, scaleActor:Boolean = true):qb2Tangible
		{
			pushEditSession();
			{
				_rigidImp.scaleBy(xValue, yValue, origin, scaleMass, scaleJointAnchors);
				
				polygon.scaleBy(xValue, yValue, origin);
				
				 // "polygonUpdated" updates _surfaceArea.
				
				var scaling:Number = xValue * yValue;
				_mass        *= scaleMass ? scaling : 1;
				
				_geometryChangeOccuredWhileInEditSession = true;
			}
			popEditSession();
			
			return this;
		}

		public override function clone(deep:Boolean = true):qb2Object
		{
			var newPolyShape:qb2PolygonShape = super.clone(deep) as qb2PolygonShape;
			newPolyShape._rigidImp._rotation = _rigidImp._rotation;
			newPolyShape._closed = this._closed;
			newPolyShape._rigidImp._position.copy(_rigidImp._position);
			
			newPolyShape.set(polygon.asPoints(), _rigidImp._position.clone());
			newPolyShape.mass = this.mass;
			
			return newPolyShape;
		}
		
		public function asGeoPolygon():amPolygon2d
		{
			return polygon.clone() as amPolygon2d;
		}
		
		qb2_friend function updateFromLagPoints(newPos:amPoint2d, newRot:Number):void
		{
			// This function has to be super optimized because it's rather time critical.
			// Therefore we hackishly bypass the normal API for points/vectors to do things as quickly as possible.
			
			const vecX:Number = newPos._x - lagPoint._x, vecY:Number = newPos._y - lagPoint._y;
			const rotDiff:Number = newRot - lagRot;
			
			if ( vecX == 0 && vecY == 0 && rotDiff == 0 )  return;
			
			var numVerts:int = polygon.verts.length;
			
			if ( rotDiff && (vecX || vecY) )  // rotate and translate
			{
				var cos_rotDiff:Number = Math.cos(rotDiff);
				var sin_rotDiff:Number = Math.sin(rotDiff);
				
				for ( var i:int = 0; i < numVerts; i++ )
				{
					var oldVert:amPoint2d = polygon.verts[i];
					
					oldVert._x += vecX;
					oldVert._y += vecY;

					var newVertX:Number = newPos._x + cos_rotDiff * (oldVert._x - newPos._x) - sin_rotDiff * (oldVert._y - newPos._y);
					var newVertY:Number = newPos._y + sin_rotDiff * (oldVert._x - newPos._x) + cos_rotDiff * (oldVert._y - newPos._y);
					
					oldVert._x = newVertX;
					oldVert._y = newVertY;				
				}
				
				//--- Update center of mass.
				polygon._centerOfMass._x += vecX;
				polygon._centerOfMass._y += vecY;
				var newCenterX:Number = newPos._x + cos_rotDiff * (polygon._centerOfMass._x - newPos._x) - sin_rotDiff * (polygon._centerOfMass._y - newPos._y);
				var newCenterY:Number = newPos._y + sin_rotDiff * (polygon._centerOfMass._x - newPos._x) + cos_rotDiff * (polygon._centerOfMass._y - newPos._y);
				polygon._centerOfMass._x = newCenterX;
				polygon._centerOfMass._y = newCenterX;
			}
			else if ( rotDiff ) // only rotate
			{
				cos_rotDiff = Math.cos(rotDiff);
				sin_rotDiff = Math.sin(rotDiff);
				
				for ( i = 0; i < numVerts; i++ )
				{
					oldVert = polygon.verts[i];

					newVertX = newPos._x + cos_rotDiff * (oldVert._x - newPos._x) - sin_rotDiff * (oldVert._y - newPos._y);
					newVertY = newPos._y + sin_rotDiff * (oldVert._x - newPos._x) + cos_rotDiff * (oldVert._y - newPos._y);
					
					oldVert._x = newVertX;
					oldVert._y = newVertY;
				}
				
				//--- Update center of mass.
				newCenterX = newPos._x + cos_rotDiff * (polygon._centerOfMass._x - newPos._x) - sin_rotDiff * (polygon._centerOfMass._y - newPos._y);
				newCenterY = newPos._y + sin_rotDiff * (polygon._centerOfMass._x - newPos._x) + cos_rotDiff * (polygon._centerOfMass._y - newPos._y);
				polygon._centerOfMass._x = newCenterX;
				polygon._centerOfMass._y = newCenterX;
			}
			else // only translate
			{
				for ( i = 0; i < numVerts; i++ )
				{
					oldVert = polygon.verts[i];
					
					oldVert._x += vecX;
					oldVert._y += vecY;
				}
				
				//--- Update center of mass.
				polygon._centerOfMass._x += vecX;
				polygon._centerOfMass._y += vecY;
			}
			
			lagPoint._x = newPos._x;
			lagPoint._y = newPos._y;
			lagRot = newRot;
			
			//--- This is how things would be done through the As3Math API...much neater but also too slow for our purposes.
			/*var vec:amVector2d = newPos.minus(lagPoint);
			polygon.removeCallback(polygonUpdated);
				polygon.translateBy(vec);
				polygon.rotateBy(newRot - lagRot, newPos);
			polygon.addCallback(polygonUpdated);
			
			lagRot = newRot;
			lagPoint.copy(newPos);*/
		}
		
		public override function get centerOfMass():amPoint2d
		{
			if ( !_bodyB2 )
			{
				return polygon.centerOfMass;
			}
			else
			{
				var vec:V2 = _bodyB2.GetWorldCenter();
				return new amPoint2d(vec.x * worldPixelsPerMeter, vec.y * worldPixelsPerMeter);
			}
		}
		
		private const b2Verts:Vector.<V2> = new Vector.<V2>();

		public override function get perimeter():Number
			{  return polygon.perimeter }
			
		qb2_friend override function makeShapeB2(theWorld:qb2World):void
		{
			var conversion:Number = theWorld._pixelsPerMeter;
			var inverse:Number = 1 / conversion;
			
			const reusable:amPoint2d = new amPoint2d();
			
			var numVerts:int = this.numVertices;
			b2Verts.length = 0;
			var allowComplex:Boolean = allowComplexPolygons;
				
			for ( var i:int = 0; i < numVerts; i++ )
			{
				var pnt:amPoint2d = reusable.copy(this.getVertexAt(i));
				if ( !_ancestorBody )
				{
					pnt.rotateBy( -_rigidImp._rotation, _rigidImp._position).subtract(_rigidImp._position);
				}
				else
				{
					pnt = _parent == _ancestorBody ? pnt : _ancestorBody.getLocalPoint(_parent.getWorldPoint(pnt));
				}
				
				pnt.scaleBy(inverse, inverse);
				
				if ( i >= 2 )
				{
				//	var 
				}
				
				b2Verts.push(new V2(pnt.x, pnt.y));
			}
			
			if ( numVerts > 2 )
			{
				if ( _closed )
				{
					if ( allowComplex )
					{
						if ( polygon.convex && numVerts <= 8 )
						{
							b2PolygonShape.EnsureCorrectVertexDirection(b2Verts);
							var polyShape:b2PolygonShape = new b2PolygonShape();
							polyShape.m_vertexCount = numVerts;
							polyShape.Set(b2Verts);
							shapeB2s.push(polyShape);
						}
						else
						{
							var vertsAsNumbers:Vector.<Number> = new Vector.<Number>();
							for ( i = 0; i < numVerts; i++)
							{
								vertsAsNumbers.push(b2Verts[i].x, b2Verts[i].y);
							}
							
							var polygonShapes:Vector.<b2PolygonShape> = b2PolygonShape.Decompose(vertsAsNumbers);
							for ( i = 0; i < polygonShapes.length; i++ )
							{
								shapeB2s.push(polygonShapes[i]);
							}
						}
					}
					else
					{
						polyShape = new b2PolygonShape();
						polyShape.m_vertexCount = numVerts;
						polyShape.Set(b2Verts);
						shapeB2s.push(polyShape);
					}
				}
				else
				{
					for ( i = 0; i < numVerts-1; i++ )
					{
						var edgeShape:b2EdgeShape = new b2EdgeShape();
						
						if ( i > 0 )
						{
							edgeShape.m_hasVertex0 = true;
							edgeShape.m_vertex0.v2 = b2Verts[i - 1];
						}
						
						edgeShape.m_vertex1.v2 = b2Verts[i];
						edgeShape.m_vertex2.v2 = b2Verts[i + 1];
						
						if ( i < numVerts - 2 )
						{
							edgeShape.m_hasVertex3 = true;
							edgeShape.m_vertex3.v2 = b2Verts[i + 2];
						}
						
						shapeB2s.push(edgeShape);
					}
				}
			}
			else if( numVerts == 2 )
			{
				edgeShape = new b2EdgeShape();
				edgeShape.m_vertex0.v2 = b2Verts[0];
				edgeShape.m_vertex1.v2 = b2Verts[1];
				shapeB2s.push(edgeShape);
			}
			/*else if ( numVerts == 1 )
			{
				var circShape:b2CircleShape = new b2CircleShape();
				circShape.m_p.x = b2Verts[0].x;
				circShape.m_p.y = b2Verts[0].y;
				circShape.m_radius = 1 / conversion;
				shapeB2s.push(circShape);
			}*/
			else return;
			
			super.makeShapeB2(theWorld); // actually creates the shape from the definition(s) created here, and recomputes mass.
			
			theWorld._totalNumPolygons++;
		}
		
		qb2_friend override function destroyShapeB2(theWorld:qb2World):void
		{
			super.destroyShapeB2(theWorld);
			
			theWorld._totalNumPolygons--;
		}
		
		qb2_friend override function makeFrictionJoints():void
		{
			var numPoints:int = b2Verts.length;
			var maxForce:Number = (frictionZ * _world.gravityZ * _mass) / (numPoints as Number);
			
			populateFrictionJointArray(numPoints);
			
			for (var i:int = 0; i < frictionJoints.length; i++) 
			{
				var ithFrictionJoint:b2FrictionJoint = frictionJoints[i];
				
				ithFrictionJoint.m_maxForce  = maxForce;
				ithFrictionJoint.m_maxTorque = 0;// maxForce / 2;
				
				ithFrictionJoint.m_localAnchorA.x = b2Verts[i].x;
				ithFrictionJoint.m_localAnchorA.y = b2Verts[i].y;
			}
		}
		
		public override function testPoint(point:amPoint2d):Boolean
		{
			if ( shapeB2s.length )
			{
				return super.testPoint(point); // uses b2Shape::TestPoint()
			}
			else
			{
				return polygon.isOn(point);
			}
		}
		
		public override function draw(graphics:srGraphics2d):void
		{
			if ( !_world )
			{
				var numVerts:uint = polygon.numVertices;
				
				if ( numVerts == 0 )  return;
				
				var firstVertex:amPoint2d = (_parent is qb2Body ) ? (_parent as qb2Body ).getWorldPoint(getVertexAt(0)) : getVertexAt(0);
				graphics.moveTo(firstVertex.x, firstVertex.y);
				
				for (var i:int = 1; i < numVerts; i++)
				{
					var vertex:amPoint2d = (_parent is qb2Body ) ? (_parent as qb2Body ).getWorldPoint(getVertexAt(i)) : getVertexAt(i);
					graphics.lineTo(vertex.x, vertex.y);
				}
				
				if ( _closed )  graphics.lineTo(firstVertex.x, firstVertex.y);
			}
			else
			{
				numVerts = b2Verts.length;
				
				if ( numVerts == 0 || !fixtures.length )  return;
				
				var theBodyB2:b2Body = fixtures[0].m_body;
				var transform:b2Transform = theBodyB2.m_xf;
				var p:b2Vec2 = transform.position;
				var r:b2Mat22 = transform.R;
				var col1:b2Vec2 = r.col1;
				var col2:b2Vec2 = r.col2;
				var pixPerMeter:Number = worldPixelsPerMeter;
				
				var firstX:Number, firstY:Number;
				for ( i = 0; i < numVerts; i++)
				{
					var v:V2 = b2Verts[i];
					
					var x:Number = col1.x * v.x + col2.x * v.y;
					var y:Number = col1.y * v.x + col2.y * v.y;
					
					x += p.x;
					y += p.y;
					
					x *= pixPerMeter;
					y *= pixPerMeter;
					
					if ( i )
					{
						graphics.lineTo(x, y);
					}
					else
					{
						graphics.moveTo(firstX = x, firstY = y);
					}
				}
				
				if ( _closed )  graphics.lineTo(firstX, firstY);
			}
		}
		
		public override function drawDebug(graphics:srGraphics2d):void
		{
			const drawFlags:uint = qb2_debugDrawSettings.flags;
			var drawOutlines:Boolean = drawFlags & qb2_debugDrawFlags.OUTLINES ? true : false;
			var drawFill:Boolean     = drawFlags & qb2_debugDrawFlags.FILLS ?    true : false;
			var drawVertices:Boolean = drawFlags & qb2_debugDrawFlags.VERTICES ? true : false;
			
			if ( drawOutlines || drawFill || drawVertices )
			{
				var staticShape:Boolean = _mass == 0;
		
				if ( drawOutlines )
					graphics.setLineStyle(qb2_debugDrawSettings.lineThickness, debugOutlineColor, qb2_debugDrawSettings.outlineAlpha);
				else
					graphics.setLineStyle();
					
				if ( _closed && drawFill )
					graphics.beginFill(debugFillColor, qb2_debugDrawSettings.fillAlpha);
					
				if( drawFill || drawOutlines )
					draw(graphics);
				
				graphics.endFill();
				
				var numVerts:uint = polygon.numVertices;
				
				if ( drawVertices && numVerts )
				{
					graphics.setLineStyle();
					graphics.beginFill(qb2_debugDrawSettings.vertexColor, qb2_debugDrawSettings.vertexAlpha);
					
					for (var i:int = 0; i < numVerts; i++) 
					{
						var vertex:amPoint2d = (_parent is qb2Body ) ? (_parent as qb2Body ).getWorldPoint(getVertexAt(i)) : getVertexAt(i);
						vertex.draw(graphics, qb2_debugDrawSettings.pointRadius, false);
					}
					
					graphics.endFill();
				}
			}
			
			if ( shapeB2s.length > 1 )
			{
				if ( qb2_debugDrawSettings.flags & qb2_debugDrawFlags.DECOMPOSITION )
				{
					graphics.setLineStyle(qb2_debugDrawSettings.lineThickness, debugOutlineColor, qb2_debugDrawSettings.outlineAlpha);
					
					var pixPer:Number = worldPixelsPerMeter;
					var xf:XF = fixtures[0].m_body.GetTransform();
					for (var j:int = 0; j < shapeB2s.length; j++) 
					{
						var polygonShape:b2PolygonShape = shapeB2s[j] as b2PolygonShape;
						
						var vertices:Vector.<V2> = polygonShape.m_vertices;
						var vertexCount:int = polygonShape.m_vertexCount;
						var v:V2 = xf.multiply(vertices[0]);
						graphics.moveTo(v.x * pixPer, v.y * pixPer);
						
						for( i = 1; i < vertexCount; ++i) {
							v = xf.multiply(vertices[i]);
							graphics.lineTo(v.x * pixPer, v.y * pixPer);
						}
						v = xf.multiply(vertices[0]);
						graphics.lineTo(v.x * pixPer, v.y * pixPer);
					}
				}
			}
			
			super.drawDebug(graphics);
		}
		
		public override function toString():String 
			{  return qb2DebugTraceUtils.formatToString(this, "qb2PolygonShape");  }
	}
}