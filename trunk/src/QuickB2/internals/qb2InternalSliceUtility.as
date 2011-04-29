package QuickB2.internals 
{
	import As3Math.consts.*;
	import As3Math.geo2d.*;
	import As3Math.misc.*;
	import Box2DAS.Common.*;
	import Box2DAS.Dynamics.*;
	import flash.utils.*;
	import QuickB2.*;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	import As3Math.*;
	
	use namespace qb2_friend;
	use namespace am_friend;

	/**
	 * The "slice" implementation is put here so that qb2Tangible::slice() doesn't add another gagillion lines of code to an already too-long file.
	 * @author Doug Koellmer
	 * @private
	 */
	public class qb2InternalSliceUtility 
	{
		private static const traverser:qb2TreeTraverser = new qb2TreeTraverser();
		private static const intPoints:Vector.<amPoint2d> = new Vector.<amPoint2d>();
		private static const INFINITE:Number = 1000000;
		
		qb2_friend static function slice(rootTang:qb2Tangible, sliceLine:amLine2d, outputPoints:Vector.<amPoint2d>):Vector.<qb2Tangible>
		{
			var infiniteBeg:amPoint2d = sliceLine.point1.translatedBy(sliceLine.direction.negate().scaleBy(INFINITE));
			var distanceDict:Dictionary = new Dictionary(true); // stores point->point's distance from infiniteBeg
			var intDict:Dictionary = new Dictionary(true);  // stores point->point's intersection status, i.e. if it intersects an edge or a vertex.
			var toReturn:Vector.<qb2Tangible> = new Vector.<qb2Tangible>();
			traverser.root = rootTang;
			
			var numBegPointIntersections:int = 0;
			while ( traverser.hasNext )
			{
				var currObject:qb2Object = traverser.currentObject;
				
				//--- Proceed to the next object in the tree under a variety of conditions...
				if ( !(currObject is qb2Tangible) )
				{
					traverser.next(false);
					continue;
				}
				
				//--- Proceed down tree and continue until we find a sliceable shape.
				//--- Ancestor containers of shapes that have IS_SLICEABLE turned off will cause the traverser to skip that branch.
				//--- This means that even if a shape itself at a leaf having IS_SLICEABLE on still won't be sliced.
				var asTang:qb2Tangible = currObject as qb2Tangible;
				if( !asTang.isSliceFlagOn(qb2_sliceFlags.IS_SLICEABLE) )
				{
					traverser.next(false);
					continue;
				}
				if ( !(currObject is qb2Shape) )
				{
					traverser.next(true);
					continue;
				}
				
				//--- Find intersection points with the slice line.  Here we extend the beginning of the line by "infinite"
				//--- in order to know whether partial slices are entrances or exits.
				intPoints.length = 0;
				utilArray.length = 0;
				var localSliceLine:amLine2d = currObject.parent ?
						new amLine2d(currObject.parent.getLocalPoint(sliceLine.point1, rootTang), currObject.parent.getLocalPoint(sliceLine.point2, rootTang), sliceLine.lineType) :
						new amLine2d(sliceLine.point1.clone(), sliceLine.point2.clone());
				var localSliceLineBeg:amPoint2d = localSliceLine.point1.translatedBy(localSliceLine.direction.negate().scaleBy(INFINITE));
				var localSliceLineInf:amLine2d = new amLine2d(localSliceLineBeg, localSliceLine.point2.clone(), localSliceLine.lineType);
				qb2InternalLineIntersectionFinder.intersectsLine(currObject as qb2Tangible, localSliceLineInf, intPoints, true);
				
				//--- Search for doubled points and either remove them or correct their indeces.  This usually happens when a slice line encounters
				//--- internal seam of a polygon.  The seam, in turn, is generally caused by a partial slice into a circle or polygon.
				if ( intPoints.length > 1 && (currObject is qb2PolygonShape) )
				{
					var verts:Vector.<amPoint2d> = (currObject as qb2PolygonShape).polygon.verts;
					
					for (var m:int = 0; m < intPoints.length-1; m++) 
					{
						var mthPoint:amPoint2d        = intPoints[m]
						var mthPlusOnePoint:amPoint2d = intPoints[m + 1];
						
						if ( mthPoint.equals(mthPlusOnePoint, DIST_TOLERANCE) )
						{
							if ( mthPoint.userData & am_intersectionFlags.CURVE_TO_POINT && mthPlusOnePoint.userData & am_intersectionFlags.CURVE_TO_POINT )
							{
								intPoints.splice(m, 2);
								m -= 2;
							}
							else
							{
								var polyIndex1:uint = mthPoint.userData >> 16;
								var polyIndex2:uint = mthPlusOnePoint.userData >> 16;
								var vert1:amPoint2d = verts[polyIndex1];
								var vert2:amPoint2d = verts[polyIndex2];
								var vector:amVector2d = vert2.minus(vert1);
								var sliceLineVec:amVector2d = localSliceLine.asVector();
								var angle:Number = vector.clockwiseAngleTo(sliceLineVec);
								
								if ( angle >= 0 && angle <= AM_PI )
								{
									//--- Faster just to swap data rather than swapping places in the array...probably
									var tempUserData:uint = mthPoint.userData;
									mthPoint.userData = mthPlusOnePoint.userData;
									mthPlusOnePoint.userData = tempUserData;
								}
							}
						}
					}
				}
				
				//--- Set up some things for the following loop.
				var numPreviousPointsOffSliceLine:int = 0;
				var encounteredPointOnSliceLine:Boolean = false;
				var flagDict:Dictionary = new Dictionary(true);
				var polyEdits:Array = [];
				var asPoly:qb2PolygonShape;
				
				for (var l:int = 0; l < intPoints.length; l++) 
				{
					var lthIntPoint:amPoint2d = intPoints[l];
					var numIntPoints:int = 0;
					
					var lthIntFlags:uint = lthIntPoint.userData;
					var lthPlusOneIntFlags:uint = 0;
					
					flagDict[lthIntPoint] = lthIntFlags;
					
					//--- See if this int point is on the actual slice line (and not the infinite version), and then if it's an incoming or outgoing point.
					//--- Also see whether this slice will be a partial slice (numIntPoints==1) or a full slice (numIntPoints==2).
					if ( localSliceLine.isOn(lthIntPoint, DIST_TOLERANCE) )
					{
						if ( numPreviousPointsOffSliceLine % 2 == 0 || encounteredPointOnSliceLine || lthIntFlags & (am_intersectionFlags.CURVE_TO_POINT) )
						{
							if ( l == intPoints.length - 1 )
							{
								numIntPoints = 1;
								lthIntPoint.userData = INCOMING;
							}
							else
							{
								numIntPoints = 2;
								lthPlusOneIntFlags = intPoints[l + 1].userData;
								flagDict[intPoints[l + 1]] = intPoints[l + 1].userData;
								lthIntPoint.userData    = INCOMING;
								intPoints[++l].userData = OUTGOING;
							}
						}
						else
						{
							numIntPoints = 1;
							lthIntPoint.userData = OUTGOING;
							numBegPointIntersections++;
						}
						
						encounteredPointOnSliceLine = true;
					}
					else
					{
						numPreviousPointsOffSliceLine++;
					}
					
					//--- If this is a partial slice (and this shape allows partial slices)...
					if ( numIntPoints == 1 && asTang.isSliceFlagOn(qb2_sliceFlags.IS_PARTIALLY_SLICEABLE) )
					{
						//--- Add the entrance or exit intersection point to the output array (in order) if the caller so desires.
						if ( outputPoints )
						{
							var outputPoint:amPoint2d = currObject.parent ? currObject.parent.getWorldPoint(lthIntPoint, rootTang.parent) : lthIntPoint;
							outputPoint.userData = lthIntPoint.userData;
							qb2InternalLineIntersectionFinder.insertPointInOrder(outputPoint, outputPoints, distanceDict, infiniteBeg);
						}
						
						//--- Find the point that represents the penetration of this shape, either the beginning or end of the slice line in the shape's parent's coordinate space.
						var penetrationPoint:amPoint2d = null;
						if ( lthIntPoint.userData == OUTGOING )
						{
							penetrationPoint = currObject.parent ? currObject.parent.getLocalPoint(sliceLine.point1, rootTang.parent) : sliceLine.point1.clone();
						}
						else
						{
							penetrationPoint = currObject.parent ? currObject.parent.getLocalPoint(sliceLine.point2, rootTang.parent) : sliceLine.point2.clone();
						}
						
						//--- Get a polygon representation, either by casting or by converting a circle to a polygon based on where the slice line hit the circle.
						if ( currObject is qb2CircleShape )
						{
							asPoly = (currObject as qb2CircleShape).convertToPoly(false, true, -1, lthIntPoint);
						}
						else
						{
							asPoly = currObject as qb2PolygonShape;
						}
						
						//--- If the slice line intersected a vertex of a polygon, or if currObject is a decomposed circle...
						if ( (currObject is qb2CircleShape) || (lthIntFlags & am_intersectionFlags.CURVE_TO_POINT) )
						{
							var cornerIndex:int = lthIntFlags >> 16;
							var afterIndex:int  = cornerIndex == asPoly.numVertices - 1 ? 0 : cornerIndex + 1;
							var pinch:amPoint2d = asPoly.getVertexAt(cornerIndex).clone();
							
							registerPolyEdit(asPoly, polyEdits, penetrationPoint, afterIndex);
							registerPolyEdit(asPoly, polyEdits, pinch,            afterIndex);
						}
						
						//--- Otherwise currObject is a polygon and the slice line intersected an edge (probably the most common case)...
						else
						{
							var edgeIndex:uint = lthIntFlags >> 16;
							
							registerPolyEdit(asPoly, polyEdits, lthIntPoint.clone(), edgeIndex + 1);
							registerPolyEdit(asPoly, polyEdits, penetrationPoint,    edgeIndex + 1);
							registerPolyEdit(asPoly, polyEdits, lthIntPoint.clone(), edgeIndex + 1);
						}
					}
					
					//--- This is a slice that goes all the way through a discrete portion of the shape (or the whole shape).
					else if( numIntPoints == 2 )
					{
						var localIntPoint1:amPoint2d = lthIntPoint;
						var localIntPoint2:amPoint2d = intPoints[l];
						
						//--- Add the intersection points in order to the coordinate space of the original slice line if user wants output.
						if ( outputPoints )
						{
							var outputPoint1:amPoint2d = currObject.parent ? currObject.parent.getWorldPoint(localIntPoint1, rootTang.parent) : localIntPoint1;
							var outputPoint2:amPoint2d = currObject.parent ? currObject.parent.getWorldPoint(localIntPoint2, rootTang.parent) : localIntPoint2;
							outputPoint1.userData = localIntPoint1.userData;
							outputPoint2.userData = localIntPoint2.userData;
							qb2InternalLineIntersectionFinder.insertPointInOrder(outputPoint1, outputPoints, distanceDict, infiniteBeg);
							qb2InternalLineIntersectionFinder.insertPointInOrder(outputPoint2, outputPoints, distanceDict, infiniteBeg);
						}
						
						//--- Circle case for two intersections is easy...just split a circle into two polygonized halves
						//--- based on where the slice line intersects the circle.
						if ( currObject is qb2CircleShape )
						{
							var asCircle:qb2CircleShape = currObject as qb2CircleShape;
							
							var vec1:amVector2d = localIntPoint1.minus(asCircle.position);
							var vec2:amVector2d = localIntPoint2.minus(asCircle.position);
							var vec1ToVec2:Number = vec1.clockwiseAngleTo(vec2);
							var vec2ToVec1:Number = (AM_PI * 2) - vec1ToVec2;
							
							var poly1:qb2PolygonShape = polygonizeArc(asCircle, localIntPoint1, vec1ToVec2);
							var poly2:qb2PolygonShape = polygonizeArc(asCircle, localIntPoint2, vec2ToVec1);
							
							if ( asCircle.parent && asCircle.isSliceFlagOn(qb2_sliceFlags.REMOVES_SELF_FROM_WORLD) )
							{
								asCircle.removeFromParent();
							}
							
							toReturn.push(poly1, poly2);
						}
						
						//--- Polygon case sucks because we have to keep track of and account for all kinds of crap.
						else if ( currObject is qb2PolygonShape )
						{
							asPoly = currObject as qb2PolygonShape;
							
							var index1:uint = lthIntFlags >> 16;
							var index2:uint = lthPlusOneIntFlags >> 16;
							
							var index1IsVertexInt:Boolean = lthIntFlags        & am_intersectionFlags.CURVE_TO_POINT ? true : false;
							var index2IsVertexInt:Boolean = lthPlusOneIntFlags & am_intersectionFlags.CURVE_TO_POINT ? true : false;
							
							var newPoly:qb2PolygonShape = new qb2PolygonShape();
							//newPoly.copyTangibleProps(asPoly);
							newPoly.copyPropertiesAndFlags(asPoly);
							toReturn.push(newPoly);
							
							var modIndex1:int = index1;
							var modIndex2:int = index2;
							
							var mod:int = asPoly.numVertices;
							
							var flipPoints:Boolean = false;
							var numSteps:int = 0;
							
							for (var i:int = modIndex1; i != modIndex2; i = (i+1) % mod ) 
							{
								for (var j:int = 0; j < intPoints.length; j++) 
								{
									if ( j == l || j == l - 1 )  continue;
									
									var jthIndex:uint = flagDict[intPoints[j]] ? flagDict[intPoints[j]] >> 16 : intPoints[j].userData >> 16;
									
									if ( jthIndex == i )
									{
										flipPoints = true;
										break;
									}
								}
								
								if ( flipPoints )
								{
									break;
								}
								
								numSteps++;
							}
							
							if ( !flipPoints && intPoints.length == 2 )
							{
								if ( numSteps < mod / 2 )
								{
									flipPoints = false;
								}
								else if ( modIndex1 > modIndex2 )
								{
									flipPoints = true;
								}
							}
							
							if ( flipPoints )
							{
								var temp:int = modIndex1;
								modIndex1 = modIndex2;
								modIndex2 = temp;
								
								var tempPoint:amPoint2d = localIntPoint1;
								localIntPoint1 = localIntPoint2;
								localIntPoint2 = tempPoint;
								
								var tempBool:Boolean = index1IsVertexInt;
								index1IsVertexInt = index2IsVertexInt;
								index2IsVertexInt = tempBool;
							}
		
							var count:int = (modIndex1 + 1) % mod;
							
							if ( index1IsVertexInt )
							{
								newPoly.addVertex(asPoly.getVertexAt(modIndex1).clone());
							}
							else
							{
								newPoly.addVertex(localIntPoint1.clone());
								registerPolyEdit(asPoly, polyEdits, localIntPoint1.clone(), (modIndex1 + 1) % mod );
							}
							
							while ( count != (modIndex2+1) % mod )
							{
								newPoly.addVertex(asPoly.getVertexAt(count).clone());
								
								registerPolyEdit(asPoly, polyEdits, null, count );
								
								count++;
								count = count % mod;
							}
							
							if ( index2IsVertexInt )
							{
								registerPolyEdit(asPoly, polyEdits, asPoly.getVertexAt(modIndex2), (modIndex2+1) % mod);
							}
							else
							{
								newPoly.addVertex(localIntPoint2.clone());
								registerPolyEdit(asPoly, polyEdits, localIntPoint2.clone(), count );
							}
							
							if ( asPoly.parent && asPoly.isSliceFlagOn(qb2_sliceFlags.ADDS_NEW_PARTS_TO_WORLD) )
							{
								newPoly.position = asPoly.parent.getWorldPoint(newPoly.position, rootTang);
								newPoly.userData = asPoly;
								rootTang.parent.addObject(newPoly);
							}
						}
					}
				}
				
				//--- Edits to the original polygon are accumlated throughtout the above loop and only processed here.
				//--- Polygons with CHANGES_OWN_GEOMETRY off won't have any changes accumulated in polyEdits.
				if ( polyEdits.length )
				{
					asPoly.pushEditSession();
					var offset:int = 0;
					for (var k:int = 0; k < polyEdits.length; k++) 
					{
						if ( polyEdits[k] is int )
						{
							asPoly.removeVertexAt(polyEdits[k] + offset);
							offset--;
						}
						else
						{
							asPoly.insertVertexAt(polyEdits[k].userData + offset, polyEdits[k]);
							polyEdits[k].userData = null;
							offset++;
						}
					}
					asPoly.popEditSession();
				}
				
				traverser.next();
			}
			
			//--- Add caps to the intersection points for the beg/end of the slice line, if needed.
			if ( outputPoints )
			{
				if ( sliceLine.lineType != amLine2d.LINE_TYPE_INFINITE )
				{
					var lineBeg:amPoint2d = sliceLine.point1.clone();
					lineBeg.userData = numBegPointIntersections;
					outputPoints.unshift(lineBeg);
				}
				
				if ( sliceLine.lineType == amLine2d.LINE_TYPE_SEGMENT )
				{
					outputPoints.push(sliceLine.point2.clone());
				}
			}
			
			return toReturn;
		}
		
		private static function registerPolyEdit(poly:qb2PolygonShape, editArray:Array, point:amPoint2d, index:int):void
		{
			if ( !(poly.sliceFlags & qb2_sliceFlags.CHANGES_OWN_GEOMETRY) )  return;
			
			var inserted:Boolean = false;
			if ( point )
			{
				point.userData = index;
			}
			
			for (var i:int = 0; i < editArray.length; i++) 
			{
				var ithIndex:int = editArray[i] is int ? editArray[i] as int : (editArray[i] as amPoint2d).userData as int;
				
				if ( index < ithIndex )
				{
					editArray.splice(i, 0, point ? point : index);
					inserted = true;
					break;
				}
			}
			
			if ( !inserted )
			{
				editArray.push(point ? point : index);
			}
		}
		
		private static function polygonizeArc(circleShape:qb2CircleShape, startPoint:amPoint2d, sweepAngle:Number):qb2PolygonShape
		{
			var circum:Number = circleShape.perimeter;
			var ratio:Number = sweepAngle / (AM_PI * 2);
			var arcLength:Number = ratio * circum;
			
			const min:int = 2;
			var approx:Number = circleShape.arcApproximation;
			var numSegs:int = Math.max(arcLength / approx, min);
			var angInc:Number = (AM_PI * 2) * ((arcLength / (numSegs as Number)) / circum);
			
			var poly:qb2PolygonShape = new qb2PolygonShape();
			poly.addVertex(startPoint.clone() );
			var rotPoint:amPoint2d = startPoint.clone();
			for (var i:int = 0; i < numSegs; i++) 
			{
				poly.addVertex(rotPoint.rotateBy(angInc, circleShape.position).clone());
			}
			
			poly.copyTangibleProps(circleShape, false);
			poly.density = circleShape.density;
			poly.copyPropertiesAndFlags(circleShape);
			
			if ( circleShape.parent )
			{
				if ( circleShape.isSliceFlagOn(qb2_sliceFlags.ADDS_NEW_PARTS_TO_WORLD) )
				{
					poly.position = circleShape.parent.getWorldPoint(poly.position, traverser.root as qb2Tangible);
					poly.userData = circleShape;
					traverser.root.parent.addObject(poly);
				}
			}
			
			return poly;
		}
		
		private static var utilPoint:amPoint2d = new amPoint2d();
		private static var utilLine:amLine2d = new amLine2d();
		private static var utilArray:Vector.<amPoint2d> = new Vector.<amPoint2d>();
		
		private static const INCOMING:String = "incoming";
		private static const OUTGOING:String = "outgoing";
		private static const INT_TOLERANCE:Number = .00000001;
		private static const DIST_TOLERANCE:Number = .001;
	}
}